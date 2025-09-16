data "cloudinit_config" "config" {
  part {
    filename     = "windows-init${var.win_version}.tpl"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/windows-init${var.win_version}.tpl", {
      ca_certificates : var.ca_certificates
      windows_user : var.windows_user
      windows_admin_password : var.windows_admin_password
      ssh_authorized_keys : var.ssh_authorized_keys
      ntp_servers : var.ntp_servers
      logrotate_keep_old : var.logrotate_keep_old
      logrotate_size : var.logrotate_size
      filepath : "${path.module}"
      reboot : var.reboot
    })
  }
}