# Velero Configuration Guide

## Overview
Velero provides backup and disaster recovery capabilities for Kubernetes clusters, supporting both resource backups and persistent volume snapshots.

## Key Configuration Choices

### Backup Storage Location Configuration
```yaml
backupStorageLocations:
- name: default
  provider: aws
  bucket: velero-backups
  config:
    region: us-east-1
    s3ForcePathStyle: "false"
  credential:
    name: cloud-credentials
    key: cloud
```
**Why**: 
- S3-compatible storage provides reliable, scalable backup storage
- Multiple storage locations enable cross-region backup strategies
- Credentials separation improves security

### Volume Snapshot Location Configuration
```yaml
volumeSnapshotLocations:
- name: default
  provider: csi
  config:
    # CSI driver handles snapshot configuration
```
**Why**: CSI snapshots provide native Kubernetes volume snapshot capabilities with better integration

### CSI Snapshot Integration
```yaml
configuration:
  features: EnableCSI
  defaultSnapshotMoveData: false
  defaultVolumesToFsBackup: false
  volumeSnapshotLocation: []
```
**Why**: CSI integration provides more reliable and efficient volume backups compared to file-level backups

## Common Pitfalls

### Backup Storage Authentication Issues
**Problem**: Velero cannot access backup storage due to authentication failures

**Solution**: Verify cloud credentials are correctly configured and have appropriate permissions

**Verification**:
```bash
# Check Velero deployment logs
kubectl logs -n velero deployment/velero

# Verify backup storage location
kubectl get backupstoragelocation -n velero

# Test backup storage access
velero backup-location get
```

### Volume Snapshot Failures
**Problem**: Volume snapshots fail during backup operations

**Solution**: Ensure CSI driver supports snapshots and VolumeSnapshotClass is properly configured

### Node Agent Issues
**Problem**: File-level backups fail due to node agent problems

**Solution**: Check node agent daemonset status and ensure proper node access

```bash
# Check node agent pods
kubectl get pods -n velero -l name=node-agent

# Check node agent logs
kubectl logs -n velero -l name=node-agent

# Verify node agent configuration
kubectl describe daemonset -n velero node-agent
```

## Required Secrets

### Cloud Storage Credentials
Velero requires credentials for accessing backup storage

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloud-credentials
  namespace: velero
type: Opaque
stringData:
  cloud: |
    [default]
    aws_access_key_id=your-access-key
    aws_secret_access_key=your-secret-key
```

**Key Fields**:
- `cloud`: Cloud provider credentials file (required)
- Format varies by provider (AWS, Azure, GCP, etc.)

### CSI Snapshot Credentials
For CSI snapshots, additional credentials may be required

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: csi-credentials
  namespace: velero
type: Opaque
stringData:
  username: csi-user
  password: csi-password
```

**Key Fields**:
- `username`: CSI storage system username (if required)
- `password`: CSI storage system password (if required)

## Verification
```bash
# Check Velero installation
velero version

# Verify backup storage location
velero backup-location get

# Check volume snapshot location
velero snapshot-location get

# List existing backups
velero backup get
```

## Usage Examples

### Create On-Demand Backup
```bash
# Backup entire cluster
velero backup create full-backup

# Backup specific namespace
velero backup create app-backup --include-namespaces myapp

# Backup with TTL
velero backup create temp-backup --ttl 24h
```

### Schedule Regular Backups
```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: daily-backup
  namespace: velero
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  template:
    includedNamespaces:
    - production
    - staging
    storageLocation: default
    ttl: 720h  # 30 days
```

### Restore from Backup
```bash
# List available backups
velero backup get

# Restore entire backup
velero restore create --from-backup full-backup

# Restore specific namespace
velero restore create --from-backup app-backup --include-namespaces myapp

# Restore to different namespace
velero restore create --from-backup app-backup --namespace-mappings myapp:myapp-restored
```

Velero provides comprehensive backup and disaster recovery capabilities. Regular testing of backup and restore procedures is essential to ensure data protection and recovery readiness.