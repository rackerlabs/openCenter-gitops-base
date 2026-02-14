# S4: FluxCD / GitOps Wiring Evidence Pack

## Scope Summary

Analyzed FluxCD configuration, GitOps workflows, reconciliation patterns, and operational practices. Focus on:
- Flux resource types and patterns
- Reconciliation intervals and dependencies
- Drift detection and remediation
- Secret management with SOPS
- Promotion workflows
- Failure modes and recovery

## Evidence Index

**Primary Sources:**
1. `llms.txt` - Flux bootstrap and patterns (lines 19-262)
2. `docs/service-standards-and-lifecycle.md` - GitOps architecture (lines 82-174)
3. `applications/base/services/cert-manager/helmrelease.yaml`
4. `applications/base/services/cert-manager/kustomization.yaml`
5. `docs/onboarding-service-overlay.md`

## Repo-Derived Facts

### Flux Version
**Evidence:** Bootstrap command specifies version
- **Citation:** `llms.txt` line 24
- **Version:** FluxCD v2.7.0
- **Installation:** `curl -s https://fluxcd.io/install.sh | sudo FLUX_VERSION=2.7.0 bash`
- **Fact:** Pinned version for reproducibility

### Bootstrap Pattern
**Evidence:** Git-based bootstrap with SSH
- **Citation:** `llms.txt` lines 26-34
- **Command:**
  ```bash
  flux bootstrap git \
    --url=ssh://git@github.com/${GIT_REPO}.git \
    --branch=main \
    --private-key-file=${HOME}/.ssh/${CLUSTER_NAME}_id_ed25519 \
    --path=applications/overlays/${CLUSTER_NAME}
  ```
- **Fact:** Each cluster has dedicated overlay path
- **Authentication:** SSH deploy keys (ed25519)

### GitRepository Pattern
**Evidence:** Base repository access via deploy key
- **Citation:** `llms.txt` lines 37-52
- **Pattern:**
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
- **Fact:** Services reference base repo by tag for stability
- **Interval:** 15-minute sync

### HelmRelease Configuration
**Evidence:** Standard 5-minute reconciliation
- **Citation:** `applications/base/services/cert-manager/helmrelease.yaml`
- **Spec:**
  ```yaml
  interval: 5m
  timeout: 10m
  driftDetection:
    mode: enabled
  install:
    remediation:
      retries: 3
      remediateLastFailure: true
  upgrade:
    remediation:
      retries: 0
      remediateLastFailure: false
  ```
- **Fact:** Drift detection enabled by default
- **Install:** 3 retries with remediation
- **Upgrade:** No auto-remediation (manual intervention)

### Kustomization with Dependencies
**Evidence:** Dependency chain prevents race conditions

- **Citation:** `docs/service-standards-and-lifecycle.md` lines 130-165
- **Pattern:**
  ```yaml
  apiVersion: kustomize.toolkit.fluxcd.io/v1
  kind: Kustomization
  metadata:
    name: cert-manager-certs
  spec:
    dependsOn:
      - name: cert-manager
    interval: 5m
    path: ./infrastructure/cert-manager/certs
    prune: true
    sourceRef:
      kind: GitRepository
      name: platform-config
  ```
- **Fact:** CRD-dependent resources wait for controller readiness
- **Health Checks:** Deployment health verified before dependents

### SOPS Secret Management
**Evidence:** Age encryption with Flux decryption
- **Citation:** `llms.txt` lines 209-262
- **Workflow:**
  1. Generate age keypair: `age-keygen -o ${HOME}/config/sops/age/${CLUSTER_NAME}_keys.txt`
  2. Configure `.sops.yaml` with age public key
  3. Encrypt: `sops -e -i secret.yaml`
  4. Create K8s secret with age key: `kubectl create secret generic sops-age --from-file=age.agekey=...`
  5. Configure Flux Kustomization:
     ```yaml
     spec:
       decryption:
         provider: sops
         secretRef:
           name: sops-age
     ```
- **Fact:** Secrets encrypted at rest in Git, decrypted by Flux

### Values Hierarchy via Secrets
**Evidence:** Three-tier configuration
- **Citation:** `applications/base/services/cert-manager/helmrelease.yaml` lines 28-36
- **Tiers:**
  1. Base (required): Generated from `helm-values/*.yaml` via secretGenerator
  2. Override (optional): Cluster-specific overrides
  3. Enterprise (optional): Enterprise edition values
