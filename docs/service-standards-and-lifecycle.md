---
id: service-standards-and-lifecycle
title: Service Standards & Lifecycle
sidebar_label: Service Standards and Lifecycle
description: Unified standards for adding, operating, and retiring services in the openCenter platform.
tags: [developer, operators, service, standards, lifecycle]
audience: [Developer, Operations]
---

# Service Standards & Lifecycle

> **Purpose.** Provide a single, authoritative standard for adding, operating, and retiring services in the openCenter platform. Covers requirements, risk, Flux GitOps architecture, scheduling, labels, testing, observability, troubleshooting, lifecycle gates, and supporting infrastructure.
>
> **Scope.** Applies to any service (cluster-level add-on or tenant-facing workload) delivered by openCenter across Kubernetes on OpenStack and other targets.

---

## 0) Service Intake Workflow

1. **Intake Request:** Submit a service RFC and draft ADR covering business value, risk appetite, data classification, and target tenants.
2. **Architecture Review:** Architect reviews Flux topology, placement rules, compliance mappings, and enabling infrastructure requirements; gaps move to §9.
3. **Prototype in Dev:** Developer produces manifests, pipelines, and automation in a dev cluster; technical writer builds initial docs bundle (§6.1).
4. **Operational Review:** Engineer validates SLOs, runbooks, observability, and failure modes; compliance confirms regulatory evidence.
5. **Stage Decision:** Feedback loop resolves findings; lifecycle stage set per §8 with exit criteria, risk score (§2), and owner sign-off recorded in Git.

---

## 1) Service Requirements (Authoritative Checklist)

A service MUST meet all **Production** requirements before it can be labeled `stage=production`. Services in **Preview** must meet the Preview subset and have an approved exit plan.

### 1.1 Functional & Delivery

* [ ] **Open Source (where applicable):** License is OSI-approved; SPDX identifier documented.
* [ ] **Supported Architectures/OS:** AMD64; (optional) ARM64; Talos Linux compatibility noted.
* [ ] **Install Method:** Helm chart or Kustomize; CRDs versioned; default values hardened.
* [ ] **Runtime Contracts:** Health endpoints, readiness, liveness; documented ports and protocols.
* [ ] **Upgrade Path:** Zero/low-downtime strategy; CRD conversion webhooks if needed; rollback tested.
* [ ] **Multi-tenancy:** Namespacing/RBAC model documented; resource quotas; isolation guarantees.
* [ ] **Dependencies:** Explicit `dependsOn` in Flux; images are pinned (digest or immutable tags).

### 1.2 Security & Compliance (Minimum)

* [ ] **SBOM & Image Policy:** SBOM available; images scanned (CVE budget defined); signature verification (Cosign) enforced.
* [ ] **Pod Security:** PSS `restricted` or justified exceptions; rootless where possible; read-only FS; drop capabilities.
* [ ] **Network Policy:** Default-deny egress/ingress with least privilege rules.
* [ ] **Secrets:** SOPS-encrypted or external secret store; no plaintext in Git.
* [ ] **Auditability:** Kubernetes Events/Logs preserved; change history via Git.
* [ ] **Compliance Mapping:** Controls mapped to ISO 27001 / SOC 2 / NIST 800-53 (relevant subset) with evidence pointers.

### 1.3 Observability (Minimum)

* [ ] **Metrics:** Prometheus scrape targets; RED/USE metrics; service-level SLI: availability, latency, error rate.
* [ ] **Logs:** Structured logs (JSON); correlation IDs.
* [ ] **Traces:** OpenTelemetry OTLP exporter (where feasible).
* [ ] **Dashboards:** Grafana dashboard JSON in repo; alert rules with actionable runbooks.

### 1.4 Operations & Support

* [ ] **Documentation:** `README.md`, `OPERATIONS.md`, `TROUBLESHOOTING.md`, `UPGRADES.md` shipped with chart.
* [ ] **Runbooks:** Standard incidents (degraded perf, crashloop, datastore issues) with step-by-step actions.
* [ ] **SLOs:** Availability & latency targets with burn-rate alerts.
* [ ] **Backups/DR:** What state exists; backup/restore test plan; RPO/RTO labels set on workloads.
* [ ] **Support Model:** On-call ownership; escalation path; vendor/community channels.

### 1.5 Implementation Guidance

