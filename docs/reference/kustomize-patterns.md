# Kustomize Patterns Reference

**Type:** Reference  
**Audience:** Platform engineers  
**Last Updated:** 2026-02-14

This document describes Kustomize patterns and conventions used in openCenter-gitops-base.

---

## Kustomize Version

**Version:** v5.2+  
**API Version:** `kustomize.config.k8s.io/v1beta1` (standard resources)  
**Component API:** `kustomize.config.k8s.io/v1alpha1` (components)

---

## Base Service Pattern

Every service follows a standardized base structure:

```
applications/base/services/<service-name>/
├── kustomization.yaml              # Base kustomization
├── namespace.yaml                  # Namespace definition
├── source.yaml                     # HelmRepository or GitRepository
├── helmrelease.yaml                # HelmRelease resource
├── helm-values/                    # Helm chart values
│   └── values-<version>.yaml
└── components/                     # Optional components
    └── enterprise/                 # Enterprise edition component
        ├── kustomization.yaml
        └── helm-values/
            └── hardened-values-<version>.yaml
```

### Base Kustomization

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - source.yaml
  - helmrelease.yaml

secretGenerator:
  - name: <service>-values-base
    namespace: <service-namespace>
    type: Opaque
    files:
      - values.yaml=helm-values/values-v1.18.2.yaml
    options:
      disableNameSuffixHash: true
```

---

## Secret Generator Pattern

Helm values are converted to Kubernetes Secrets using `secretGenerator`.

### Basic Secret Generator

```yaml
secretGenerator:
  - name: cert-manager-values-base
    namespace: cert-manager
    type: Opaque
    files:
      - values.yaml=helm-values/values-v1.18.2.yaml
    options:
      disableNameSuffixHash: true
```

### Fields

| Field | Description |
|-------|-------------|
| `name` | Secret name (referenced in HelmRelease) |
| `namespace` | Target namespace |
| `type` | Secret type (typically `Opaque`) |
| `files` | Map of key=file pairs |
| `options.disableNameSuffixHash` | Disable automatic name suffix (required for HelmRelease) |

### Multiple Values Files

```yaml
secretGenerator:
  - name: service-values-base
    namespace: service
    files:
      - values.yaml=helm-values/base-values-v1.2.3.yaml
  
  - name: service-values-override
    namespace: service
    files:
      - override.yaml=helm-values/override-values-v1.2.3.yaml
    options:
      disableNameSuffixHash: true
  
  - name: service-values-enterprise
    namespace: service
    files:
      - hardened-enterprise.yaml=helm-values/enterprise-values-v1.2.3.yaml
    options:
      disableNameSuffixHash: true
```

---

## Kustomize Components

Components are reusable, composable configuration units that can be included in multiple kustomizations.

### Component Structure

```
components/
└── enterprise/
    ├── kustomization.yaml          # Component definition
    ├── helm-values/
    │   └── hardened-values-v1.18.2.yaml
    └── patches/                    # Optional patches
        └── helmrelease-source.yaml
```

### Component Kustomization

```yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - ../../../global/enterprise/source.yaml

patches:
  # Remove community HelmRepository
  - target:
      kind: HelmRepository
      name: jetstack
    patch: |
      $patch: delete
      apiVersion: source.toolkit.fluxcd.io/v1
      kind: HelmRepository
      metadata:
        name: jetstack
  
  # Patch HelmRelease to use enterprise source
  - target:
      group: helm.toolkit.fluxcd.io
      version: v2
      kind: HelmRelease
      name: cert-manager
    patch: |
      - op: replace
        path: /spec/chart/spec/sourceRef/name
        value: opencenter-cloud

secretGenerator:
  - name: cert-manager-values-enterprise
    namespace: cert-manager
    type: Opaque
    files:
      - hardened-enterprise.yaml=helm-values/hardened-values-v1.18.2.yaml
    options:
      disableNameSuffixHash: true
```

### Including Components

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base/services/cert-manager

components:
  - ../../base/services/cert-manager/components/enterprise
```

---

## Patch Patterns

### Strategic Merge Patch

```yaml
patches:
  - target:
      kind: Deployment
      name: my-app
    patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: my-app
      spec:
        replicas: 3
```

