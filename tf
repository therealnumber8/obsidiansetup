# azure_vm_module/main.tf

terraform {
  required_version = ">= 1.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.105"
    }
  }
}

provider "azurerm" {
  features {}
}

# -------------------- Variables --------------------
variable "vm_name"               { type = string }
variable "resource_group_name"    { type = string }
variable "location"               { type = string }

variable "subnet_ids" {
  type        = any  # string or list(string)
  description = "Subnet ID (string) or list of subnet IDs to align (index‑wise) with NICs. If a single subnet is given but multiple NICs are attached, every NIC will use that same subnet."
}

variable "vm_size"               { type = string  default = "Standard_B2s" }

variable "os_type" {
  type        = string
  description = "linux or windows"
  validation {
    condition     = contains(["linux", "windows"], lower(var.os_type))
    error_message = "os_type must be either \"linux\" or \"windows\"."
  }
}

variable "admin_username"        { type = string }

variable "admin_password" {
  type      = string
  default   = null
  sensitive = true
}

variable "ssh_public_key" {
  type    = string
  default = null
}

variable "disable_password_authentication" {
  type        = bool
  default     = true
  description = "Disable password auth on Linux VMs (ignored for Windows)."
}

variable "use_existing_nics" {
  type        = list(string)
  default     = []
  description = "Optional list of *names* of existing NICs (in the same RG) to attach in the provided order. If non‑empty, module will *not* create NICs."
}

variable "image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

variable "data_disks" {
  type = list(object({
    name    = string
    size_gb = number
    sku     = optional(string, "Premium_LRS")
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

# -------------------- Locals --------------------
locals {
  is_linux   = lower(var.os_type) == "linux"
  is_windows = !local.is_linux

  subnet_ids_list = flatten([var.subnet_ids])

  create_nics     = length(var.use_existing_nics) == 0

  # Align subnets to NIC count:
  # ‑ if caller supplies more subnets than NICs -> truncate automatically via index match
  # ‑ if caller supplies exactly one subnet but multiple NICs -> replicate that subnet
  aligned_subnets = local.create_nics ? local.subnet_ids_list : (
    length(local.subnet_ids_list) == 1 ? [for _ in var.use_existing_nics : local.subnet_ids_list[0]] : local.subnet_ids_list
  )
}

# -------------------- Networking --------------------
# Create new NICs when use_existing_nics is empty
resource "azurerm_network_interface" "this" {
  for_each = local.create_nics ? { for idx, subnet in local.aligned_subnets : idx => subnet } : {}

  name                = "${var.vm_name}-nic-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = each.value
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# Lookup existing NICs (order preserved)
data "azurerm_network_interface" "existing" {
  for_each = local.create_nics ? {} : { for idx, n in var.use_existing_nics : idx => n }

  name                = each.value
  resource_group_name = var.resource_group_name
}

# Build NIC ID list preserving the caller's order
locals {
  network_interface_ids = local.create_nics ?
    [for n in azurerm_network_interface.this : n.value.id] :
    [for idx in range(length(var.use_existing_nics)) : data.azurerm_network_interface.existing[tostring(idx)].id]
}

# -------------------- Managed Data Disks --------------------
resource "azurerm_managed_disk" "data" {
  for_each = { for d in var.data_disks : d.name => d }

  name                 = each.value.name
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = lookup(each.value, "sku", "Premium_LRS")
  create_option        = "Empty"
  disk_size_gb         = each.value.size_gb

  tags = var.tags
}

# -------------------- Virtual Machines --------------------
resource "azurerm_linux_virtual_machine" "this" {
  count  = local.is_linux ? 1 : 0

  name                  = var.vm_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  admin_username        = var.admin_username
  disable_password_authentication = var.disable_password_authentication

  network_interface_ids = local.network_interface_ids

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != null ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key
    }
  }

  tags = var.tags
}

resource "azurerm_windows_virtual_machine" "this" {
  count  = local.is_windows ? 1 : 0

  name                  = var.vm_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password

  network_interface_ids = local.network_interface_ids

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  tags = var.tags
}

# -------------------- Data‑Disk Attachments --------------------
locals {
  vm_id = local.is_linux ? azurerm_linux_virtual_machine.this[0].id : azurerm_windows_virtual_machine.this[0].id
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each           = azurerm_managed_disk.data

  managed_disk_id    = each.value.id
  virtual_machine_id = local.vm_id
  lun                = index(keys(azurerm_managed_disk.data), each.key)
  caching            = "None"
}

# -------------------- Outputs --------------------
output "vm_id" {
  description = "ID of the created virtual machine"
  value       = local.vm_id
}

output "network_interface_ids" {
  description = "List of NIC IDs attached to the VM in caller‑specified order"
  value       = local.network_interface_ids
}

output "data_disk_ids" {
  description = "IDs of managed data disks"
  value       = [for d in azurerm_managed_disk.data : d.value.id]
}

# -------------------- Example Calls --------------------
# 1️⃣ Auto‑create NICs (one per subnet) – same subnet can be duplicated if wanted
# module "vm_multi_nic" {
#   source              = "./modules/azure_vm_module"
#   vm_name             = "linux01"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   subnet_ids          = [azurerm_subnet.frontend.id, azurerm_subnet.backend.id]
#   os_type             = "linux"
#   admin_username      = "azureuser"
#   ssh_public_key      = file("~/.ssh/id_rsa.pub")
# }
#
# 2️⃣ Re‑use existing NICs – order maps 1‑to‑1 with subnets (or same subnet if only one supplied)
# module "vm_existing" {
#   source              = "./modules/azure_vm_module"
#   vm_name             = "app01"
#   resource_group_name = "rg-shared"
#   location            = "West Europe"
#   subnet_ids          = ["/subs/...subnetA", "/subs/...subnetB"]  # or single subnet ID for all NICs
#   use_existing_nics   = ["nic-A", "nic-B"]
#   os_type             = "windows"
#   admin_username      = "azureadmin"
#   admin_password      = var.win_admin_password
# }

