output "network_interface_ids" {
  description = "List of NIC IDs attached to the VM in caller‑specified order"
  value       = local.network_interface_ids
}

output "private_ip_addresses" {
  description = "List of primary private IPs matching network_interface_ids order"
  value       = local.private_ip_addresses
}


locals {
  # Ordered NIC IDs list
  network_interface_ids = local.create_nics ?
    [for nic in azurerm_network_interface.this : nic.value.id] :
    [for idx in range(length(var.use_existing_nics)) : data.azurerm_network_interface.existing[tostring(idx)].id]

  # Ordered private IP list (primary IP of each NIC)
  private_ip_addresses = local.create_nics ?
    [for nic in azurerm_network_interface.this : nic.value.ip_configuration[0].private_ip_address] :
    [for idx in range(length(var.use_existing_nics)) : data.azurerm_network_interface.existing[tostring(idx)].ip_configuration[0].private_ip_address]
}
