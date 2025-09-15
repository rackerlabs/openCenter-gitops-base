variable "addresses_worker" {
  type    = list(string)
  default = null
}

variable "audit_max_age" {
  type    = number
  default = 10
}

variable "audit_max_backup" {
  type    = number
  default = 10
}

variable "audit_max_size" {
  type    = number
  default = 100
}

variable "ca_certificates" {
  type = string
}

variable "calico_mtu" {
  type    = number
  default = 0
}

variable "calico_version" {
  type    = string
  default = ""
}

variable "cloud-config" {
  type    = string
  default = ""
}

variable "csi_enabled" {
  type    = bool
  default = false
}

variable "dns_zone_name" {
  type = string
}

variable "enable_dex" {
  type    = bool
  default = true
}

variable "flavor_bastion" {
  type = string
}

variable "floatingip_pool" {
  type    = string
  default = ""
}

variable "ips_to_names_worker" {
  type    = map(string)
  default = {}
}

variable "kured_helm_repo_url" {
  type    = string
  default = "https://weaveworks.github.io/kured"
}

variable "image_id" {
  type    = string
  default = ""
}

variable "image_name" {
  type    = string
  default = ""
}

variable "kubernetes_resources" {
  type    = bool
  default = false
}

variable "system_images" {
  type    = string
  default = ""
}

variable "metallb_cidr_prefix" {
  type    = string
  default = ""
}

variable "metallb_host_count" {
  type    = number
  default = 0
}

variable "metallb_host_start" {
  type    = number
  default = 0
}

variable "metallb_reserve_range" {
  type    = bool
  default = false
}

variable "metallb_protocol" {
  type    = string
  default = ""
}

variable "metallb_bgp_peers" {
  type    = map(any)
  default = {}
}

variable "metallb_bgp_address_pools" {
  type    = map(any)
  default = {}
}

variable "metallb_helm_repo" {
  type    = string
  default = "https://charts.helm.sh/stable"
}

variable "metallb_helmchart_version" {
  type    = string
  default = "0.8.1"
}

variable "metallb_helmchart_vals" {
  type = list(object({
    name = string
    val  = string
  }))
  default = []
}

variable "metallb_namespace" {
  type    = string
  default = "metallb-system"
}

variable "module_depends_on" {
  type    = any
  default = null
}

variable "naming_prefix" {
  type = string
}

variable "node_default_gw" {
  type    = string
  default = ""
}

variable "nodeport_addresses" {
  type    = string
  default = ""
}

variable "network_id" {
  type = string
}

variable "openstack_auth_url" {
  type = string
}

variable "openstack_ca" {
  type = string
}

variable "openstack_insecure" {
  type    = bool
  default = false
}

variable "openstack_password" {
  type = string
}

variable "openstack_region" {
  type    = string
  default = "RegionOne"
}

variable "openstack_tenant_name" {
  type = string
}

variable "openstack_user_name" {
  type = string
}

variable "rke_version" {
  default = ""
  type    = string
}

variable "services_ca_crt" {
  type    = string
  default = ""
}

variable "services_ca_key" {
  type    = string
  default = ""
}

variable "size_master" {
  type = object({
    count  = number
    flavor = string
  })
}

variable "size_worker" {
  type = object({
    count  = number
    flavor = string
  })
}

variable "ssh_key_path" {
  type    = string
  default = "~/.ssh/id_rsa"
}

variable "ssh_authorized_keys" {
  type = list(string)
}

variable "ntp_servers" {
  type = list(string)
  default = [
    "time.dfw1.rackspace.com",
    "time2.dfw1.rackspace.com",
  ]
}

variable "subnet_id" {
  type = string
}

variable "subnet_pods" {
  type    = string
  default = "10.42.0.0/16"
}

variable "subnet_services" {
  type    = string
  default = "10.43.0.0/16"
}

variable "subnet_servers" {
  type    = string
  default = ""
}

variable "user_data" {
  type    = string
  default = ""
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "pkg_manager_proxy" {
  type    = string
  default = ""
}

variable "docker_registry" {
  type    = string
  default = ""
}

variable "yum_repo" {
  type    = bool
  default = false
}

variable "apt_repo" {
  type    = bool
  default = false
}

variable "docker_ce_gpg_key_url" {
  type    = string
  default = ""
}

variable "docker_ce_repo_base_url" {
  type    = string
  default = ""
}

variable "yum_base_repo_package_url" {
  type    = string
  default = ""
}

variable "yum_updates_repo_package_url" {
  type    = string
  default = ""
}

variable "yum_extras_repo_package_url" {
  type    = string
  default = ""
}

variable "yum_centosplus_repo_package_url" {
  type    = string
  default = ""
}

/*
extra_env allows providing environment variables to kubelet and kube-controller.
*/
variable "extra_env" {
  type    = list(string)
  default = []
}

//kubelet_extra_binds allows providing additional bind mounts to kubelet.
variable "kubelet_extra_binds" {
  type    = list(string)
  default = []
}

variable "pf9_onboard" {
  type = bool
}

variable "pf9ctl_setup_download_url" {
  type    = string
  default = "https://pmkft-assets.s3-us-west-1.amazonaws.com"
}

variable "pf9_account_url" {
  type = string
}

variable "pf9_username" {
  type    = string
  default = ""
}

variable "pf9_password" {
  type    = string
  default = ""
}

variable "pf9_tenant" {
  type    = string
  default = ""
}

variable "pf9_region" {
  type    = string
  default = ""
}

variable "use_designate" {
  type = bool
}

variable "vrrp_ip" {
  type    = string
  default = ""
}