---
doc_type: tutorial
title: "Getting Started with openCenter-gitops-base"
audience: "Platform engineers new to openCenter"
---

# Getting Started with openCenter-gitops-base

**Purpose:** For platform engineers new to openCenter, shows how to deploy your first platform service (cert-manager) end-to-end using FluxCD GitOps, covering repository structure, configuration, and verification.

## What You'll Accomplish

By the end of this tutorial, you will:
- Understand the openCenter-gitops-base repository structure
- Deploy cert-manager to a Kubernetes cluster using FluxCD
- Verify the deployment is working correctly
- Know where to go next for more advanced tasks

**Time:** 30-45 minutes

## Prerequisites

Before starting, ensure you have:

- **Kubernetes cluster** (v1.28+) with kubectl access
- **FluxCD** (v2.7.0+) installed and bootstrapped on your cluster
- **Git** installed locally
- **SSH access** to GitHub (deploy key configured)
- **Basic knowledge** of:
  - Kubernetes concepts (pods, deployments, namespaces)
  - Git workflows (clone, commit, push)
  - YAML syntax

**Verify your setup:**

```bash
# Check kubectl access
kubectl cluster-info

# Check Flux is installed
flux check

# Verify Flux version
flux version
```

Expected output shows Flux v2.7.0+ and all components ready.

## Step 1: Understand the Repository Structure

The openCenter-gitops-base repository contains platform services deployed via GitOps. Each service follows a consistent pattern.

**Navigate to the cert-manager service:**

```bash
cd applications/base/services/cert-manager/
ls -la
```

You'll see:
- `namespace.yaml` - Creates the cert-manager namespace
- `community/source.yaml` - Defines the Helm chart source
- `helmrelease.yaml` - Configures the deployment
- `helm-values/` - Contains Helm values files
- `kustomization.yaml` - Ties everything together

**Key insight:** Every service in openCenter follows this structure. Once you understand cert-manager, you understand them all.

## Step 2: Examine the HelmRelease Configuration

Open `helmrelease.yaml` and look at the key sections:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  interval: 5m                    # Reconcile every 5 minutes
  timeout: 10m                    # Allow 10 minutes for operations
  driftDetection:
    mode: enabled                 # Detect manual changes
  install:
    remediation:
      retries: 3                  # Retry failed installs 3 times
  chart:
    spec:
      chart: cert-manager
      version: v1.18.2            # Pinned version
      sourceRef:
        kind: HelmRepository
        name: jetstack
  valuesFrom:
    - kind: Secret
      name: cert-manager-values-base
      valuesKey: values.yaml
```

**What this means:**
- FluxCD checks every 5 minutes if cert-manager matches the desired state
- If you manually change something in the cluster, Flux detects it (drift detection)
- Installation failures retry automatically 3 times
- Configuration comes from a Kubernetes Secret (generated from files)

## Step 3: Review the Kustomization

Open `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
    - namespace.yaml
    - community/source.yaml
    - helmrelease.yaml
secretGenerator:
    - name: cert-manager-values-base
      namespace: cert-manager
      files:
        - values.yaml=helm-values/values-v1.18.2.yaml
```

**What this does:**
- Applies namespace, source, and helmrelease in order
- Generates a Secret from `helm-values/values-v1.18.2.yaml`
- The Secret is named `cert-manager-values-base` (referenced in HelmRelease)

**Key insight:** Helm values are stored as files in Git, then converted to Secrets by Kustomize. This keeps configuration version-controlled.

## Step 4: Create a GitRepository Source

FluxCD needs to know where to find the openCenter-gitops-base repository. Create a GitRepository resource in your cluster overlay.

**In your customer cluster repository** (e.g., `customers/1861184-Metro-Bank-PLC/applications/overlays/k8s-sandbox/services/sources/`):

Create `opencenter-cert-manager.yaml`:

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

**Commit and push:**

```bash
git add services/sources/opencenter-cert-manager.yaml
git commit -m "Add cert-manager GitRepository source"
git push
```

**Wait for Flux to reconcile:**

```bash
flux reconcile source git flux-system
```

**Verify the source:**

```bash
kubectl get gitrepository -n flux-system opencenter-cert-manager
```

Expected: `READY` column shows `True`.

## Step 5: Create a Kustomization to Deploy cert-manager

Now tell FluxCD to deploy cert-manager from the base repository.

**In your cluster overlay** (`services/fluxcd/`), create `cert-manager.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: opencenter-cert-manager
  path: applications/base/services/cert-manager
  prune: true
  targetNamespace: cert-manager
  healthChecks:
    - apiVersion: helm.toolkit.fluxcd.io/v2
      kind: HelmRelease
      name: cert-manager
      namespace: cert-manager
```

**Commit and push:**

```bash
git add services/fluxcd/cert-manager.yaml
git commit -m "Deploy cert-manager from base repository"
git push
```

**Trigger reconciliation:**

```bash
flux reconcile kustomization flux-system
```

## Step 6: Watch the Deployment

FluxCD will now deploy cert-manager. Watch the progress:

```bash
# Watch the Kustomization
flux get kustomizations cert-manager

