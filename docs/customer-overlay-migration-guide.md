---
doc_type: how-to
title: "Customer Overlay Migration Guide - ADR-001"
audience: "platform engineers, customer teams"
---

# Customer Overlay Migration Guide

**Purpose:** For platform engineers and customer teams, shows how to migrate customer overlays to use the new ADR-001 Kustomize Components pattern.

## Overview

The openCenter-gitops-base repository has migrated to Kustomize Components pattern (ADR-001). This eliminates the `community/` and `enterprise/` directory structure in favor of a cleaner component-based approach.

**Breaking Change:** Customer overlays that reference `applications/base/services/<service>/enterprise` paths must be updated.

## What Changed

### Before (Old Pattern)
```
applications/base/services/cert-manager/
├── community/
│   ├── kustomization.yaml
│   └── source.yaml
└── enterprise/
    ├── kustomization.yaml          # ← Customer overlays referenced this
    └── helm-values/
```

### After (New Pattern)
```
applications/base/services/cert-manager/
├── source.yaml                     # At root (community by default)
├── enterprise/
│   └── helm-values/                # Only helm-values remain
├── components/
│   └── enterprise/
│       └── kustomization.yaml      # Component for enterprise features
└── kustomization.yaml              # Root kustomization
```

## Migration Paths

### Option 1: FluxCD Kustomization with Components (Recommended)

**Best for:** FluxCD v2.0+ deployments

**Before:**
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager
  namespace: flux-system
spec:
  sourceRef:
    kind: GitRepository
    name: opencenter-gitops-base
  path: applications/base/services/cert-manager/enterprise  # ❌ Old path
  interval: 10m
```

**After (Community):**
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager
  namespace: flux-system
spec:
  sourceRef:
    kind: GitRepository
    name: opencenter-gitops-base
  path: applications/base/services/cert-manager  # ✅ Root path
  interval: 10m
```

**After (Enterprise):**
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager
  namespace: flux-system
spec:
  sourceRef:
    kind: GitRepository
    name: opencenter-gitops-base
  path: applications/base/services/cert-manager  # ✅ Root path
  interval: 10m
  components:
    - components/enterprise  # ✅ Enable enterprise component
```

### Option 2: Local Kustomization Wrapper

**Best for:** Complex overlays with additional customizations

Create a local kustomization in your customer overlay:

```yaml
# customers/<customer>/applications/overlays/<cluster>/services/cert-manager/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../../../../../openCenter-gitops-base/applications/base/services/cert-manager
components:
  - ../../../../../../openCenter-gitops-base/applications/base/services/cert-manager/components/enterprise

# Add your customer-specific patches here
patches:
  - target:
      kind: HelmRelease
      name: cert-manager
    patch: |-
      - op: replace
        path: /spec/values/replicaCount
        value: 3
```

## Service-Specific Migration

### Standard Helm Services

**Services:** cert-manager, metallb, headlamp, postgres-operator, rbac-manager, gateway-api, vsphere-csi, strimzi-kafka-operator, kyverno/policy-engine

**Migration:**
- Change path from `<service>/enterprise` to `<service>`
- Add `components: [components/enterprise]` for enterprise deployments

### Multi-Component Services

**Services:** istio/base, istio/istiod, observability/kube-prometheus-stack, observability/loki, observability/opentelemetry-kube-stack

**Migration:**
- Change path from `<service>/enterprise` to `<service>`
- Add `components: [components/enterprise]` for enterprise deployments

**Example (istio/base):**
```yaml
# Before
path: applications/base/services/istio/base/enterprise

# After (enterprise)
path: applications/base/services/istio/base
components:
  - components/enterprise
```

### Keycloak (Multi-Component)

Keycloak has 4 sub-components. Each must be migrated separately.

**Sub-components:**
- 00-postgres
- 10-operator
- 20-keycloak
- 30-oidc-rbac

**Example (00-postgres):**
```yaml
# Before
path: applications/base/services/keycloak/enterprise/00-postgres

# After (enterprise)
path: applications/base/services/keycloak/00-postgres
components:
  - components/enterprise