### JSON Patch (RFC 6902)

```yaml
patches:
  - target:
      kind: HelmRelease
      name: cert-manager
    patch: |
      - op: replace
        path: /spec/chart/spec/version
        value: v1.19.0
      - op: add
        path: /spec/values/replicaCount
        value: 3
```

### Delete Patch

```yaml
patches:
  - target:
      kind: HelmRepository
      name: jetstack
    patch: |
      $patch: delete
      apiVersion: source.toolkit.fluxcd.io/v1
      kind: HelmRepository
      metadata:
        name: jetstack
```

### Inline Patch

```yaml
patches:
  - patch: |
      apiVersion: v1
      kind: Namespace
      metadata:
        name: cert-manager
        labels:
          pod-security.kubernetes.io/enforce: restricted
```

---

## Multi-Component Services

Services with multiple sub-components use numbered directories for deployment order.

### Structure

```
keycloak/
├── 00-postgres/
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── source.yaml
│   └── helmrelease.yaml
├── 10-operator/
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── source.yaml
│   └── helmrelease.yaml
├── 20-keycloak/
│   ├── kustomization.yaml
│   ├── helmrelease.yaml
│   └── helm-values/
└── 30-oidc-rbac/
    ├── kustomization.yaml
    └── rbac.yaml
```

### Parent Kustomization

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - 00-postgres
  - 10-operator
  - 20-keycloak
  - 30-oidc-rbac
```

### Deployment Order

Components deploy in numerical order:
1. `00-postgres` - Database
2. `10-operator` - Operator
3. `20-keycloak` - Application
4. `30-oidc-rbac` - Configuration

FluxCD Kustomization dependencies enforce order:

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: keycloak-postgres
spec:
  path: ./keycloak/00-postgres
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: keycloak-operator
spec:
  dependsOn:
    - name: keycloak-postgres
  path: ./keycloak/10-operator
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: keycloak-instance
spec:
  dependsOn:
    - name: keycloak-operator
  path: ./keycloak/20-keycloak
```

---

## Namespace Pattern

Every service defines its namespace with required labels.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager
  labels:
    app.kubernetes.io/name: cert-manager
    app.kubernetes.io/part-of: opencenter
    opencenter.io/tier: platform
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Required Labels

| Label | Description |
|-------|-------------|
| `app.kubernetes.io/name` | Service name |
| `app.kubernetes.io/part-of` | Platform identifier |
| `opencenter.io/tier` | Service tier (platform/shared/tenant) |
| `pod-security.kubernetes.io/*` | Pod Security Standards |

---

## Resource Ordering

Resources are listed in dependency order:

```yaml
resources:
  - namespace.yaml          # 1. Namespace first
  - source.yaml             # 2. Source (HelmRepository/GitRepository)
  - helmrelease.yaml        # 3. HelmRelease (depends on source)
  - additional-resources/   # 4. Additional resources
```

---

## Common Kustomization Fields

### Resources

```yaml
resources:
  - namespace.yaml
  - source.yaml
  - helmrelease.yaml
  - ../common/rbac.yaml
```

### Components

```yaml
components:
  - components/enterprise
  - ../common/monitoring
```

### Patches

```yaml
patches:
  - path: patches/replicas.yaml
  - target:
      kind: Deployment
    patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: not-used
      spec:
        replicas: 3
```

### Secret Generator

```yaml
secretGenerator:
  - name: app-config
    namespace: app
    files:
      - config.yaml
    options:
      disableNameSuffixHash: true
```

### Config Map Generator

```yaml
configMapGenerator:
  - name: app-config
    namespace: app
    literals:
      - KEY=value
      - ANOTHER_KEY=another-value
```

### Namespace

```yaml
namespace: cert-manager
```

Sets default namespace for all resources without explicit namespace.

### Common Labels

```yaml
commonLabels:
  app.kubernetes.io/managed-by: fluxcd
  opencenter.io/tier: platform
```

Adds labels to all resources.

### Common Annotations

```yaml
commonAnnotations:
  managed-by: opencenter
```

Adds annotations to all resources.

---

## Validation Commands

