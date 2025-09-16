output "k8s_api_ip" {
  value = var.use_octavia == true ? module.loadbalancer[0].ip : (var.vrrp_enabled == true ? module.floating-vip[0].ip : module.node_master.nodes[0].access_ip_v4)
}

output "k8s_internal_ip" {
  value = var.vrrp_enabled == false ? (var.use_octavia == true ? var.vrrp_ip : module.node_master.nodes[0].access_ip_v4) : var.vrrp_ip
}

output "bastion_floating_ip" {
  value = var.disable_bastion == true ? "" : module.bastion[0].ip
}

output "worker_nodes" {
  value = module.node_worker.nodes[*]
}

output "master_nodes" {
  value = module.node_master.nodes[*]
}

output "worker_ids" {
  value = module.node_worker.ids
}

output "user-data" {
  value = module.user_data_ubuntu.rendered
}

output "secgroup_id_master" {
  value = module.secgroup.master_id
}

output "windows_nodes" {
  value = var.size_worker_windows.count > 0 ? module.node_worker_windows.nodes[*] : []
}

