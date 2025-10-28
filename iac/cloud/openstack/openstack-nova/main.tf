locals {
  windows_enabled = var.size_worker_windows.count > 0 || length(var.additional_server_pools_worker_windows) > 0
}


module "bastion" {
  source = "../lib/openstack-bastion"
  count  = var.disable_bastion == true ? 0 : 1

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
  module_depends_on   = var.vlan_id == "" ? (var.router_id == "" ? [openstack_networking_router_interface_v2.router[0].id] : [var.router_id]) : []
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
  naming_prefix       = var.naming_prefix
}


module "node_master" {
  source = "../lib/openstack-compute"

  depends_on                     = [module.bastion, module.ssh-keypair, module.secgroup]
  additional_block_devices       = var.additional_block_devices_master
  availability_zone              = var.availability_zone
  allowed_addresses              = [var.vrrp_ip, var.subnet_nodes, var.subnet_pods, var.subnet_services]
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
  additional_block_devices       = var.additional_block_devices_worker
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
  servergroup_id                 = length(var.wn_server_group_affinity) > 0 ? module.servergroup_worker[0].id : ""
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
  # count               = var.size_worker_windows.count > 0 ? 1 : 0
  depends_on                     = [module.bastion, module.secgroup]
  availability_zone              = var.availability_zone
  allowed_addresses              = [var.subnet_nodes, var.subnet_pods, var.subnet_services]
  flavor_name                    = var.size_worker_windows.flavor
  image_id                       = var.image_id_windows
  image_name                     = var.image_name
  naming_prefix                  = var.naming_prefix
  network_id                     = var.network_id == "" ? openstack_networking_network_v2.network[0].id : var.network_id
  node_count                     = var.size_worker_windows.count
  node_type                      = var.node_worker_windows == "" ? "win_wn" : var.node_worker_windows
  security_group_ids             = [module.secgroup.worker_windows_id]
  servergroup_id                 = length(var.win_server_group_affinity) > 0 ? module.servergroup_windows[0].id : ""
  subnet_id                      = var.subnet_id == "" ? openstack_networking_subnet_v2.subnet[0].id : var.subnet_id
  user_data                      = local.windows_enabled == 1 ? module.user_data_windows[0].rendered : ""
  node_bfv_source_type           = var.worker_node_bfv_source_type
  node_bfv_destination_type      = var.worker_node_bfv_destination_type
  node_bfv_volume_size           = var.worker_node_bfv_volume_size
  node_bfv_delete_on_termination = var.worker_node_bfv_delete_on_termination
  node_bfv_volume_type           = var.worker_node_bfv_volume_type
}

module "secgroup" {
  source = "../lib/openstack-secgroup"

  additional_ports_master                = var.additional_ports_master
  additional_ports_worker                = var.additional_ports_worker
  naming_prefix                          = var.naming_prefix
  subnet_pods                            = var.subnet_pods
  subnet_services                        = var.subnet_services
  subnet_servers                         = var.subnet_nodes
  k8s_api_port                           = var.k8s_api_port
  disable_bastion                        = var.disable_bastion
  worker_count_windows                   = var.size_worker_windows.count
  additional_server_pools_worker_windows = var.additional_server_pools_worker_windows
  vrrp_enabled                           = var.vrrp_enabled
  k8s_api_port_acl                       = var.k8s_api_port_acl
}

module "servergroup_master" {
  source                = "../lib/openstack-servergroup"
  name                  = "master"
  naming_prefix         = var.naming_prefix
  server_group_affinity = var.cp_server_group_affinity
}

module "servergroup_worker" {
  source                = "../lib/openstack-servergroup"
  count                 = length(var.wn_server_group_affinity) > 0 ? 1 : 0
  name                  = "worker"
  naming_prefix         = var.naming_prefix
  server_group_affinity = var.wn_server_group_affinity
}

module "servergroup_windows" {
  source                = "../lib/openstack-servergroup"
  count                 = length(var.win_server_group_affinity) > 0 ? 1 : 0
  name                  = "windows"
  naming_prefix         = var.naming_prefix
  server_group_affinity = var.win_server_group_affinity
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
  source                 = "../lib/user_data-windows"
  count                  = local.windows_enabled == true ? 1 : 0
  ca_certificates        = join("\n", [var.openstack_ca, (var.services_ca_enabled == true ? module.ca.certificate : ""), var.ca_certificates])
  ssh_authorized_keys    = concat(var.ssh_authorized_keys, [module.ssh-keypair.keypair.public_key])
  ntp_servers            = var.ntp_servers
  pkg_manager_proxy      = var.pkg_manager_proxy
  reboot                 = var.reboot
  windows_user           = var.windows_user
  windows_admin_password = var.windows_admin_password
}

module "ansible_inventory" {
  source          = "../lib/ansible-inventory"
  count           = var.ansible_inventory_enabled == true ? 1 : 0
  address_bastion = var.disable_bastion == true ? "" : module.bastion[0].ip
  worker_nodes    = module.node_worker.nodes
  master_nodes    = module.node_master.nodes
  ssh_user        = var.ssh_user
}

