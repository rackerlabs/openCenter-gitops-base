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

variable "ssh_user" {
  type = string
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

variable "pf9_onboard" {
  type = bool
}

variable "pf9_account_url" {
  type = string
}

variable "pf9_username" {
  type = string
}

variable "pf9_password" {
  type = string
}

variable "pf9_tenant" {
  type = string
}

variable "pf9_region" {
  type = string
}

variable "pf9ctl_setup_download_url" {
  type    = string
  default = "https://pmkft-assets.s3-us-west-1.amazonaws.com"
}

variable "reboot" {
  type    = bool
  default = false

}

variable "ub_version" {
  type    = string
  default = ""
}