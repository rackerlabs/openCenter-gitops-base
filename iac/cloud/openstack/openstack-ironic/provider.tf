provider "openstack" {
  auth_url    = var.openstack_auth_url
  cacert_file = var.openstack_ca
  insecure    = var.openstack_insecure
  password    = var.openstack_password
  region      = var.openstack_region
  tenant_name = var.openstack_tenant_name
  use_octavia = true
  user_name   = var.openstack_user_name
  version     = "~> 1.29"
}
