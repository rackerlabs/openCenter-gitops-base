# Longhorn Configuration Guide

## Overview
Longhorn is a distributed block storage system for Kubernetes that provides persistent storage with built-in backup, snapshot, and disaster recovery capabilities.

## Key Configuration Choices

### Storage Class Configuration
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn
provisioner: driver.longhorn.io
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "2880"
  fromBackup: ""
  fsType: "ext4"
  dataLocality: "disabled"
```
**Why**: 
- Multiple replicas provide data redundancy and high availability
- Volume expansion allows growing storage without downtime
- Configurable parameters optimize performance for different workloads

### Backup Target Configuration
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-backup-target
  namespace: longhorn-system
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID: your-access-key
  AWS_SECRET_ACCESS_KEY: your-secret-key
  AWS_ENDPOINTS: https://s3.amazonaws.com
---
apiVersion: longhorn.io/v1beta1
kind: Setting
metadata:
  name: backup-target
  namespace: longhorn-system
spec:
  value: s3://longhorn-backups@us-east-1/
```
**Why**: S3-compatible backup storage enables disaster recovery and cross-cluster data migration

### Node and Disk Configuration
```yaml
apiVersion: longhorn.io/v1beta1
kind: Setting
metadata:
  name: default-data-path
  namespace: longhorn-system
spec:
  value: /var/lib/longhorn/
---
apiVersion: longhorn.io/v1beta1
kind: Setting
metadata:
  name: replica-soft-anti-affinity
  namespace: longhorn-system
spec:
  value: "true"
```
**Why**: Proper data path configuration and anti-affinity rules ensure optimal storage distribution

## Common Pitfalls

### Volume Attachment Issues
**Problem**: Pods cannot start due to volume attachment failures

**Solution**: Check node connectivity, iSCSI configuration, and Longhorn engine status

**Verification**:
```bash
# Check volume status
kubectl get volumes -n longhorn-system

# Check engine status
kubectl get engines -n longhorn-system

# Verify node connectivity
kubectl get nodes -n longhorn-system -o wide
```

### Replica Scheduling Failures
**Problem**: Volumes become degraded due to replica scheduling issues

**Solution**: Ensure sufficient storage space on nodes and check node taints/tolerations

### Backup and Restore Issues
**Problem**: Backup operations fail or restore doesn't work

**Solution**: Verify backup target configuration, credentials, and network connectivity

```bash
# Check backup target settings
kubectl get setting -n longhorn-system backup-target

# List available backups
kubectl get backups -n longhorn-system

# Check backup job logs
kubectl logs -n longhorn-system -l app=longhorn-manager | grep backup
```

## Required Secrets

### Backup Storage Credentials
For S3-compatible backup storage

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-backup-target
  namespace: longhorn-system
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID: your-access-key
  AWS_SECRET_ACCESS_KEY: your-secret-key
  AWS_ENDPOINTS: https://s3.amazonaws.com
```

**Key Fields**:
- `AWS_ACCESS_KEY_ID`: S3 access key ID (required for S3 backups)
- `AWS_SECRET_ACCESS_KEY`: S3 secret access key (required for S3 backups)
- `AWS_ENDPOINTS`: S3 endpoint URL (optional, defaults to AWS)

### Registry Credentials
For private container registries

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-registry-secret
  namespace: longhorn-system
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-docker-config>
```

**Key Fields**:
- `.dockerconfigjson`: Docker registry credentials (required for private registries)

## Verification
```bash
# Check Longhorn pods
kubectl get pods -n longhorn-system

# Verify Longhorn UI access
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80

# Check storage class
kubectl get storageclass longhorn

# Test volume creation
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 1Gi
EOF
```

## Usage Examples

### Create Recurring Backup Job
```yaml
apiVersion: longhorn.io/v1beta1
kind: RecurringJob
metadata:
  name: daily-backup
  namespace: longhorn-system
spec:
  cron: "0 2 * * *"  # Daily at 2 AM
  task: backup
  groups:
  - default
  retain: 7
  concurrency: 2
```

### Volume Snapshot
```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: myapp-snapshot
spec:
  volumeSnapshotClassName: longhorn-snapshot-vsc
  source:
    persistentVolumeClaimName: myapp-pvc
```

### Restore from Backup
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 10Gi
  dataSource:
    name: backup-xyz
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
```

### Configure Volume Encryption
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn-encrypted
provisioner: driver.longhorn.io
parameters:
  numberOfReplicas: "3"
  encrypted: "true"
  # Encryption requires additional setup with cryptsetup
```

Longhorn provides enterprise-grade distributed storage for Kubernetes. Regular monitoring of storage usage, backup verification, and disaster recovery testing are essential for maintaining data integrity.