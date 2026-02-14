# ADR-001: Use Kustomize Components for Community/Enterprise Pattern

> **Status**: Proposed  
> **Date**: 2025-02-09  
> **Deciders**: Platform Engineering Team  
> **Related**: [Community vs Enterprise Improvement Proposal](./02-community-enterprise-improvement-proposal.md)

---

## Context

The openCenter-gitops-base repository currently uses parallel directory structures (`community/` and `enterprise/`) to support both community and enterprise editions of services. This pattern has resulted in:

- **55 edition-specific files** across 11 services with ~60% duplicate content
- **Systematic duplication** of secretGenerator blocks for base values
- **Copy-paste errors** (e.g., kyverno enterprise patch incorrectly references metallb metadata)
- **High maintenance burden** for version upgrades (version strings in 6+ locations)
- **Structural inconsistency** across the repository (4 different service patterns)

### Current Pattern Example (cert-manager)

```
cert-manager/
├── community/
│   ├── kustomization.yaml          # Defines base secretGenerator
│   └── source.yaml
└── enterprise/
    ├── kustomization.yaml          # DUPLICATES base secretGenerator + adds enterprise
    ├── patch-helmrelease-source.yaml
    └── helm-values/
        └── hardened-values-v1.18.2.yaml
```

The enterprise `kustomization.yaml` fully duplicates the base `secretGenerator` block from community, then adds the enterprise-specific secret. This duplication exists in all 11 services with the pattern.

### Problem Impact

1. **Version upgrades require updating 4-6 files per service** (helmrelease, base values filename, community kustomization, enterprise kustomization, enterprise values filename, patch file)
2. **Copy-paste errors already present** (kyverno patch file has metallb metadata)
3. **New service onboarding requires 7+ files** with significant boilerplate
4. **Cognitive overhead** for new team members understanding why two directories exist

## Decision

We will migrate to **Kustomize Components** (`kind: Component`) to make enterprise a composable add-on rather than a parallel directory tree.

### New Pattern (cert-manager)

```
cert-manager/
├── kustomization.yaml              # Base (community by default)
├── source.yaml                     # Community HelmRepository
├── namespace.yaml
├── helmrelease.yaml
├── helm-values/
│   └── values-v1.18.2.yaml
├── enterprise/
│   └── kustomization.yaml          # Thin wrapper: includes base + component
└── components/
    └── enterprise/
        ├── kustomization.yaml      # Component: patches source + adds enterprise values
        └── helm-values/
            └── hardened-values-v1.18.2.yaml
```

### How It Works

1. **Base kustomization** at service root produces a working community deployment
2. **Enterprise component** adds:
   - Global enterprise OCI source (`opencenter-cloud`)
   - Patch to replace community HelmRepository with enterprise source
   - Enterprise hardened values secret
3. **Thin enterprise wrapper** at `enterprise/kustomization.yaml` includes base + component for backward compatibility
4. **Customer overlays** continue using existing paths (`cert-manager/enterprise`) with zero changes

### Component Kustomization Example

