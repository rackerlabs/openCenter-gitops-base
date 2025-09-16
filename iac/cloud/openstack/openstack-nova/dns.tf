resource "openstack_dns_zone_v2" "zone" {
  count = var.use_designate == false ? 0 : 1
  name  = "${var.dns_zone_name}."
  email = "noreply@rackspace.com"
  ttl   = 300
  type  = "PRIMARY"
}

resource "openstack_dns_recordset_v2" "k8s" {
  count   = var.use_designate == false ? 0 : 1
  zone_id = openstack_dns_zone_v2.zone[0].id
  name    = "k8s.${var.dns_zone_name}."
  type    = "A"
  records = var.vlan_id == "" ? (var.use_octavia == true ? [module.loadbalancer[0].ip] : [module.floating-vip[0].ip]) : [var.vrrp_ip]
}
