output "ip" {
  value = var.floatingip_pool == "" ? openstack_lb_loadbalancer_v2.k8s.vip_address : openstack_networking_floatingip_v2.k8s[0].address
}
