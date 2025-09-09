variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-efs-project"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "efs_encrypted" {
  description = "Whether to encrypt the EFS file system"
  type        = bool
  default     = true
}

variable "efs_performance_mode" {
  description = "The file system performance mode"
  type        = string
  default     = "generalPurpose"
  
  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.efs_performance_mode)
    error_message = "Performance mode must be either 'generalPurpose' or 'maxIO'."
  }
}

variable "efs_throughput_mode" {
  description = "Throughput mode for the file system"
  type        = string
  default     = "bursting"
  
  validation {
    condition     = contains(["bursting", "provisioned"], var.efs_throughput_mode)
    error_message = "Throughput mode must be either 'bursting' or 'provisioned'."
  }
}

variable "efs_access_points" {
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
  default = {
    web = {
      posix_user = {
        gid = 1000
        uid = 1000
      }
      root_directory = {
        path = "/web"
        creation_info = {
          owner_gid   = 1000
          owner_uid   = 1000
          permissions = "755"
        }
      }
    }
  }
}
