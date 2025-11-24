variable "floatingip_pool" {
  type    = string
  default = ""
}

variable "master_ips" {
  type = list(string)
}

variable "naming_prefix" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "server_count" {
  type = string
}

variable "use_octavia" {
  type    = bool
  default = true
}

variable "availability_zone" {
  type    = string
  default = "nova"
}

variable "k8s_api_port" {
  type = number
}

variable "vrrp_ip" {
  type    = string
  default = ""
}

variable "loadbalancer_provider" {
  type    = string
  default = "amphora"
}

variable "rke2_enable" {
  type        = bool
  default     = false
  description = "value to create additional listeners for rke2"
}

variable "rke_server_port" {
  type        = number
  default     = 9345
  description = "value to set the port for the rke2 join api"
}
