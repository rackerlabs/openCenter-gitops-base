variable "address_bastion" {
  type = string
  default = ""
}

variable "master_nodes" {
  type = list(object({
    id           = string
    name         = string
    access_ip_v4 = string
  }))
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "worker_nodes" {
  type = list(object({
    id           = string
    name         = string
    access_ip_v4 = string
  }))
}


