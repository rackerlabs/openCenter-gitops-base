# OpenStack IaC Modules

This directory contains the OpenStack-specific Terraform/OpenTofu modules used by openCenter.

The top-level modules are:

- `openstack-identity`: creates or prepares the OpenStack project, user, quotas, flavors, and optional VLAN-backed network
- `openstack-nova`: deploys a Kubernetes cluster on Nova virtual machines
- `openstack-ironic`: alternative top-level OpenStack cluster module

## Module Map

| Module | Purpose | Reference |
| --- | --- | --- |
| `openstack-identity` | Creates user, project, quotas, flavors, and optional VLAN network for cluster deployment | `openstack-identity/README.md` |
| `openstack-nova` | Creates an all-Nova cluster, including bastion, control plane, workers, VIP or load balancer, and optional Windows workers | `openstack-nova/README.md` |
| `openstack-ironic` | Alternative top-level OpenStack cluster module | `openstack-ironic/README.md` |

## Variable Reference

The tables below summarize the main inputs exposed by the current `variables.tf` files in this directory. For exact behavior, use the module source as the final reference.

### `openstack-identity`

| Variable | Required | Default | Notes |
| --- | --- | --- | --- |
| `openstack_auth_url` | Yes | None | Keystone auth URL |
| `openstack_ca` | Yes | None | CA bundle or CA path used by the provider |
| `openstack_user_name` | Yes | None | Name for the cluster user |
| `openstack_user_password` | Yes | None | Password for the cluster user |
| `openstack_admin_password` | Yes | None | Admin password used to create resources |
| `openstack_insecure` | No | `false` | Skip TLS verification |
| `openstack_region` | No | `RegionOne` | OpenStack region |
| `openstack_user_email` | No | `""` | Optional email for the created user |
| `openstack_admin_name` | No | `admin` | Admin username |
| `openstack_admin_tenant_name` | No | `admin` | Admin project/tenant name |
| `openstack_project_id` | No | `""` | Reuse an existing project instead of creating one |
| `openstack_domain_id` | No | `default` | Domain used when reusing an existing project |
| `quotas` | No | See module defaults | Compute and block storage quota object |
| `small_flavor` | No | See module defaults | Small flavor definition |
| `medium_flavor` | No | See module defaults | Medium flavor definition |
| `large_flavor` | No | See module defaults | Large flavor definition |
| `xlarge_flavor` | No | See module defaults | Extra-large flavor definition |
| `vlan_id` | No | `""` | When set, creates a VLAN-backed network |
| `vlan_mtu` | No | `1500` | MTU for the VLAN network |
| `network_provider` | No | `""` | Provider network name used for VLAN mode |

Key outputs:

| Output | Notes |
| --- | --- |
| `openstack_tenant_id` | Project ID created or reused by the module |
| `openstack_user_id` | Created OpenStack user ID |
| `openstack_user_name` | Created OpenStack user name |
| `small_flavor_name` | Name of the small flavor |
| `medium_flavor_name` | Name of the medium flavor |
| `large_flavor_name` | Name of the large flavor |
| `xlarge_flavor_name` | Name of the extra-large flavor |
| `network_id` | VLAN network ID when `vlan_id` is used |

### `openstack-nova`

Required inputs:

| Variable | Required | Default | Notes |
| --- | --- | --- | --- |
| `dns_zone_name` | Yes | None | DNS zone used by the cluster |
| `flavor_bastion` | Yes | None | Flavor for the bastion host |
| `floatingip_pool` | Yes | None | External network or pool used for floating IPs |
| `image_id` | Yes | None | Base image for Linux nodes |
| `naming_prefix` | Yes | None | Prefix used in resource names |
| `openstack_auth_url` | Yes | None | Keystone auth URL |
| `openstack_ca` | Yes | None | CA bundle or CA path used by the provider |
| `openstack_password` | Yes | None | Password for the OpenStack user |
| `openstack_tenant_name` | Yes | None | Project or tenant for the cluster |
| `openstack_user_name` | Yes | None | OpenStack username |
| `router_external_network_id` | Yes | None | External network ID used when this module creates the router |
| `size_master` | Yes | None | Object with master count and flavor |
| `size_worker` | Yes | None | Object with worker count and flavor |
| `ssh_authorized_keys` | Yes | None | Public keys injected into instances |
| `use_designate` | Yes | None | Enable or disable Designate DNS resources |
| `vrrp_ip` | Yes | None | Internal VIP used for the Kubernetes API |

