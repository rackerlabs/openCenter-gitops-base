# Helm Values Schema Reference

**Type:** Reference  
**Audience:** Platform engineers  
**Last Updated:** 2026-02-14

This document describes the three-tier Helm values pattern used in openCenter-gitops-base.

---

## Three-Tier Values Architecture

openCenter uses a three-tier Helm values hierarchy to separate concerns and enable flexible configuration:

1. **Base values** - Core service configuration (required)
2. **Override values** - Cluster-specific customization (optional)
3. **Enterprise values** - Enterprise edition features (optional)

---

## Values File Naming Convention

```
applications/base/services/<service-name>/helm-values/
├── base-values-<chart-version>.yaml
├── override-values-<chart-version>.yaml
└── enterprise-values-<chart-version>.yaml
```

**Examples:**
- `base-values-v1.18.2.yaml`
- `override-values-v1.18.2.yaml`
- `enterprise-values-v1.18.2.yaml`

---

## Tier 1: Base Values

**Purpose:** Core service configuration that applies to all deployments

**Characteristics:**
- Required for service operation
- Security-hardened defaults
- Resource limits and requests
- Standard labels and annotations
- Common integrations (monitoring, logging)

**Example:** `cert-manager/helm-values/base-values-v1.18.2.yaml`

```yaml
# Resource limits
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

# Security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  capabilities:
    drop:
      - ALL

# Monitoring integration
prometheus:
  enabled: true
  servicemonitor:
    enabled: true
    interval: 30s

# Standard labels
commonLabels:
  app.kubernetes.io/managed-by: fluxcd
  opencenter.io/tier: platform
```

---

## Tier 2: Override Values

**Purpose:** Cluster-specific customization without modifying base

**Characteristics:**
- Optional (not all clusters need overrides)
- Environment-specific settings
- Scaling parameters
- Storage classes
- Ingress hostnames
- External endpoints

**Example:** `cert-manager/helm-values/override-values-v1.18.2.yaml`

```yaml
# Cluster-specific replicas
replicaCount: 3

# Cluster-specific ingress
ingress:
  enabled: true
  hosts:
    - cert-manager.prod.example.com
  tls:
    - secretName: cert-manager-tls
      hosts:
        - cert-manager.prod.example.com

# Cluster-specific storage
persistence:
  storageClass: longhorn-fast

# External DNS integration
externalDNS:
  enabled: true
  domain: prod.example.com
```

---

## Tier 3: Enterprise Values

**Purpose:** Enterprise edition features and hardening

**Characteristics:**
- Optional (only for enterprise deployments)
- Advanced security features
- High availability configurations
- Enterprise integrations
- Compliance requirements

**Example:** `cert-manager/helm-values/enterprise-values-v1.18.2.yaml`

```yaml
# High availability
replicaCount: 5
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/name: cert-manager
        topologyKey: kubernetes.io/hostname

# Enterprise security
podSecurityPolicy:
  enabled: true
  useAppArmor: true

# Audit logging
auditLog:
  enabled: true
  destination: /var/log/cert-manager/audit.log
  retention: 90d

# Enterprise support
support:
  enabled: true
  endpoint: https://support.example.com
  licenseKey: ${LICENSE_KEY}
```

---

## HelmRelease Integration

Values are referenced in HelmRelease via `valuesFrom`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  chart:
    spec:
      chart: cert-manager
      version: v1.18.2
  valuesFrom:
    # Tier 1: Base (required)
    - kind: Secret
      name: cert-manager-values-base
      valuesKey: values.yaml
    
    # Tier 2: Override (optional)
    - kind: Secret
      name: cert-manager-values-override
      valuesKey: override.yaml
      optional: true
    
    # Tier 3: Enterprise (optional)
    - kind: Secret
      name: cert-manager-values-enterprise
      valuesKey: hardened-enterprise.yaml
      optional: true
```

---

## Secret Generation

Values files are converted to Kubernetes Secrets via Kustomize `secretGenerator`:

```yaml
# applications/base/services/cert-manager/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

secretGenerator:
  - name: cert-manager-values-base
    files:
      - values.yaml=helm-values/base-values-v1.18.2.yaml
  
  - name: cert-manager-values-override
    files:
      - override.yaml=helm-values/override-values-v1.18.2.yaml
    options:
      disableNameSuffixHash: true
  
  - name: cert-manager-values-enterprise
    files:
      - hardened-enterprise.yaml=helm-values/enterprise-values-v1.18.2.yaml
    options:
      disableNameSuffixHash: true
```

---

## Values Merge Behavior

Helm merges values in order, with later values overriding earlier ones:

1. Chart default values
2. Base values (Tier 1)
3. Override values (Tier 2)
4. Enterprise values (Tier 3)

**Example merge:**

```yaml
# Chart defaults
replicaCount: 1
resources:
  limits:
    cpu: 100m

