# OpenStack Ironic

This module deploys a standard Kubernetes cluster on OpenStack, with the
control plane (masters) on Nova and Ironic workers.

## Pre run requirements

Before you can use this module, all of the Openstack bits need to be created
first. You can either create the resources and quotas listed below, or you can use the (preferred)
module [openstack-identity](../openstack-identity/README.md) (with the exception of
[neutron networking requirements](#network)).

### Permissions

A couple of items in Openstack will need to be setup prior to starting a
`terraform apply`.

Unless the customer requires something else, create new of the following:

- user
- project
- flavors

On the project, you should also be sure quotas are at or above the following:

- cpus >= 200
- instances >= 100
- volumes >= 100
- RAM >= 512000
- security groups >= 100

The role of the new user will also need to have load_balancer_member (or
equivalent role granting Octavia access) assigned.

```
openstack role add --user <new_user> --project <new_project> load-balancer_member
```

### Flavor

A new flavor will need to be created for the servers to be created with.

### Images

Since this module will create workers on bare metal, a standard image and an
ironic image will need to be created and uploaded.

### Gateway ID

One more piece of information you will need is the external gateway id. This
can be found in the network list and you will want the ID. Each Openstack
setup will likely be different, so you will need an external facing gateway
id.

### SSH Key

When a key is added to the public key list in the terraform file, the private
key is currently required to be in the default location `~/.ssh/id_rsa`. This
will be fixed with https://github.com/rackerlabs/terraform-rke/issues/9

### Kubernetes API Audit Logging

If you are deploying with an RKE version > 1.1.0 then the Kubernetes API logging is enabled
by default. You can change the following settings if desired using the following configuration
variables in `terrafor.tf`:

- `audit_max_age`: The maximum number of days to retain old audit log files (default: 10)
- `audit_max_backup`: The maximum number of audit log files to retain (default: 10)
- `audit_max_size`: The maximum size in megabytes of the audit log file before it gets rotated. (default: 100)

See https://kubernetes.io/docs/tasks/debug-application-cluster/audit/ for more info
on what is logged.

### CA Certs

The CA cert chain will need to be provided for the Openstack cluster and added
to the `terraform.tf` file in PEM format under `openstack_ca`.

### NTP Servers
You can set custom ntp servers for the host images to use for NTP. Set a 
`ntp_servers` config as a comma seperated list of the form 
`["ntp1.server.com","ntp2.server.com"]

### Kubernetes Resources
Terraform is not able to create Kubernetes resources in the first run. This is
because the Terraform provider configuration is evaluated before the kube config
is created. Therefore, a variable called `kubernetes_resources` is available.
The recommended workflow is to run your first apply without setting this variable,
and when the application is complete, add `kubernetes_resources = true` to the
openstack-nova module and run `terraform apply` again.

## Package Manager Proxy

You can configure the package manager to use a proxy by setting 
`pkg_manager_proxy: http://<proxy_url:port>`following value in `terraform.tf`.

### Private Image Repository

If your deployment is using a private image repository for your docker images,
you will need to add the registry url in the format of `"url:port"` under the
`docker_registry` key in `terraform.tf`. This entry will be added as an insecure
registry.

### Private Yum Package Repository

If your deployment is using a private yum package repository for your yum
packages you will need to set the `yum_repo` key to `true`. You will also need to 
set the following variables appropriately:

- `docker_ce_gpg_key_url: http(s)://<url:port>/<repository_dir>`
- `docker_ce_repo_base_url: http(s)://<url:port>/<repository_dir>`
- `yum_base_repo_package_url: http(s)://<url:port>/<repository_dir>`
- `yum_updates_repo_package_url: http(s)://<url:port>/<repository_dir>`
- `yum_extras_repo_package_url: http(s)://<url:port>/<repository_dir>`
- `yum_centosplus_repo_package_url: http(s)://<url:port>/<repository_dir>`

### Network

In most OpenStack Ironic deployments, the network in use will be shared. To
create Allowed Address Pairs for this network, a special Neutron Policy must
be added:

```yaml
neutron_policy_overrides:
  create_port:allowed_address_pairs: "rule:admin_or_network_owner or role:aap"
  create_port:allowed_address_pairs:ip_address: "rule:admin_or_network_owner or role:aap"
  create_port:allowed_address_pairs:mac_address: "rule:admin_or_network_owner or role:aap"
  update_port:allowed_address_pairs: "rule:admin_or_network_owner or role:aap"
  update_port:allowed_address_pairs:ip_address: "rule:admin_or_network_owner or role:aap"
  update_port:allowed_address_pairs:mac_address: "rule:admin_or_network_owner or role:aap"
```

Once this policy is added, the `aap` role will need to be added to the user
created for deployment.

## Setup

### Terraform Setup

Copy the following example terraform file into a new directory for the customer's
cluster and fill out the variables.

## Example terraform.tf (with Layer 2 as metallb configuration)

```yaml
module "openstack-ironic" {
  source = "git@github.com:rackerlabs/terraform-rke.git//openstack-ironic"
  dns_zone_name         = "<customer_domain_for_clusters>"
  flavor_bastion        = "<new_flavor>"
  naming_prefix         = "<cluster_name>-"
  openstack_auth_url    = "https://<openstack_cluster_api>:5000/v3"
  openstack_insecure    = true
  openstack_ca          = <<EOF
-----BEGIN CERTIFICATE-----
MIIIWjCCBkKgAwIBAgITGQAAAASeol/i3qNNqQAAAAAABDANBgkqhkiG9w0BAQsF
...
EOF
  openstack_password    = "<password_generated_for_new_user>"
  openstack_tenant_name = "<new_project>"
  openstack_user_name   = "<new_user>"
  network_id            = "<network_id>"
  metallb_protocol      = layer2
  metallb_cidr_prefix   = "192.168.200.10/24"
  metallb_host_count    = 10
  metallb_host_start    = 10
  image_id              = "<image_id>"
  size_master = {
    count  = 3
    flavor = "<new_flavor>"
  }
  size_worker = {
    count    = 4
    flavor   = "<ironic_flavor>"
    image_id = "<ironic_image_id>"
  }
  ssh_key_path = "<private_key_for_ssh>"
  ssh_authorized_keys = [
    "ssh-rsa <public_key_of_ssh_key_path>"
  ]
  subnet_id = "<subnet_id>"
}
```

## Example terraform.tf (with BGP as metallb configuration)

```yaml
module "openstack-ironic" {
  <redacted>
  metallb_protocol      = bgp
  metallb_bgp_peers     = {
    "<peer_address>" = {
      "peer_asn" = "<peer_asn>"
      "my_asn" = "<my_asn>"
    }
  }
  metallb_bgp_address_pools = {
    "<pool_name>" = {
      "address_pool" = "<address_with_prefix>"
      "<auto_assign>" = "<auto_assign>"
      "bgp_advertisements_aggregation_length_local" = "<bgp_advertisements_aggregation_length_local>"
      "bgp_advertisements_localpref" = <bgp_advertisements_localpref>
      "bgp_advertisements_aggregation_length_generate" = "<bgp_advertisements_aggregation_length_generate>"
    }
  }
  <redacted>
}
```

When the file is in place, the environment will need to be initialized.

```
terraform init -upgrade=true
```

NOTE: `-upgrade=true` will update modules if the tag referenced in the
source line above has updates (`?ref=v1.0`).

## Build

### Terraform apply

Once everything is ready to go, a simple apply can be run.

```
terraform apply
```

After your initial apply, set the variable `kubernetes_resources = true` in
the `openstack-nova module` andd run `terraform apply` again.

### Tear down

If everything needs to be torn down and created again, RKE needs to be cleaned
up first and then the environment.

```
terraform destroy
rm -f cluster.rkestate kube_config_cluster.yml cluster.yml
```
