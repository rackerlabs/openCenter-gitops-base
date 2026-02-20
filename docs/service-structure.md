---
doc_type: reference
title: "Service Structure Reference"
audience: "platform engineers"
---

# Service Structure Reference

**Purpose:** For platform engineers, provides complete reference for openCenter-gitops-base service structure following ADR-001 Kustomize Components pattern.

## Standard Helm Service Structure

### Directory Layout

```
<service>/
├── kustomization.yaml              # Base kustomization (community by default)
├── source.yaml                     # HelmRepository (community source)
├── namespace.yaml                  # Namespace definition
├── helmrelease.yaml                # HelmRelease resource
├── helm-values/
│   └── values-v<version>.yaml      # Base Helm values
├── enterprise/
│   └── helm-values/
│       └── hardened-values-v<version>.yaml  # Enterprise hardened values
└── components/
    └── enterprise/
        ├── kustomization.yaml      # Enterprise component
        └── helm-values/            # Symlink or copy of ../enterprise/helm-values
```

### File Descriptions

**kustomization.yaml** (Root)
- Base kustomization for community deployment
- References namespace, source, helmrelease
- Defines base secretGenerator for Helm values

**source.yaml**
- HelmRepository pointing to community chart repository
- Example: Jetstack for cert-manager, Bitnami for postgres-operator

**namespace.yaml**
- Kubernetes Namespace resource
- Includes labels and annotations

**helmrelease.yaml**
- FluxCD HelmRelease resource
- References HelmRepository from source.yaml
- References values from secretGenerator

**helm-values/values-v<version>.yaml**
- Base Helm values for community deployment
- Version-specific filename for easy upgrades

**components/enterprise/kustomization.yaml**
- Kustomize Component (`kind: Component`)
- References global enterprise source
- Patches HelmRelease to use enterprise source
- Adds enterprise values secretGenerator

### Example: cert-manager

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - source.yaml
  - helmrelease.yaml
secretGenerator:
  - name: cert-manager-values-base
    namespace: cert-manager
    type: Opaque
    files:
      - values.yaml=helm-values/values-v1.18.2.yaml
    options:
      disableNameSuffixHash: true
```

```yaml
# source.yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: jetstack
  namespace: flux-system
spec:
  url: https://charts.jetstack.io
  interval: 1h
```

```yaml
# components/enterprise/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
resources:
  - ../../../global/enterprise/source.yaml
patches:
  - target:
      kind: HelmRepository
      name: jetstack
    patch: |-
      $patch: delete
      apiVersion: source.toolkit.fluxcd.io/v1
      kind: HelmRepository
      metadata:
        name: jetstack
  - target:
      group: helm.toolkit.fluxcd.io
      version: v2
      kind: HelmRelease
      name: cert-manager
    patch: |-
      - op: replace
        path: /spec/chart/spec/sourceRef/name
        value: opencenter-cloud
secretGenerator:
  - name: cert-manager-values-enterprise
    namespace: cert-manager
    type: Opaque
    files:
      - hardened-enterprise.yaml=../../enterprise/helm-values/hardened-values-v1.18.2.yaml
    options:
      disableNameSuffixHash: true
```

## Multi-Component Service Structure

### Directory Layout

```
<service>/
├── README.md
├── namespace/
│   └── namespace.yaml              # Shared namespace
├── sources/
│   └── <service>.yaml              # Shared HelmRepository
├── <sub-component-1>/
│   ├── kustomization.yaml
│   ├── helmrelease.yaml
│   ├── helm-values/
│   │   └── values-v<version>.yaml
│   └── components/
│       └── enterprise/
│           ├── kustomization.yaml
│           └── helm-values/
│               └── hardened-values-v<version>.yaml
└── <sub-component-2>/
    └── ... (similar structure)
```

### Example: Istio

```
istio/
├── README.md
├── namespace/
│   └── namespace.yaml
├── sources/
│   └── istio.yaml                  # Shared HelmRepository
├── base/
│   ├── kustomization.yaml
│   ├── helmrelease.yaml
│   ├── helm-values/
│   │   └── values-1.28.3.yaml
│   └── components/
│       └── enterprise/
│           ├── kustomization.yaml
│           └── helm-values/
│               └── hardened-values-1.28.3.yaml
└── istiod/
    ├── kustomization.yaml
    ├── helmrelease.yaml
    ├── helm-values/
    │   └── values-1.28.3.yaml
    └── components/
        └── enterprise/
            ├── kustomization.yaml
            └── helm-values/
                └── hardened-values-1.28.3.yaml
```

### Sub-Component Kustomization

```yaml
# istio/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../namespace/namespace.yaml
  - ../sources/istio.yaml
  - helmrelease.yaml
secretGenerator:
  - name: istio-base-values-base
    namespace: istio-system
    type: Opaque
    files:
      - values.yaml=helm-values/values-1.28.3.yaml
    options:
      disableNameSuffixHash: true
```

## Non-Helm Service Structure

### Directory Layout

```
<service>/
├── kustomization.yaml              # Base kustomization
├── namespace.yaml                  # Namespace (if applicable)
├── manifests/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ...
└── components/
    └── enterprise/
        └── kustomization.yaml      # Component with patches
```

### Example: OLM

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - "https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.34.0/crds.yaml"
  - "https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.34.0/olm.yaml"
```

```yaml
# components/enterprise/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
patches:
  - target:
      kind: Deployment
      name: catalog-operator
    path: patch-catalog-operator-images.yaml
  - target:
      kind: CatalogSource
      name: operatorhubio-catalog
    path: patch-operatorhubio-catalog-image.yaml
```

## Global Enterprise Source

### Location

