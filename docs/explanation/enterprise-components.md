---
doc_type: explanation
title: "Enterprise Components Pattern"
audience: "platform engineers, architects"
---

# Enterprise Components Pattern

**Purpose:** For platform engineers and architects, explains the Kustomize components pattern used to differentiate community and enterprise editions, how components enable optional features, and the migration strategy from the previous approach.

## The Problem: Edition Sprawl

openCenter supports both community and enterprise editions. Enterprise editions include additional features:

- High availability configurations (multiple replicas, pod anti-affinity)
- Advanced security (mTLS, encryption at rest, audit logging)
- Premium integrations (enterprise monitoring, backup, disaster recovery)
- Commercial support and SLAs

The naive approach creates separate directories for each edition:

```
applications/base/services/cert-manager-community/
applications/base/services/cert-manager-enterprise/
```

This duplicates most configuration. The two editions differ in 10-20% of their configuration but share 80-90%. Maintaining both versions means updating security patches, version bumps, and configuration changes in two places. Bugs fixed in one edition must be manually ported to the other.

The Kustomize components pattern solves this by treating enterprise features as optional additions to a common base.

## What Are Kustomize Components

Kustomize components are reusable configuration fragments that can be included in multiple kustomizations. Unlike bases (which you extend) or overlays (which you apply on top), components are optional additions that you explicitly enable.

A component is a directory containing a `kustomization.yaml` with `kind: Component`:

```yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - high-availability.yaml

patches:
  - patch: |-
      - op: replace
        path: /spec/replicas
        value: 3
    target:
      kind: Deployment
```

You include components in a kustomization with the `components` field:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base/services/cert-manager

components:
  - ../../base/services/cert-manager/components/enterprise
```

The component's resources and patches are applied on top of the base configuration.

## How openCenter Uses Components

openCenter structures services with an optional enterprise component:

```
applications/base/services/cert-manager/
├── kustomization.yaml          # Base configuration (community)
├── helmrelease.yaml
├── namespace.yaml
├── helm-values/
│   └── hardened-values-v1.18.2.yaml
└── components/
    └── enterprise/
        ├── kustomization.yaml  # Component definition
        └── helm-values/
            └── hardened-enterprise-v1.18.2.yaml
```

The base configuration works for community edition. Enterprise customers include the enterprise component in their cluster overlay:

```yaml
# Customer cluster overlay
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base/services/cert-manager

components:
  - ../../base/services/cert-manager/components/enterprise
```

The enterprise component adds enterprise-specific Helm values through a secretGenerator:

```yaml
# components/enterprise/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

secretGenerator:
  - name: cert-manager-values-enterprise
    files:
      - hardened-enterprise.yaml=helm-values/hardened-enterprise-v1.18.2.yaml
