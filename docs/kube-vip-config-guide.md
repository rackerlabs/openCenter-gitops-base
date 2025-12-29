# Kube-VIP Configuration Guide

## Overview

Kube-VIP provides a highly available Virtual IP (VIP) for the Kubernetes control plane API server. It uses ARP (Address Resolution Protocol) to advertise the VIP across control plane nodes, ensuring that the Kubernetes API remains accessible even if individual control plane nodes fail.

## When to Use Kube-VIP

Use kube-vip when:
- You need a highly available Kubernetes API endpoint without external load balancers
- You're deploying on bare metal or environments where Octavia/cloud load balancers are not available
- You want a simple, lightweight HA solution for the control plane
- You have multiple control plane nodes (1 or 3+ masters)

## Architecture

Kube-VIP runs as a static pod on each control plane node and:
1. Manages a shared VIP that floats between control plane nodes
2. Uses ARP to announce the VIP on the network
3. Provides automatic failover if the active node becomes unavailable
4. Binds to a specific network interface for VIP management

## Configuration Variables

### Required Variables

```hcl
# Enable kube-vip
kube_vip_enabled = true

# The Virtual IP address for the Kubernetes API
# Must be from the same subnet as your nodes (subnet_nodes)
# Should NOT be in the DHCP/allocation pool range
vrrp_ip = "10.2.184.10"

# Network interface where kube-vip will bind
# This should match your primary node network interface
cni_iface = "enp3s0"

# Enable Kube-vip and the creation of its required infrastructure resources. Eg In Openstack a dummy port with a floating IP associated.
vrrp_enabled = true

# Disable Octavia (cloud load balancer)
# kube-vip and Octavia are mutually exclusive
use_octavia = false
```

### Network Planning

When planning your network, reserve IP addresses appropriately:

```hcl
# Example network layout
subnet_nodes = "10.2.184.0/22"

# Reserve IPs outside the allocation pool
allocation_pool_start = "10.2.184.50"   # Start DHCP range here
allocation_pool_end   = "10.2.184.254"  # End DHCP range here

# VIP should be outside the allocation pool
vrrp_ip = "10.2.184.10"  # Reserved for kube-vip

# Optional: Reserve range for MetalLB or other services
# e.g., 10.2.184.11-10.2.184.49
```

## Implementation Example

### Stage Cluster Configuration

From `000000-opencenter-example/infrastructure/clusters/stage-cluster/main.tf`:

```hcl
locals {
  # Network configuration
  subnet_nodes          = "10.2.184.0/22"
  subnet_nodes_oct      = join(".", slice(split(".", split("/", local.subnet_nodes)[0]), 0, 3))
  
  # Reserve VIP outside allocation pool
  allocation_pool_start = "${local.subnet_nodes_oct}.50"
  allocation_pool_end   = "${local.subnet_nodes_oct}.254"
  vrrp_ip              = "${local.subnet_nodes_oct}.10"
  
  # Kube-VIP settings
  kube_vip_enabled     = true
  vrrp_enabled         = true
  use_octavia          = false
  
  # Network interface
  cni_iface            = "enp3s0"
  
  # API configuration
  k8s_api_port         = 443
}

module "kubespray-cluster" {
  source = "github.com/rackerlabs/openCenter.git//install/iac/kubespray?ref=main"
  
  kube_vip_enabled = local.kube_vip_enabled
  vrrp_ip          = local.vrrp_ip
  vrrp_enabled     = local.vrrp_enabled
  use_octavia      = local.use_octavia
  cni_iface        = local.cni_iface
  k8s_api_ip       = module.openstack-nova.k8s_api_ip
  k8s_api_port     = local.k8s_api_port
  
  # ... other configuration
}
```

## Kubespray Integration

The kubespray opentofu module automatically configures kube-vip through the addons template:

```yaml
# Generated in inventory/group_vars/k8s_cluster/addons.yml
kube_vip_enabled: true
kube_vip_arp_enabled: true
kube_vip_controlplane_enabled: true
kube_vip_address: 10.2.184.10
kube_vip_interface: "enp3s0"
kube_vip_services_enabled: false
```

### Key Settings Explained

- `kube_vip_arp_enabled`: Enables ARP for VIP advertisement
- `kube_vip_controlplane_enabled`: Enables control plane VIP management
- `kube_vip_address`: The VIP that clients will use to reach the API
- `kube_vip_interface`: Network interface for VIP binding
- `kube_vip_services_enabled`: Set to false (use MetalLB for service load balancing instead)

## Hardening Considerations

When using kube-vip with hardened clusters, ensure the VIP is included in kubelet secure addresses:

```yaml
# From hardening.tpl
kubelet_secure_addresses: "localhost link-local ${subnet_pods} ${subnet_nodes} ${vrrp_ip}"
```

This allows kubelet to accept connections from the VIP address.

## Verification

After deployment, verify kube-vip is working:

```bash
# Check kube-vip pods on control plane nodes
kubectl get pods -n kube-system | grep kube-vip

# Verify VIP is responding
curl -k https://<vrrp_ip>:<k8s_api_port>/healthz

# Check which node is currently holding the VIP
ip addr show | grep <vrrp_ip>
```

## Troubleshooting

### VIP Not Accessible

1. Verify the VIP is not in the DHCP allocation pool
2. Check that `vrrp_enabled = true` and `use_octavia = false`
3. Ensure the network interface name (`cni_iface`) is correct
4. Verify no firewall rules are blocking ARP traffic
5. Check if quorum is broken. Like 2 nodes down out of the total 3.

### Kube-VIP Pods Not Starting

1. Check kubespray deployment logs
2. Verify the interface exists on control plane nodes: `ip link show`
3. Check the kube-vip container logs directly on the control plane nodes.

### API Endpoint Not Updating

After deployment, the kubeconfig is automatically updated to use the VIP:

```bash
# The kubespray module runs this automatically
ansible localhost -c local -m replace \
  -a "path=./kubeconfig.yaml \
      regexp='server: https://.*:[0-9]*' \
      replace='server: https://${vrrp_ip}:${k8s_api_port}'"
```

## Kube-VIP vs Octavia

| Feature | Kube-VIP | Octavia |
|---------|----------|---------|
| Deployment | Static pods on control plane | External load balancer service |
| Cost | No additional cost | May incur cloud provider costs |
| Complexity | Simple, self-contained | Requires cloud provider integration |
| Use Case | Bare metal, on-prem, cost-sensitive | Cloud environments with LBaaS |
| Mutual Exclusivity | Cannot use with Octavia | Cannot use with kube-vip |

**Important**: `vrrp_enabled` cannot be set to true if `use_octavia` is true. Choose one approach.

## Best Practices

1. **IP Planning**: Always reserve the VIP outside your DHCP/allocation pool
2. **Interface Verification**: Confirm the network interface name before deployment
3. **Master Count**: Deploy 1 or 3 control plane nodes (avoid 2 for quorum)
4. **Service Load Balancing**: Use MetalLB for service-type LoadBalancer, not kube-vip
5. **Monitoring**: Monitor kube-vip pod health and VIP accessibility
6. **Documentation**: Document your VIP and reserved IP ranges

## Related Configuration

- **MetalLB**: For service load balancing (separate from control plane HA)
- **Calico/CNI**: Ensure CNI interface matches kube-vip interface
- **Firewall Rules**: Allow ARP and API traffic on the VIP
- **DNS**: Optionally create DNS records pointing to the VIP

## References

- [Kube-VIP Documentation](https://kube-vip.io/)
- [Kubespray Kube-VIP Integration](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/kube-vip.md)
- OpenCenter GitOps Base: `iac/provider/kubespray/`
