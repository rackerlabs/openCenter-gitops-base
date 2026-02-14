# Design Document: Reflector Deployment for Secret Replication

## Overview

This design implements Kubernetes Reflector deployment to enable automatic secret replication across namespaces. Reflector consolidates OCI credentials from 11+ per-service files to a single source secret in flux-system that automatically replicates to all service namespaces, reducing credential management complexity by 91%.

## Architecture

### Reflector-Based Credentials Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ flux-system namespace                                           │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Secret: oci-creds                                        │   │
│  │ Type: kubernetes.io/dockerconfigjson                     │   │
│  │ Annotations:                                             │   │
│  │   reflector.v1.k8s.emberstack.com/reflection-allowed     │   │
│  │   reflector.v1.k8s.emberstack.com/reflection-allowed-    │   │
│  │     namespaces: "cert-manager,metallb-system,..."        │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                  │
└──────────────────────────────┼──────────────────────────────────┘
                               │
                               │ Reflector watches and replicates
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐      ┌───────────────┐     ┌───────────────┐
│ cert-manager  │      │ metallb-system│     │ kyverno       │
│               │      │               │     │               │
│ oci-creds     │      │ oci-creds     │     │ oci-creds     │
│ (replicated)  │      │ (replicated)  │     │ (replicated)  │
└───────────────┘      └───────────────┘     └───────────────┘
```

Reflector runs as a managed service and watches the source secret in flux-system. When the secret is created or updated, Reflector automatically replicates it to all namespaces in the allowed list within seconds.

## Components and Interfaces

### Reflector Deployment

**Purpose**: Deploy Kubernetes Reflector as a managed service.

**Interface**: FluxCD HelmRelease resource

**Configuration**:
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: reflector
  namespace: reflector-system
spec:
  chart:
    spec:
      chart: reflector
      version: 7.1.288
      sourceRef:
        kind: HelmRepository
        name: emberstack
  values:
    rbac:
      enabled: true
```

**RBAC Permissions**:
- Read: secrets in flux-system namespace
- Write: secrets in allowed namespaces (cert-manager, metallb-system, etc.)
- Watch: secrets with reflection annotations

### OCI Credentials Consolidation Script

**Purpose**: Consolidate per-service OCI credentials into single source secret.

**Interface**:
```bash
consolidate-oci-creds.sh <customer> <cluster>
```

**Inputs**:
- Customer name
- Cluster name
- Existing per-service oci-creds.yaml files

**Outputs**:
- Single oci-creds.yaml in flux-system namespace with Reflector annotations
- Updated service kustomizations (removed oci-creds.yaml references)
- Deleted per-service oci-creds.yaml files

**Behavior**:
1. Read OCI credentials from any existing service oci-creds.yaml
2. Create flux-system/oci-creds.yaml with Reflector annotations
3. List all service namespaces requiring OCI access
4. Add namespace list to reflection-allowed-namespaces annotation
5. Encrypt with SOPS
6. Remove oci-creds.yaml from all service directories
7. Update service kustomizations to remove resource reference

## Data Models

### Reflector Source Secret Structure

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: oci-creds
  namespace: flux-system
  annotations:
    reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
    reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces: "cert-manager,metallb-system,kyverno,istio-system,observability,postgres-operator,rbac-system,vmware-system-csi,gateway-api,headlamp,keycloak"