```

This creates the `cert-manager-values-enterprise` secret that the HelmRelease references in its `valuesFrom` field. Community deployments don't include the component, so the secret doesn't exist, and FluxCD skips it (because `optional: true`).

## Why Components Work Better

**Single source of truth** - There's one base configuration. Enterprise features are additions, not duplicates. Security patches and version updates happen in one place.

**Explicit opt-in** - Enterprise features are visible in the cluster overlay. You can see which clusters use enterprise features by checking their kustomization files.

**Composability** - You can have multiple components (enterprise, high-availability, advanced-monitoring) and mix and match them. A cluster could use enterprise + high-availability but not advanced-monitoring.

**Testability** - You can test the base configuration independently. You can test components in isolation. You can test combinations of components.

**Migration path** - Existing deployments can adopt components incrementally. Start with base configuration, add components as needed.

## Components vs Overlays

Overlays and components both modify base configuration, but they serve different purposes:

**Overlays** represent environments or clusters. You have one overlay per deployment target (dev, stage, prod, customer-a, customer-b). Overlays are mutually exclusive - a deployment uses exactly one overlay.

**Components** represent optional features. You have one component per feature (enterprise, high-availability, backup). Components are composable - a deployment can use zero, one, or many components.

In openCenter:
- Customer cluster repositories are overlays (one per cluster)
- Enterprise features are components (optional additions)

This separation keeps concerns distinct. The overlay handles cluster-specific configuration (domain names, storage classes). Components handle feature flags (enterprise vs community).

## Migration from Previous Approach

openCenter recently migrated from a different pattern to components. The previous approach used separate directories for community and enterprise editions. The migration involved:

1. **Consolidate base configuration** - Move shared configuration to a single base directory
2. **Extract enterprise differences** - Identify configuration that differs between editions
3. **Create enterprise component** - Move enterprise-specific configuration to `components/enterprise/`
4. **Update overlays** - Add `components` field to cluster overlays that need enterprise features
5. **Test both editions** - Verify community and enterprise deployments produce correct configuration
6. **Deploy incrementally** - Migrate non-production clusters first, then production

The migration tools in `tools/kustomize-migration/` automate parts of this process. They analyze existing configurations, identify differences, and generate component definitions.

## Trade-offs

**Complexity** - Components add another layer to the Kustomize hierarchy. Understanding the final configuration requires mentally applying base + components + overlay.

**Discoverability** - Finding which features are available requires looking for component directories. There's no central registry of components.

**Ordering** - Components are applied in the order listed. If two components modify the same field, the later one wins. This can cause unexpected behavior.

**Tooling** - Not all tools understand components. Some Kustomize-based tools only support bases and overlays.

**Documentation** - Each component needs documentation explaining what it does, when to use it, and what it changes.

## When to Use Components

**Use components for:**
- Edition differences (community vs enterprise)
- Optional features (backup, disaster recovery, advanced monitoring)
- Experimental features (alpha/beta features that aren't ready for all deployments)
- Compliance profiles (PCI-DSS, HIPAA, FedRAMP configurations)
- Performance profiles (high-throughput, low-latency, cost-optimized)

**Don't use components for:**
- Environment differences (dev vs prod) - use overlays
- Customer-specific configuration - use overlays
- Required configuration - put it in the base
- Configuration that varies continuously - use Helm values

## Common Patterns

**Feature flags** - Components act as feature flags. Including the component enables the feature. This is cleaner than Helm values with boolean flags because the feature configuration is self-contained.

**Compliance profiles** - Different customers need different compliance configurations. Create components for each compliance framework (pci-dss, hipaa, fedramp) and include the appropriate component in each customer's overlay.

**Performance profiles** - Create components for different performance characteristics (high-throughput, low-latency, cost-optimized). Customers choose the profile that matches their needs.

**Experimental features** - New features start as components. Once they're stable and widely adopted, they can move to the base configuration.

## Alternatives Considered

**Separate repositories** - Maintain separate repositories for community and enterprise editions. This provides complete isolation but makes sharing improvements difficult. Security patches must be manually ported between repositories.

**Helm chart dependencies** - Use Helm subcharts for enterprise features. This works but is more complex than Kustomize components and doesn't integrate as cleanly with the GitOps workflow.

**Conditional Helm values** - Use boolean flags in Helm values to enable enterprise features. This works but mixes feature flags with configuration. Components keep feature selection (which components to include) separate from configuration (what values to use).

**Git branches** - Maintain community and enterprise editions on separate branches. This creates merge conflicts and makes it hard to keep editions in sync.

The Kustomize components pattern provides better separation of concerns and easier maintenance than these alternatives.

## Future Direction

The components pattern enables additional capabilities:

**Component marketplace** - A catalog of available components with descriptions, dependencies, and compatibility information.

**Automated testing** - Test all combinations of components to ensure they work together correctly.

**Component versioning** - Version components independently from base configuration, allowing faster iteration on enterprise features.

**Component dependencies** - Express that component A requires component B, enabling automatic inclusion of dependencies.

These enhancements would make components more powerful and easier to use, but they're not implemented yet.

## Evidence

This explanation is based on the following repository analysis:

- Kustomize components structure: `applications/base/services/*/components/enterprise/`
- Component kustomization format: `applications/base/services/*/components/enterprise/kustomization.yaml`
- Migration tools: `tools/kustomize-migration/` directory
- Service standards mentioning enterprise editions: `docs/service-standards-and-lifecycle.md`
- Components pattern analysis: `docs/analysis/S1-APP-RUNTIME-APIS.md`
- Build tooling and migration strategy: `docs/analysis/S2-BUILD-DEV-TOOLING.md`
- HelmRelease optional values pattern: `applications/base/services/cert-manager/helmrelease.yaml`
