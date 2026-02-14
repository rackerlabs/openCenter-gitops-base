# FluxCD Resources Reference

**Type:** Reference  
**Audience:** Platform engineers  
**Last Updated:** 2026-02-14

This document provides a complete reference for FluxCD resources used in openCenter-gitops-base.

---

## FluxCD Version

**Version:** v2.7.0  
**Installation:**
```bash
curl -s https://fluxcd.io/install.sh | sudo FLUX_VERSION=2.7.0 bash
```

---

## GitRepository

Defines a Git repository as a source for Flux.

### Specification

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: opencenter-cert-manager
  namespace: flux-system
spec:
  interval: 15m
  url: ssh://git@github.com/rackerlabs/openCenter-gitops-base.git
  ref:
    tag: v1.0.0
  secretRef:
    name: opencenter-base
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `interval` | duration | Yes | Sync interval (e.g., `15m`, `1h`) |
| `url` | string | Yes | Git repository URL (SSH or HTTPS) |
| `ref.tag` | string | No | Git tag to track |
| `ref.branch` | string | No | Git branch to track |
| `ref.commit` | string | No | Specific commit SHA |
| `secretRef.name` | string | No | Secret containing SSH key or credentials |

### Common Patterns

**Tag-based (recommended for stability):**
```yaml
ref:
  tag: v1.0.0
```

**Branch-based (for development):**
```yaml
ref:
  branch: main
```

**Commit-based (for pinning):**
```yaml
ref:
  commit: abc123def456
```

---

## HelmRepository

Defines a Helm chart repository as a source.

### Specification

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: jetstack
  namespace: flux-system
spec:
  interval: 1h
  url: https://charts.jetstack.io
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `interval` | duration | Yes | Sync interval |
| `url` | string | Yes | Helm repository URL |
| `secretRef.name` | string | No | Secret for authentication |

---

## HelmRelease

Manages Helm chart installations and upgrades.

### Specification

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  interval: 5m
  timeout: 10m
  driftDetection:
    mode: enabled
  chart:
    spec:
      chart: cert-manager
      version: v1.18.2
      sourceRef:
        kind: HelmRepository
        name: jetstack
        namespace: flux-system
  install:
    remediation:
      retries: 3
      remediateLastFailure: true
  upgrade:
    remediation:
      retries: 0
      remediateLastFailure: false
  valuesFrom:
    - kind: Secret
      name: cert-manager-values-base
      valuesKey: values.yaml
    - kind: Secret
      name: cert-manager-values-override
      valuesKey: override.yaml
      optional: true
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `interval` | duration | Yes | Reconciliation interval (typically `5m`) |
| `timeout` | duration | Yes | Operation timeout (typically `10m`) |
| `driftDetection.mode` | string | No | `enabled` or `disabled` (default: disabled) |
| `chart.spec.chart` | string | Yes | Helm chart name |
| `chart.spec.version` | string | Yes | Chart version |
| `chart.spec.sourceRef` | object | Yes | Reference to HelmRepository or GitRepository |
| `install.remediation.retries` | int | No | Install retry count (default: 3) |
| `install.remediation.remediateLastFailure` | bool | No | Retry last failure (default: true) |
| `upgrade.remediation.retries` | int | No | Upgrade retry count (default: 0) |
| `upgrade.remediation.remediateLastFailure` | bool | No | Retry last upgrade failure (default: false) |
| `valuesFrom` | array | No | List of value sources (Secrets or ConfigMaps) |

### Values Hierarchy

openCenter uses a three-tier values pattern:

1. **Base values** (required): Core configuration
2. **Override values** (optional): Cluster-specific overrides
3. **Enterprise values** (optional): Enterprise edition configuration

```yaml
valuesFrom:
  - kind: Secret
    name: service-values-base
    valuesKey: values.yaml
  - kind: Secret
    name: service-values-override
    valuesKey: override.yaml
    optional: true
  - kind: Secret
    name: service-values-enterprise
    valuesKey: hardened-enterprise.yaml
    optional: true
```

### Drift Detection

When enabled, Flux detects configuration drift and automatically corrects it:

```yaml
driftDetection:
  mode: enabled
```

### Remediation Policies

**Install remediation** (aggressive):
- Retries: 3
- Remediate last failure: true
- Use case: New installations should retry automatically

**Upgrade remediation** (conservative):
- Retries: 0
- Remediate last failure: false
- Use case: Failed upgrades require manual intervention

---

## Kustomization

Applies Kustomize manifests to the cluster.

### Specification

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager
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
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `dependsOn` | array | No | List of Kustomizations to wait for |
| `interval` | duration | Yes | Reconciliation interval |
| `retryInterval` | duration | No | Retry interval on failure |
| `timeout` | duration | Yes | Operation timeout |
| `sourceRef` | object | Yes | Reference to GitRepository |
| `path` | string | Yes | Path within repository |
| `targetNamespace` | string | No | Override namespace for all resources |
| `prune` | bool | No | Delete resources removed from Git (default: false) |
| `healthChecks` | array | No | Resources to check before marking ready |
| `decryption.provider` | string | No | `sops` for encrypted secrets |
| `decryption.secretRef.name` | string | No | Secret containing decryption key |

### Dependencies

Use `dependsOn` to create ordered deployments:

