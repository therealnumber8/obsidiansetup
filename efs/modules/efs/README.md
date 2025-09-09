# AWS EFS Terraform Module

A minimal Terraform module for creating AWS Elastic File System (EFS) resources following best practices.

## Features

- Creates EFS file system with configurable performance and throughput modes
- Supports encryption with optional KMS key
- Creates mount targets in specified subnets
- Optional access points with POSIX user and root directory configuration
- Lifecycle policies for cost optimization
- Comprehensive tagging support

## Usage

```hcl
module "efs" {
  source = "./modules/efs"

  name       = "my-efs"
  subnet_ids = ["subnet-12345", "subnet-67890"]
  security_group_ids = ["sg-abcdef"]

  # Optional configurations
  encrypted = true
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  
  # Access points (optional)
  access_points = {
    app = {
      posix_user = {
        gid = 1001
        uid = 1001
      }
      root_directory = {
        path = "/app"
        creation_info = {
          owner_gid   = 1001
          owner_uid   = 1001
          permissions = "755"
        }
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0 |

## Resources

| Name | Type |
|------|------|
| aws_efs_file_system.this | resource |
| aws_efs_mount_target.this | resource |
| aws_efs_access_point.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the EFS file system | `string` | n/a | yes |
| subnet_ids | List of subnet IDs where EFS mount targets will be created | `list(string)` | n/a | yes |
| security_group_ids | List of security group IDs to associate with the EFS mount targets | `list(string)` | n/a | yes |
| creation_token | A unique name used as reference when creating the Elastic File System | `string` | `null` | no |
| performance_mode | The file system performance mode. Can be either generalPurpose or maxIO | `string` | `"generalPurpose"` | no |
| throughput_mode | Throughput mode for the file system. Valid values: bursting, provisioned | `string` | `"bursting"` | no |
| provisioned_throughput_in_mibps | The throughput, measured in MiB/s, that you want to provision for the file system | `number` | `null` | no |
| encrypted | If true, the disk will be encrypted | `bool` | `true` | no |
| kms_key_id | The ARN for the KMS encryption key | `string` | `null` | no |
| transition_to_ia | Indicates how long it takes to transition files to the IA storage class | `string` | `"AFTER_30_DAYS"` | no |
| transition_to_primary_storage_class | Describes the policy used to transition a file from infequent access storage to primary storage | `string` | `"AFTER_1_ACCESS"` | no |
| access_points | Map of access points to create | `map(object)` | `{}` | no |
| tags | A map of tags to assign to the resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| file_system_id | The ID that identifies the file system |
| file_system_arn | Amazon Resource Name of the file system |
| file_system_dns_name | The DNS name for the filesystem |
| mount_target_ids | List of IDs of the EFS mount targets |
| mount_target_dns_names | List of DNS names for the EFS mount targets |
| mount_target_network_interface_ids | List of the network interface IDs that Amazon EFS created when it created the mount targets |
| access_point_ids | Map of access point names to their IDs |
| access_point_arns | Map of access point names to their ARNs |

## Examples

See the `examples/` directory for complete usage examples.
