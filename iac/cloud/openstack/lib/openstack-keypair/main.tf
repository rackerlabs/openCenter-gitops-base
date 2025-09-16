resource "openstack_compute_keypair_v2" "ssh_keypair" {
  name = replace(format("%skey", var.naming_prefix), ".", "-")
}

resource "local_file" "private_key" {
  content  = openstack_compute_keypair_v2.ssh_keypair.private_key
  filename = "${path.root}/id_rsa"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content  = openstack_compute_keypair_v2.ssh_keypair.public_key
  filename = "${path.root}/id_rsa.pub"
  file_permission = "0644"
}