# Base values (Tier 1)
replicaCount: 2
resources:
  limits:
    memory: 128Mi

# Override values (Tier 2)
replicaCount: 3

# Final merged result
replicaCount: 3  # From Tier 2
resources:
  limits:
    cpu: 100m      # From chart defaults
    memory: 128Mi  # From Tier 1
```

---

## Common Values Patterns

### Resource Limits

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

### Security Context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
  capabilities:
    drop:
      - ALL
```

### Pod Security Standards

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

containerSecurityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
```

### Affinity and Tolerations

```yaml
# Node affinity
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: workload
              operator: In
              values:
                - system

# Pod anti-affinity
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: my-service
          topologyKey: kubernetes.io/hostname

# Tolerations
tolerations:
  - key: workload
    operator: Equal
    value: system
    effect: NoSchedule
```

### Monitoring Integration

```yaml
# Prometheus ServiceMonitor
prometheus:
  enabled: true
  servicemonitor:
    enabled: true
    interval: 30s
    scrapeTimeout: 10s
    labels:
      prometheus: kube-prometheus

# Grafana dashboards
grafana:
  dashboards:
    enabled: true
    label: grafana_dashboard
```

### Ingress Configuration

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: service.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: service-tls
      hosts:
        - service.example.com
```

### Persistence

```yaml
persistence:
  enabled: true
  storageClass: longhorn
  accessMode: ReadWriteOnce
  size: 10Gi
  annotations:
    opencenter.io/backup-profile: daily
```

---

## Version Management

### Versioning Strategy

- Values files are versioned with chart version
- Multiple versions can coexist for gradual upgrades
- Old versions retained for rollback capability

### Upgrade Process

1. Add new values file with new chart version
2. Update HelmRelease chart version
3. Update secretGenerator to reference new file
4. Test in non-production environment
5. Promote to production
6. Remove old values file after successful upgrade

**Example:**

```yaml
# Before upgrade
secretGenerator:
  - name: cert-manager-values-base
    files:
      - values.yaml=helm-values/base-values-v1.18.2.yaml

# During upgrade (both versions present)
secretGenerator:
  - name: cert-manager-values-base
    files:
      - values.yaml=helm-values/base-values-v1.19.0.yaml

# After upgrade (old version removed)
# Delete helm-values/base-values-v1.18.2.yaml
```

---

## Best Practices

### Base Values

- Include all required configuration
- Use security-hardened defaults
- Set resource limits
- Enable monitoring and logging
- Use standard labels

### Override Values

- Keep cluster-specific only
- Document why overrides are needed
- Avoid duplicating base values
- Use environment variables for secrets

### Enterprise Values

- Document enterprise features
- Include compliance requirements
- Set higher resource limits
- Enable advanced security features

### General

- Use YAML anchors for repeated values
- Comment complex configurations
- Validate values with `helm template`
- Test values in non-production first
- Keep values files under 500 lines

---

## Validation

### Helm Template

Render templates locally to validate values:

```bash
helm template my-release chart-name \
  -f base-values-v1.18.2.yaml \
  -f override-values-v1.18.2.yaml \
  -f enterprise-values-v1.18.2.yaml
```

### Kustomize Build

Validate Kustomization builds correctly:

```bash
cd applications/base/services/cert-manager
kubectl kustomize . --dry-run=server
```

### Flux Dry-Run

Test HelmRelease without applying:

```bash
flux install --dry-run
```

---

## Troubleshooting

### Values Not Applied

Check HelmRelease status:
```bash
flux get helmreleases -n cert-manager
kubectl describe helmrelease cert-manager -n cert-manager
```

### Secret Not Found

Verify secret exists:
```bash
kubectl get secret cert-manager-values-base -n cert-manager
kubectl get secret cert-manager-values-override -n cert-manager
```

### Values Merge Issues

View final merged values:
```bash
helm get values my-release -n cert-manager
```

### Syntax Errors

Validate YAML syntax:
```bash
yamllint helm-values/base-values-v1.18.2.yaml
```

---

## Evidence

**Source Files:**
- `applications/base/services/cert-manager/helmrelease.yaml` (valuesFrom pattern)
- `applications/base/services/cert-manager/kustomization.yaml` (secretGenerator)
- `applications/base/services/cert-manager/helm-values/` (values files)
- `docs/service-standards-and-lifecycle.md` (service standards)
- `docs/analysis/S1-APP-RUNTIME-APIS.md` (three-tier values analysis)
- `llms.txt` lines 95-125 (HelmRelease patterns)
