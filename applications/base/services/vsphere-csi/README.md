# vSphere CSI – Base Configuration

This directory contains the base manifests for deploying the vSphere Cloud Storage Interface (CSI) driver, enabling Kubernetes clusters running on VMware vSphere to provision and manage persistent storage natively.  
It is designed to be consumed by cluster repositories as a remote base, allowing each cluster to apply custom overrides such as StorageClass definitions, topology settings, or credentials.

**About vSphere CSI:**

- Provides dynamic provisioning of PersistentVolumes (PVs) backed by vSphere datastores including vSAN, VMFS, and NFS.
- Supports advanced features such as volume expansion, snapshots, and cloning.
- Integrates with vSphere Storage Policy Based Management (SPBM) so Kubernetes PVCs can inherit vSphere storage policies.
- Enables topology-aware provisioning, ensuring volumes are created in the appropriate zone or failure domain for workload placement.
- Offloads volume lifecycle operations to vSphere, improving reliability, consistency, and automation.
