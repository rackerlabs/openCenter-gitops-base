variable "availability_zone" {
  type    = string
  default = "nova"
}

variable "flavor_bastion" {
  type = string
}

variable "floatingip_pool" {
  type    = string
  default = ""
}

variable "image_id" {
  type = string
}

variable "image_name" {
  type = string
}

variable "module_depends_on" {
  type    = any
  default = null
}

variable "naming_prefix" {
  type = string
}

variable "network_id" {
  type = string
}

variable "security_group_name" {
  type = string
}

variable "user_data" {
  type    = string
  default = ""
}

variable "key_pair" {
  type = object({
    id          = string
    name        = string
    private_key = string
    public_key  = string
  })
}