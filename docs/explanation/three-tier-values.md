---
doc_type: explanation
title: "Three-Tier Helm Values Architecture"
audience: "platform engineers"
---

# Three-Tier Helm Values Architecture

**Purpose:** For platform engineers, explains the three-tier Helm values pattern (base, override, enterprise), why this architecture exists, its trade-offs and benefits, and when to use each tier.

## The Problem: Configuration Sprawl

Kubernetes services need configuration that varies across environments, customers, and editions. A naive approach creates separate Helm values files for every combination:

- `values-dev.yaml`
- `values-stage.yaml`
- `values-prod.yaml`
- `values-customer-a-dev.yaml`
- `values-customer-a-prod.yaml`
- `values-customer-b-dev.yaml`
- `values-enterprise-dev.yaml`

This explodes to N × M × P files (environments × customers × editions). Maintaining consistency becomes impossible. Updating a security setting requires changing dozens of files. Finding which file controls a specific setting requires searching through all of them.

The three-tier values pattern solves this by separating concerns into layers.

## The Three Tiers

openCenter uses three value tiers, applied in order:

**Base values** (required) contain security-hardened defaults that apply to all deployments. These values enforce security policies, set resource limits, enable monitoring, and configure production-ready settings. Base values live in `applications/base/services/<service>/helm-values/hardened-values-v<version>.yaml`.

**Override values** (optional) contain cluster-specific customization. These values change settings that vary by environment (domain names, storage classes, node selectors) or by customer requirements (replica counts, resource limits, feature flags). Override values live in customer cluster repositories at `applications/overlays/<cluster>/services/<service>/override-values.yaml`.

**Enterprise values** (optional) contain enterprise edition features. These values enable advanced capabilities (high availability, advanced security, premium features) that community editions don't include. Enterprise values live in `applications/base/services/<service>/helm-values/hardened-enterprise-v<version>.yaml`.

FluxCD merges these tiers in order. Later tiers override earlier tiers. The final configuration is base + override + enterprise.

## How It Works

The HelmRelease resource references all three tiers through `valuesFrom`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  valuesFrom:
    - kind: Secret
      name: cert-manager-values-base
      valuesKey: values.yaml
    - kind: Secret
      name: cert-manager-values-override
      valuesKey: override.yaml
      optional: true
    - kind: Secret
      name: cert-manager-values-enterprise
      valuesKey: hardened-enterprise.yaml
      optional: true
```

The `optional: true` setting means FluxCD doesn't fail if the secret doesn't exist. Clusters that don't need overrides or enterprise features simply don't create those secrets.

Kustomize creates these secrets from files using `secretGenerator`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
secretGenerator:
  - name: cert-manager-values-base
    files:
      - values.yaml=helm-values/hardened-values-v1.18.2.yaml
```

This pattern keeps values in YAML files (easy to read and edit) but delivers them to Helm as Kubernetes secrets (the format FluxCD expects).

## Why Three Tiers

**Base tier** enforces organizational standards. Security teams define security contexts, network policies, and monitoring requirements once. Every deployment inherits these settings. When a new CVE requires changing a security setting, you update one file and all clusters get the fix.

**Override tier** enables customization without forking. Customers need different domain names, storage backends, and resource allocations. Instead of copying the entire base configuration and modifying it (which breaks updates), they create a small override file with just the differences.

**Enterprise tier** separates community and commercial features. The same base configuration works for both editions. Enterprise customers add the enterprise tier to unlock additional capabilities. This avoids maintaining separate codebases for different editions.

## Benefits

**Consistency** - All clusters start from the same hardened baseline. Security settings, monitoring configuration, and operational best practices are consistent across environments.

**Maintainability** - Updating a security setting requires changing one file. The change propagates to all clusters automatically through GitOps reconciliation.

**Auditability** - You can see exactly what differs between clusters by examining override files. The base configuration is the same everywhere, so differences are explicit and documented.

**Testability** - You can test base values once and trust they work everywhere. Override values are small and focused, making them easier to test.

