# OpenStack Identity

This module deploys OpenStack resources that are prerequisite to using the `openstack-nova`
and `openstack-ironic` modules.

## Usage

Below is a complete Terraform template that will deploy an RKE cluster in `dev1` (nova) and output a config file for deploying the `kaas` managed services. Replace all the occurences of `<REPLACE ME>` with appropriate values (see inline comments).


```tf
locals {
  # this will be the user's name and the DNS zone prefix
  cluster_name               = <REPLACE ME>
  openstack_user_name        = local.cluster_name
  naming_prefix              = "${local.cluster_name}-"
  dns_zone_name              = "${local.cluster_name}.kaas-dev1.rpc.rackspace.com"
  openstack_auth_url         = "https://mk8s-dev1.rpc.rackspace.com:5000/v3"
  # this is the (already-existing) CA for dev1
  openstack_ca               = <<EOF
<REPLACE ME>
EOF
  openstack_insecure         = false
  openstack_region           = "RegionOne"
  # this is the password for the user that will be created
  openstack_user_password    = <REPLACE ME>
  dns_nameservers            = ["8.8.8.8", "8.8.4.4"]
  # this value is the (already-existing) the OpenStack admin user's password
  openstack_admin_password   = <REPLACE ME>
  # this is the ssh private key path that will be able to connect to the cluster's bastion node
  ssh_key_path = "<REPLACE ME>"
  # these are the ssh public keys that will be able to connect to the cluster's bastion node
  ssh_authorized_keys        = [<REPLACE ME>]
}

module "openstack-identity" {
  source = "git@github.com:rackerlabs/terraform-rke.git//openstack-identity?ref=v1.1.6"

  openstack_auth_url         = local.openstack_auth_url
  openstack_ca               = local.openstack_ca
  openstack_insecure         = local.openstack_insecure
  openstack_region           = local.openstack_region
  openstack_user_name        = local.openstack_user_name
  openstack_user_password    = local.openstack_user_password
  openstack_admin_password   = local.openstack_admin_password
}

module "openstack-nova" {
  source = "git@github.com:rackerlabs/terraform-rke.git//openstack-nova?ref=v1.1.6"

  dns_nameservers            = local.dns_nameservers
  dns_zone_name              = local.dns_zone_name
  flavor_bastion             = module.openstack-identity.small_flavor_name
  naming_prefix              = local.naming_prefix
  openstack_auth_url         = local.openstack_auth_url
  openstack_ca               = local.openstack_ca
  openstack_insecure         = local.openstack_insecure
  openstack_region           = local.openstack_region
  openstack_tenant_name      = module.openstack-identity.openstack_user_name
  openstack_user_name        = module.openstack-identity.openstack_user_name
  openstack_password         = local.openstack_user_password
  protect_kernel_defaults    = true

  floatingip_pool            = "GATEWAY_NET"
  # this image ID is for CentOS 7
  image_id                   = "43f6f2b2-0bfe-46c5-b3d7-3390f2de1463"
  router_external_network_id = "e8cb7f65-d5b7-4a10-adc8-ecf5ff094d7e"
  size_master = {
    count  = 3
    flavor = module.openstack-identity.small_flavor_name
  }
  size_worker = {
    count  = 4
    flavor = module.openstack-identity.medium_flavor_name
  }
  ssh_authorized_keys = local.ssh_authorized_keys
}

module "openstack-nova-kaas-config" {
  source = "git@github.com:rackerlabs/kaas.git//tools/terraform/openstack-nova"

  dns_nameservers            = local.dns_nameservers
  dns_zone_name              = local.dns_zone_name
  openstack_auth_url         = local.openstack_auth_url
  openstack_ca               = local.openstack_ca
  openstack_insecure         = local.openstack_insecure
  openstack_region           = local.openstack_region
  openstack_user_name        = local.openstack_user_name
  openstack_user_password    = local.openstack_user_password
  openstack_user_tenant_name = local.openstack_user_name
  openstack_admin_password   = local.openstack_admin_password
  openstack_user_tenant_id   = module.openstack-identity.openstack_tenant_id
}

```