# Watch the HelmRelease
flux get helmreleases -n cert-manager

# Watch pods being created
kubectl get pods -n cert-manager -w
```

**What's happening:**
1. Flux creates the cert-manager namespace
2. Flux creates the HelmRepository source (Jetstack)
3. Flux generates the values Secret from the file
4. Flux creates the HelmRelease
5. Helm-controller installs cert-manager chart
6. Pods start running

This takes 2-5 minutes.

## Step 7: Verify cert-manager is Working

Once pods are running, verify cert-manager is functional:

```bash
# Check all pods are ready
kubectl get pods -n cert-manager

# Check cert-manager webhook is responding
kubectl get validatingwebhookconfigurations cert-manager-webhook

# Check CRDs are installed
kubectl get crds | grep cert-manager
```

Expected output:
- 3 pods running: cert-manager, cert-manager-cainjector, cert-manager-webhook
- Webhook configuration exists
- Multiple CRDs like `certificates.cert-manager.io`, `issuers.cert-manager.io`

**Test certificate issuance:**

Create a test self-signed issuer:

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: test-selfsigned
  namespace: cert-manager
spec:
  selfSigned: {}
EOF
```

Create a test certificate:

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-cert
  namespace: cert-manager
spec:
  secretName: test-cert-tls
  issuerRef:
    name: test-selfsigned
  dnsNames:
    - test.example.com
EOF
```

**Verify the certificate was issued:**

```bash
kubectl get certificate -n cert-manager test-cert
```

Expected: `READY` column shows `True` within 30 seconds.

**Check the secret was created:**

```bash
kubectl get secret -n cert-manager test-cert-tls
```

Expected: Secret exists with `tls.crt` and `tls.key` data.

**Clean up test resources:**

```bash
kubectl delete certificate -n cert-manager test-cert
kubectl delete issuer -n cert-manager test-selfsigned
kubectl delete secret -n cert-manager test-cert-tls
```

## Step 8: Understand What You've Built

Congratulations! You've deployed cert-manager using the openCenter GitOps pattern. Here's what you accomplished:

**GitOps Workflow:**
- Configuration lives in Git (single source of truth)
- FluxCD continuously reconciles cluster state with Git
- Changes are made via Git commits, not kubectl commands
- Drift detection prevents manual changes from persisting

**Three-Tier Architecture:**
- **Base repository** (openCenter-gitops-base): Hardened service configurations
- **Customer overlay**: Cluster-specific customizations
- **FluxCD**: Automated deployment and reconciliation

**Declarative Management:**
- HelmRelease defines desired state
- Flux ensures actual state matches desired state
- Automatic retries on failures
- Health checks verify deployment success

## Check Your Work

Before moving on, verify:

- [ ] GitRepository `opencenter-cert-manager` shows READY=True
- [ ] Kustomization `cert-manager` shows READY=True
- [ ] HelmRelease `cert-manager` shows READY=True
- [ ] All cert-manager pods are Running
- [ ] Test certificate was issued successfully
- [ ] You understand the GitOps workflow

**Troubleshooting:**

If something isn't working:

```bash
# Check Flux logs
flux logs --level=error

# Check specific resource status
flux get sources git
flux get kustomizations
flux get helmreleases -A

# Describe resources for details
kubectl describe gitrepository -n flux-system opencenter-cert-manager
kubectl describe kustomization -n flux-system cert-manager
kubectl describe helmrelease -n cert-manager cert-manager
```

## Next Steps

Now that you've deployed your first service, explore these topics:

**Customize Configuration:**
- [Configure Helm Values](../how-to/configure-helm-values.md) - Override base values for your cluster
- [Manage Secrets with SOPS](../how-to/manage-secrets.md) - Encrypt sensitive configuration

**Deploy More Services:**
- [Add a New Service](../how-to/add-new-service.md) - Deploy additional platform services
- [Service Catalog](../reference/service-catalog.md) - Browse available services

**Advanced Topics:**
- [Configure Gateway API](../how-to/configure-gateway.md) - Set up ingress routing
- [Setup Observability](../how-to/setup-observability.md) - Deploy monitoring stack
- [Troubleshoot Flux](../how-to/troubleshoot-flux.md) - Debug reconciliation issues

**Understand the Architecture:**
- [GitOps Workflow](../explanation/gitops-workflow.md) - How FluxCD manages deployments
- [Three-Tier Values](../explanation/three-tier-values.md) - Why we use this pattern
- [Architecture Overview](../explanation/architecture.md) - System design decisions

## Evidence

This tutorial is based on:
- `applications/base/services/cert-manager/helmrelease.yaml` - HelmRelease configuration
- `applications/base/services/cert-manager/kustomization.yaml` - Kustomize pattern
- `docs/analysis/S4-FLUXCD-GITOPS.md` - FluxCD workflow analysis
- `docs/analysis/S1-APP-RUNTIME-APIS.md` - Service deployment patterns
- `docs/analysis/B-DOCUMENTATION-PLAN.md` - Tutorial structure guidance
