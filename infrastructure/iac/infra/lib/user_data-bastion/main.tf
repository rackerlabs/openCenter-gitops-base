data "cloudinit_config" "config" {
  part {
    filename     = "bastion-init.tpl"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/bastion-init.tpl", {
      ca_certificates : var.ca_certificates
      ssh_user : var.ssh_user
      ssh_authorized_keys : var.ssh_authorized_keys
      ntp_servers : var.ntp_servers
      logrotate_keep_old : var.logrotate_keep_old
      logrotate_size : var.logrotate_size
      docker_registry : var.docker_registry
      filepath : "${path.module}"
    })
  }
}