```yaml
---
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

## Alternatives Considered

### Option 2: Overlay-Driven Enterprise Selection

**Approach:** Move community/enterprise decision entirely to customer overlays. Base repository contains only community definitions.

**Pros:**
- Simplest possible base repository
- Maximum per-customer flexibility

**Cons:**
- **Breaking change:** ALL customer overlays must be updated simultaneously
- Enterprise hardened values duplicated across every customer
- Loses base repository's role as single source of truth for enterprise hardening
- Significant per-overlay boilerplate
- ~50+ files need updating across all customer directories

**Rejected because:** High customer impact, loss of central governance, and duplication moved from base to overlays.

### Option 3: Parameterized Kustomization with Replacements

**Approach:** Use Kustomize replacements with a ConfigMap "feature flag" to parameterize edition selection.

**Pros:**
- Single directory per service
- Edition selection explicit via ConfigMap

**Cons:**
- **No conditional resource inclusion** — both sources deployed, requires deletion patches
- Enterprise values secret always created (even in community mode)
- Kustomize replacements complex and hard to debug
- **Breaking change:** All customer overlays must be updated
- Workarounds add complexity instead of removing it

**Rejected because:** Kustomize limitations require workarounds that negate simplification benefits; high customer impact.

## Consequences

### Positive

1. **Eliminates all duplication:** Base secretGenerator defined once in root kustomization
2. **Prevents copy-paste errors:** No per-service patch files to copy incorrectly
3. **Backward compatible:** Existing customer overlay paths continue working via thin wrapper
4. **Incremental migration:** Services migrated one at a time with independent validation
5. **Reduces file count:** 55 → 22 files (with thin wrappers) or 55 → 11 files (future state)
6. **Simplifies version upgrades:** Version string in 2 locations instead of 6
7. **Preserves central governance:** Enterprise hardened values remain in base repository
8. **Natural extensibility:** Enterprise-only resources simply added to component resources list

### Negative

1. **Requires Kustomize v5.0+:** Already met (tech stack specifies v5.2+)
2. **Component API is v1alpha1:** Despite version, Components stable since Kustomize v5.0 (2023)
3. **Less widely known pattern:** Team must learn Kustomize Components (well-documented)
4. **Thin wrapper adds one file per service:** Temporary during transition; optional to remove later

### Neutral

1. **Migration effort:** 7 weeks estimated for 16 services (11 standard + 3 observability + 2 special cases)
2. **Documentation updates:** Service templates, guides, and examples need updating
3. **Validation required:** Each service migration must produce byte-identical output

## Additional Improvement: Global OCI Credentials Management

### Current Problem

Each service in each customer overlay maintains its own `oci-creds.yaml` file:

```
<customer>/applications/overlays/<cluster>/services/
├── cert-manager/
│   └── oci-creds.yaml          # Duplicate 1
├── metallb/
│   └── oci-creds.yaml          # Duplicate 2
├── kyverno/
│   └── oci-creds.yaml          # Duplicate 3
├── istio/
│   └── oci-creds.yaml          # Duplicate 4
├── gateway-api/
│   └── oci-creds.yaml          # Duplicate 5
├── headlamp/
│   └── oci-creds.yaml          # Duplicate 6
├── postgres-operator/
│   └── oci-creds.yaml          # Duplicate 7
├── rbac-manager/
│   └── oci-creds.yaml          # Duplicate 8
├── vsphere-csi/
│   └── oci-creds.yaml          # Duplicate 9
├── kube-prometheus-stack/
│   └── oci-creds.yaml          # Duplicate 10
├── loki/
│   └── oci-creds.yaml          # Duplicate 11
└── opentelemetry-kube-stack/
    └── oci-creds.yaml          # Duplicate 12
```

**Impact:**
- **11+ files per cluster** with identical encrypted credentials
- **Hundreds of duplicate files** across all customer clusters
- **High maintenance burden** when rotating credentials
- **Inconsistency risk** if files get out of sync
- **Large git diffs** when updating credentials

### Solution: Reflector-Based Secret Replication

Deploy [Kubernetes Reflector](https://github.com/emberstack/kubernetes-reflector) to automatically replicate OCI credentials from a single source to all service namespaces.

#### Architecture

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

#### Implementation Steps

**Step 1: Deploy Reflector**

Add Reflector to the base repository as a managed service:

```yaml
# applications/base/managed-services/reflector/helmrelease.yaml
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

**Step 2: Create Single OCI Credentials Secret**

In each customer overlay, create one secret in `flux-system` namespace:

```yaml
# <customer>/applications/overlays/<cluster>/flux-system/oci-creds.yaml
apiVersion: v1
kind: Secret
metadata:
  name: oci-creds
  namespace: flux-system
  annotations:
    # Allow reflection to other namespaces
    reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
    # Specify which namespaces can receive the secret
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

Encrypt with SOPS:
```bash
sops -e -i <customer>/applications/overlays/<cluster>/flux-system/oci-creds.yaml
```

**Step 3: Update Global Enterprise Source**

Ensure the global enterprise source references the flux-system secret:

```yaml
# applications/base/services/global/enterprise/source.yaml
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

**Step 4: Remove Per-Service OCI Credentials**

Delete all per-service `oci-creds.yaml` files from customer overlays:

```bash
# Per customer overlay
find applications/overlays/<cluster>/services/ -name "oci-creds.yaml" -delete
```

Update service kustomizations to remove the resource reference:

```yaml
# Before
resources:
  - ./oci-creds.yaml
  - ./registry-credentials.yaml

# After
resources:
  - ./registry-credentials.yaml
```

