module "bastion" {
  source = "../lib/openstack-bastion"
  count = var.disable_bastion == true ? 0 : 1

  availability_zone   = var.availability_zone
  flavor_bastion      = var.flavor_bastion
  floatingip_pool     = var.vlan_id == "" ? var.floatingip_pool : ""
  image_id            = var.bastion_image_id == "" ? var.image_id : var.bastion_image_id
  image_name          = var.image_name
  naming_prefix       = var.naming_prefix
  network_id          = var.network_id == "" ? openstack_networking_network_v2.network[0].id : var.network_id
  security_group_name = module.secgroup.controlplane_name
  user_data           = module.user_data_bastion.rendered
  key_pair            = module.ssh-keypair.keypair
  module_depends_on   = var.vlan_id == "" ? ( var.router_id == "" ? [openstack_networking_router_interface_v2.router[0].id] : [var.router_id]) : []
}

module "ca" {
  source          = "../lib/ca"
  count           = var.services_ca_enabled == false ? 0 : 1
  services_ca_crt = var.services_ca_crt
  services_ca_key = var.services_ca_key
}

module "loadbalancer" {
  source = "../lib/openstack-loadbalancer"

  count                 = var.use_octavia == false ? 0 : 1
  floatingip_pool       = var.floatingip_pool
  master_ips            = keys(module.node_master.ips_to_names)
  server_count          = module.node_master.server_count
  availability_zone     = var.availability_zone
  naming_prefix         = var.naming_prefix
  subnet_id             = var.subnet_id == "" ? openstack_networking_subnet_v2.subnet[0].id : var.subnet_id
  use_octavia           = var.use_octavia
  k8s_api_port          = var.k8s_api_port
  vrrp_ip               = var.vrrp_ip
  loadbalancer_provider = var.loadbalancer_provider
  rke2_enable           = var.rke2_enable
  rke_server_port       = var.rke_server_port
}

module "floating-vip" {
  source = "../lib/floating-vip"

  count              = var.vrrp_enabled == true ? 1 : 0
  naming_prefix      = var.naming_prefix
  floatingip_pool    = var.floatingip_pool
  network_id         = var.network_id == "" ? openstack_networking_network_v2.network[0].id : var.network_id
  subnet_id          = var.subnet_id == "" ? openstack_networking_subnet_v2.subnet[0].id : var.subnet_id
  vrrp_ip            = var.vrrp_ip
  use_octavia        = var.use_octavia
  security_group_ids = [module.secgroup.controlplane_id, module.secgroup.master_id]
}

module "ssh-keypair" {
  source              = "../lib/openstack-keypair"
  openstack_user_name = var.openstack_user_name
  naming_prefix = var.naming_prefix
}


module "node_master" {
  source = "../lib/openstack-compute"

  depends_on                     = [module.bastion, module.ssh-keypair, module.secgroup]
  availability_zone              = var.availability_zone
  allowed_addresses              = [var.vrrp_ip ,var.subnet_nodes, var.subnet_pods, var.subnet_services]
  flavor_name                    = var.size_master.flavor
  image_id                       = var.image_id
  image_name                     = var.image_name
  naming_prefix                  = var.naming_prefix
  network_id                     = var.network_id == "" ? openstack_networking_network_v2.network[0].id : var.network_id
  node_count                     = var.size_master.count
  node_type                      = var.node_master == "" ? "master" : var.node_master
  security_group_ids             = [module.secgroup.controlplane_id, module.secgroup.master_id]
  servergroup_id                 = module.servergroup_master.id
  subnet_id                      = var.subnet_id == "" ? openstack_networking_subnet_v2.subnet[0].id : var.subnet_id
  user_data                      = module.user_data_ubuntu.rendered
  pf9_onboard                    = var.pf9_onboard
  bastion_floating_ip            = var.disable_bastion == true ? "" : module.bastion[0].ip
  ssh_user                       = var.ssh_user
  key_pair                       = module.ssh-keypair.keypair
  node_bfv_source_type           = var.master_node_bfv_source_type
  node_bfv_destination_type      = var.master_node_bfv_destination_type
  node_bfv_volume_size           = var.master_node_bfv_volume_size
  node_bfv_delete_on_termination = var.master_node_bfv_delete_on_termination
  node_bfv_volume_type           = var.master_node_bfv_volume_type
}

module "node_worker" {
  source = "../lib/openstack-compute"

