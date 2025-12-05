variable "name" {
  type = string
}

variable "naming_prefix" {
  type = string
}

variable "server_group_affinity" {
  type    = list(string)
  default = []
}