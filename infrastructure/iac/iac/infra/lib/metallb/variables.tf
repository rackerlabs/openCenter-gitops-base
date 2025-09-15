variable "module_depends_on" {
  type    = any
  default = null
}

variable "metallb_helm_repo" {
  type = string
  // This default is set to allow current code that uses this module
  // to continue working, but this chart has been deprecated in this repo.
  // The new location is: https://charts.bitnami.com/bitnami
  default = "https://charts.helm.sh/stable"
}

variable "metallb_helmchart_version" {
  type = string
  // This default is set to allow current code that uses this module
  // to continue working, but users should set this to variable something
  // more recent.
  default = "0.8.1"
}

// Overrides to set in the metallb helm chart.
variable "metallb_helmchart_vals" {
  type = list(object({
    name = string
    val  = string
  }))
  default = []
}

variable "metallb_namespace" {
  type = string
  // This default is set to allow current code that uses this module
  // to continue working.
  default = "metallb-system"
}

variable "metallb_cidr_prefix" {
  type    = string
  default = ""
}

variable "metallb_host_start" {
  type = number
}

variable "metallb_host_count" {
  type = number
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

variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}
