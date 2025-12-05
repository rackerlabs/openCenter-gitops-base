variable "windows_user" {
  type    = string
  default = "administrator"
}
variable "windows_admin_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "ca_certificates" {
  type    = string
  default = ""
}

variable "cloud-config" {
  type    = string
  default = ""
}

variable "ssh_authorized_keys" {
  type = list(string)
}

variable "ntp_servers" {
  type = list(string)
  default = [
    "time.dfw1.rackspace.com",
    "time2.dfw1.rackspace.com",
  ]
}

variable "pkg_manager_proxy" {
  type    = string
  default = ""
}

variable "logrotate_keep_old" {
  type    = number
  default = 4
}

variable "logrotate_size" {
  type    = string
  default = "300M"
}

variable "reboot" {
  type    = bool
  default = true
}

variable "win_version" {
  type    = string
  default = "2022"
}