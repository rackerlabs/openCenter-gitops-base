# Adding a New Service to openCenter GitOps Base

This guide explains how to add a new service to the openCenter GitOps base repository using the standardized Flux CD patterns. We'll use **cert-manager** as a reference example to illustrate the complete process.

## Overview

All services in openCenter GitOps follow a consistent structure using Flux CD's GitOps approach with:

- **HelmRepository**: Defines the Helm chart source
- **HelmRelease**: Manages the application deployment
- **Kustomization**: Orchestrates resources and generates secrets
- **Namespace**: Isolates the service resources
- **Hardened Values**: Security-focused Helm configurations

## Service Directory Structure

Each service follows this standardized directory layout:

```
applications/base/services/my-service/
├── kustomization.yaml          # Main orchestration file
├── namespace.yaml              # Service namespace
├── source.yaml                 # HelmRepository definition
├── helmrelease.yaml           # HelmRelease configuration
└── helm-values/
    └── hardened-values-vX.Y.Z.yaml  # Security-hardened Helm values
```

## Step-by-Step Implementation Guide

### Step 1: Create the Service Directory Structure

Create the directory structure for your new service:

```bash
mkdir -p applications/base/services/my-service/helm-values
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

Create `applications/base/services/my-service/helm-values/hardened-values-vX.Y.Z.yaml`:

This file contains security-hardened configuration for the Helm chart. Use the chart version in the filename for versioning.

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

### Step 6: Create the Kustomization File

Create `applications/base/services/my-service/kustomization.yaml`:

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
    type: Opaque
    files: [hardened.yaml=helm-values/hardened-values-vX.Y.Z.yaml]
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
    type: Opaque
    files: [hardened.yaml=helm-values/hardened-values-v1.18.2.yaml]
    options:
      disableNameSuffixHash: true
```

**Key Configuration:**

- `resources`: List all YAML files to include
- `secretGenerator`: Creates Kubernetes secrets from hardened values
- `disableNameSuffixHash: true`: Required for consistent secret naming

## Validation and Testing

### Step 1: Validate HelmRelease

Check if the HelmRelease configuration is valid:

```bash
cd applications/base/services/my-service
kubectl apply --dry-run=server -f helmrelease.yaml
```

### Step 2: Validate Kustomization

Test the kustomization builds correctly:

```bash
cd applications/base/services/my-service
kubectl kustomize . --dry-run=server
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
