---
doc_type: explanation
title: "GitOps Workflow in openCenter"
audience: "platform engineers, architects"
---

# GitOps Workflow in openCenter

**Purpose:** For platform engineers and architects, explains how GitOps works in openCenter, covering the FluxCD reconciliation loop, source-to-deployment flow, drift detection, and remediation strategies.

## What is GitOps

GitOps treats Git as the single source of truth for infrastructure and application configuration. Every change to the cluster state happens through a Git commit. Controllers running in the cluster continuously reconcile the actual state with the desired state declared in Git.

In openCenter, FluxCD implements this pattern. When you commit a change to the repository, FluxCD detects it, validates it, and applies it to the cluster. If someone makes a manual change directly to the cluster (drift), FluxCD detects and corrects it.

## The FluxCD Reconciliation Loop

FluxCD runs three primary controllers that work together:

**Source Controller** pulls content from Git repositories and Helm chart repositories. It checks for updates every 15 minutes by default. When it detects a change, it downloads the content and makes it available to other controllers.

**Kustomize Controller** applies Kubernetes manifests to the cluster. It builds Kustomize overlays, decrypts SOPS-encrypted secrets, and applies the resulting manifests. It reconciles every 5 minutes.

**Helm Controller** manages Helm releases. It watches HelmRelease resources, fetches charts from HelmRepository sources, merges values from multiple sources, and installs or upgrades releases. It also reconciles every 5 minutes.

These controllers run independently but coordinate through Kubernetes resources. A GitRepository resource tells the source controller where to pull code. A Kustomization resource tells the kustomize controller which path to apply. A HelmRelease resource tells the helm controller which chart to install.

## Source → Kustomization → HelmRelease Flow

The typical deployment flow in openCenter follows this pattern:

1. **GitRepository** defines the source repository. For openCenter-gitops-base services, customer clusters create GitRepository resources pointing to specific tags:

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

The source controller clones this repository every 15 minutes and checks if the tag has changed. Using tags instead of branches provides stability - services only update when you explicitly change the tag reference.

2. **Kustomization** applies manifests from the GitRepository. It specifies a path within the repository and can depend on other Kustomizations:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager
spec:
  dependsOn:
    - name: sources
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: opencenter-cert-manager
  path: applications/base/services/cert-manager
  prune: true
  healthChecks:
    - apiVersion: helm.toolkit.fluxcd.io/v2
      kind: HelmRelease
      name: cert-manager
      namespace: cert-manager
```

The `dependsOn` field ensures that source repositories are created before services that reference them. The `healthChecks` field tells FluxCD to wait for the HelmRelease to become ready before marking this Kustomization as ready.

3. **HelmRelease** deploys the actual service. The Kustomization creates a HelmRelease resource, which the helm controller processes:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  interval: 5m
  timeout: 10m
  chart:
    spec:
      chart: cert-manager
      version: 1.18.2
      sourceRef:
        kind: HelmRepository
        name: jetstack
  driftDetection:
    mode: enabled
  install:
    remediation:
      retries: 3
  upgrade:
    remediation:
      retries: 0
  valuesFrom:
    - kind: Secret
      name: cert-manager-values-base
```

The helm controller fetches the chart from the HelmRepository, merges values from the referenced secrets, and installs or upgrades the release.

## Drift Detection and Remediation

Drift occurs when the actual cluster state diverges from the desired state in Git. This happens when someone runs `kubectl apply` manually, when an operator modifies resources, or when a controller makes unexpected changes.

FluxCD detects drift through two mechanisms:

**Periodic reconciliation** happens every 5 minutes for HelmRelease and Kustomization resources. FluxCD compares the current state with the desired state and corrects any differences.

**Drift detection mode** (enabled by default in openCenter) makes FluxCD actively watch for changes to resources it manages. When a resource changes outside of FluxCD, it triggers an immediate reconciliation instead of waiting for the next interval.

Remediation behavior differs between install and upgrade operations:

**Install failures** retry 3 times with exponential backoff. If a service fails to install due to a transient issue (network timeout, temporary API server unavailability), FluxCD automatically retries. The `remediateLastFailure: true` setting means FluxCD will attempt to fix a failed installation even if the HelmRelease spec hasn't changed.

