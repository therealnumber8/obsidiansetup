variable "name" {
  description = "Name of the EFS file system"
  type        = string
}

variable "creation_token" {
  description = "A unique name (a maximum of 64 characters are allowed) used as reference when creating the Elastic File System to ensure idempotent file system creation"
  type        = string
  default     = null
}

variable "performance_mode" {
  description = "The file system performance mode. Can be either generalPurpose or maxIO"
  type        = string
  default     = "generalPurpose"
  
  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Performance mode must be either 'generalPurpose' or 'maxIO'."
  }
}

variable "throughput_mode" {
  description = "Throughput mode for the file system. Defaults to bursting. Valid values: bursting, provisioned"
  type        = string
  default     = "bursting"
  
  validation {
    condition     = contains(["bursting", "provisioned"], var.throughput_mode)
    error_message = "Throughput mode must be either 'bursting' or 'provisioned'."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with throughput_mode set to provisioned"
  type        = number
  default     = null
}

variable "encrypted" {
  description = "If true, the disk will be encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. When specifying kms_key_id, encrypted needs to be set to true"
  type        = string
  default     = null
}

variable "transition_to_ia" {
  description = "Indicates how long it takes to transition files to the IA storage class"
  type        = string
  default     = "AFTER_30_DAYS"
  
  validation {
    condition = contains([
      "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", 
      "AFTER_60_DAYS", "AFTER_90_DAYS"
    ], var.transition_to_ia)
    error_message = "Transition to IA must be one of: AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS."
  }
}

variable "transition_to_primary_storage_class" {
  description = "Describes the policy used to transition a file from infequent access storage to primary storage"
  type        = string
  default     = "AFTER_1_ACCESS"
  
  validation {
    condition     = contains(["AFTER_1_ACCESS"], var.transition_to_primary_storage_class)
    error_message = "Transition to primary storage class must be 'AFTER_1_ACCESS'."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs where EFS mount targets will be created"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the EFS mount targets"
  type        = list(string)
}

variable "access_points" {
  description = "Map of access points to create"
  type = map(object({
    posix_user = object({
      gid = number
      uid = number
    })
    root_directory = object({
      path = string
      creation_info = object({
        owner_gid   = number
        owner_uid   = number
        permissions = string
      })
    })
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