```yaml
spec:
  dependsOn:
    - name: cert-manager
      namespace: flux-system
```

This ensures CRDs and controllers are ready before dependent resources apply.

### Health Checks

Verify resource health before marking Kustomization as ready:

```yaml
healthChecks:
  - apiVersion: apps/v1
    kind: Deployment
    name: cert-manager
    namespace: cert-manager
  - apiVersion: helm.toolkit.fluxcd.io/v2
    kind: HelmRelease
    name: cert-manager
    namespace: cert-manager
```

### SOPS Decryption

Enable automatic secret decryption:

```yaml
decryption:
  provider: sops
  secretRef:
    name: sops-age
```

Requires age key stored in Secret:
```bash
kubectl create secret generic sops-age \
  --from-file=age.agekey=${HOME}/.config/sops/age/${CLUSTER_NAME}_keys.txt \
  -n flux-system
```

---

## Reconciliation Intervals

Standard intervals used in openCenter:

| Resource Type | Interval | Rationale |
|---------------|----------|-----------|
| GitRepository | 15m | Source changes are infrequent |
| HelmRepository | 1h | Chart updates are infrequent |
| HelmRelease | 5m | Fast drift detection |
| Kustomization | 5m | Fast drift detection |

---

## Flux CLI Commands

### Bootstrap

```bash
flux bootstrap git \
  --url=ssh://git@github.com/${GIT_REPO}.git \
  --branch=main \
  --private-key-file=${HOME}/.ssh/${CLUSTER_NAME}_id_ed25519 \
  --path=applications/overlays/${CLUSTER_NAME}
```

### Reconcile

Force immediate reconciliation:

```bash
# Reconcile specific resource
flux reconcile source git opencenter-cert-manager
flux reconcile helmrelease cert-manager -n cert-manager
flux reconcile kustomization cert-manager

# Reconcile with source
flux reconcile kustomization cert-manager --with-source
```

### Get Status

```bash
# All resources
flux get all -A

# Specific resource type
flux get sources git
flux get helmreleases -A
flux get kustomizations
```

### Logs

```bash
# Controller logs
flux logs --level=error --all-namespaces

# Specific resource
flux logs --kind=HelmRelease --name=cert-manager --namespace=cert-manager
```

### Suspend/Resume

```bash
# Suspend reconciliation
flux suspend helmrelease cert-manager -n cert-manager

# Resume reconciliation
flux resume helmrelease cert-manager -n cert-manager
```

---

## SOPS Configuration

### Age Key Generation

```bash
# Generate age keypair
age-keygen -o ${HOME}/.config/sops/age/${CLUSTER_NAME}_keys.txt

# Extract public key
grep "# public key:" ${HOME}/.config/sops/age/${CLUSTER_NAME}_keys.txt
```

### .sops.yaml Configuration

```yaml
creation_rules:
  - path_regex: .*.yaml
    encrypted_regex: ^(data|stringData)$
    age: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
```

### Encrypt/Decrypt

```bash
# Encrypt in place
sops -e -i secret.yaml

# Decrypt to stdout
sops -d secret.yaml

# Edit encrypted file
sops secret.yaml
```

### Create Kubernetes Secret with Age Key

```bash
kubectl create secret generic sops-age \
  --from-file=age.agekey=${HOME}/.config/sops/age/${CLUSTER_NAME}_keys.txt \
  -n flux-system
```

---

## Common Patterns

### Service Onboarding

1. Create GitRepository source
2. Create Kustomization referencing source
3. Kustomization applies service manifests
4. Service manifests include HelmRelease
5. HelmRelease deploys Helm chart

### Dependency Chain

```
sources (Kustomization)
  └─> cert-manager (Kustomization)
      └─> cert-manager-certs (Kustomization)
```

### Multi-Component Service

Services like Keycloak with multiple components:

```
keycloak-postgres (Kustomization)
  └─> keycloak-operator (Kustomization)
      └─> keycloak-instance (Kustomization)
          └─> keycloak-oidc-rbac (Kustomization)
```

---

## Troubleshooting

### Check Resource Status

```bash
flux get sources git opencenter-cert-manager
flux get helmreleases -n cert-manager
flux get kustomizations
```

### View Events

```bash
kubectl describe gitrepository opencenter-cert-manager -n flux-system
kubectl describe helmrelease cert-manager -n cert-manager
kubectl describe kustomization cert-manager -n flux-system
```

### Force Reconciliation

```bash
flux reconcile source git opencenter-cert-manager
flux reconcile helmrelease cert-manager -n cert-manager --with-source
```

### View Controller Logs

```bash
kubectl logs -n flux-system deploy/source-controller
kubectl logs -n flux-system deploy/helm-controller
kubectl logs -n flux-system deploy/kustomize-controller
```

---

## Evidence

**Source Files:**
- `llms.txt` lines 19-262 (Flux patterns and bootstrap)
- `docs/service-standards-and-lifecycle.md` lines 82-174 (GitOps architecture)
- `applications/base/services/cert-manager/helmrelease.yaml` (HelmRelease example)
- `applications/base/services/cert-manager/kustomization.yaml` (Kustomization example)
- `docs/onboarding-service-overlay.md` (Service onboarding workflow)
- `docs/analysis/S4-FLUXCD-GITOPS.md` (FluxCD analysis)