- **Pattern:**
  ```yaml
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
- **Fact:** Kustomize secretGenerator creates secrets from files

### Promotion Workflow
**Evidence:** Git-based environment promotion
- **Citation:** `docs/service-standards-and-lifecycle.md` lines 166-174
- **Flow:**
  1. Merge to `main` → preview/stage auto-deploy
  2. Validate in-cluster (dashboards, checks, policies)
  3. Promote to prod via release tag or PR
  4. Optional: Flagger for canary analysis
- **Fact:** Git is source of truth; no manual kubectl in prod

### Reconciliation Intervals
**Evidence:** Consistent timing across resources
- **GitRepository:** 15 minutes
- **HelmRelease:** 5 minutes
- **Kustomization:** 5 minutes
- **Citation:** Multiple manifest examples
- **Fact:** Faster reconciliation for app resources vs sources

### Prune Policy
**Evidence:** Automatic cleanup enabled
- **Citation:** `docs/service-standards-and-lifecycle.md` line 158
- **Setting:** `prune: true` on Kustomizations
- **Fact:** Deleted resources in Git are removed from cluster

## Risks & Findings

### HIGH: No Flux Upgrade Strategy Documented
- **Severity:** High
- **Impact:** Flux upgrades may break reconciliation
- **Evidence:** Version pinned to 2.7.0 but no upgrade docs
- **Recommendation:** Document Flux upgrade procedure and testing
- **Effort:** 1-2 days
- **Risk:** Cluster-wide GitOps failure

### HIGH: SOPS Key Loss = Secret Recovery Failure
- **Severity:** High
- **Impact:** Cannot decrypt secrets if age key lost
- **Evidence:** `docs/service-standards-and-lifecycle.md` line 171
- **Root Cause:** Age keys are single point of failure
- **Recommendation:** Backup age keys to secure vault, document recovery
- **Effort:** 4 hours
- **Risk:** Complete secret loss

### MEDIUM: No Flux Monitoring Dashboards
- **Severity:** Medium
- **Impact:** Difficult to detect reconciliation failures
- **Evidence:** No Grafana dashboards for Flux controllers
- **Recommendation:** Add Flux monitoring dashboards
- **Effort:** 1-2 days
- **Risk:** Silent failures, delayed incident detection

### MEDIUM: Upgrade Remediation Disabled
- **Severity:** Medium
- **Impact:** Failed upgrades require manual intervention
- **Evidence:** `helmrelease.yaml` line 21: `retries: 0` for upgrades
- **Root Cause:** Conservative approach to avoid auto-rollback
- **Recommendation:** Document upgrade failure response procedure
- **Effort:** 4 hours
- **Risk:** Extended downtime during upgrades

### LOW: Long Dependency Chains
- **Severity:** Low
- **Impact:** Slow deployment of dependent services
- **Evidence:** `docs/service-standards-and-lifecycle.md` line 172
- **Recommendation:** Break large services into smaller Kustomizations
- **Effort:** Ongoing refactoring
- **Risk:** Deployment delays

### LOW: No Flagger Integration
- **Severity:** Low
- **Impact:** No automated canary deployments
- **Evidence:** Flagger mentioned but not implemented
- **Recommendation:** Implement Flagger for critical services
- **Effort:** 1-2 weeks
- **Risk:** Risky deployments without gradual rollout

## Doc Inputs (Diátaxis-Aware)

### Tutorial Topics
- "Bootstrap Flux on a New Cluster"
- "Deploy Your First Service with GitOps"
- "Encrypt Secrets with SOPS and Age"

### How-to Topics
- "Create GitRepository Source for Base Repo"
- "Configure HelmRelease with Drift Detection"
- "Set Up Kustomization Dependencies"
- "Rotate SOPS Age Keys"
- "Force Reconciliation of Stuck Resources"
- "Troubleshoot Flux Reconciliation Failures"
- "Promote Service from Stage to Production"
- "Roll Back Failed Deployment"

### Reference Topics
- **Flux Resources Reference**
  - GitRepository spec fields
  - HelmRelease spec fields
  - Kustomization spec fields
  - Reconciliation intervals
  - Retry and remediation policies
- **SOPS Configuration Reference**
  - .sops.yaml format
  - Age key generation
  - Encryption/decryption commands
- **Flux CLI Reference**
  - flux bootstrap
  - flux reconcile
  - flux get
  - flux logs

### Explanation Topics
- "GitOps Principles and Benefits"
- "Why Flux Over ArgoCD"
- "Drift Detection and Remediation Strategy"
- "SOPS vs Sealed Secrets vs External Secrets"
- "Promotion Workflow Rationale"

## Unknowns + VERIFY Steps

1. **Flux Controller Resource Limits**
   - **Unknown:** Are Flux controllers resource-constrained?
   - **VERIFY:** Check flux-system namespace deployments
   - **Expected:** CPU/memory limits set

2. **Flux Notification Configuration**
   - **Unknown:** Are Flux alerts configured?
   - **VERIFY:** Check for Provider and Alert CRDs
   - **Expected:** Slack/PagerDuty notifications

3. **Image Automation**
   - **Unknown:** Is Flux image automation used?
   - **VERIFY:** Check for ImageRepository, ImagePolicy CRDs
   - **Expected:** Automated image updates for some services

4. **Flux Multi-Tenancy**
   - **Unknown:** How are tenant namespaces isolated?
   - **VERIFY:** Check for tenant-specific Kustomizations
   - **Expected:** Namespace-scoped service accounts

5. **Flux Upgrade History**
   - **Unknown:** Has Flux been upgraded from earlier versions?
   - **VERIFY:** Check git history for flux-system changes
   - **Expected:** Upgrade notes in commits

## Cross-Cutting Alerts

- **Security:** SOPS key backup critical for DR
- **Reliability:** Flux monitoring gaps may hide failures
- **Operations:** Upgrade procedures need documentation
- **Performance:** Long dependency chains slow deployments