- **Open Source Alignment:** Favor OSS components to preserve transparency and avoid lock-in. Proprietary dependencies require explicit support contracts and documented exit plans.
- **Support & Ownership:** Record the accountable team, on-call rotation, and escalation paths in the service catalog and runbooks. Preview services still need a named owner.
- **Observability Baseline:** Instrument metrics, logs, and traces during the first iteration. Provision default dashboards and alerts before promoting to production.
- **Automated Deployments:** Ship container images and GitOps manifests that work for preview and production with environment-specific overlays only. Keep install commands repeatable (`helm install`, `flux reconcile`, etc.).
- **Promotion Workflow:** Treat Git as the control plane. Flux watches main for preview; promotion to production happens via PR, tag, or branch change with explicit reviewer approval.

#### Sample Compliance Manifest

```yaml
service_name: payments-api
stage: preview
open_source: true
support:
  team: FinTech Team
  on_call: fintech-rotation
observability:
  metrics_endpoint: /metrics
  logging: structured-json
  tracing: enabled
deployment:
  method: HelmChart
  chart_repository: https://repo.example.com/charts
```

#### Common Pitfalls

- Treating checklists as paperwork instead of verifying dashboards, alerts, and runbooks exist.
- Enforcing a single deployment mechanism without exemptions for complex workloads.
- Underestimating instrumentation effort and deferring logs/metrics until late in delivery.
- Requiring 24/7 support for low-tier preview services without staffing the rotation.

---

## 2) Project Risk Assessment (Per Service)

Create `RISK.md` capturing the following. Compute a weighted score to determine adoption tier.

| Factor                 | Measure                                      | Scale | Notes                  |
| ---------------------- | -------------------------------------------- | ----- | ---------------------- |
| **Project Age**        | First commit / release cadence               | 1–5   | 1=new, 5=mature        |
| **Maintainer Type**    | Individual / foundation / company            | 1–5   | Foundation≥4           |
| **Bus Factor**         | Active maintainers in last 90d               | 1–5   | ≥5 maintainers = 5     |
| **Community Adoption** | Stars, downloads, CNCF level, distro usage   | 1–5   | CNCF Graduated = 5     |
| **Security Posture**   | CVE response time, sigstore use, security.md | 1–5   |                        |
| **Roadmap & Velocity** | Issues closed / release frequency            | 1–5   |                        |
| **License Risk**       | Copyleft obligations, CLA status             | 1–5   | Permissive=5           |
| **Ops Complexity**     | Statefulness, CRD count, tuning              | 1–5   | Simpler = higher score |

**Risk Score =** Σ(weightᵢ×scoreᵢ) / Σ(weightᵢ). Document weights and thresholds:

* **Adopt (Green):** ≥4.0
* **Caution (Amber):** 3.0–3.99 (Preview only)
* **Avoid (Red):** <3.0 unless exception ADR approved

Record additionally: project age, maintainer structure, support signals, release cadence, known critical issues, and any compensating controls.

---

## 3) Flux Architecture (Platform-Standard)

### 3.1 Git Layout (Mono-repo example)

```
repo/
├─ clusters/
│  ├─ prod/ (cluster-level Kustomizations)
│  └─ stage/
├─ apps/
│  ├─ <service-A>/
│  │  ├─ helmrelease.yaml
│  │  ├─ kustomization.yaml
│  │  └─ values/ (env overlays)
│  └─ <service-B>/
├─ infra/ (ingress, certs, storage classes, cni)
└─ policies/ (Kyverno/OPA, PSS, image-verify)
```

### 3.2 Principles

- **Self-contained services:** Each service folder is independently deployable; owns its values, dashboards, alerts, policies, and tests.
- **Immutability:** Use image digests; Git is the source of truth; no manual `kubectl` in prod.
- **Promotion via PR:** Environment overlays (dev→stage→prod) with `kustomize` patches.
- **Dependencies:** Use `HelmRelease.spec.dependsOn` or Flux `Kustomization.dependsOn`.
- **Secrets:** `sops` with age or KMS; no unencrypted secrets in Git.
- **Verification:** Pre-merge `kubectl kustomize` + `kubeconform` + policy checks in CI.

### 3.3 Example `HelmRelease`

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: tempo
  labels:
    app.kubernetes.io/name: tempo
    app.kubernetes.io/part-of: observability
