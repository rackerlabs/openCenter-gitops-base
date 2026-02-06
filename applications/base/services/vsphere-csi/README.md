# vSphere CSI – Base Configuration

This directory contains the base manifests for deploying the vSphere Cloud Storage Interface (CSI) driver, enabling Kubernetes clusters running on VMware vSphere to provision and manage persistent storage natively.  
It is designed to be consumed by cluster repositories as a remote base, allowing each cluster to apply custom overrides such as StorageClass definitions, topology settings, or credentials.

**About vSphere CSI:**

- Provides dynamic provisioning of PersistentVolumes (PVs) backed by vSphere datastores including vSAN, VMFS, and NFS.
- Supports advanced features such as volume expansion, snapshots, and cloning.
- Integrates with vSphere Storage Policy Based Management (SPBM) so Kubernetes PVCs can inherit vSphere storage policies.
- Enables topology-aware provisioning, ensuring volumes are created in the appropriate zone or failure domain for workload placement.
- Offloads volume lifecycle operations to vSphere, improving reliability, consistency, and automation.

## Topology Support

This base configuration includes the `csinodetopologies.cns.vmware.com` CustomResourceDefinition (CRD) required for topology-aware volume provisioning. The CRD enables:

- **Zone-aware volume placement**: Volumes are created in the same vSphere cluster/zone as the Pod
- **High availability across failure domains**: StatefulSets can be spread across multiple zones
- **Pod and volume co-location**: Minimizes latency by keeping Pods and volumes in the same zone
- **Intelligent scheduling**: Supports Kubernetes affinity/anti-affinity rules based on failure domains

### Topology Configuration

To enable topology features, configure the following in your cluster-specific overrides:

1. **Tag vSphere inventory objects** with region and zone labels
2. **Configure csi-vsphere.conf** with topology labels:
   ```ini
   [Labels]
   region = k8s-region
   zone = k8s-zone
   ```
3. **Enable topology in Helm values**:
   ```yaml
   improved-volume-topology: true
   ```

For detailed topology configuration, see the [vSphere CSI Topology Documentation](https://vsphere-csi-driver.sigs.k8s.io/features/topology.html).

## CRDs Included

This base configuration includes all required vSphere CSI CustomResourceDefinitions:

- **csinodetopologies.cns.vmware.com**: Tracks node topology information for zone-aware provisioning
- **cnsvolumeoperationrequests.cns.vmware.com**: Manages asynchronous volume operations (create, delete, attach, detach, extend)
- **csistoragecapacities.storage.k8s.io**: Tracks available storage capacity for intelligent scheduling (Note: Built-in for Kubernetes 1.24+, included for compatibility with older versions)

## Dependencies

- vSphere 6.7 U3+ or vSphere 7.0+
- Kubernetes 1.18+
- vSphere Cloud Provider (CPI) must be installed and nodes must have ProviderID set
