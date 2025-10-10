resource "openstack_compute_servergroup_v2" "servergroup" {
  name     = "${var.naming_prefix}${var.name}"
  policies = var.cp_server_group_affinity
}
