output "controlplane_id" {
  value = openstack_networking_secgroup_v2.controlplane.id
}

output "controlplane_name" {
  value = openstack_networking_secgroup_v2.controlplane.name
}

output "master_id" {
  value = openstack_networking_secgroup_v2.master.id
}

output "worker_id" {
  value = openstack_networking_secgroup_v2.worker.id
}

output "worker_windows_id" {
  value = var.worker_count_windows > 0 ? openstack_networking_secgroup_v2.worker_windows[0].id : (length(var.additional_server_pools_worker_windows) > 0 ? openstack_networking_secgroup_v2.worker_windows[0].id : "")
}

