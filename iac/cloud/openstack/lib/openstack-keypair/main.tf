resource "openstack_compute_keypair_v2" "ssh_keypair" {
  name = replace(format("%skey", var.naming_prefix), ".", "-")
}

resource "null_resource" "save_ssh_keys" {
  triggers = {
    key_id = openstack_compute_keypair_v2.ssh_keypair.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo '${openstack_compute_keypair_v2.ssh_keypair.private_key}' > ${path.root}/id_rsa
      chmod 600 ${path.root}/id_rsa
      echo '${openstack_compute_keypair_v2.ssh_keypair.public_key}' > ${path.root}/id_rsa.pub
      chmod 644 ${path.root}/id_rsa.pub
    EOT
  }
}