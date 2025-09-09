output "efs_file_system_id" {
  description = "The ID of the EFS file system"
  value       = module.efs.file_system_id
}

output "efs_file_system_arn" {
  description = "The ARN of the EFS file system"
  value       = module.efs.file_system_arn
}

output "efs_dns_name" {
  description = "The DNS name of the EFS file system"
  value       = module.efs.file_system_dns_name
}

output "efs_mount_targets" {
  description = "The mount target information"
  value = {
    ids       = module.efs.mount_target_ids
    dns_names = module.efs.mount_target_dns_names
  }
}

output "efs_access_points" {
  description = "The access point information"
  value = {
    ids  = module.efs.access_point_ids
    arns = module.efs.access_point_arns
  }
}

output "security_group_id" {
  description = "The ID of the security group created for EFS"
  value       = aws_security_group.efs.id
}