#### Reflector Configuration Options

**Option 1: Explicit Namespace List (Recommended)**

```yaml
annotations:
  reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
  reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces: "cert-manager,metallb-system,kyverno"
```

**Pros:**
- Explicit control over which namespaces receive the secret
- Security: prevents accidental replication to unintended namespaces
- Clear documentation of which services need OCI access

**Cons:**
- Must update annotation when adding new services

**Option 2: Auto-Reflection to All Namespaces**

```yaml
annotations:
  reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
  reflector.v1.k8s.emberstack.com/reflection-auto-enabled: "true"
```

**Pros:**
- Automatic replication to all namespaces
- No updates needed when adding services

**Cons:**
- Less secure: secret replicated everywhere
- Harder to audit which services have OCI access

**Recommendation:** Use Option 1 (explicit namespace list) for better security and auditability.

#### Credential Rotation Workflow

**Before (per-service files):**
1. Generate new OCI credentials
2. Update 11+ files per cluster
3. Encrypt each file with SOPS
4. Commit and push
5. Wait for FluxCD to reconcile each service
6. Verify each service can pull from OCI registry

**After (Reflector):**
1. Generate new OCI credentials
2. Update 1 file per cluster (`flux-system/oci-creds.yaml`)
3. Encrypt with SOPS
4. Commit and push
5. Reflector automatically updates all service namespaces within seconds
6. Verify services can pull from OCI registry

**Time savings:** ~90% reduction in manual work

#### Alternative Solutions Considered

**Alternative 1: External Secrets Operator**

**Approach:** Integrate with external secret managers (Vault, AWS Secrets Manager, Azure Key Vault, GCP Secret Manager).

**Pros:**
- Industry-standard secret management
- Automatic rotation support
- Audit logging built-in
- Centralized secret management across multiple clusters

**Cons:**
- Requires external infrastructure (Vault, cloud secret manager)
- More complex setup and maintenance
- Additional cost for cloud secret managers
- Requires network connectivity to external service

**Decision:** Deferred to future work. Reflector provides immediate value without infrastructure dependencies.

**Alternative 2: Kubernetes Service Account with ImagePullSecrets**

**Approach:** Create ServiceAccount in each namespace with `imagePullSecrets` reference to a single secret.

**Limitation:** Only works for container image pulls, not OCI Helm charts. FluxCD's HelmRepository requires a secret reference in the same namespace.

**Decision:** Not viable for OCI Helm chart access.

**Alternative 3: Flux Kustomization postBuild Substitution**

**Approach:** Use Flux's `postBuild.substitute` to inject credentials at reconciliation time.

**Limitation:** Credentials would be in plaintext in FluxCD Kustomization resources. Not suitable for sensitive data.

**Decision:** Not secure enough for production credentials.

#### Security Considerations

**Encryption at Rest:**
- OCI credentials stored in git are encrypted with SOPS
- Age encryption keys stored securely outside git
- Each cluster has its own Age key

**Encryption in Transit:**
- Secrets replicated within cluster (not over network)
- Kubernetes API communication uses TLS
- OCI registry access uses HTTPS

**Access Control:**
- Reflector runs with minimal RBAC permissions (read source secret, write to allowed namespaces)
- Explicit namespace list prevents accidental replication
- SOPS decryption keys only available to FluxCD controllers

**Audit Trail:**
- Git history tracks all changes to OCI credentials
- Reflector logs all replication events
- Kubernetes audit logs track secret access

#### Monitoring and Validation

**Metrics to Monitor:**
- Reflector pod health and restarts
- Secret replication lag (time from source update to replica update)
- Failed replication attempts
- Services unable to pull from OCI registry

**Recommended Alerts:**
- Reflector pod not running
- Secret replication failed for >5 minutes
- HelmRelease reconciliation failed due to authentication error

**Validation Commands:**

```bash
# Check Reflector is running
kubectl get pods -n reflector-system

# Verify source secret exists
kubectl get secret oci-creds -n flux-system

# Verify secret replicated to service namespace
kubectl get secret oci-creds -n cert-manager

# Check Reflector logs
kubectl logs -n reflector-system deploy/reflector

# Test OCI registry access
kubectl run test-oci --rm -it --image=alpine --restart=Never -- sh
# Inside pod:
# apk add curl
# curl -u username:password https://ghcr.io/v2/opencenter-cloud/cert-manager/tags/list
```