  depends_on                     = [module.bastion, module.ssh-keypair, module.secgroup]
  availability_zone              = var.availability_zone
  allowed_addresses              = [var.subnet_nodes, var.subnet_pods, var.subnet_services]
  flavor_name                    = var.size_worker.flavor
  image_id                       = var.image_id
  image_name                     = var.image_name
  naming_prefix                  = var.naming_prefix
  network_id                     = var.network_id == "" ? openstack_networking_network_v2.network[0].id : var.network_id
  node_count                     = var.size_worker.count
  node_type                      = var.node_worker == "" ? "worker" : var.node_worker
  security_group_ids             = [module.secgroup.worker_id]
  subnet_id                      = var.subnet_id == "" ? openstack_networking_subnet_v2.subnet[0].id : var.subnet_id
  user_data                      = module.user_data_ubuntu.rendered
  pf9_onboard                    = var.pf9_onboard
  bastion_floating_ip            = var.disable_bastion == true ? "" : module.bastion[0].ip
  ssh_user                       = var.ssh_user
  key_pair                       = module.ssh-keypair.keypair
  node_bfv_source_type           = var.worker_node_bfv_source_type
  node_bfv_destination_type      = var.worker_node_bfv_destination_type
  node_bfv_volume_size           = var.worker_node_bfv_volume_size
  node_bfv_delete_on_termination = var.worker_node_bfv_delete_on_termination
  node_bfv_volume_type           = var.worker_node_bfv_volume_type
}

module "node_worker_windows" {
  source = "../lib/openstack-compute-windows"
  count               = var.size_worker_windows.count > 0 ? 1 : 0
  depends_on          = [module.bastion, module.secgroup]
  availability_zone   = var.availability_zone
  allowed_addresses   = [var.subnet_nodes, var.subnet_pods, var.subnet_services]
  flavor_name         = var.size_worker_windows.flavor
  image_id            = var.image_id_windows
  image_name          = var.image_name
  naming_prefix       = var.naming_prefix
  network_id          = var.network_id == "" ? openstack_networking_network_v2.network[0].id : var.network_id
  node_count          = var.size_worker_windows.count
  node_type           = var.node_worker_windows == "" ? "win_wn" : var.node_worker_windows
  security_group_ids  = [module.secgroup.worker_windows_id]
  subnet_id           = var.subnet_id == "" ? openstack_networking_subnet_v2.subnet[0].id : var.subnet_id
  user_data           = module.user_data_windows[0].rendered
  node_bfv_size       = var.worker_node_bfv_size_windows
  node_bfv_type       = var.worker_node_bfv_type_windows
}

module "secgroup" {
  source = "../lib/openstack-secgroup"

  additional_ports_master = var.additional_ports_master
  additional_ports_worker = var.additional_ports_worker
  naming_prefix           = var.naming_prefix
  subnet_pods             = var.subnet_pods
  subnet_services         = var.subnet_services
  subnet_servers          = var.subnet_nodes
  k8s_api_port            = var.k8s_api_port
  disable_bastion         = var.disable_bastion
  worker_count_windows    = var.size_worker_windows.count
  vrrp_enabled            = var.vrrp_enabled
  k8s_api_port_acl        = var.k8s_api_port_acl
}

module "servergroup_master" {
  source = "../lib/openstack-servergroup"
  name          = "master"
  naming_prefix = var.naming_prefix
}

module "user_data_ubuntu" {
  source = "../lib/user_data-ubuntu"

  ca_certificates     = join("\n", [var.openstack_ca, (var.services_ca_enabled == true ? module.ca.certificate : ""), var.ca_certificates])
  ssh_authorized_keys = var.ssh_authorized_keys
  ntp_servers         = var.ntp_servers
  ssh_user            = var.ssh_user
  pkg_manager_proxy   = var.pkg_manager_proxy
  pf9_onboard         = var.pf9_onboard
  pf9_account_url     = var.pf9_account_url
  pf9_username        = var.pf9_username
  pf9_password        = var.pf9_password
  pf9_tenant          = var.pf9_tenant
  pf9_region          = var.pf9_region
  ub_version          = var.ub_version
  reboot              = var.reboot
}

module "user_data_bastion" {
  source = "../lib/user_data-bastion"

  ca_certificates     = join("\n", [var.openstack_ca, (var.services_ca_enabled == true ? module.ca.certificate : ""), var.ca_certificates])
  ssh_authorized_keys = var.ssh_authorized_keys
  ntp_servers         = var.ntp_servers
  ssh_user            = var.ssh_user
  pkg_manager_proxy   = var.pkg_manager_proxy
}

module "user_data_windows" {
  source = "../lib/user_data-windows"
  count               = var.size_worker_windows.count > 0 ? 1 : 0
  ca_certificates     = join("\n", [var.openstack_ca, (var.services_ca_enabled == true ? module.ca.certificate : ""), var.ca_certificates])
  ssh_authorized_keys = concat(var.ssh_authorized_keys, [module.ssh-keypair.keypair.public_key])
  ntp_servers         = var.ntp_servers
  pkg_manager_proxy   = var.pkg_manager_proxy
  reboot              = var.reboot
  windows_user        = var.windows_user
  windows_admin_password      = var.windows_admin_password
}

module "ansible_inventory" {
  source          = "../lib/ansible-inventory"
  count           = var.ansible_inventory_enabled == true ? 1 : 0
  address_bastion = var.disable_bastion == true ? "" : module.bastion[0].ip
  worker_nodes    = module.node_worker.nodes
  master_nodes    = module.node_master.nodes
  ssh_user        = var.ssh_user
}
