resource "openstack_networking_port_v2" "node" {
  name = "${substr(var.naming_prefix, 0, 8)}${var.node_type}${count.index}"
  count      = var.node_count
  network_id = var.network_id

  fixed_ip {
    subnet_id = var.subnet_id
  }

  security_group_ids = var.security_group_ids

  dynamic "allowed_address_pairs" {
    for_each = var.allowed_addresses
    content {
      ip_address = allowed_address_pairs.value
    }
  }
}

resource "openstack_compute_instance_v2" "node" {
  name = "${substr(var.naming_prefix, 0, 8)}${var.node_type}${count.index}"
  config_drive      = true  # Windows needs config drive
  count             = var.node_count
  flavor_name       = var.flavor_name
  image_id          = var.image_id
  image_name        = var.image_name
  user_data         = var.user_data
  availability_zone = var.availability_zone
#   key_pair          = var.key_pair.name

#   metadata = {
#     bastion      = var.bastion_floating_ip
#     user         = var.windows_user
#     admin_pass   = var.admin_password  # Windows admin password
#   }

  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    volume_size           = var.node_bfv_size
    boot_index            = 0
    destination_type      = var.node_bfv_type
    delete_on_termination = true
  }

  network {
    port = openstack_networking_port_v2.node[count.index].id
  }

  scheduler_hints {
    group = var.servergroup_id
  }

  # Windows-specific provisioner using WinRM
#   provisioner "remote-exec" {
#     when       = destroy
#     on_failure = continue
#     inline     = [
#       "powershell.exe -ExecutionPolicy Bypass -File C:\\remove_node.ps1"
#     ]

#     connection {
#       type     = "winrm"
#       user     = self.metadata.user
#       password = self.metadata.admin_pass
#       host     = self.access_ip_v4
#       port     = 5985
#       https    = false
#       insecure = true
#       timeout  = "10m"  # Windows boot times are typically longer
      
#       # If using bastion/jump host for Windows
#       # Note: WinRM through bastion is more complex and may require additional setup
#       bastion_host     = var.use_bastion ? self.metadata.bastion : null
#       bastion_user     = var.use_bastion ? self.metadata.user : null
#       bastion_password = var.use_bastion ? var.bastion_password : null
#     }
#   }

  lifecycle {
    ignore_changes = [
      user_data,
      image_id,
      metadata.admin_pass  # Ignore password changes
    ]
  }
}