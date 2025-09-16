

resource "openstack_networking_port_v2" "vrrp" {
  name               = "${var.naming_prefix}vrrp"
  network_id         = var.network_id
  security_group_ids = var.security_group_ids
  admin_state_up     = "true"
  fixed_ip {
    ip_address = var.vrrp_ip
    subnet_id  = var.subnet_id
  }
}

resource "openstack_compute_floatingip_v2" "k8s_api_ip" {
  count = var.floatingip_pool == "" ? 0 : 1
  pool  = var.floatingip_pool

}

resource "openstack_networking_floatingip_associate_v2" "fip_1" {
  count       = var.floatingip_pool == "" ? 0 : 1
  floating_ip = openstack_compute_floatingip_v2.k8s_api_ip[0].address
  port_id     = openstack_networking_port_v2.vrrp.id
}