**Separation of concerns** - Platform teams own base values. Cluster operators own override values. Product teams own enterprise values. Each team has clear ownership boundaries.

## Trade-offs

**Indirection** - Understanding the final configuration requires mentally merging three files. Debugging "why is this setting this value" requires checking all three tiers.

**Merge complexity** - Helm's value merging is deep and recursive. Nested maps merge, but lists replace. This can cause unexpected behavior when overriding complex structures.

**Discovery** - Finding which tier controls a setting requires searching three files. Tools like `helm get values` show the final merged result but don't indicate which tier provided each value.

**Ordering constraints** - The tier order is fixed (base → override → enterprise). You can't apply enterprise values before overrides. This rarely matters but can be limiting.

**Secret overhead** - Each tier becomes a Kubernetes secret. This adds resources to the cluster and complexity to the Kustomization configuration.

## When to Use Each Tier

**Use base values for:**
- Security contexts (runAsNonRoot, readOnlyRootFilesystem, capabilities)
- Resource limits (memory, CPU)
- Monitoring configuration (ServiceMonitor, PodMonitor)
- Network policies
- Pod disruption budgets
- Affinity and anti-affinity rules
- Security scanning and compliance settings
- Anything that should be consistent across all deployments

**Use override values for:**
- Domain names and ingress hosts
- Storage classes and volume sizes
- Node selectors and tolerations
- Replica counts (when different from base)
- Environment-specific endpoints (databases, APIs)
- Customer-specific feature flags
- Resource limits (when base limits are insufficient)
- Anything that varies by cluster or customer

**Use enterprise values for:**
- High availability settings (multiple replicas, pod anti-affinity)
- Advanced security features (mTLS, encryption at rest)
- Premium features (advanced monitoring, backup, disaster recovery)
- Enterprise integrations (LDAP, SAML, SSO)
- Anything that differentiates enterprise from community editions

## Common Patterns

**Minimal overrides** - Most clusters need few overrides. A typical override file contains 5-10 lines changing domain names and storage classes. If your override file is hundreds of lines, you're probably duplicating base configuration.

**Environment-specific overrides** - Development clusters might reduce replica counts and resource limits. Production clusters might increase them. These differences belong in override values.

**Customer-specific overrides** - Customer A needs integration with their LDAP server. Customer B needs a specific storage class. These differences belong in override values in each customer's repository.

**Edition-specific features** - Enterprise edition enables backup, disaster recovery, and advanced monitoring. These features belong in enterprise values.

## Alternatives Considered

**Single values file per cluster** - Simple but doesn't scale. Every cluster duplicates the entire configuration. Updates require changing every file.

**Environment variables** - Doesn't work for complex nested configuration. Helm values are deeply nested YAML structures that don't map well to flat environment variables.

**Helm subcharts** - Could separate base and override configuration into separate charts. More complex than the three-tier pattern and doesn't integrate as cleanly with Kustomize.

**Kustomize patches** - Could use strategic merge patches or JSON patches instead of Helm values. Works but is more verbose and harder to read than YAML values files.

The three-tier pattern balances simplicity, flexibility, and maintainability better than these alternatives.

## Migration Path

Existing deployments using single values files can migrate incrementally:

1. Extract common settings into base values
2. Leave cluster-specific settings in override values
3. Test that merged values produce the same result
4. Deploy to non-production first
5. Gradually migrate production clusters

The migration is low-risk because you can verify the final merged values match the original values before deploying.

## Evidence

This explanation is based on the following repository analysis:

- Three-tier values pattern in HelmRelease: `applications/base/services/cert-manager/helmrelease.yaml` lines 28-36
- Kustomize secretGenerator for values: `applications/base/services/cert-manager/kustomization.yaml`
- Values hierarchy documentation: `llms.txt` lines 95-125
- Service standards requiring hardened values: `docs/service-standards-and-lifecycle.md`
- HelmRelease configuration patterns: `docs/analysis/S1-APP-RUNTIME-APIS.md`
- Values merging behavior: `docs/analysis/S4-FLUXCD-GITOPS.md`
