---
doc_type: how-to
title: "Add a New Platform Service"
audience: "platform engineers"
---

# Add a New Platform Service

**Purpose:** For platform engineers, shows how to add a new platform service to openCenter-gitops-base, covering directory structure, HelmRelease configuration, and testing.

## Prerequisites

- Git access to openCenter-gitops-base repository
- kubectl access to a test cluster
- FluxCD CLI installed (`flux version`)
- Basic understanding of Helm and Kustomize

## Steps

### 1. Create service directory structure

```bash
cd openCenter-gitops-base/applications/base/services/

# Create service directory
mkdir -p my-service/helm-values

# Create required files
touch my-service/kustomization.yaml
touch my-service/namespace.yaml
touch my-service/source.yaml
touch my-service/helmrelease.yaml
touch my-service/README.md
```

### 2. Define namespace

Create `my-service/namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-service
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### 3. Configure Helm repository source

Create `my-service/source.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: my-service
  namespace: flux-system
spec:
  interval: 15m
  url: https://charts.example.com/
  timeout: 1m
```

For OCI registries:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: my-service
  namespace: flux-system
spec:
  interval: 15m
  type: oci
  url: oci://registry.example.com/charts
```

### 4. Create base Helm values

Create `my-service/helm-values/values-v1.0.0.yaml`:

```yaml
# Base configuration for my-service v1.0.0
replicaCount: 2

image:
  repository: registry.example.com/my-service
  tag: "1.0.0"
  pullPolicy: IfNotPresent

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL

service:
  type: ClusterIP
  port: 8080
```

### 5. Create HelmRelease

Create `my-service/helmrelease.yaml`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: my-service
  namespace: my-service
spec:
  interval: 5m
  timeout: 10m
  releaseName: my-service
  
  chart:
    spec:
      chart: my-service
      version: "1.0.0"
      sourceRef:
        kind: HelmRepository
        name: my-service
        namespace: flux-system
      interval: 15m
  
  driftDetection:
    mode: enabled
  
  install:
    crds: CreateReplace
    remediation:
      retries: 3
      remediateLastFailure: true
  
  upgrade:
    crds: CreateReplace
    remediation:
      retries: 0
      remediateLastFailure: false
  
  valuesFrom:
    - kind: Secret
      name: my-service-values-base
      valuesKey: values.yaml
    - kind: Secret
      name: my-service-values-override
      valuesKey: override.yaml
      optional: true
    - kind: Secret
      name: my-service-values-enterprise
      valuesKey: hardened-enterprise.yaml
      optional: true
```

### 6. Configure Kustomization

Create `my-service/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: my-service

resources:
  - namespace.yaml
  - source.yaml
  - helmrelease.yaml

secretGenerator:
  - name: my-service-values-base
    files:
      - values.yaml=helm-values/values-v1.0.0.yaml
    options:
      disableNameSuffixHash: true

generatorOptions:
  disableNameSuffixHash: true
```

### 7. Document the service

Create `my-service/README.md`:

```markdown
# My Service

## Purpose

Brief description of what this service does.

## Version

- Chart: 1.0.0
- App: 1.0.0

## Dependencies

- None (or list dependencies)

## Configuration

### Base Values

Located in `helm-values/values-v1.0.0.yaml`.

### Override Values

Create in customer overlay: `applications/overlays/<cluster>/services/my-service/override-values.yaml`

## Resources

- CPU: 100m request, 500m limit
- Memory: 128Mi request, 512Mi limit

## Observability

- Metrics: Exposed on port 8080 at /metrics
- Logs: JSON format to stdout
- Traces: OTLP to OpenTelemetry collector

## Security

- Runs as non-root user (UID 1000)
- Read-only root filesystem
- All capabilities dropped
```

### 8. Validate locally

```bash
# Build Kustomization
kustomize build applications/base/services/my-service

# Check for errors
echo $?  # Should be 0
```

### 9. Test in cluster

```bash
# Create test namespace
kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -

# Apply service manifests
kustomize build applications/base/services/my-service | kubectl apply -f -

# Check HelmRelease status
kubectl get helmrelease -n my-service my-service

# View reconciliation
flux reconcile helmrelease my-service -n my-service

# Check logs
flux logs --kind=HelmRelease --name=my-service --namespace=my-service
```

### 10. Verify deployment

```bash
# Check pods
kubectl get pods -n my-service

# Check HelmRelease conditions
kubectl describe helmrelease my-service -n my-service

# Verify drift detection
kubectl get helmrelease my-service -n my-service -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}'
```

### 11. Commit to repository

```bash
git add applications/base/services/my-service/
git commit -m "feat(services): add my-service v1.0.0"
git push origin main
```

## Verification

After FluxCD reconciles:

```bash
# Check GitRepository sync
flux get sources git

# Check HelmRelease status
flux get helmreleases -n my-service

# Verify service is running
kubectl get all -n my-service
```

Expected output:
- HelmRelease shows "Ready" status
- Pods are running
- Service endpoint is accessible

## Troubleshooting

### HelmRelease stuck in "Installing"

Check Helm repository access:

```bash
flux get sources helm
kubectl describe helmrepository my-service -n flux-system
```

### Values not applied

Verify secret generation:

```bash
kubectl get secret my-service-values-base -n my-service -o yaml
```

### Drift detected but not remediated

Check drift detection mode:

```bash
kubectl get helmrelease my-service -n my-service -o jsonpath='{.spec.driftDetection.mode}'
```

Should return "enabled".

## Next Steps

- Configure observability (see [setup-observability.md](setup-observability.md))
- Add Gateway API routing (see [configure-gateway.md](configure-gateway.md))
- Create customer overlay for cluster-specific configuration

## Evidence

**Sources:**
- `applications/base/services/cert-manager/` - Reference service structure
- `applications/base/services/keycloak/` - Multi-component pattern
- `docs/service-standards-and-lifecycle.md` - Service standards
- S1-APP-RUNTIME-APIS.md - HelmRelease patterns
- S4-FLUXCD-GITOPS.md - FluxCD configuration
