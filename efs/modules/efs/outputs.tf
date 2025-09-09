output "file_system_id" {
  description = "The ID that identifies the file system"
  value       = aws_efs_file_system.this.id
}

output "file_system_arn" {
  description = "Amazon Resource Name of the file system"
  value       = aws_efs_file_system.this.arn
}

output "file_system_dns_name" {
  description = "The DNS name for the filesystem"
  value       = aws_efs_file_system.this.dns_name
}

output "mount_target_ids" {
  description = "List of IDs of the EFS mount targets"
  value       = aws_efs_mount_target.this[*].id
}

output "mount_target_dns_names" {
  description = "List of DNS names for the EFS mount targets"
  value       = aws_efs_mount_target.this[*].dns_name
}

output "mount_target_network_interface_ids" {
  description = "List of the network interface IDs that Amazon EFS created when it created the mount targets"
  value       = aws_efs_mount_target.this[*].network_interface_id
}

output "access_point_ids" {
  description = "Map of access point names to their IDs"
  value       = { for k, v in aws_efs_access_point.this : k => v.id }
}

output "access_point_arns" {
  description = "Map of access point names to their ARNs"
  value       = { for k, v in aws_efs_access_point.this : k => v.arn }
}
