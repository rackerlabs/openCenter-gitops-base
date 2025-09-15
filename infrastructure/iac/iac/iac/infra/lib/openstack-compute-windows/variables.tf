variable "allowed_addresses" {
  type    = list(string)
  default = []
}

variable "availability_zone" {
  type    = string
  default = "nova"
}

variable "node_bfv_size" {
  type    = number
  description = "volume size for boot from volume nodes"
}

variable "node_bfv_type" {
  type    = string
  description = "boot from volume type for nodes"
}

variable "flavor_name" {
  type = string
}

variable "image_id" {
  type = string
}

variable "image_name" {
  type = string
}

variable "naming_prefix" {
  type = string
}

variable "network_id" {
  type = string
}

variable "node_count" {
  type = number
}

variable "node_type" {
  type = string
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "servergroup_id" {
  type    = string
  default = ""
}

variable "subnet_id" {
  type = string
}

variable "user_data" {
  type    = string
  default = ""
}
