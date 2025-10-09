variable "name" {
  type = string
}

variable "naming_prefix" {
  type = string
}

variable "cp_server_group_affinity" {
  type    = list(string)
  default = []
}