**Upgrade failures** do not retry automatically (`retries: 0`). This conservative approach prevents FluxCD from repeatedly attempting a broken upgrade. When an upgrade fails, FluxCD marks the HelmRelease as failed and waits for manual intervention. You must either fix the issue in Git and push a new commit, or manually trigger reconciliation with `flux reconcile helmrelease <name>`.

This asymmetry exists because install failures are often transient (cluster not ready, network issues), while upgrade failures usually indicate a real problem (incompatible values, breaking changes, resource conflicts) that requires human judgment.

## Why This Pattern Works

The source → kustomization → helmrelease flow provides several benefits:

**Separation of concerns** - Source controller handles Git operations, kustomize controller handles manifest application, helm controller handles Helm-specific logic. Each controller does one thing well.

**Dependency management** - The `dependsOn` field creates an explicit dependency graph. Services that require CRDs wait for the CRD controller to be ready. Services that need secrets wait for secret creation.

**Declarative configuration** - Everything is a Kubernetes resource. You can inspect the state with `kubectl get gitrepository,kustomization,helmrelease -A`. You can debug issues by checking resource status and events.

**Auditability** - Every change goes through Git. You can see who changed what, when, and why. You can revert changes by reverting commits.

**Consistency** - FluxCD ensures the cluster matches Git. Manual changes are corrected. Configuration drift is eliminated.

## Trade-offs and Limitations

GitOps with FluxCD is not without constraints:

**Reconciliation delay** - Changes take up to 20 minutes to fully propagate (15 minutes for source sync + 5 minutes for kustomization/helmrelease reconciliation). You can force immediate reconciliation with `flux reconcile`, but the default intervals mean changes are not instant.

**Complexity** - The three-layer architecture (GitRepository → Kustomization → HelmRelease) adds indirection. Debugging requires understanding how these resources interact. New users often struggle to understand why changing a file in Git doesn't immediately update the cluster.

**Upgrade conservatism** - The zero-retry policy for upgrades means failed upgrades require manual intervention. This is safer than automatic retries but increases operational burden.

**Secret management overhead** - SOPS encryption adds steps to the workflow. You must encrypt secrets before committing, manage age keys, and ensure FluxCD has the decryption key. This is more secure than plaintext secrets but more complex than storing secrets directly in the cluster.

**Dependency chains** - Long dependency chains slow deployment. If service A depends on B, which depends on C, which depends on D, the entire chain must reconcile sequentially. Each step takes at least one reconciliation interval (5 minutes), so a four-level dependency takes 20+ minutes.

## When GitOps Doesn't Fit

GitOps works well for declarative configuration but has limitations:

**Imperative operations** - Tasks like database migrations, one-time jobs, or manual interventions don't fit the GitOps model. You can't declare "run this migration once" in a way that's safe to reconcile repeatedly.

**Secrets rotation** - Rotating secrets requires updating both Git and external systems (databases, APIs). The GitOps workflow doesn't help with the external coordination.

**Emergency fixes** - In an outage, waiting 20 minutes for GitOps reconciliation may be unacceptable. You may need to apply changes directly with `kubectl` and reconcile with Git later.

**Stateful operations** - Scaling a StatefulSet, draining a node, or cordoning nodes are operational tasks that don't belong in Git. GitOps manages desired state, not operational procedures.

For these cases, openCenter uses a hybrid approach: GitOps for configuration, imperative tools for operations.

## Evidence

This explanation is based on the following repository analysis:

- FluxCD bootstrap and reconciliation patterns: `llms.txt` lines 19-262
- GitRepository configuration: `applications/base/services/cert-manager/kustomization.yaml`
- HelmRelease drift detection: `applications/base/services/cert-manager/helmrelease.yaml`
- GitOps architecture and promotion workflow: `docs/service-standards-and-lifecycle.md` lines 82-174
- Reconciliation intervals and remediation policies: `docs/analysis/S4-FLUXCD-GITOPS.md`
- Dependency management patterns: `docs/analysis/S4-FLUXCD-GITOPS.md` lines 130-165