# Server groups for additional worker pools - always created for each pool
module "servergroup_additional_worker_pools" {
  source   = "../lib/openstack-servergroup"
  for_each = { for pool in var.additional_server_pools_worker : pool.name => pool }

  naming_prefix         = var.naming_prefix
  name                  = "${each.value.name}-worker"
  server_group_affinity = length(each.value.server_group_affinity) > 0 ? [each.value.server_group_affinity] : ["soft-anti-affinity"]
}

module "additional_worker_pools" {
  source   = "../lib/openstack-compute"
  for_each = { for pool in var.additional_server_pools_worker : pool.name => pool }

  depends_on = [module.bastion, module.ssh-keypair, module.secgroup]

  # Basic configuration
  availability_zone = var.availability_zone
  naming_prefix     = var.naming_prefix
  ssh_user          = var.ssh_user

  # Network configuration
  network_id = var.network_id == "" ? openstack_networking_network_v2.network[0].id : var.network_id
  subnet_id  = length(each.value.subnet_id) > 0 ? each.value.subnet_id : (var.subnet_id == "" ? openstack_networking_subnet_v2.subnet[0].id : var.subnet_id)

  # Node-specific configuration from the variable
  node_count        = each.value.worker_count
  node_type         = each.value.node_worker
  flavor_name       = each.value.flavor_worker
  image_id          = each.value.image_id
  image_name        = each.value.image_name
  allowed_addresses = [var.subnet_nodes, var.subnet_pods, var.subnet_services]

  # Boot from volume configuration
  node_bfv_volume_size           = each.value.worker_node_bfv_volume_size
  node_bfv_destination_type      = each.value.worker_node_bfv_destination_type
  node_bfv_source_type           = each.value.worker_node_bfv_source_type
  node_bfv_volume_type           = each.value.worker_node_bfv_volume_type
  node_bfv_delete_on_termination = each.value.worker_node_bfv_delete_on_termination

  # Additional block devices
  additional_block_devices = each.value.additional_block_devices_worker

  # Security and server group configuration - each pool gets its own server group
  security_group_ids = [module.secgroup.worker_id]
  servergroup_id     = module.servergroup_additional_worker_pools[each.key].id

  # User data and bastion configuration
  user_data   = module.user_data_ubuntu.rendered
  pf9_onboard = each.value.pf9_onboard
  key_pair    = module.ssh-keypair.keypair

}

# Server groups for additional Windows worker pools - always created for each pool
module "servergroup_additional_worker_pools_windows" {
  source   = "../lib/openstack-servergroup"
  for_each = { for pool in var.additional_server_pools_worker_windows : pool.name => pool }

  naming_prefix         = var.naming_prefix
  name                  = "${each.value.name}-worker-windows"
  server_group_affinity = each.value.server_group_affinity != "" ? [each.value.server_group_affinity] : ["soft-anti-affinity"]
}

module "additional_worker_pools_windows" {
  source   = "../lib/openstack-compute-windows"
  for_each = { for pool in var.additional_server_pools_worker_windows : pool.name => pool }

  depends_on = [module.bastion, module.secgroup]

  # Basic configuration
  availability_zone = var.availability_zone
  naming_prefix     = var.naming_prefix

  # Network configuration
  network_id = var.network_id == "" ? openstack_networking_network_v2.network[0].id : var.network_id
  subnet_id  = length(each.value.subnet_id) > 0 ? each.value.subnet_id : (var.subnet_id == "" ? openstack_networking_subnet_v2.subnet[0].id : var.subnet_id)

  # Node-specific configuration from the variable
  node_count        = each.value.worker_count
  node_type         = each.value.node_worker
  flavor_name       = each.value.flavor_worker
  image_id          = each.value.image_id
  image_name        = each.value.image_name
  allowed_addresses = length(each.value.allowed_addresses) > 0 ? each.value.allowed_addresses : [var.subnet_nodes, var.subnet_pods, var.subnet_services]

  # Boot from volume configuration (Windows uses different parameter names)
  node_bfv_volume_size           = each.value.worker_node_bfv_volume_size
  node_bfv_destination_type      = each.value.worker_node_bfv_destination_type
  node_bfv_source_type           = each.value.worker_node_bfv_source_type
  node_bfv_volume_type           = each.value.worker_node_bfv_volume_type
  node_bfv_delete_on_termination = each.value.worker_node_bfv_delete_on_termination

  # Additional block devices
  additional_block_devices = each.value.additional_block_devices_worker_windows

  # Security and server group configuration - each pool gets its own server group
  security_group_ids = [module.secgroup.worker_windows_id]
  servergroup_id     = module.servergroup_additional_worker_pools_windows[each.key].id

  # User data configuration
  user_data = module.user_data_windows[0].rendered
}
