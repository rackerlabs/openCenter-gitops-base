output "ip" {
  value = var.floatingip_pool == "" ? openstack_compute_instance_v2.bastion.access_ip_v4 : openstack_compute_floatingip_v2.bastion[0].address
}
