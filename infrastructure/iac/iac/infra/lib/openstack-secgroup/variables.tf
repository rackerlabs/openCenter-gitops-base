variable "additional_ports_master" {
  description = "List of additional ports to create security group rules for custom applications"
  type        = list(string)
  default     = []  # No rules created by default
}

variable "additional_ports_worker" {
  description = "List of additional ports to create security group rules for custom applications"
  type        = list(string)
  default     = []  # No rules created by default
}

variable "naming_prefix" {
  type = string
}

variable "subnet_pods" {
  type = string
}

variable "subnet_services" {
  type = string
}

variable "subnet_servers" {
  type    = string
  default = ""
}

variable "k8s_api_port" {
  type = number
}

variable "disable_bastion" {
  type = bool
}

variable "rke2_enable" {
  type = bool
  default = false
  description = "value to create and configure the infrastructure for rke2"
}

variable "rke_server_port" {
  type    = number
  default = 9345
  description = "value to set the port for the rke2 join api"
}

variable "vrrp_enabled" {
  type = bool
  default = false
  description = "Will create a port to use as a VIP. If floating IP pool is defined it will get a floating IP assigned to it."
}

variable "k8s_api_port_acl" {
  type = list(string)
  default = ["0.0.0.0/0"]
  description = "List of CIDR blocks to allow access to to the vrrp VIP"
}

variable "worker_count_windows" {
  type    = number
  default = 0
  description = "number of windows worker nodes to create"
}