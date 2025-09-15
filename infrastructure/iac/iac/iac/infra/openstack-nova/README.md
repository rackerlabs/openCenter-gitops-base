# OpenStack Nova

This module deploys a standard Kubernetes cluster on OpenStack Nova.

## Pre run requirements

Before you can use this module, all of the Openstack bits need to be created
first. You can either create the resources and quotas listed below, or you can use the (preferred)
module [openstack-identity](../openstack-identity/README.md).

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

The role of the new user will also need to have load_balancer_member assigned.

```
openstack role add --user <new_user> --project <new_project> load-balancer_member
```

### Flavor

A new flavor will need to be created for the servers to be created with.

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

### PCI compliance

For PCI compliance, the `bastion_image_id` needs to be set to an image ID that has the
Splunk Universal Forwarder installed. Not setting `bastion_image_id` will use the same
`image_id` for all the nodes.

## Setup

### Terraform Setup

Copy the following example terraform file into a new directory for the customer's
cluster and fill out the variables.

## Example terraform.tf

```yaml
module "openstack-nova" {
  source = "git@github.com:rackerlabs/terraform-rke.git//openstack-nova"
  dns_zone_name              = "<customer_domain_for_clusters>"
  flavor_bastion             = "<new_flavor>"
  floatingip_pool            = "<gateway_net_name>"
  naming_prefix              = "<cluster_name>-"
  openstack_auth_url         = "https://<openstack_cluster_api>:5000/v3"
  openstack_insecure         = true
  openstack_ca               = <<EOF
-----BEGIN CERTIFICATE-----
MIIIWjCCBkKgAwIBAgITGQAAAASeol/i3qNNqQAAAAAABDANBgkqhkiG9w0BAQsF
...
EOF
  openstack_password         = "<password_generated_for_new_user>"
  openstack_tenant_name      = "<new_project>"
  openstack_user_name        = "<new_user>"
  router_external_network_id = "<GATEWAY_NET_ID>"
  size_master = {
    count  = 3
    flavor = "<new_flavor>"
  }
  size_worker = {
    count  = 4
    flavor = "<new_flavor>"
  }
  ssh_key_path = "<private_ssh_key_path>"
  ssh_authorized_keys = [
    "ssh-rsa <public_key_of_ssh_key_path>"
  ]
  pkg_manager_proxy = "http://<proxy_url:port>"
  docker_registry = "<registry_url:port>"
}
```

When the file is in place, the environment will need to be initialized.

```
terraform init -upgrade=true
```

NOTE: `-upgrade=true` will update modules if the tag referenced in the
source line above has updates (`?ref=v1.0`).

## Deploying MetalLB

```tf

module "openstack_nova" {
  //...

  use_octavia = false
}

/*
This module can be added either before or after the cluster is deployed.
Either set the local variables defined in this block or hard-code them below.
Make sure the module in the `module_depends_on` value below matches the name
of the Nova module defined above.
*/
module "metallb" {
  source = "git@github.com:rackerlabs/terraform-rke.git//lib/metallb"

  metallb_helm_repo         = "https://charts.bitnami.com/bitnami"
  metallb_helmchart_version = "2.3.6"
  metallb_protocol          = "layer2"

  metallb_cidr_prefix       = local.metallb_cidr_prefix
  metallb_host_count        = local.metallb_host_count
  metallb_host_start        = local.metallb_host_start
  network_id                = local.network_id
  subnet_id                 = local.subnet_id

  metallb_helmchart_vals    = [
    {
      name = "psp.create"
      val  = "true"
    }
  ]
  
  module_depends_on         = [module.openstack_nova]
}
```

## Build

### Terraform apply

Once everything is ready to go, a simple apply can be run.

```
terraform apply
```

### Tear down

If everything needs to be torn down and created again, RKE needs to be cleaned
up first and then the environment.

```
terraform destroy
rm -f cluster.rkestate kube_config_cluster.yml cluster.yml
```

# Contributions
Please see our [Contributing Guidelines](./CONTRIBUTING.md)