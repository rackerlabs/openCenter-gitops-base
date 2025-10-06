# Velero – Base Configuration

This directory contains the **base manifests** for deploying [Velero](https://velero.io/), an open-source tool for **backup, restore, and disaster recovery** of Kubernetes clusters and persistent volumes.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About Velero:**

- Provides **backup and restore** capabilities for Kubernetes resources, namespaces, and persistent volumes.  
- Supports **scheduled backups**, **on-demand restores**, and **disaster recovery** across clusters or environments.  
- Integrates with multiple storage backends, including **S3-compatible object storage**.
- Uses **BackupStorageLocation** and **VolumeSnapshotLocation** custom resources to manage backup targets and configurations.  
- Works seamlessly with **CSI snapshotters**(such as External Snapshotter) for volume-level backups.  
- Enables **migration of workloads** between clusters by restoring backups into new environments.  
- Supports encryption, retention policies, and incremental backups for efficient and secure data protection.  
- Commonly used to safeguard production workloads and ensure recoverability in hybrid or multi-cluster Kubernetes deployments.  
- Simplifies cluster recovery workflows and enhances operational resilience.  
