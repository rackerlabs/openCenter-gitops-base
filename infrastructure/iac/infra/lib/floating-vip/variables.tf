variable "floatingip_pool" {
  type    = string
  default = ""
}

variable "naming_prefix" {
  type = string
}

variable "network_id" {
  type = string
}
variable "vrrp_ip" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "use_octavia" {
  type = bool
}
variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "vlan_id" {
  type    = string
  default = ""
}