output "openstack_tenant_id" {
  value = var.openstack_project_id == "" ? openstack_identity_project_v3.project[0].id : var.openstack_project_id
}

output "openstack_user_id" {
  value = openstack_identity_user_v3.user.id
}

output "openstack_user_name" {
  value = openstack_identity_user_v3.user.name
}

output "small_flavor_name" {
  value = openstack_compute_flavor_v2.mk8s_small.name
}

output "medium_flavor_name" {
  value = openstack_compute_flavor_v2.mk8s_medium.name
}

output "large_flavor_name" {
  value = openstack_compute_flavor_v2.mk8s_large.name
}

output "xlarge_flavor_name" {
  value = openstack_compute_flavor_v2.mk8s_xlarge.name
}

output "network_id" {
  value = var.vlan_id == "" ? "" : openstack_networking_network_v2.network_vlan[0].id
}