type: kubernetes.io/dockerconfigjson
stringData:
  .dockerconfigjson: |
    {
      "auths": {
        "ghcr.io": {
          "username": "opencenter-bot",
          "password": "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        }
      }
    }
```

**Fields**:
- `metadata.name`: Must be `oci-creds` (referenced by global enterprise source)
- `metadata.namespace`: Must be `flux-system`
- `metadata.annotations`: Reflector configuration
- `reflector.v1.k8s.emberstack.com/reflection-allowed`: Enables reflection
- `reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces`: Explicit namespace list
- `type`: Must be `kubernetes.io/dockerconfigjson` for OCI registry auth
- `stringData[".dockerconfigjson"]`: Docker config JSON with registry credentials

## Correctness Properties

### Property 5: Secret Replication Consistency

*For any* namespace in the Reflector allowed list, when the source oci-creds secret exists in flux-system, a replicated secret with identical content should exist in that namespace with the same name.

**Validates: Requirements 7.1, 7.4**

### Property 6: Secret Replication Timeliness

*For any* update to the source oci-creds secret in flux-system, all replicated secrets in allowed namespaces should be updated to match within 60 seconds.

**Validates: Requirements 7.2**

### Property 7: OCI Credentials Consolidation

*For any* cluster after OCI consolidation, exactly one oci-creds.yaml file should exist in the flux-system namespace, and zero oci-creds.yaml files should exist in service directories.

**Validates: Requirements 6.1, 6.6, 10.2**

### Property 11: Reflector Namespace Replication

*For any* new namespace added to the reflection-allowed-namespaces annotation, the Reflector should replicate the oci-creds secret to that namespace.

**Validates: Requirements 7.3**

## Error Handling

### Reflector Failures

**Pod Not Running**: If Reflector pod is not running:
1. Check pod status: `kubectl get pods -n reflector-system`
2. Check pod logs: `kubectl logs -n reflector-system deploy/reflector`
3. Check HelmRelease status: `kubectl get helmrelease -n reflector-system reflector`
4. Alert platform team if pod is crash-looping

**Replication Lag**: If secret replication takes longer than 60 seconds:
1. Check Reflector logs for errors
2. Verify source secret has correct annotations
3. Verify target namespace exists
4. Verify target namespace is in allowed list
5. Alert if lag exceeds 5 minutes

**Replication Failure**: If secret is not replicated to target namespace:
1. Verify source secret exists: `kubectl get secret oci-creds -n flux-system`
2. Verify Reflector annotations are correct
3. Verify target namespace is in allowed list
4. Check Reflector RBAC permissions
5. Check Reflector logs for permission errors

### OCI Credentials Failures

**Authentication Failure**: If HelmRelease fails with authentication error:
1. Verify oci-creds secret exists in service namespace
2. Verify secret content is valid Docker config JSON
3. Verify credentials are not expired
4. Verify OCI registry is accessible
5. Rotate credentials if compromised

**Missing Secret**: If oci-creds secret is missing from service namespace:
1. Verify source secret exists in flux-system
2. Verify Reflector is running
3. Verify namespace is in allowed list
4. Manually create secret as temporary workaround
5. Investigate Reflector logs

## Testing Strategy

### Property-Based Tests

**Property Test 4: Secret Replication Consistency**
- **Tag**: Feature: reflector-deployment, Property 5: Secret Replication Consistency
- Generate random namespace lists
- Create source secret with namespace list annotation
- Verify replicated secret exists in each namespace with identical content
- Validates: Property 5

**Property Test 5: OCI Credentials Consolidation**
- **Tag**: Feature: reflector-deployment, Property 7: OCI Credentials Consolidation
- Generate random cluster structures with per-service oci-creds files
- Run consolidation
- Verify exactly one oci-creds.yaml in flux-system
- Verify zero oci-creds.yaml in service directories
- Validates: Property 7

### Integration Tests

**Reflector Deployment and Replication**:
1. Deploy Reflector to test cluster
2. Create source secret in flux-system with annotations
3. Wait for replication
4. Verify secrets exist in all target namespaces
5. Update source secret
6. Verify replicated secrets update within 60 seconds

**OCI Credentials Consolidation**:
1. Create test cluster overlay with per-service oci-creds files
2. Run consolidation script
3. Verify single source secret created
4. Verify per-service files removed
5. Deploy to test cluster
6. Verify all HelmReleases can authenticate to OCI registry

## Implementation Notes

### SOPS Encryption

All oci-creds.yaml files must be encrypted with SOPS before committing. The consolidation script should handle encryption automatically:

```bash
sops -e -i <customer>/applications/overlays/<cluster>/flux-system/oci-creds.yaml
```

### Namespace List Management

The namespace list in the reflection-allowed-namespaces annotation must be kept in sync with services requiring OCI access. When adding a new service:

1. Add the service namespace to the annotation
2. Update the source secret
3. Reflector will automatically replicate to the new namespace

### Credential Rotation

To rotate OCI credentials:

1. Update the source secret in flux-system
2. Reflector automatically updates all replicated secrets within 60 seconds
3. No need to update individual service configurations
4. Verify replication with: `kubectl get secrets -A | grep oci-creds`
