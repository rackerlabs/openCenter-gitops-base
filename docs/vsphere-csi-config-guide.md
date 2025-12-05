# vSphere CSI Driver Configuration

## Overview
vSphere CSI driver provides persistent storage and snapshot capabilities for Kubernetes workloads running on vSphere infrastructure.

## Key Configuration Choices

### Snapshot Support
```yaml
controller:
  replicaCount: 3
  config:
    block-volume-snapshot: true
  snapshotter:
    image:
      registry: registry.k8s.io
      repository: sig-storage/csi-snapshotter
      tag: v8.2.0
```
**Why**: 
- `block-volume-snapshot: true`: Enables block volume snapshot capability in the CSI driver
- `snapshotter` sidecar: Required for the CSI controller to handle VolumeSnapshot requests from Velero

Both settings are required for CSI snapshot functionality.

### Snapshot Controller
```yaml
snapshot:
  controller:
    enabled: true
```
**Why**: Deploys the snapshot-controller which watches VolumeSnapshot resources and coordinates with the CSI driver to create snapshots.

## Common Pitfalls

### Missing Snapshotter Sidecar
**Problem**: VolumeSnapshots stuck in "Waiting for CSI driver" state.

**Solution**: The `controller.snapshotter` configuration must be present in helm values. The snapshotter sidecar container is NOT enabled by default and must be explicitly configured.

**Verification**:
```bash
kubectl get pod -n vmware-system-csi <controller-pod> -o jsonpath='{.spec.containers[*].name}'
```
Should include `csi-snapshotter` in the output.

### Pod Security Standards
**Problem**: CSI pods fail to start with "violates PodSecurity" errors.

**Solution**: The vmware-system-csi namespace requires `privileged` Pod Security Standard due to hostPath volumes and privileged containers.

```yaml
metadata:
  labels:
    pod-security.kubernetes.io/enforce: privileged
```

## Required Secrets

### vsphere-config-secret (CSI Driver)
Contains vSphere connection details for the CSI driver. Key: `csi-vsphere.conf`

```ini
[Global]
cluster-id = "k8s-dr"

[VirtualCenter "vcenter.example.com"]
insecure-flag = "true"
user = "administrator@vsphere.local"
password = "password"
port = "443"
datacenters = "Datacenter1"
```

**Key Fields**:
- `cluster-id`: Unique identifier for this Kubernetes cluster
- `insecure-flag`: Set to "true" for self-signed certificates
- `datacenters`: vSphere datacenter name(s)

### vsphere-cpi-secret (Cloud Provider Interface)
Contains vSphere configuration for the CPI. Key: `vsphere.conf`

```yaml
global:
  port: 443
  insecureFlag: true

vcenter:
  vcenter-name:
    server: vcenter.example.com
    user: administrator@vsphere.local
    password: "password"
    datacenters:
      - Datacenter1
```

**Key Fields**:
- `vcenter-name`: Arbitrary name for this vCenter (used as identifier)
- `server`: vCenter hostname or IP
- `datacenters`: List of datacenter names

**Note**: Both secrets use the same vSphere credentials but different formats (INI vs YAML).

## Verification
```bash
# Check CSI driver is registered
kubectl get csidrivers csi.vsphere.vmware.com

# Verify snapshot controller is running
kubectl get pods -n vmware-system-csi | grep snapshot-controller

# Test snapshot capability
kubectl get volumesnapshotclass
```
