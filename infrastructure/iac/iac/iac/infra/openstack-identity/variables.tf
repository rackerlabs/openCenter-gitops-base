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

variable "openstack_region" {
  type    = string
  default = "RegionOne"
}

variable "openstack_user_name" {
  type = string
}

variable "openstack_user_password" {
  type = string
}

variable "openstack_user_email" {
  type    = string
  default = ""
}

variable "openstack_admin_name" {
  type    = string
  default = "admin"
}

variable "openstack_admin_password" {
  type = string
}

variable "openstack_admin_tenant_name" {
  type    = string
  default = "admin"
}

variable "openstack_project_id" {
  type    = string
  default = ""
}

variable "openstack_domain_id" {
  type    = string
  default = "default"
}

variable "quotas" {
  type = object({
    ram                         = number
    cores                       = number
    instances                   = number
    key_pairs                   = number
    security_group_rules        = number
    security_groups             = number
    server_group_members        = number
    server_groups               = number
    floating_ips                = number
    injected_file_content_bytes = number
    injected_file_path_bytes    = number
    injected_files              = number
    metadata_items              = number
    volumes                     = number
    snapshots                   = number
    gigabytes                   = number
    per_volume_gigabytes        = number
  })
  default = {
    ram                         = 512000
    cores                       = 200
    instances                   = 100
    key_pairs                   = 10
    security_group_rules        = 200
    security_groups             = 100
    server_group_members        = 100
    server_groups               = 100
    floating_ips                = 50
    injected_file_content_bytes = 10240
    injected_file_path_bytes    = 255
    injected_files              = 5
    metadata_items              = 128
    volumes                     = 100
    snapshots                   = 300
    gigabytes                   = 10000
    per_volume_gigabytes        = -1
  }
}

variable "small_flavor" {
  type = object({
    name  = string
    ram   = number
    vcpus = number
    disk  = number
  })
  default = {
    name  = ""
    ram   = 5120
    vcpus = 2
    disk  = 40
  }
}

variable "medium_flavor" {
  type = object({
    name  = string
    ram   = number
    vcpus = number
    disk  = number
  })
  default = {
    name  = ""
    ram   = 10240
    vcpus = 4
    disk  = 100
  }
}

variable "large_flavor" {
  type = object({
    name  = string
    ram   = number
    vcpus = number
    disk  = number
  })
  default = {
    name  = ""
    ram   = 16384
    vcpus = 8
    disk  = 100
  }
}

variable "xlarge_flavor" {
  type = object({
    name  = string
    ram   = number
    vcpus = number
    disk  = number
  })
  default = {
    name  = ""
    ram   = 32768
    vcpus = 8
    disk  = 100
  }
}

variable "vlan_id" {
  type    = string
  default = ""
}

variable "vlan_mtu" {
  type    = string
  default = "1500"
}

variable "network_provider" {
  type    = string
  default = ""

}