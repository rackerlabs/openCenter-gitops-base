# Adding a New Service to openCenter GitOps Base

This guide explains how to add a new service to the openCenter GitOps base repository using the standardized Flux CD patterns following ADR-001 Kustomize Components pattern. We'll use **cert-manager** as a reference example to illustrate the complete process.

## Overview

All services in openCenter GitOps follow a consistent structure using Flux CD's GitOps approach with:

- **HelmRepository**: Defines the Helm chart source
- **HelmRelease**: Manages the application deployment
- **Kustomization**: Orchestrates resources and generates secrets
- **Namespace**: Isolates the service resources
- **Hardened Values**: Security-focused Helm configurations
- **Components**: Optional enterprise features using Kustomize Components

## Service Directory Structure

### Standard Helm Service (Community Only)

```
applications/base/services/my-service/
├── kustomization.yaml              # Base kustomization (community)
├── namespace.yaml                  # Service namespace
├── source.yaml                     # HelmRepository (community source)
├── helmrelease.yaml               # HelmRelease configuration
└── helm-values/
    └── values-vX.Y.Z.yaml         # Base Helm values
```

### Standard Helm Service (with Enterprise Variant)

```
applications/base/services/my-service/
├── kustomization.yaml              # Base kustomization (community)
├── namespace.yaml                  # Service namespace
├── source.yaml                     # HelmRepository (community source)
├── helmrelease.yaml               # HelmRelease configuration
├── helm-values/
│   └── values-vX.Y.Z.yaml         # Base Helm values
├── enterprise/
│   └── helm-values/
│       └── hardened-values-vX.Y.Z.yaml  # Enterprise hardened values
└── components/
    └── enterprise/
        ├── kustomization.yaml      # Enterprise component
        └── helm-values/            # Symlink or reference to ../enterprise/helm-values
```

## Step-by-Step Implementation Guide

### Step 1: Determine Service Type

Before creating files, determine:

1. **Community-only or Enterprise variant?**
   - Community-only: No enterprise-specific features
   - Enterprise variant: Has hardened/enterprise-specific configuration

2. **Helm-based or raw manifests?**
   - Helm: Uses HelmRepository and HelmRelease
   - Raw: Uses direct Kubernetes manifests

This guide covers Helm-based services. For raw manifests, see [Service Structure Reference](./service-structure.md).

### Step 2: Create the Service Directory Structure

**For community-only service:**
```bash
mkdir -p applications/base/services/my-service/helm-values
```

**For service with enterprise variant:**
```bash
mkdir -p applications/base/services/my-service/helm-values
mkdir -p applications/base/services/my-service/enterprise/helm-values
mkdir -p applications/base/services/my-service/components/enterprise/helm-values
```

### Step 2: Create the Namespace Resource

Create `applications/base/services/my-service/namespace.yaml`:

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: my-service
```

**Key Points:**

- Use a clear, descriptive namespace name
- Follow kebab-case naming convention
- Keep namespace name consistent with service name

### Step 3: Define the Helm Repository Source

Create `applications/base/services/my-service/source.yaml`:

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: my-service-repo
spec:
  url: https://charts.example.com
  interval: 1h
```

**Example using cert-manager:**

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: jetstack
spec:
  url: https://charts.jetstack.io
  interval: 1h
```

**Key Configuration:**

- `metadata.name`: Unique identifier for the repository
- `spec.url`: HTTPS URL to the Helm repository
- `spec.interval`: How often to check for updates (typically 1h)

### Step 4: Create the HelmRelease Configuration

Create `applications/base/services/my-service/helmrelease.yaml`:

```yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: my-service
  namespace: my-service
spec:
  releaseName: my-service
  interval: 5m
  timeout: 10m
  driftDetection:
    mode: enabled
  install:
    remediation:
      retries: 3
      remediateLastFailure: true
  upgrade:
    remediation:
      retries: 0
      remediateLastFailure: false
  targetNamespace: my-service
  chart:
    spec:
      chart: my-service-chart
      version: vX.Y.Z
      sourceRef:
        kind: HelmRepository
        name: my-service-repo
        namespace: my-service
  valuesFrom:
    - kind: Secret
      name: my-service-values-base
      valuesKey: hardened.yaml
    - kind: Secret
      name: my-service-values-override
      valuesKey: override.yaml
      optional: true
```

**Example using cert-manager:**

```yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  releaseName: cert-manager
  interval: 5m
  timeout: 10m
  driftDetection:
    mode: enabled
  install:
    remediation:
      retries: 3
      remediateLastFailure: true
  upgrade:
    remediation:
      retries: 0
      remediateLastFailure: false
  targetNamespace: cert-manager
  chart:
    spec:
      chart: cert-manager
      version: v1.18.2
      sourceRef:
        kind: HelmRepository
        name: jetstack
        namespace: cert-manager
  valuesFrom:
    - kind: Secret
      name: cert-manager-values-base
      valuesKey: hardened.yaml
    - kind: Secret
      name: cert-manager-values-override
      valuesKey: override.yaml
      optional: true
