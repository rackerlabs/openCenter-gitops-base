module "bastion" {
  source = "../lib/openstack-bastion"

  flavor_bastion      = var.flavor_bastion
  floatingip_pool     = var.floatingip_pool
  image_id            = var.image_id
  image_name          = var.image_name
  naming_prefix       = var.naming_prefix
  network_id          = var.network_id
  security_group_name = module.secgroup.controlplane_name
  user_data           = module.user_data_ubuntu.rendered
}

module "ca" {
  source          = "../lib/ca"
  services_ca_crt = var.services_ca_crt
  services_ca_key = var.services_ca_key
}

module "kured" {
  source               = "../lib/kured"
  helm_repo_url        = var.kured_helm_repo_url
  module_depends_on    = [module.rke.null_resource_id]
  kubernetes_resources = var.kubernetes_resources
  system_images        = var.system_images
}

module "loadbalancer" {
  source = "../lib/openstack-loadbalancer"

  floatingip_pool = var.floatingip_pool
  master_ips      = keys(module.node_master.ips_to_names)
  server_count    = module.node_master.server_count
  naming_prefix   = var.naming_prefix
  subnet_id       = var.subnet_id
}

module "metallb" {
  source = "../lib/metallb"

  metallb_helm_repo         = var.metallb_helm_repo
  metallb_helmchart_version = var.metallb_helmchart_version
  metallb_helmchart_vals    = var.metallb_helmchart_vals
  metallb_namespace         = var.metallb_namespace
  metallb_cidr_prefix       = var.metallb_cidr_prefix
  metallb_host_count        = var.metallb_host_count
  metallb_host_start        = var.metallb_host_start
  metallb_reserve_range     = var.metallb_reserve_range
  metallb_protocol          = var.metallb_protocol
  metallb_bgp_peers         = var.metallb_bgp_peers
  metallb_bgp_address_pools = var.metallb_bgp_address_pools
  network_id                = var.network_id
  subnet_id                 = var.subnet_id
  module_depends_on         = [module.rke.null_resource_id]
}

module "rke" {
  source     = "../lib/rke"
  depends_on = [module.user_data_ubuntu]

  address_bastion     = module.bastion.ip
  audit_max_age       = var.audit_max_age
  audit_max_backup    = var.audit_max_backup
  audit_max_size      = var.audit_max_size
  csi_enabled         = var.csi_enabled
  ips_to_names_master = module.node_master.ips_to_names
  ips_to_names_worker = var.ips_to_names_worker == {} ? module.node_worker.ips_to_names : var.ips_to_names_worker
  addresses_worker    = var.addresses_worker != null ? var.addresses_worker : keys(module.node_worker.ips_to_names)
  calico_mtu          = var.calico_mtu
  dns_zone_name       = var.dns_zone_name
  enable_dex          = var.enable_dex
  node_default_gw     = var.node_default_gw
  system_images       = var.system_images
  rke_version         = var.rke_version
  subnet_pods         = var.subnet_pods
  subnet_services     = var.subnet_services
  ssh_user            = var.ssh_user
  docker_registry     = var.docker_registry
  nodeport_addresses  = var.nodeport_addresses
  ssh_key_path        = var.ssh_key_path
  extra_env           = var.extra_env
  kubelet_extra_binds = var.kubelet_extra_binds
}

module "node_master" {
  source = "../lib/openstack-compute"

  allowed_addresses  = list(var.subnet_pods, var.subnet_services)
  flavor_name        = var.size_master.flavor
  image_id           = var.image_id
  image_name         = var.image_name
  naming_prefix      = var.naming_prefix
  network_id         = var.network_id
  node_count         = var.size_master.count
  node_type          = "master"
  security_group_ids = [module.secgroup.controlplane_id, module.secgroup.master_id]
  servergroup_id     = module.servergroup_master.id
  subnet_id          = var.subnet_id
  user_data          = module.user_data_ubuntu.rendered
}

module "node_worker" {
  source = "../lib/openstack-compute"

  flavor_name   = var.size_worker.flavor
  image_id      = var.image_id
  image_name    = var.image_name
  naming_prefix = var.naming_prefix
  network_id    = var.network_id
  node_count    = var.size_worker.count
  node_type     = "worker"
  subnet_id     = var.subnet_id
  user_data     = join("\n", [module.user_data_ubuntu.rendered, var.user_data])
}

module "secgroup" {
  source = "../lib/openstack-secgroup"

  subnet_pods     = var.subnet_pods
  subnet_services = var.subnet_services
  subnet_servers  = var.subnet_servers
  naming_prefix   = var.naming_prefix
}
module "servergroup_master" {
  source = "../lib/openstack-servergroup"

  name          = "master"
  naming_prefix = var.naming_prefix
}

module "user_data_ubuntu" {
  source = "../lib/user_data-ubuntu"

  ca_certificates     = join("\n", [var.openstack_ca, module.ca.certificate, var.ca_certificates])
  cloud-config        = var.cloud-config
  csi_enabled         = var.csi_enabled
  ssh_authorized_keys = var.ssh_authorized_keys
  ntp_servers         = var.ntp_servers
  ssh_user            = var.ssh_user
  pkg_manager_proxy   = var.pkg_manager_proxy
  docker_registry     = var.docker_registry
  pf9_onboard         = var.pf9_onboard
  pf9_account_url     = var.pf9_account_url
  pf9_username        = var.pf9_username
  pf9_password        = var.pf9_password
  pf9_tenant          = var.pf9_tenant
  pf9_region          = var.pf9_region
}