spec:
  interval: 5m
  chart:
    spec:
      chart: tempo
      version: 1.2.3
      sourceRef:
        kind: HelmRepository
        name: grafana
  install:
    remediation:
      retries: 3
  upgrade:
    remediation:
      retries: 3
  dependsOn:
    - name: loki
  valuesFrom:
    - kind: Secret
      name: tempo-values
```

### 3.4 Sample Kustomization Chain

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager
  namespace: flux-system
spec:
  interval: 5m
  path: ./infrastructure/cert-manager/controller
  prune: true
  sourceRef:
    kind: GitRepository
    name: platform-config
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: cert-manager
      namespace: cert-manager
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager-certs
  namespace: flux-system
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

This pattern prevents race conditions by ensuring dependent workloads (e.g., certificate custom resources) apply only after the controller and CRDs become healthy.

### 3.5 Secrets Management

- Encrypt every Kubernetes `Secret` manifest with SOPS. Store keys in-cluster (e.g., `Secret/sops-keys`) referencing cloud KMS or GPG.
- Configure Flux decryption per Kustomization:

  ```yaml
  spec:
    decryption:
      provider: sops
      secretRef:
        name: sops-keys
  ```

- Alternative: Bitnami SealedSecrets, but SOPS keeps Flux as the single reconciling component.
- Never require manual secret injection for platform environments; automation must manage rotations.

### 3.6 Promotion Workflow

1. Merge to `main` updates preview/stage overlays automatically.
2. Validate in-cluster via dashboards, synthetic checks, and policy reports.
3. Promote to production via release tag or PR against production overlays.
4. Optionally integrate Flagger for canary analysis before full rollout.

### 3.7 Common Risks

- Additional expertise required to debug Flux reconciliation issues and dependency chains.
- Long dependency chains slow delivery; break large services into smaller Kustomizations.
- SOPS key loss blocks secret recovery—treat keys as tier-0 assets with backups and audit logging.
- Mono-repo merge pressure: invest in lint bots and pre-commit to avoid drift and conflicts.

---

## 4) Toleration & Node Selection Strategy

### 4.1 Definitions

- **Node Taints (supply-side):**
  - `workload=system:NoSchedule` (platform add-ons)
  - `workload=app:NoSchedule` (tenant apps)
  - `class=gpu:NoSchedule`, `class=spot:NoSchedule`, `class=storage:NoSchedule`
  - `zone=<az>:NoSchedule` when pinning to failure domains
- **Selectors/Affinity (demand-side):** Workloads declare `nodeSelector`/`nodeAffinity` to match intended pools.

### 4.2 Policy

- Platform services MUST tolerate `workload=system` and select nodes with `nodeSelector: {workload: system}`.
- Tenant services MUST NOT schedule on system nodes.
- GPU workloads require `tolerations` for `class=gpu` and `nodeSelector: {class: gpu}`.
- Spot workloads MUST be interrupt-tolerant and have PDBs and HPA tuned.

### 4.3 Example Manifest

```yaml
spec:
  tolerations:
    - key: workload
      operator: Equal
      value: system
      effect: NoSchedule
  nodeSelector:
    workload: system
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: class
                operator: In
                values: ["storage"]
```

### 4.4 Discovery

- Inventory current taints/labels: `kubectl get nodes -o json | jq '.items[] | {name:.metadata.name, taints:.spec.taints, labels:.metadata.labels}'`
- Detect workloads lacking placement rules: `kubectl get deploy -A -o=jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name} {end}'`
- Report exceptions with a script or Policy Report (Kyverno).

### 4.5 Test (Policy-as-Code)

- Kyverno rule: require toleration/selector by namespace label `purpose=platform`.
- Conftest/Rego tests in CI against rendered manifests.

### 4.6 ADR

Create `adr/00NN-scheduling-policy.md` documenting rationale, alternatives (e.g., only affinity), and consequences.

---

## 5) Label Policy for Services

### 5.1 Required Labels (Kubernetes-recommended + openCenter)