```

**Key Configuration:**

- `spec.interval`: 5m reconciliation cycle (standard)
- `spec.timeout`: 10m installation timeout (standard)
- `spec.driftDetection.mode`: enabled (required for consistency)
- `spec.install.remediation.retries`: 3 (standard retry policy)
- `valuesFrom`: References to hardened values and optional overrides

### Step 5: Create Hardened Helm Values

Create `applications/base/services/my-service/helm-values/values-vX.Y.Z.yaml`:

This file contains base configuration for the Helm chart. Use the chart version in the filename for versioning.

**Example structure for cert-manager:**

```yaml
# Security configurations
replicaCount: 2
securityContext:
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault
containerSecurityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true

# Production configurations
prometheus:
  enabled: true
config:
  enableGatewayAPI: true
nodeSelector:
  kubernetes.io/os: linux

# Feature enablement
crds:
  enabled: true
  keep: true
```

**Security Hardening Guidelines:**

- Enable non-root execution (`runAsNonRoot: true`)
- Use security profiles (`seccompProfile.type: RuntimeDefault`)
- Drop all capabilities (`capabilities.drop: [ALL]`)
- Use read-only root filesystem (`readOnlyRootFilesystem: true`)
- Disable privilege escalation (`allowPrivilegeEscalation: false`)
- Enable monitoring (`prometheus.enabled: true`)
- Use Linux node selectors for mixed OS clusters

### Step 6: Create Enterprise Hardened Values (Optional)

**Only if your service has enterprise-specific features.**

Create `applications/base/services/my-service/enterprise/helm-values/hardened-values-vX.Y.Z.yaml`:

```yaml
# Enterprise-specific hardened configuration
# This typically includes:
# - Stricter security settings
# - Enterprise-only features
# - Compliance-related configurations
# - Additional monitoring/logging

# Example:
replicaCount: 3  # Higher availability for enterprise
resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 512Mi

# Enterprise-specific features
enterpriseFeature:
  enabled: true
  
# Additional security
podSecurityContext:
  fsGroup: 1000
  runAsUser: 1000
  runAsGroup: 1000
```

### Step 7: Create Enterprise Component (Optional)

**Only if your service has enterprise-specific features.**

Create `applications/base/services/my-service/components/enterprise/kustomization.yaml`:

```yaml
---
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
resources:
  - ../../../global/enterprise/source.yaml
patches:
  # Delete community HelmRepository
  - target:
      kind: HelmRepository
      name: my-service-repo  # Match name from source.yaml
    patch: |-
      $patch: delete
      apiVersion: source.toolkit.fluxcd.io/v1
      kind: HelmRepository
      metadata:
        name: my-service-repo
  
  # Patch HelmRelease to use enterprise source
  - target:
      group: helm.toolkit.fluxcd.io
      version: v2
      kind: HelmRelease
      name: my-service  # Match name from helmrelease.yaml
    patch: |-
      - op: replace
        path: /spec/chart/spec/sourceRef/name
        value: opencenter-cloud

secretGenerator:
  - name: my-service-values-enterprise
    namespace: my-service
    type: Opaque
    files:
      - hardened-enterprise.yaml=../../enterprise/helm-values/hardened-values-vX.Y.Z.yaml
    options:
      disableNameSuffixHash: true
```

**Key Points:**

- `kind: Component` - Must be Component, not Kustomization
- References global enterprise source
- Deletes community HelmRepository
- Patches HelmRelease to use enterprise source
- Adds enterprise values secretGenerator

### Step 8: Create the Kustomization File

Create `applications/base/services/my-service/kustomization.yaml`:

**For community-only service:**
```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: 
  - "./namespace.yaml"
  - "./source.yaml"
  - "./helmrelease.yaml"

secretGenerator:
  - name: my-service-values-base
    namespace: my-service
    type: Opaque
    files: [values.yaml=helm-values/values-vX.Y.Z.yaml]
    options:
      disableNameSuffixHash: true
```

**For service with enterprise variant:**
```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: 
  - "./namespace.yaml"
  - "./source.yaml"
  - "./helmrelease.yaml"

secretGenerator:
  - name: my-service-values-base
    namespace: my-service
    type: Opaque
    files: [values.yaml=helm-values/values-vX.Y.Z.yaml]
    options:
      disableNameSuffixHash: true
