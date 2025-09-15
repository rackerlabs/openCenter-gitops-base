output "ip" {
 value = var.floatingip_pool == "" ? var.vrrp_ip : openstack_compute_floatingip_v2.k8s_api_ip[0].address
}
