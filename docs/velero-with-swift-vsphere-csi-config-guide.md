# Velero Backup Configuration

## Overview
Velero provides backup and disaster recovery for Kubernetes clusters using OpenStack Swift for object storage and vSphere CSI for volume snapshots.

## Key Configuration Choices

### Storage Backend
```yaml
backupStorageLocation:
  - name: iad3-flex-dei7343-a9256
    provider: community.openstack.org/openstack
    bucket: k8s-dr-velero
```
**Why**: Uses OpenStack Swift via the community plugin for backup metadata storage. 

**Note**: Initially attempted to use the AWS S3 plugin with Swift's S3-compatible endpoint, but Swift doesn't support AWS chunked uploads (used for large objects). The native OpenStack plugin provides better compatibility with Swift's API.

### CSI Snapshot Integration
```yaml
configuration:
  features: EnableCSI
  defaultSnapshotMoveData: false
  defaultVolumesToFsBackup: false
  volumeSnapshotLoc []
```
**Why**: 
- `defaulCSI`: Enables CSI snapshot support for volume backups
- `defaultVolushotMoveData: false`: Uses CSI snapshots instead of file-level backups by default
- `defaultVolumesToFsBackup: false`: Prevents automatic file-level backups (opt-in only)
- `volumeSnapshotLocation: []`: Disables legacy VolumeSnapshotLocation (CSI uses VolumeSnapshotClass instead)

### VolumeSnapshotClass
```yaml
extraObjects:
  - apiVersion: snapshot.storage.k8s.io/v1
    kind: VolumeSnapshotClass
    metadata:
      name: velero-vsphere-snapshot-class
      labels:
        velero.io/csi-volumesnapshot-cl "true"
    driver: csi.vspher
    deletionPolicy: Delete
```
**Why**: Defines how Velero creates CSI snapshots. The label `velero.io/csi-volumesnapshot-class: "true"` tells Velero to use this class for backups.

### Credentials
```yaml
podEnvFrom:
  - secretRef:
      name: cloud-credentials
```
**Why**: OpenStack plugin requires environment variables (`OS_AUTH_URL`, `OS_APPLICATION_CREDENTIAL_ID`, etc.) for authentication. The secret contains both individual env vars and a `cloud` key for Velero's credential file mount.

### Node Agent
```yaml
deployNodeAgent: false
```
**Why**: Currently disabled. Kopia (the file-level backup engine) doesn't support OpenStack Swift backend. Requires further research into:
- Using S3-compatible Swift endpoint for Kopia
- Alternative storage backends for file-level backups
- Hybrid approach with separate storage for file-level vs metadata

CSI snapshots provide sufficient backup coverage for current needs.

## Common Pitfalls

### Kopia Backend Incompatibility
**Problem**: "invalid backend type community.openstack.org/openstack" errors during file-level backups.

**Solution**: Kopia (used by node-agent) doesn't support OpenStack. Set `defaultVolumesToFsBackup: false` to use CSI snapshots by default.

### Missing Environment Variables
**Problem**: "Missing input for argument [auth_url]" authentication errors.

**Solution**: The secret must be mounted as environment variables using `podEnvFrom`. Individual `OS_*` keys in the secret are required, not just a clouds.yaml file.

### Swift Temp URL Authentication
**Problem**: "401 Unauthorized: Temp URL invalid" errors.

**Solution**: Both `OS_SWIFT_TEMP_URL_KEY` and `OS_SWIFT_TEMP_URL_DIGEST` are required in the credentials secret. These must match the temp URL key configured on the Swift container.

```bash
TEMP_URL_KEY=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c "35")
echo "$TEMP_URL_KEY"
# Set temp URL key on Swift container (if not already set)
openstack --os-cloud flex-dfw3 container set --property "Temp-URL-Key=$TEMP_URL_KEY" 
```

The `OS_SWIFT_TEMP_URL_KEY` value must match the key set on the container, and `OS_SWIFT_TEMP_URL_DIGEST` specifies the hash algorithm (typically `sha256`).

### VolumeSnapshotLocation Errors
**Problem**: "spec.provider: Required value" during Helm upgrade.

**Solution**: Set `volumeSnapshotLocation: []` to disable legacy snapshot locations. CSI snapshots use VolumeSnapshotClass instead.

### Pod Security Standards
**Problem**: node-agent DaemonSet fails with "violates PodSecurity" errors.

**Solution**: Velero namespace requires `privileged` Pod Security Standard for hostPath volumes.

## Required Secrets

### cloud-credentials
Contains OpenStack authentication credentials. Must include both environment variables and a `cloud` key.

```yaml
stringData:
  # Environment variables for OpenStack plugin
  OS_AUTH_URL: https://keystone.api.iad3.rackspacecloud.com/v3
  OS_APPLICATION_CREDENTIAL_ID: <credential-id>
  OS_APPLICATION_CREDENTIAL_SECRET: <credential-secret>
  OS_REGION_NAME: IAD3
  OS_SWIFT_TEMP_URL_KEY: <temp-url-key>
  OS_SWIFT_TEMP_URL_DIGEST: sha256
```

**Key Fields**:
- `OS_AUTH_URL`: OpenStack Keystone endpoint (required)
- `OS_APPLICATION_CREDENTIAL_ID`: Application credential ID (required)
- `OS_APPLICATION_CREDENTIAL_SECRET`: Application credential secret (required)
- `OS_REGION_NAME`: OpenStack region (required)
- `OS_SWIFT_TEMP_URL_KEY`: Temp URL key for Swift authentication (required, must match container setting)
- `OS_SWIFT_TEMP_URL_DIGEST`: Hash algorithm for temp URLs (required, typically `sha256`)

## Verification
```bash
# Check backup storage location
kubectl get backupstoragelocation -n velero

# Verify CSI snapshot class
kubectl get volumesnapshotclass velero-vsphere-snapshot-class

# Test backup
velero backup create test --include-namespaces=default

# Check backup status
velero backup describe test --details

# View backup logs
velero backup logs test
```

## Backup Usage

### CSI Snapshot Backup (Current Method)
```bash
velero backup create my-backup --include-namespaces=myapp
```

### File-Level Backup (Future)
File-level backups via node-agent are currently disabled and require:
- Compatible storage backend (Kopia doesn't support OpenStack)
- Additional testing and validation
- Possible migration to S3-compatible Swift endpoint or alternative backend

For now, all backups use CSI snapshots exclusively.