```

**Example using cert-manager:**

```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - "./namespace.yaml"
  - "./source.yaml"
  - "./helmrelease.yaml"

secretGenerator:
  - name: cert-manager-values-base
    namespace: cert-manager
    type: Opaque
    files: [values.yaml=helm-values/values-v1.18.2.yaml]
    options:
      disableNameSuffixHash: true
```

**Key Configuration:**

- `resources`: List all YAML files to include
- `secretGenerator`: Creates Kubernetes secrets from values files
- `disableNameSuffixHash: true`: Required for consistent secret naming
- **Note:** Enterprise component is NOT referenced here - it's applied separately by customer overlays

## Validation and Testing

### Step 1: Validate Structure

Check if the service structure follows ADR-001 pattern:

```bash
cd applications/base/services/my-service

# Run validation script
../../../../tools/validate-components.sh .
```

### Step 2: Validate Kustomization

Test the kustomization builds correctly:

```bash
# Validate community deployment
kubectl kustomize .

# Validate enterprise deployment (if applicable)
kustomize build . \
  --enable-alpha-plugins \
  --load-restrictor=LoadRestrictionsNone \
  --components=components/enterprise
```

### Step 3: Validate HelmRelease

Check if the HelmRelease configuration is valid:

```bash
kubectl apply --dry-run=client -f helmrelease.yaml
```

### Step 3: Deploying service to Kubernetes Cluster

To include a new service in the Kubernetes cluster, it must be referenced in the cluster's GitOps repository.

For example: Deploying `cert-manager`

- Create a GitRepository secret for Flux:

```bash
flux create secret git opencenter-base --ssh-key-algorithm=ed25519 --url=ssh://git@github.com/rackerlabs/openCenter-gitops-base.git   -n flux-system
```

- Add the generated `deploy key` to [openCenter GitOps base repository](https://github.com/rackerlabs/openCenter-gitops-base). Refer [GitHub’s documentation on deploy keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys#set-up-deploy-keys) for more details.

- Update the Cluster GitOps repository:
  - Create a source definition at: `applications/overlays/<cluster>/services/sources/opencenter-cert-manager.yaml`

    ```yaml
    ---
    apiVersion: source.toolkit.fluxcd.io/v1
    kind: GitRepository
    metadata:
      name: opencenter-cert-manager
      namespace: flux-system
    spec:
      interval: 15m
      url: ssh://git@github.com/rackerlabs/openCenter-gitops-base.git
      ref:
        branch: main
      secretRef:
        name: opencenter-base
    ```

  - Create a Kustomization at: `applications/overlays/<cluster>/services/fluxcd/cert-manager.yaml`:

    ```yaml
    ---
    apiVersion: kustomize.toolkit.fluxcd.io/v1
    kind: Kustomization
    metadata:
      name: cert-manager-base
      namespace: flux-system
    spec:
      dependsOn:
        - name: sources
          namespace: flux-system
      interval: 5m
      retryInterval: 1m
      timeout: 10m
      sourceRef:
        kind: GitRepository
        name: opencenter-cert-manager
        namespace: flux-system
      path: applications/base/services/cert-manager
      targetNamespace: cert-manager
      prune: true
      healthChecks:
        - apiVersion: helm.toolkit.fluxcd.io/v2
          kind: HelmRelease
          name: cert-manager
          namespace: cert-manager
      commonMetadata:
        labels:
          app.kubernetes.io/part-of: cert-manager
          app.kubernetes.io/managed-by: flux
          opencenter/managed-by: opencenter
    ```

### Step 4: Monitor

After committing changes to the Kubernetes cluster GitOps repository, monitor the deployment to ensure it reconciles correctly:

```bash
# Check Flux reconciliation
kubectl get gitrepository -n flux-system
kubectl get kustomization -n flux-system
kubectl get helmreleases -n my-service

# Check application status
kubectl get pods -n my-service
```

## Common Configuration Patterns

### Multiple Helm Values Files

For complex services requiring multiple configuration files:

```yaml
# In kustomization.yaml
secretGenerator:
  - name: my-service-values-base
    type: Opaque
    files:
      - hardened.yaml=helm-values/hardened-values-v1.0.0.yaml
      - monitoring.yaml=helm-values/monitoring-overrides.yaml
      - networking.yaml=helm-values/networking-overrides.yaml
    options:
      disableNameSuffixHash: true
```

```yaml
# In helmrelease.yaml
valuesFrom:
  - kind: Secret
    name: my-service-values-base
    valuesKey: hardened.yaml
  - kind: Secret
    name: my-service-values-base
    valuesKey: monitoring.yaml
  - kind: Secret
    name: my-service-values-base
    valuesKey: networking.yaml
