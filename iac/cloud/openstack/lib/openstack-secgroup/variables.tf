variable "additional_ports_master" {
  description = "List of additional ports to create security group rules for custom applications"
  type        = list(string)
  default     = [] # No rules created by default
}

variable "additional_ports_worker" {
  description = "List of additional ports to create security group rules for custom applications"
  type        = list(string)
  default     = [] # No rules created by default
}

variable "additional_server_pools_worker_windows" {
  description = "List of additional Windows worker server pools with their configurations"
  type = list(object({
    name                                  = string
    server_group_affinity                 = optional(string, "soft-anti-affinity")
    worker_count                          = number
    flavor_worker                         = string
    node_worker                           = string
    image_id                              = string
    image_name                            = optional(string, "")
    allowed_addresses                     = optional(list(string), [])
    worker_node_bfv_volume_size           = optional(number, 0)
    worker_node_bfv_destination_type      = optional(string, "local")
    worker_node_bfv_source_type           = optional(string, "image")
    worker_node_bfv_volume_type           = optional(string, "")
    worker_node_bfv_delete_on_termination = optional(bool, true)
    additional_block_devices_worker_windows = optional(list(object({
      source_type           = string
      volume_size           = number
      volume_type           = string
      boot_index            = number
      destination_type      = string
      delete_on_termination = bool
      mountpoint            = optional(string, "")
      filesystem            = optional(string, "")
      label                 = optional(string, "")
    })), [])
    subnet_id              = optional(string, "")
    windows_user           = optional(string, "Administrator")
    windows_admin_password = optional(string, "")
  }))
  default = []
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
  type        = bool
  default     = false
  description = "value to create and configure the infrastructure for rke2"
}

variable "rke_server_port" {
  type        = number
  default     = 9345
  description = "value to set the port for the rke2 join api"
}

variable "vrrp_enabled" {
  type        = bool
  default     = false
  description = "Will create a port to use as a VIP. If floating IP pool is defined it will get a floating IP assigned to it."
}

variable "k8s_api_port_acl" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "List of CIDR blocks to allow access to to the vrrp VIP"
}

variable "worker_count_windows" {
  type        = number
  default     = 0
  description = "number of windows worker nodes to create"
}