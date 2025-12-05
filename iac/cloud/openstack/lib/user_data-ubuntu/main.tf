data "cloudinit_config" "config" {
  part {
    filename     = "ubuntu-init${var.ub_version}.tpl"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/ubuntu-init${var.ub_version}.tpl", {
      ca_certificates : var.ca_certificates
      ssh_user : var.ssh_user
      ssh_authorized_keys : var.ssh_authorized_keys
      ntp_servers : var.ntp_servers
      logrotate_keep_old : var.logrotate_keep_old
      logrotate_size : var.logrotate_size
      filepath : "${path.module}"
      pf9_onboard : var.pf9_onboard
      pf9_account_url : var.pf9_account_url
      pf9_username : var.pf9_username
      pf9_password : var.pf9_password
      pf9_region : var.pf9_region
      pf9_tenant : var.pf9_tenant
      pf9ctl_setup_download_url : var.pf9ctl_setup_download_url
      reboot : var.reboot
    })
  }
}