```

### Services with Custom Resources

For services that deploy CRDs or require multiple namespaces:

```yaml
# In kustomization.yaml
resources:
  - ./namespace.yaml
  - ./source.yaml
  - ./helmrelease.yaml
  - ./custom-resources/
```

### Version Pinning Strategy

Always pin specific versions in HelmReleases:

```yaml
chart:
  spec:
    chart: my-service
    version: v1.2.3  # Exact version, not ranges
```

## Troubleshooting Guide

### Common Issues

1. **HelmRelease Stuck in Installing State**

   ```bash
   kubectl describe helmrelease my-service -n my-service
   kubectl logs -n flux-system deploy/helm-controller
   ```

2. **Authentication / Git Access**

- **Symptom**: Failed to fetch repository, permission denied (publickey), or reconciliation stuck on GitRepository.
- **Fix**:
  - Verify the deploy key was added to the GitHub repo with read-only permissions.
  - Ensure the Flux Secret name matches what is referenced in the GitRepository.

3. **Chart Source Not Found**

   ```bash
   kubectl get helmrepositories -A
   kubectl describe helmrepository my-service-repo -n my-service
   ```

4. **Values Override Issues**

   ```bash
   kubectl get secret my-service-values-base -n my-service -o yaml
   ```

### Debugging Commands

```bash
# View Flux logs if issues occur
kubectl logs -n flux-system deploy/helm-controller
kubectl logs -n flux-system deploy/kustomize-controller
kubectl logs -n flux-system deploy/source-controller

# Force reconciliation
flux reconcile kustomization my-service  -n flux-system --with-source
flux reconcile helmrelease my-service -n my-service --with-source

# Check all Flux resources
kubectl get kustomization,gitrepositories,helmrepositories,helmreleases -A

# View generated manifests
helm template my-service-repo/my-service --values /tmp/values.yaml
```

## Best Practices

### Security

- Always use hardened values with security contexts
- Pin exact chart versions, avoid ranges or latest
- Enable drift detection for configuration consistency
- Use least-privilege RBAC configurations

### Reliability

- Set appropriate timeouts and retry policies
- Use health checks and readiness probes
- Configure resource limits and requests
- Enable monitoring and observability

### Maintainability

- Use consistent naming conventions
- Version hardened values files with chart versions
- Document service-specific configurations
- Follow the established directory structure

### GitOps Workflow

- Commit all changes to version control
- Use pull requests for service additions
- Test in development environments first
- Monitor deployments after changes

## Example: Complete cert-manager Implementation

Here's the complete cert-manager implementation as a reference:

**Directory Structure:**

```
applications/base/services/cert-manager/
├── kustomization.yaml
├── namespace.yaml
├── source.yaml
├── helmrelease.yaml
└── helm-values/
    └── hardened-values-v1.18.2.yaml
```

**File Contents:**

See the actual files in `applications/base/services/cert-manager/` for the complete, production-ready implementation that follows all the patterns described in this guide.

## Next Steps

After successfully adding your service:

1. **Monitor Deployment**: Watch the HelmRelease status and pod health
2. **Configure Monitoring**: Ensure Prometheus scraping and Grafana dashboards
3. **Test Functionality**: Verify the service works as expected
4. **Document Usage**: Add service-specific documentation
5. **Set Up Alerts**: Configure alerting rules for service health

This standardized approach ensures consistency, security, and maintainability across all services in the openCenter GitOps platform.


## ADR-001 Component Pattern

### Enterprise Component Usage

After ADR-001 migration, enterprise features are enabled using Kustomize Components:

**In customer overlay FluxCD Kustomization:**
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-service
  namespace: flux-system
spec:
  sourceRef:
    kind: GitRepository
    name: opencenter-gitops-base
  path: applications/base/services/my-service
  components:
    - components/enterprise  # Enable enterprise features
```

### Component Structure Requirements

If your service has enterprise features, the component must:

1. **Use kind: Component** - Not Kustomization
2. **Reference global enterprise source** - `../../../global/enterprise/source.yaml`
3. **Delete community HelmRepository** - Using `$patch: delete`
4. **Patch HelmRelease** - To use enterprise source (`opencenter-cloud`)
5. **Add enterprise values** - Via secretGenerator

See [Service Structure Reference](./service-structure.md) for complete component examples.

## References

- [Service Structure Reference](./service-structure.md) - Complete structure patterns
- [Version Upgrade Guide](./version-upgrade-guide.md) - How to upgrade service versions
- [Customer Overlay Migration Guide](./customer-overlay-migration-guide.md) - For customer deployments
- [ADR-001: Kustomize Components Pattern](../ADRS/ADR-001-kustomize-components-for-enterprise-pattern.md) - Architecture decision