Common optional inputs:

| Variable | Default | Notes |
| --- | --- | --- |
| `openstack_insecure` | `false` | Skip TLS verification |
| `openstack_region` | `RegionOne` | OpenStack region |
| `openstack_project_domain_name` | `null` | Project domain override |
| `openstack_user_domain_name` | `null` | User domain override |
| `application_credential_id` | `""` | Optional application credential ID |
| `application_credential_secret` | `""` | Optional application credential secret |
| `availability_zone` | `nova` | Placement AZ for instances |
| `network_id` | `""` | Reuse an existing network instead of creating one |
| `subnet_id` | `""` | Reuse an existing subnet instead of creating one |
| `subnet_nodes` | `10.0.0.0/22` | Node network CIDR when the module creates networking |
| `subnet_pods` | `10.42.0.0/16` | Pod CIDR |
| `subnet_services` | `10.43.0.0/16` | Service CIDR |
| `dns_nameservers` | `["8.8.8.8","8.8.4.4"]` | DNS resolvers for the created subnet |
| `ntp_servers` | `["time.dfw1.rackspace.com","time2.dfw1.rackspace.com"]` | NTP servers passed into cloud-init |
| `ssh_key_path` | `~/.ssh/id_rsa` | Private key path used by downstream automation |
| `ssh_user` | `ubuntu` | Linux SSH user |
| `disable_bastion` | `false` | Skip bastion creation |
| `bastion_image_id` | `""` | Override bastion image |
| `image_name` | `""` | Use image name lookup instead of ID where supported |
| `use_octavia` | `true` | Create Octavia load balancer resources for the API |
| `loadbalancer_provider` | `amphora` | Octavia provider |
| `k8s_api_port` | `443` | Public Kubernetes API port |
| `vrrp_enabled` | `true` | Create VIP port and optional floating IP |
| `k8s_api_port_acl` | `["0.0.0.0/0"]` | Allowed CIDRs for Kubernetes API access |
| `allocation_pool_start` | `null` | Optional DHCP allocation pool start for the created subnet |
| `allocation_pool_end` | `null` | Optional DHCP allocation pool end for the created subnet |
| `mtu` | `null` | MTU for the created network |
| `vlan_id` | `""` | Create or use VLAN-backed networking mode |
| `router_id` | `""` | Reuse an existing router attachment instead of creating one |

Advanced optional inputs:

| Variable | Default | Notes |
| --- | --- | --- |
| `size_worker_windows` | `{ count = 0, flavor = "gp.0.8.16" }` | Enables Windows workers when count is greater than zero |
| `image_id_windows` | `899af84f-d98f-4255-bf98-ceba5e3a8257` | Default Windows image ID |
| `windows_user` | `administrator` | Windows user injected into user-data |
| `windows_admin_password` | `""` | Windows administrator password |
| `node_master` | `""` | Override the master hostname role label |
| `node_worker` | `""` | Override the worker hostname role label |
| `node_worker_windows` | `""` | Override the Windows worker hostname role label |
| `additional_allowed_addresses_master` | `[]` | Extra allowed address pairs added to master nodes |
| `additional_allowed_addresses_worker` | `[]` | Extra allowed address pairs added to worker nodes |
| `additional_ports_master` | `[]` | Extra security group ports for masters |
| `additional_ports_worker` | `[]` | Extra security group ports for workers |
| `additional_block_devices_master` | `[]` | Extra block devices for masters |
| `additional_block_devices_worker` | `[]` | Extra block devices for workers |
| `additional_server_pools_worker` | `[]` | Additional Linux worker pools |
| `additional_server_pools_worker_windows` | `[]` | Additional Windows worker pools |
| `master_node_bfv_source_type` | `image` | Boot-from-volume source type for masters |
| `master_node_bfv_volume_size` | `0` | Boot-from-volume size for masters |
| `master_node_bfv_destination_type` | `local` | Boot destination type for masters |
| `master_node_bfv_delete_on_termination` | `true` | Delete master boot volume on instance termination |
| `master_node_bfv_volume_type` | `Standard` | Master boot volume type |
| `worker_node_bfv_source_type` | `image` | Boot-from-volume source type for workers |
| `worker_node_bfv_volume_size` | `0` | Boot-from-volume size for workers |
| `worker_node_bfv_destination_type` | `local` | Boot destination type for workers |
| `worker_node_bfv_delete_on_termination` | `true` | Delete worker boot volume on instance termination |
| `worker_node_bfv_volume_type` | `standard` | Worker boot volume type |
| `worker_node_bfv_size_windows` | `100` | Windows worker boot volume size |
| `worker_node_bfv_type_windows` | `local` | Windows worker boot volume type |
| `services_ca_enabled` | `false` | Enables generated services CA material |
| `services_ca_crt` | `""` | Provided services CA certificate |
| `services_ca_key` | `""` | Provided services CA key |
| `ansible_inventory_enabled` | `false` | Emit ansible inventory output |
| `csi_enabled` | `false` | Enable CSI-related configuration |
| `kubernetes_resources` | `false` | Defer Kubernetes resource creation to a later apply |
| `pf9_onboard` | `false` | Platform9 onboarding toggle |
| `pf9_account_url` | `""` | Platform9 account URL |
| `pf9_username` | `""` | Platform9 username |
| `pf9_password` | `""` | Platform9 password |
| `pf9_tenant` | `service` | Platform9 tenant |
| `pf9_region` | `RegionOne` | Platform9 region |
| `pf9_use_hostname` | `false` | Use hostnames with Platform9 |
| `pkg_manager_proxy` | `""` | Proxy for package manager access |
| `docker_registry` | `""` | Private image registry |
| `yum_repo` | `false` | Enable custom yum repository settings |
| `apt_repo` | `false` | Enable custom apt repository settings |
| `extra_env` | `[]` | Extra environment variables for kubelet and controller |
| `kubelet_extra_binds` | `[]` | Extra bind mounts for kubelet |
| `ub_version` | `""` | Ubuntu template selector used by user-data |
| `reboot` | `true` | Reboot nodes during cloud-init flow |
| `rke2_enable` | `false` | Configure additional listeners for RKE2 |
| `rke_server_port` | `9345` | RKE2 join API port |

Useful outputs:

| Output | Notes |
| --- | --- |
| `k8s_api_ip` | External or reachable Kubernetes API IP |
| `k8s_internal_ip` | Internal Kubernetes API VIP or node IP |
| `bastion_floating_ip` | Bastion floating IP when bastion is enabled |
| `master_nodes` | Master node objects |
| `worker_nodes` | Linux worker node objects |
| `worker_ids` | Linux worker instance IDs |
| `windows_nodes` | Windows worker node objects |
| `additional_worker_pools_nodes` | Map of additional Linux worker pool node objects |
| `additional_worker_pools_windows_nodes` | Map of additional Windows worker pool node objects |

### `openstack-ironic`

Required inputs:

| Variable | Required | Default | Notes |
| --- | --- | --- | --- |
| `ca_certificates` | Yes | None | Extra CA chain content passed into user-data |
| `dns_zone_name` | Yes | None | DNS zone used by the cluster |
| `flavor_bastion` | Yes | None | Flavor for the bastion host |
| `naming_prefix` | Yes | None | Prefix used in resource names |
| `network_id` | Yes | None | Existing network ID |
| `openstack_auth_url` | Yes | None | Keystone auth URL |
| `openstack_ca` | Yes | None | CA bundle or CA path used by the provider |
| `openstack_password` | Yes | None | Password for the OpenStack user |
| `openstack_tenant_name` | Yes | None | Project or tenant for the cluster |
| `openstack_user_name` | Yes | None | OpenStack username |
| `size_master` | Yes | None | Object with master count and flavor |
| `size_worker` | Yes | None | Object with worker count and flavor |
| `ssh_authorized_keys` | Yes | None | Public keys injected into instances |
| `subnet_id` | Yes | None | Existing subnet ID |
| `pf9_onboard` | Yes | None | Platform9 onboarding toggle |
| `pf9_account_url` | Yes | None | Platform9 account URL |
| `use_designate` | Yes | None | Declared by the module interface, but no Designate resources are defined in the current `openstack-ironic` module files |

Common optional inputs:

| Variable | Default | Notes |
| --- | --- | --- |
| `openstack_insecure` | `false` | Skip TLS verification |
| `openstack_region` | `RegionOne` | OpenStack region |
| `floatingip_pool` | `""` | Floating IP pool for bastion and load balancer |
| `image_id` | `""` | Base image ID |
| `image_name` | `""` | Base image name |
| `ssh_key_path` | `~/.ssh/id_rsa` | Private key path used by downstream automation |
| `ssh_user` | `ubuntu` | Linux SSH user |
| `ntp_servers` | `["time.dfw1.rackspace.com","time2.dfw1.rackspace.com"]` | NTP configuration passed to cloud-init |
| `subnet_pods` | `10.42.0.0/16` | Pod CIDR |
| `subnet_services` | `10.43.0.0/16` | Service CIDR |
| `subnet_servers` | `""` | Server subnet or CIDR reference |
| `user_data` | `""` | Extra user-data appended to worker nodes |
| `pkg_manager_proxy` | `""` | Proxy for package manager access |
| `docker_registry` | `""` | Private image registry |
| `yum_repo` | `false` | Enable custom yum repository settings |
| `apt_repo` | `false` | Enable custom apt repository settings |
| `addresses_worker` | `null` | Override worker addresses passed to the cluster layer |
| `ips_to_names_worker` | `{}` | Override worker IP-to-name mapping |
| `rke_version` | `""` | Explicit RKE version |
| `enable_dex` | `true` | Enable Dex configuration |
| `csi_enabled` | `false` | Enable CSI-related configuration |
| `audit_max_age` | `10` | Audit log retention days |
| `audit_max_backup` | `10` | Audit log backup count |
| `audit_max_size` | `100` | Audit log size in MB before rotation |

MetalLB and networking inputs:

| Variable | Default | Notes |
| --- | --- | --- |
| `metallb_protocol` | `""` | Set to `layer2` or `bgp` when using MetalLB |
| `metallb_cidr_prefix` | `""` | Address range for Layer 2 configuration |
| `metallb_host_count` | `0` | Number of service IPs to allocate |
| `metallb_host_start` | `0` | Starting host offset |
| `metallb_reserve_range` | `false` | Reserve the MetalLB range in OpenStack |
| `metallb_bgp_peers` | `{}` | BGP peer definitions |
| `metallb_bgp_address_pools` | `{}` | BGP address pool definitions |
| `metallb_helm_repo` | `https://charts.helm.sh/stable` | Helm repository |
| `metallb_helmchart_version` | `0.8.1` | Chart version |
| `metallb_helmchart_vals` | `[]` | Extra Helm values |
| `metallb_namespace` | `metallb-system` | Namespace for MetalLB |
| `node_default_gw` | `""` | Default gateway override for nodes |
| `nodeport_addresses` | `""` | NodePort address restriction |
| `vrrp_ip` | `""` | VIP used by the cluster, when applicable |

Useful outputs:

| Output | Notes |
| --- | --- |
| `loadbalancer_ip` | IP address returned by the module load balancer |
