# AWS EFS File System
resource "aws_efs_file_system" "this" {
  creation_token = var.creation_token
  
  performance_mode                = var.performance_mode
  provisioned_throughput_in_mibps = var.performance_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null
  throughput_mode                 = var.throughput_mode
  
  encrypted  = var.encrypted
  kms_key_id = var.kms_key_id

  lifecycle_policy {
    transition_to_ia                    = var.transition_to_ia
    transition_to_primary_storage_class = var.transition_to_primary_storage_class
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

# EFS Mount Targets
resource "aws_efs_mount_target" "this" {
  count = length(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = var.security_group_ids

  depends_on = [aws_efs_file_system.this]
}

# EFS Access Points (optional)
resource "aws_efs_access_point" "this" {
  for_each = var.access_points

  file_system_id = aws_efs_file_system.this.id

  posix_user {
    gid = each.value.posix_user.gid
    uid = each.value.posix_user.uid
  }

  root_directory {
    path = each.value.root_directory.path
    
    creation_info {
      owner_gid   = each.value.root_directory.creation_info.owner_gid
      owner_uid   = each.value.root_directory.creation_info.owner_uid
      permissions = each.value.root_directory.creation_info.permissions
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-${each.key}"
    }
  )
}
