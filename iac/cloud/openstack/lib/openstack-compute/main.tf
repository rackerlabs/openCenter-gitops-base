resource "openstack_networking_port_v2" "node" {
  name       = "${var.naming_prefix}${var.node_type}${count.index}"
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
  name              = "${var.naming_prefix}${var.node_type}${count.index}"
  config_drive      = false
  count             = var.node_count
  flavor_name       = var.flavor_name
  image_id          = var.image_id
  image_name        = var.image_name
  user_data         = var.user_data
  availability_zone = var.availability_zone
  key_pair          = var.key_pair.name

  # metadata = {
  #   bastion = var.bastion_floating_ip
  #   user    = var.ssh_user
  # }

  block_device {
    uuid                  = var.node_bfv_source_type == "blank" ? "" : var.image_id
    source_type           = var.node_bfv_source_type
    volume_size           = var.node_bfv_volume_size
    volume_type           = var.node_bfv_destination_type == "local" ? "" : var.node_bfv_volume_type
    boot_index            = 0
    destination_type      = var.node_bfv_destination_type
    delete_on_termination = var.node_bfv_delete_on_termination
  }
  
  dynamic "block_device" {
    for_each = var.additional_block_devices
    content {
      uuid                  = block_device.value.source_type == "blank" ? "" : null
      source_type           = block_device.value.source_type
      volume_size           = block_device.value.volume_size
      volume_type           = block_device.value.destination_type == "local" ? "" : block_device.value.volume_type
      boot_index            = block_device.value.boot_index
      destination_type      = block_device.value.destination_type
      delete_on_termination = block_device.value.delete_on_termination
    }
  }

  network {
    port = openstack_networking_port_v2.node[count.index].id
  }


  scheduler_hints {
    group = var.servergroup_id
  }

  # provisioner "remote-exec" {
  #   when       = destroy
  #   on_failure = continue
  #   inline     = ["sudo bash /root/remove_node.sh"]

  #   connection {
  #     type                = "ssh"
  #     user                = self.metadata.user
  #     private_key         = file("${path.root}/id_rsa")
  #     host                = self.access_ip_v4
  #     bastion_host        = self.metadata.bastion
  #     bastion_user        = self.metadata.user
  #     bastion_private_key = file("${path.root}/id_rsa")
  #     timeout             = "10s"
  #   }
  # }

  lifecycle {
    ignore_changes = [
      user_data,
      image_id
    ]
  }
}