```

### OLM (Non-Helm)

**Before:**
```yaml
path: applications/base/services/olm/enterprise
```

**After (enterprise):**
```yaml
path: applications/base/services/olm
components:
  - components/enterprise
```

## Migration Checklist

For each customer overlay:

- [ ] Identify all services using enterprise variant
- [ ] Update FluxCD Kustomization paths
- [ ] Add `components` field for enterprise deployments
- [ ] Update any local patches referencing old paths
- [ ] Test in non-production cluster
- [ ] Validate FluxCD reconciliation
- [ ] Deploy to production

## Finding Services to Migrate

```bash
# Find all FluxCD Kustomizations referencing enterprise paths
grep -r "path:.*enterprise" customers/<customer>/applications/overlays/*/services/

# Example output:
# customers/1861184-Metro-Bank-PLC/applications/overlays/k8s-sandbox/services/cert-manager.yaml:  path: applications/base/services/cert-manager/enterprise
```

## Testing Migration

### Step 1: Validate Kustomization

```bash
# Test community deployment
kubectl kustomize applications/base/services/cert-manager

# Test enterprise deployment (requires kustomize v5.0+)
kustomize build applications/base/services/cert-manager \
  --enable-alpha-plugins \
  --load-restrictor=LoadRestrictionsNone \
  --components=components/enterprise
```

### Step 2: Deploy to Test Cluster

```bash
# Update FluxCD Kustomization
kubectl apply -f customers/<customer>/applications/overlays/<cluster>/services/cert-manager.yaml

# Force reconciliation
flux reconcile kustomization cert-manager --with-source

# Check status
flux get kustomizations cert-manager
kubectl get helmrelease cert-manager -n cert-manager
```

### Step 3: Verify Deployment

```bash
# Check pods are running
kubectl get pods -n cert-manager

# Check HelmRelease status
kubectl describe helmrelease cert-manager -n cert-manager

# Verify enterprise features (if applicable)
# Example: Check if enterprise image is used
kubectl get deployment -n cert-manager -o yaml | grep image:
```

## Troubleshooting

### Issue: FluxCD Reconciliation Fails

**Symptom:** Kustomization shows "path not found" error

**Solution:**
```bash
# Verify path exists in gitops-base repository
ls -la openCenter-gitops-base/applications/base/services/cert-manager

# Check FluxCD GitRepository is up to date
flux reconcile source git opencenter-gitops-base

# Check Kustomization path
kubectl get kustomization cert-manager -n flux-system -o yaml | grep path
```

### Issue: Component Not Found

**Symptom:** Error: "components/enterprise not found"

**Solution:**
```bash
# Verify component exists
ls -la openCenter-gitops-base/applications/base/services/cert-manager/components/enterprise

# Check component kustomization
cat openCenter-gitops-base/applications/base/services/cert-manager/components/enterprise/kustomization.yaml

# Ensure it has kind: Component
grep "kind: Component" openCenter-gitops-base/applications/base/services/cert-manager/components/enterprise/kustomization.yaml
```

### Issue: Enterprise Features Not Applied

**Symptom:** Deployment uses community version instead of enterprise

**Solution:**
```bash
# Verify components field in Kustomization
kubectl get kustomization cert-manager -n flux-system -o yaml | grep -A 2 components

# Check if enterprise values secret exists
kubectl get secret cert-manager-values-enterprise -n cert-manager

# Verify HelmRelease references enterprise values
kubectl get helmrelease cert-manager -n cert-manager -o yaml | grep enterprise
```

### Issue: Multi-Component Service Fails

**Symptom:** kubectl kustomize fails with "file not in or below" error

**Solution:** This is expected for multi-component services (istio, observability) due to parent directory references. Use FluxCD for deployment:

```bash
# Don't use kubectl kustomize directly
# Instead, deploy via FluxCD
flux reconcile kustomization <service> --with-source
```

## Rollback Procedure

If migration causes issues:

### Step 1: Revert FluxCD Kustomization

```bash
# Restore old path
kubectl edit kustomization cert-manager -n flux-system

# Change:
# path: applications/base/services/cert-manager
# components: [components/enterprise]

# Back to:
# path: applications/base/services/cert-manager/enterprise
```

### Step 2: Force Reconciliation

```bash
flux reconcile kustomization cert-manager --with-source
```

### Step 3: Verify Rollback

```bash
flux get kustomizations cert-manager
kubectl get helmrelease cert-manager -n cert-manager
```

## Migration Script

Automate migration for multiple services:

```bash
#!/bin/bash
# migrate-customer-overlay.sh

CUSTOMER="$1"
CLUSTER="$2"
SERVICE="$3"

if [[ -z "$CUSTOMER" ]] || [[ -z "$CLUSTER" ]] || [[ -z "$SERVICE" ]]; then
    echo "Usage: $0 <customer> <cluster> <service>"
    exit 1
fi

KUSTOMIZATION_FILE="customers/$CUSTOMER/applications/overlays/$CLUSTER/services/$SERVICE.yaml"

if [[ ! -f "$KUSTOMIZATION_FILE" ]]; then
    echo "Error: $KUSTOMIZATION_FILE not found"
    exit 1
fi

# Backup
cp "$KUSTOMIZATION_FILE" "$KUSTOMIZATION_FILE.bak"

# Update path (remove /enterprise)
sed -i.tmp 's|path: \(.*\)/enterprise$|path: \1|g' "$KUSTOMIZATION_FILE"

# Add components field (if not already present)
if ! grep -q "components:" "$KUSTOMIZATION_FILE"; then
    # Add after interval line
    sed -i.tmp '/interval:/a\  components:\n    - components/enterprise' "$KUSTOMIZATION_FILE"
fi

# Cleanup
rm -f "$KUSTOMIZATION_FILE.tmp"

echo "Migrated: $KUSTOMIZATION_FILE"
echo "Backup: $KUSTOMIZATION_FILE.bak"
```

**Usage:**
```bash
./migrate-customer-overlay.sh 1861184-Metro-Bank-PLC k8s-sandbox cert-manager
```

## Communication Template

Use this template to communicate changes to customers:

```
Subject: Action Required: openCenter-gitops-base Migration

Dear [Customer Team],

We are migrating the openCenter-gitops-base repository to a new structure (ADR-001) 
that simplifies maintenance and eliminates duplication.

BREAKING CHANGE: Customer overlays must be updated.

TIMELINE:
- [Date]: Migration guide available
- [Date]: Test cluster migration
- [Date]: Production migration

ACTIONS REQUIRED:
1. Review migration guide: [link]
2. Update FluxCD Kustomizations (see guide)
3. Test in non-production cluster
4. Schedule production migration

SUPPORT:
- Migration guide: [link]
- Support channel: [channel]
- Office hours: [schedule]

We will provide hands-on support during migration.

Best regards,
Platform Engineering Team
```

## FAQ

**Q: Do I need to update all services at once?**  
A: No, services can be migrated incrementally. Each service is independent.

**Q: Will this cause downtime?**  
A: No, FluxCD will reconcile the new structure without downtime. The underlying resources remain the same.

**Q: What if I have custom patches?**  
A: Custom patches will continue to work. Update any path references in your patches.

**Q: Can I stay on the old structure?**  
A: No, the old `community/` and `enterprise/` directories have been removed from the base repository.

**Q: What version of FluxCD is required?**  
A: FluxCD v2.0+ is required for native component support. Earlier versions can use local kustomization wrappers.

**Q: How do I test without affecting production?**  
A: Deploy to a test cluster first, validate functionality, then migrate production.

## Support

For assistance with migration:

- **Documentation:** This guide
- **Tools:** `tools/validate-components.sh` in openCenter-gitops-base
- **Support:** Platform Engineering Team
- **Office Hours:** [Schedule]

## References

- [ADR-001: Kustomize Components Pattern](../ADRS/ADR-001-kustomize-components-for-enterprise-pattern.md)
- [Kustomize Components Documentation](https://kubectl.docs.kubernetes.io/guides/config_management/components/)
- [FluxCD Kustomization API](https://fluxcd.io/flux/components/kustomize/kustomizations/)