- `app.kubernetes.io/name`
- `app.kubernetes.io/instance`
- `app.kubernetes.io/version`
- `app.kubernetes.io/component`
- `app.kubernetes.io/part-of`
- `app.kubernetes.io/managed-by` (must be `fluxcd`)
- `opencenter.io/owner` (team or email)
- `opencenter.io/tier` (platform|shared|tenant)
- `opencenter.io/data-sensitivity` (public|internal|confidential|restricted)
- `opencenter.io/rto` (e.g., `4h`), `opencenter.io/rpo` (e.g., `1h`)
- `opencenter.io/sla` (e.g., `99.9`)
- `opencenter.io/backup-profile` (none|daily|hourly)

**Rule:** Every Pod/Deployment/StatefulSet/Job must carry these labels (directly or via template metadata).

### 5.2 Example Deployment Labels

```yaml
metadata:
  labels:
    app.kubernetes.io/name: loki
    app.kubernetes.io/instance: loki-prod
    app.kubernetes.io/version: "3.1.0"
    app.kubernetes.io/component: indexing
    app.kubernetes.io/part-of: observability
    app.kubernetes.io/managed-by: fluxcd
    opencenter.io/owner: sre@opencenter.io
    opencenter.io/tier: platform
    opencenter.io/data-sensitivity: internal
    opencenter.io/rto: 4h
    opencenter.io/rpo: 1h
    opencenter.io/sla: "99.9"
    opencenter.io/backup-profile: daily
```

### 5.3 Enforcement Patterns

- Scaffold new services with required labels to minimize manual edits.
- Enforce via policy-as-code. Example Gatekeeper constraint:

  ```yaml
  apiVersion: constraints.gatekeeper.sh/v1beta1
  kind: K8sRequiredLabels
  metadata:
    name: require-core-labels
  spec:
    match:
      kinds:
        - apiGroups: ["apps"]
          kinds: ["Deployment"]
        - apiGroups: [""]
          kinds: ["Service"]
    parameters:
      labels: ["app.kubernetes.io/name", "opencenter.io/owner"]
  ```

- Mirror enforcement in CI to catch issues before hitting the cluster.

### 5.4 Discovery & Reporting

- `kubectl get deploy -A -o json | jq '.. | objects | select(has("labels")) | .metadata.labels'`
- Generate Kyverno `PolicyReport`s to highlight non-compliant workloads.

### 5.5 Common Pitfalls

- Third-party charts lacking required labels—use Kustomize patches or exemptions with documented justification.
- Policy webhook outages blocking deployments—run Gatekeeper highly available and monitor latency.
- Adding new required labels without a migration plan; sequence changes to avoid blocking redeployments.

---

## 6) Production Service Requirements (Detailed)

### 6.1 Documentation Bundle

- `README.md` (what/why), `VALUES.md` (config matrix), `OPERATIONS.md`, `TROUBLESHOOTING.md`, `SLO.md`.
- Example diagrams (Mermaid) for data flow.

### 6.2 Product Lifecycle

- State the current **Stage** (Preview, Production, Deprecated, Retired), with target dates.
- Define EOL policy and security-fix windows.

### 6.3 Installation & Upgrades

- Helm chart with defaults hardened; example overlays for dev/stage/prod.
- Pre-flight checks (CRDs present, storage classes, ingress, quotas).

### 6.4 Support

- Ownership, escalation path, office hours; upstream issue links.
- Severity matrix and SLAs.

### 6.5 Observability (Minimum)

- Prometheus rules (availability, saturation, errors) and prebuilt Grafana dashboards.
- Log retention and index cost guidance.
- Synthetic checks (blackbox exporter) for critical endpoints.

### 6.6 Troubleshooting

- Symptom→Cause→Resolution tables; `kubectl` and `flux` commands; rollback playbooks.

### 6.7 Operational Readiness Review

- Run ORR checklist jointly with SRE, Support, Security, and Compliance.
- Verify incident response contacts, PagerDuty rotations, escalation timers, and vendor SLAs.
- Confirm observability dashboards, alerts, and runbooks are discoverable in central catalog.
- Capture unresolved actions as Git issues with owners and target stages for closure.

### 6.8 Resiliency & Chaos Engineering

- Document failure domains (zone, region, dependency) and expected blast radius.
- Schedule chaos drills (pod delete, node drain, dependency outage) at least once per release.
- Track recovery metrics (MTTR, data loss) against RTO/RPO labels; feed lessons into ADR updates.

---

## 7) Preview Service Requirements

- Meets security baseline; lower SLO; **opt-in only**.
- Marked with `opencenter.io/stage=preview` label.
- Telemetry enabled (§10.2) to measure adoption.
- Explicit success criteria and a 90-day decision window (graduate or retire).