### Build Kustomization

```bash
kubectl kustomize applications/base/services/cert-manager
```

### Dry-Run Against Cluster

```bash
kubectl kustomize applications/base/services/cert-manager | kubectl apply --dry-run=server -f -
```

### Validate with Kubeconform

```bash
kubectl kustomize applications/base/services/cert-manager | kubeconform -strict -
```

### Diff Against Cluster

```bash
kubectl diff -k applications/base/services/cert-manager
```

---

## Best Practices

### File Organization

1. **Namespace first** - Always list namespace.yaml first in resources
2. **Sources before consumers** - HelmRepository before HelmRelease
3. **Dependencies explicit** - Use FluxCD Kustomization dependencies for ordering
4. **Components for variants** - Use components for optional features

### Naming Conventions

1. **Directories** - kebab-case (e.g., `cert-manager`)
2. **Files** - kebab-case with descriptive suffixes (e.g., `base-values-v1.18.2.yaml`)
3. **Secrets** - `<service>-values-<tier>` (e.g., `cert-manager-values-base`)
4. **Components** - Descriptive names (e.g., `enterprise`, `monitoring`)

### Secret Generator

1. **Disable name suffix** - Always use `disableNameSuffixHash: true` for HelmRelease values
2. **Version in filename** - Include chart version in values filename
3. **Namespace explicit** - Always specify namespace in secretGenerator

### Components

1. **Self-contained** - Components should be independently usable
2. **Minimal patches** - Only patch what's necessary
3. **Clear purpose** - Component name should indicate purpose
4. **Documented** - Include README.md in component directory

### Patches

1. **Prefer strategic merge** - Easier to read and maintain
2. **Use JSON patch for precision** - When strategic merge insufficient
3. **Target specific resources** - Use target selectors
4. **Test patches** - Validate output with `kubectl kustomize`

---

## Troubleshooting

### Kustomization Build Fails

```bash
# Check syntax
kubectl kustomize applications/base/services/cert-manager

# Common issues:
# - Missing resources
# - Invalid YAML syntax
# - Incorrect file paths
# - Missing namespace in secretGenerator
```

### Secret Not Generated

```bash
# Verify secretGenerator configuration
kubectl kustomize applications/base/services/cert-manager | grep -A 10 "kind: Secret"

# Common issues:
# - File path incorrect
# - disableNameSuffixHash not set
# - Namespace missing
```

### Component Not Applied

```bash
# Verify component is included
kubectl kustomize applications/base/services/cert-manager | grep -i enterprise

# Common issues:
# - Component path incorrect
# - Component kustomization.yaml missing
# - Component API version wrong (must be v1alpha1)
```

### Patch Not Applied

```bash
# View final output
kubectl kustomize applications/base/services/cert-manager

# Common issues:
# - Target selector doesn't match
# - Patch syntax incorrect
# - Strategic merge conflicts
```

---

## Migration from Community/Enterprise Directories

The repository is migrating from parallel `community/` and `enterprise/` directories to Kustomize components.

### Old Pattern

```
cert-manager/
├── community/
│   ├── kustomization.yaml
│   └── source.yaml
└── enterprise/
    ├── kustomization.yaml
    ├── patch-helmrelease-source.yaml
    └── helm-values/
```

### New Pattern

```
cert-manager/
├── kustomization.yaml              # Base (community)
├── source.yaml
├── helmrelease.yaml
└── components/
    └── enterprise/
        ├── kustomization.yaml      # Component
        └── helm-values/
```

### Benefits

- Eliminates duplication (60% file reduction)
- Prevents copy-paste errors
- Simplifies version upgrades
- Maintains backward compatibility

---

## Evidence

**Source Files:**
- `applications/base/services/cert-manager/kustomization.yaml` (base pattern)
- `applications/base/services/keycloak/` (multi-component pattern)
- `docs/ADR-001-kustomize-components-for-enterprise-pattern.md` (component pattern)
- `docs/service-standards-and-lifecycle.md` (service standards)
- `docs/analysis/S1-APP-RUNTIME-APIS.md` (service patterns)
- `.kiro/specs/kustomize-components-migration/` (migration specification)
