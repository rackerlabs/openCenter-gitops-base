# MetalLB Configuration Guide

## Overview
MetalLB is a load-balancer implementation for bare-metal Kubernetes clusters, providing LoadBalancer service functionality in environments without native cloud load balancer support.

## Key Configuration Choices

### IP Address Pool Configuration
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.100-192.168.1.200
  - 10.0.0.0/24
  autoAssign: true
```
**Why**: 
- IP pools define available addresses for LoadBalancer services
- CIDR notation and ranges provide flexible address allocation
- autoAssign enables automatic IP assignment to services

### Layer 2 Advertisement Configuration
```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default-l2-adv
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
  nodeSelectors:
  - matchLabels:
      kubernetes.io/os: linux
```
**Why**: Layer 2 mode uses ARP to announce service IPs and works in most network environments without additional configuration

### BGP Advertisement Configuration
```yaml
apiVersion: metallb.io/v1beta1
kind: BGPAdvertisement
metadata:
  name: default-bgp-adv
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
  peers:
  - peer-address: 192.168.1.1
    peer-asn: 65000
    my-asn: 65001
```
**Why**: BGP mode provides better scalability and integration with network infrastructure

## Common Pitfalls

### LoadBalancer Services Stuck in Pending
**Problem**: Services with type LoadBalancer remain in pending state without external IP

**Solution**: Verify IPAddressPool is configured and has available addresses

**Verification**:
```bash
# Check IP address pools
kubectl get ipaddresspool -n metallb-system

# Check MetalLB controller logs
kubectl logs -n metallb-system -l app.kubernetes.io/component=controller

# Verify service events
kubectl describe svc <service-name>
```

### External IPs Not Reachable
**Problem**: Services get external IPs but are not accessible from outside the cluster

**Solution**: Ensure network routing is configured correctly and L2Advertisement or BGPAdvertisement is properly set up

### Speaker Pods Not Running
**Problem**: MetalLB speaker pods fail to start or crash repeatedly

**Solution**: Check node network configuration, security contexts, and host network access

```bash
# Check speaker pod logs
kubectl logs -n metallb-system -l app.kubernetes.io/component=speaker

# Verify speaker daemonset
kubectl get daemonset -n metallb-system speaker

# Check node network interfaces
kubectl exec -n metallb-system <speaker-pod> -- ip addr show
```

## Required Secrets

### BGP Router Passwords
For BGP mode, router authentication passwords may be required

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: bgp-auth
  namespace: metallb-system
type: Opaque
stringData:
  password: your-bgp-password
```

**Key Fields**:
- `password`: BGP peer authentication password (optional)

### TLS Certificates
For webhook validation, TLS certificates are automatically managed

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: webhook-server-cert
  namespace: metallb-system
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-cert>
  tls.key: <base64-encoded-key>
```

**Key Fields**:
- `tls.crt`: TLS certificate for webhook server (automatically generated)
- `tls.key`: TLS private key for webhook server (automatically generated)

## Verification
```bash
# Check MetalLB pods are running
kubectl get pods -n metallb-system

# Verify IP address pools
kubectl get ipaddresspool -n metallb-system

# Check L2 advertisements
kubectl get l2advertisement -n metallb-system

# Test LoadBalancer service
kubectl get svc --field-selector spec.type=LoadBalancer
```

## Usage Examples

### Create LoadBalancer Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-lb
spec:
  type: LoadBalancer
  loadBalancerIP: 192.168.1.150  # Optional: request specific IP
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx
```

### Configure Multiple IP Pools
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: production-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.1.100-10.0.1.200
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: development-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.2.100-10.0.2.200
```

MetalLB provides essential LoadBalancer functionality for bare-metal and on-premises Kubernetes clusters. Choose Layer 2 mode for simple deployments or BGP mode for integration with network infrastructure and better scalability.