---

## 8) Service Lifecycle (Gates & Criteria)

**Stages:** `incubating → preview → production → deprecated → retired`

| Stage      | Entry Criteria                                     | Exit Criteria                                    |
| ---------- | -------------------------------------------------- | ------------------------------------------------ |
| Incubating | ADR approved; risk ≤ Amber; PoC passes CI          | Deployed to dev; basic SLOs defined              |
| Preview    | Dev+stage deployments; runbooks; observability min | ≥2 real tenants; incident review; risk Green     |
| Production | All requirements in §1 met; DR tested              | Deprecation notice issued when replacement ready |
| Deprecated | Replacement path; support window set               | Retired                                          |
| Retired    | Artifacts archived; images yanked                  | n/a                                              |

**Deliverables by Stage:**
- **Incubating:** ADR, risk score, proto manifests, draft docs bundle, sandbox cost estimate.
- **Preview:** Stage cluster deployment, burn-in test report, partial runbooks, customer comms template.
- **Production:** Signed ORR, chaos drill evidence, DR test report, compliance control mapping, final docs.
- **Deprecated:** Deprecation notice, migration plan, support sunset schedule.
- **Retired:** Postmortem of retirement, archive location for artifacts, removal PR merged.

**Change Control:** All stage changes via ADR with owner + date.

---

## 9) What Infrastructure Is Missing (Gaps & Recommendations)

### 9.1 openCenter CLI

- Purpose: bootstrap clusters, scaffold services, enforce policy (labels, tolerations), lint manifests, generate ADRs.
- Commands: `opencenter init`, `opencenter svc create`, `opencenter policy lint`, `opencenter risk score`, `opencenter adr new`.
- Packaging: static Go binary; supply `mise` tasks; integrate Cosign.

### 9.2 Telemetry Service (OSS Usage)

- Privacy-first, opt-in. Collect anonymous metrics: service name, version, stage, cluster size, feature flags.
- Transport via OTLP/http or HTTPS; buffer offline; exponential backoff.
- Governance: public metrics schema; disable flag; data retention ≤ 90 days.

### 9.3 Entitlement-Aware Registry

- Use Harbor/Quay with OIDC; project-scoped robot tokens; per-tenant repos.
- Enforce image signing; replication to edge.
- API hook to validate entitlements before pull (token claims `plan`, `expires_at`).

### 9.4 Observability Backbone

- Managed Prometheus stack with long-term remote write (Mimir/Thanos) and Grafana multi-tenant dashboards.
- Tempo/Jaeger tracing pipeline with tenant segregation and sampling policies.
- Loki or Elastic for logs with retention tiers, index lifecycle automation, and cost guardrails.
- Alert routing via Alertmanager to on-call rotations, Slack, and ticketing integrations.

### 9.5 Policy & Security Automation

- Central Kyverno/OPA bundle published as Helm chart; services import policies as dependencies.
- Image signing service with Cosign key management (KMS/PKI) and Rekor transparency log mirroring.
- Pipeline library (`.github/workflows`/`pipelines/`) providing reusable lint/test stages and compliance attestation generation.
- Evidence store (GCS/S3) retaining SBOMs, scan results, and audit logs per release.

---

## 10) Testing & Verification Pipeline (CI/CD)

1. **Render:** `kustomize build` → YAML.
2. **Validate:** `kubeconform` (strict), `helm lint`.
3. **Policy:** Kyverno/OPA (labels, tolerations, PSS, signatures).
4. **Security:** Trivy image scan; Cosign verify.
5. **DRY-RUN:** `kubectl apply --server-dry-run`.
6. **E2E Smoke:** Kind/Talos test cluster; probes; synthetic checks.
7. **Promotion:** Tag + PR to next environment overlay.

### 10.1 Implementation Notes

- **Shift-left testing:** Run unit/integration tests and static analysis on every commit; block merges that drop coverage or introduce lint errors.
- **Preview environments:** Automate ephemeral namespaces/clusters per PR to unblock parallel validation and user acceptance.
- **Security gates:** Integrate SAST, dependency scanning, and container image scanning; fail on critical CVEs.
- **Progressive delivery:** Use Flagger/Argo Rollouts for canaries or blue/green transitions with automated rollback triggers.
- **Pipeline-as-code:** Keep CI definitions under version control; offer shared templates so every service inherits the same gates.