```
applications/base/services/global/enterprise/source.yaml
```

### Content

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: opencenter-cloud
  namespace: flux-system
spec:
  url: oci://ghcr.io/opencenter-cloud
  type: oci
  interval: 1h
  secretRef:
    name: oci-creds
    namespace: flux-system
```

### Usage

All enterprise components reference this global source:

```yaml
# In any service's components/enterprise/kustomization.yaml
resources:
  - ../../../global/enterprise/source.yaml
```

## Component Pattern

### Component Kustomization Requirements

1. **kind: Component** - Must use Component kind
2. **Global source reference** - Must reference global/enterprise/source.yaml
3. **Delete community source** - Must delete community HelmRepository
4. **Patch HelmRelease** - Must patch HelmRelease to use enterprise source
5. **Enterprise values** - Must add enterprise values secretGenerator

### Component Template

```yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
resources:
  - ../../../global/enterprise/source.yaml
patches:
  # Delete community HelmRepository
  - target:
      kind: HelmRepository
      name: <community-repo-name>
    patch: |-
      $patch: delete
      apiVersion: source.toolkit.fluxcd.io/v1
      kind: HelmRepository
      metadata:
        name: <community-repo-name>
  
  # Patch HelmRelease to use enterprise source
  - target:
      group: helm.toolkit.fluxcd.io
      version: v2
      kind: HelmRelease
      name: <service-name>
    patch: |-
      - op: replace
        path: /spec/chart/spec/sourceRef/name
        value: opencenter-cloud

secretGenerator:
  - name: <service-name>-values-enterprise
    namespace: <namespace>
    type: Opaque
    files:
      - hardened-enterprise.yaml=../../enterprise/helm-values/hardened-values-v<version>.yaml
    options:
      disableNameSuffixHash: true
```

## Naming Conventions

### Files
- `kustomization.yaml` - Kustomize configuration
- `source.yaml` - HelmRepository (community)
- `namespace.yaml` - Namespace definition
- `helmrelease.yaml` - HelmRelease resource
- `values-v<version>.yaml` - Versioned Helm values
- `hardened-values-v<version>.yaml` - Enterprise hardened values

### Directories
- `helm-values/` - Helm values files
- `components/enterprise/` - Enterprise component
- `enterprise/helm-values/` - Enterprise values storage
- `sources/` - Shared sources (multi-component)
- `namespace/` - Shared namespace (multi-component)

### Resources
- `<service>-values-base` - Base values secret name
- `<service>-values-enterprise` - Enterprise values secret name
- `opencenter-cloud` - Global enterprise HelmRepository name

## Version Upgrades

### Standard Service Upgrade

**Files to update (2):**
1. `helm-values/values-v<new-version>.yaml` - New base values
2. `enterprise/helm-values/hardened-values-v<new-version>.yaml` - New enterprise values

**Files to modify (2):**
1. `kustomization.yaml` - Update secretGenerator filename
2. `components/enterprise/kustomization.yaml` - Update secretGenerator filename

**Example:**
```yaml
# Before (v1.18.2)
secretGenerator:
  - name: cert-manager-values-base
    files:
      - values.yaml=helm-values/values-v1.18.2.yaml

# After (v1.19.0)
secretGenerator:
  - name: cert-manager-values-base
    files:
      - values.yaml=helm-values/values-v1.19.0.yaml
```

### Multi-Component Service Upgrade

Update each sub-component independently following standard service upgrade process.

## Validation

### Structure Validation

```bash
# Validate service structure
./tools/validate-components.sh applications/base/services/<service>
```

### Output Validation

```bash
# Validate community deployment
kubectl kustomize applications/base/services/<service>

# Validate enterprise deployment
kustomize build applications/base/services/<service> \
  --enable-alpha-plugins \
  --load-restrictor=LoadRestrictionsNone \
  --components=components/enterprise
```

## Common Patterns

### Pattern 1: Simple Helm Service
- Single HelmRelease
- Community and enterprise variants
- Example: cert-manager, metallb, headlamp

### Pattern 2: Multi-Component Service
- Multiple sub-components
- Shared namespace and sources
- Example: istio, observability, keycloak

### Pattern 3: Non-Helm Service
- Raw Kubernetes manifests or remote URLs
- Enterprise uses image/manifest patches
- Example: olm

### Pattern 4: Community-Only Service
- No enterprise variant
- No components/enterprise directory
- Example: harbor, mimir, tempo

## Troubleshooting

### Issue: kubectl kustomize fails

**Symptom:** Error loading resources

**Check:**
1. Verify all referenced files exist
2. Check YAML syntax
3. Validate resource references

### Issue: Component not found

**Symptom:** "components/enterprise not found"

**Check:**
1. Verify components/enterprise/ directory exists
2. Check kustomization.yaml has kind: Component
3. Validate file paths in component

### Issue: Duplicate resources

**Symptom:** "multiple matches for Id"

**Check:**
1. Ensure no duplicate secretGenerator names
2. Verify component doesn't duplicate base resources
3. Check for conflicting patches

## Best Practices

1. **Version filenames** - Always include version in helm-values filenames
2. **Consistent naming** - Follow naming conventions for secrets and resources
3. **Component isolation** - Components should only add/modify, not duplicate
4. **Validation** - Always validate after changes
5. **Documentation** - Update README.md for complex services
6. **Testing** - Test both community and enterprise deployments

## References

- [ADR-001: Kustomize Components Pattern](../ADRS/ADR-001-kustomize-components-for-enterprise-pattern.md)
- [Customer Overlay Migration Guide](./customer-overlay-migration-guide.md)
- [Kustomize Components Documentation](https://kubectl.docs.kubernetes.io/guides/config_management/components/)