#### Benefits Summary

**Quantitative Benefits:**
- **File reduction:** 11 files per cluster → 1 file per cluster (91% reduction)
- **Credential rotation time:** ~90% reduction in manual work
- **Git diff size:** ~90% smaller when updating credentials
- **Maintenance burden:** Single file to track per cluster

**Qualitative Benefits:**
- **Consistency:** Impossible for services to have different credentials
- **Security:** Single source of truth reduces risk of stale credentials
- **Auditability:** One file to review per cluster
- **Simplicity:** New services automatically receive credentials
- **Reliability:** Reflector handles replication automatically

## Implementation Plan

### Phase 1: Pilot (Week 1-2)
- Migrate cert-manager as proof of concept
- Validate output equivalence (community and enterprise)
- Deploy to non-production cluster
- Refine migration script

### Phase 2: Standard Helm Services (Week 3-4)
- Migrate 8 services: metallb, headlamp, rbac-manager, postgres-operator, istio, gateway-api, vsphere-csi, kyverno/policy-engine
- Fix kyverno/metallb bug during migration
- Use automated migration script

### Phase 3: Observability Sub-Services (Week 5)
- Migrate kube-prometheus-stack, loki, opentelemetry-kube-stack
- Handle shared sources and namespace
- Handle multiple values files and extra resources

### Phase 4: Special Cases (Week 6)
- Migrate OLM (non-Helm, image patches)
- Migrate Keycloak (multi-component, 4 sub-components)

### Phase 5: Cleanup and Documentation (Week 7)
- Remove empty community directories
- Update service templates and documentation
- Create enterprise components guide
- Fix kyverno/metallb bug (already resolved in Phase 2)

### Phase 6: Global OCI Credentials (Parallel with Phase 1-5)
- Deploy Reflector to all clusters
- Create single `oci-creds` secret in `flux-system` namespace per cluster
- Configure Reflector annotations for namespace replication
- Remove per-service `oci-creds.yaml` files from customer overlays
- Validate secret replication to all service namespaces

### Phase 7: Optional Future (Remove Thin Wrappers)
- Only after all customer overlays updated to point to service roots
- Removes `<service>/enterprise/` directories
- Reduces file count by additional 11 files

## Validation Criteria

Each service migration must meet these criteria:

1. **Output equivalence:** `diff` between baseline and new output shows zero differences
2. **Community path works:** `kubectl kustomize <service>` produces valid output
3. **Enterprise path works:** `kubectl kustomize <service>/enterprise` produces valid output
4. **Backward compatibility:** Existing customer overlay FluxCD Kustomizations work unchanged
5. **Rollback possible:** Migration can be reverted via `git revert`

## Success Metrics

### Quantitative
- File count: 55 → 22 (60% reduction with thin wrappers)
- Duplicated YAML lines: ~200-250 lines eliminated
- Version upgrade touchpoints: 6 → 2 locations per service
- New service files: 7 → 4 files required
- OCI credentials files: 11 per cluster → 1 per cluster (91% reduction)

### Qualitative
- Zero copy-paste errors possible (no per-service patch files)
- Single source of truth for base values
- Single source of truth for OCI credentials
- Consistent structure across all services
- Simplified new service onboarding
- Reduced cognitive overhead
- Simplified credential rotation (one file per cluster)

## References

- [Kustomize Components Documentation](https://kubectl.docs.kubernetes.io/guides/config_management/components/)
- [Community vs Enterprise Improvement Proposal](./02-community-enterprise-improvement-proposal.md)
- [Kustomize v5.0 Release Notes](https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.0.0)
- [Kubernetes Reflector GitHub](https://github.com/emberstack/kubernetes-reflector)
- [Reflector Helm Chart](https://github.com/emberstack/kubernetes-reflector/tree/main/helm/reflector)
- [External Secrets Operator](https://external-secrets.io/)
- [FluxCD Secret Management](https://fluxcd.io/flux/guides/mozilla-sops/)

## Notes

- Components have been stable since Kustomize v5.0 (2023) despite `v1alpha1` API version
- The `v1alpha1` version reflects Kustomize's conservative versioning policy, not instability
- Components are the officially recommended approach for cross-cutting concerns in Kustomize
- This pattern is widely used in the Kubernetes community for similar use cases
