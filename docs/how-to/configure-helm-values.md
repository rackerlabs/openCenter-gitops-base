---
doc_type: how-to
title: "Configure Helm Values"
audience: "platform engineers"
---

# Configure Helm Values

**Purpose:** For platform engineers, shows how to customize service configuration using the three-tier Helm values pattern, covering base, override, and enterprise values.

## Prerequisites

- Service already added to openCenter-gitops-base
- Understanding of Helm values hierarchy
- Access to customer overlay repository

## Three-Tier Values Pattern

Values are applied in order (later values override earlier):

1. **Base values** (required) - Default configuration in openCenter-gitops-base
2. **Override values** (optional) - Cluster-specific customization
3. **Enterprise values** (optional) - Enterprise edition features

## Steps

### 1. Identify value to change

Check current base values:

```bash
cat applications/base/services/cert-manager/helm-values/values-v1.18.2.yaml
```

Example: Change resource limits for cert-manager.

### 2. Choose appropriate tier

**Use base values when:**
- Setting defaults for all clusters
- Configuring security hardening
- Defining resource baselines

**Use override values when:**
- Customizing for specific cluster
- Environment-specific settings (dev vs prod)
- Infrastructure-specific configuration (cloud provider)

**Use enterprise values when:**
- Enabling enterprise features
- Compliance-specific settings
- Advanced security controls

### 3. Update base values (openCenter-gitops-base)

Edit `applications/base/services/cert-manager/helm-values/values-v1.18.2.yaml`:

```yaml
# Existing configuration
replicaCount: 1

# Add or modify values
resources:
  limits:
    cpu: 200m      # Changed from 100m
    memory: 256Mi  # Changed from 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

# Add new configuration
prometheus:
  enabled: true
  servicemonitor:
    enabled: true
    interval: 30s
```

Commit changes:

```bash
git add applications/base/services/cert-manager/helm-values/
git commit -m "feat(cert-manager): increase resource limits"
git push origin main
```

Tag for customer consumption:

```bash
git tag v1.0.1
git push origin v1.0.1
```

### 4. Create override values (customer overlay)

Navigate to customer overlay:

```bash
cd customers/1861184-Metro-Bank-PLC/applications/overlays/k8s-sandbox/services/cert-manager/
```

Create `override-values.yaml`:

```yaml
# Cluster-specific overrides for k8s-sandbox

# Increase replicas for production
replicaCount: 3

# Use cluster-specific DNS servers
extraArgs:
  - --dns01-recursive-nameservers=192.168.1.1:53
  - --dns01-recursive-nameservers-only

# Configure cluster issuer for this environment
clusterIssuer:
  name: letsencrypt-prod
  email: ops@metrobank.example.com
  server: https://acme-v02.api.letsencrypt.org/directory
```

Create `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: cert-manager

secretGenerator:
  - name: cert-manager-values-override
    files:
      - override.yaml=override-values.yaml
    options:
      disableNameSuffixHash: true

generatorOptions:
  disableNameSuffixHash: true
```

### 5. Create enterprise values (optional)

For enterprise features, create `hardened-enterprise.yaml`:

```yaml
# Enterprise edition features

# Enable advanced security
securityContext:
  seccompProfile:
    type: RuntimeDefault
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

# Enable audit logging
webhook:
  auditAnnotations:
    enabled: true

# Configure high availability
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
                - cert-manager
        topologyKey: kubernetes.io/hostname

# Enable backup
backup:
  enabled: true
  schedule: "0 2 * * *"
  retention: 30
```

Add to `kustomization.yaml`:

```yaml
secretGenerator:
  - name: cert-manager-values-override
    files:
      - override.yaml=override-values.yaml
    options:
      disableNameSuffixHash: true
  - name: cert-manager-values-enterprise
    files:
      - hardened-enterprise.yaml=hardened-enterprise.yaml
    options:
      disableNameSuffixHash: true
```

### 6. Validate values hierarchy

Build and inspect final values:

```bash
# From customer overlay directory
kustomize build . | kubectl apply --dry-run=client -f -

# Check generated secrets
kustomize build . | grep -A 20 "kind: Secret"
```

### 7. Apply to cluster

Commit customer overlay changes:

```bash
git add applications/overlays/k8s-sandbox/services/cert-manager/
git commit -m "feat(cert-manager): configure for k8s-sandbox cluster"
git push origin main
```

FluxCD will reconcile automatically within 5 minutes.

### 8. Force immediate reconciliation

```bash
flux reconcile kustomization cert-manager -n flux-system
```

## Verification

Check HelmRelease values:

```bash
# View applied values
kubectl get helmrelease cert-manager -n cert-manager -o yaml

# Check valuesFrom references
kubectl get helmrelease cert-manager -n cert-manager -o jsonpath='{.spec.valuesFrom[*].name}'
```

Expected output:
```
cert-manager-values-base cert-manager-values-override cert-manager-values-enterprise
```

Verify secrets exist:

```bash
kubectl get secret -n cert-manager | grep cert-manager-values
```

Check effective configuration:

```bash
# View deployed resources
kubectl get deployment cert-manager -n cert-manager -o yaml

# Verify resource limits
kubectl get deployment cert-manager -n cert-manager -o jsonpath='{.spec.template.spec.containers[0].resources}'
```

## Common Patterns

### Override single nested value

Base values:

```yaml
controller:
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
```

Override values (only change memory):

```yaml
controller:
  resources:
    limits:
      memory: 256Mi  # Only this value changes
```

Result: CPU limit remains 100m, memory becomes 256Mi.

### Disable feature from base

Base values:

```yaml
monitoring:
  enabled: true
```

Override values:

```yaml
monitoring:
  enabled: false
```

### Add environment-specific configuration

Override values for development:

```yaml
logLevel: debug
replicaCount: 1
resources:
  requests:
    cpu: 10m
    memory: 32Mi
```

Override values for production:

```yaml
logLevel: info
replicaCount: 3
resources:
  requests:
    cpu: 100m
    memory: 128Mi
```

## Troubleshooting

### Values not applied

Check secret exists:

```bash
kubectl get secret cert-manager-values-override -n cert-manager
```

If missing, verify Kustomization built correctly:

```bash
kustomize build applications/overlays/k8s-sandbox/services/cert-manager/
```

### Wrong values applied

Check HelmRelease status:

```bash
kubectl describe helmrelease cert-manager -n cert-manager
```

View Helm release values:

```bash
helm get values cert-manager -n cert-manager
```

### Values conflict

Values are merged in order. Later values override earlier. Check merge result:

```bash
# Extract values from secrets
kubectl get secret cert-manager-values-base -n cert-manager -o jsonpath='{.data.values\.yaml}' | base64 -d

kubectl get secret cert-manager-values-override -n cert-manager -o jsonpath='{.data.override\.yaml}' | base64 -d
```

## Best Practices

1. **Keep base values minimal** - Only include required configuration
2. **Document overrides** - Add comments explaining why values are overridden
3. **Use semantic versioning** - Tag base values with version numbers
4. **Test in non-production first** - Validate changes in dev/staging
5. **Avoid duplicating base values** - Only override what changes
6. **Use SOPS for secrets** - Never commit plaintext credentials (see [manage-secrets.md](manage-secrets.md))

## Next Steps

- Encrypt sensitive values (see [manage-secrets.md](manage-secrets.md))
- Add observability configuration (see [setup-observability.md](setup-observability.md))
- Configure Gateway API routing (see [configure-gateway.md](configure-gateway.md))

## Evidence

**Sources:**
- `applications/base/services/cert-manager/helmrelease.yaml` - valuesFrom configuration
- `applications/base/services/cert-manager/kustomization.yaml` - secretGenerator pattern
- S1-APP-RUNTIME-APIS.md - Three-tier values hierarchy
- S4-FLUXCD-GITOPS.md - Values hierarchy via secrets