### 10.2 Example Pipeline Outline

```yaml
stages:
  - install
  - lint
  - test
  - security
  - build
  - deploy_preview
  - deploy_prod

install:
  script:
    - pnpm install

lint:
  script:
    - pnpm lint
    - pnpm prettier:check

test:
  script:
    - pnpm test --filter unit
    - pnpm test --filter integration
  coverage: 80

security:
  script:
    - pnpm exec trivy fs --exit-code 1 .
    - pnpm exec trivy image --exit-code 1 registry.example.com/opencenter/service:${CI_COMMIT_SHA}

build:
  script:
    - docker build -t registry.example.com/opencenter/service:${CI_COMMIT_SHA} .
    - docker push registry.example.com/opencenter/service:${CI_COMMIT_SHA}
  only: [main, tags]

deploy_preview:
  script:
    - flux reconcile kustomization service-preview --with-source
  when: on_success
  only: [main]

deploy_prod:
  script:
    - flux reconcile kustomization service-prod --with-source
    - ./scripts/run-smoke-tests.sh
  when: manual
  environment:
    name: production
```

### 10.3 Common Pitfalls

- Flaky integration tests delaying releases—invest in deterministic test data and test harnesses.
- Expanding pipeline stages without optimizing runtime; parallelize where practical.
- Policy enforcement absent from CI, causing drift between environments and Flux errors on apply.
- Preview environments consuming excessive resources; implement TTL controllers and quotas.

---

## 11) Standard ADR Template

```
# ADR NN: <Title>

- **Status:** Proposed | Accepted | Superseded | Rejected
- **Date:** YYYY-MM-DD
- **Owners:** <team/people>
- **Context**
  - Problem, constraints, stakeholders, risks
- **Decision**
  - What we chose and why (with trade-offs)
- **Options Considered**
  - Option A (pros/cons)
  - Option B (pros/cons)
- **Consequences**
  - Operational, security, cost, UX
- **Related**
  - Links to issues, PRs, RFCs
```

### 11.1 Usage Guidance

- Focus ADRs on architecturally significant decisions (one-way doors, cross-team impacts, tooling choices).
- Draft ADRs early so peers can comment during design reviews; mark status when accepted or superseded.
- Reference ADR IDs in PR descriptions, runbooks, and onboarding docs to link decisions to implementation.

### 11.2 Sample ADR

```
# ADR-001: Use Redis for Session Caching

- **Status:** Accepted (2025-09-29)
- **Context:** Need a distributed cache for user sessions. Options: in-process cache, Redis, Memcached.
- **Decision:** Adopt Redis for session storage to balance latency, HA, and operations.
- **Consequences:**
  - Redis offers clustering, persistence, and managed service support.
  - Adds external dependency; services must handle cache outages gracefully.
- **Alternatives:** In-process cache (lacked cross-instance coherence); Memcached (no persistence, fewer data structures).
```

### 11.3 Operational Tips

- Maintain an index file listing ADR numbers, titles, and status for quick discovery.
- Review ADRs during quarterly architecture retrospectives to retire outdated decisions.
- Automate ADR scaffolding (`opencenter adr new`) to lower friction and maintain consistent formatting.

---

## 12) Appendices

### 12.1 Example Kyverno Policies

- **Require Labels:** enforce keys from §5.1.
- **Require Scheduling:** enforce tolerations/selectors by namespace purpose.
- **Verify Images:** require Cosign signatures for `opencenter.io/tier=platform`.

### 12.2 Example Grafana/Alerting Bundles

- Ship as JSON under `apps/<svc>/dashboards/` and `alerts/`.

### 12.3 Glossary

- **Service:** Any deployable unit owned by platform with SLOs.
- **Preview:** Opt-in, limited-support stage used to validate value and risk.

### 12.4 Reference Tools & Templates

- `adr/decisions/0001-record-architecture-decisions.md` – exemplar ADR capturing format and governance expectations.
- `docs/gitops/05-workflows-pr-environments.md` – detailed promotion workflow backing §§3 and 10.
- `docs/operations/observability.md` – platform observability standards referenced in §§1.3 and 6.5.
- `docs/operations/runbooks.md` – shared runbook structure aligned with §§1.4 and 6.6.
