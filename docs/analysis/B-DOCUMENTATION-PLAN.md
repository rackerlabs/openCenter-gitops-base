# Diátaxis Documentation Generation Plan

**Analysis Date:** 2026-02-14  
**Framework:** Diátaxis (Tutorials, How-to, Reference, Explanation)  
**Approach:** Evidence-driven documentation from repository analysis

---

## B0) Repo-Derived Documentation Facts Inventory

### Build/Toolchains
**Evidence:** S2

- **Language:** Go (migration tools in `tools/kustomize-migration/`)
- **Package Manager:** Go modules
- **Linting:** yamllint, ansible-lint, shellcheck, black (Python)
- **Pre-commit:** Conventional commits, YAML validation, formatting
- **CI/CD:** GitHub Actions (self-hosted runner)
- **Testing:** None found (gap)

---

### Entry Points
**Evidence:** S1, S5

- **HTTPS (443):** Envoy Gateway → Services
- **SSH (22):** FluxCD Git access
- **Kubernetes API (6443):** kubectl access
- **Grafana UI:** Observability dashboards
- **Keycloak UI:** Identity management

---

### Ports/Routes
**Evidence:** S5, S6

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Envoy Gateway | 443 | HTTPS | Ingress |
| Grafana | 3000 | HTTP | Dashboards |
| Prometheus | 9090 | HTTP | Metrics |
| Alertmanager | 9093 | HTTP | Alerts |
| Loki | 3100 | HTTP | Logs |
| Tempo | 3200 | HTTP | Traces |
| Keycloak | 8080 | HTTP | IAM |

---

### Config Surfaces
**Evidence:** S1, S4

**HelmRelease Configuration:**
- `interval`: Reconciliation frequency (5m)
- `timeout`: Operation timeout (10m)
- `driftDetection.mode`: enabled
- `install.remediation.retries`: 3
- `upgrade.remediation.retries`: 0
- `valuesFrom`: Three-tier values (base, override, enterprise)

**Kustomization Configuration:**
- `resources`: Base manifests
- `components`: Enterprise components
- `secretGenerator`: Helm values from files
- `namespace`: Target namespace

**SOPS Configuration (.sops.yaml):**
- `creation_rules`: Encryption rules
- `age`: Public key for encryption
- `encrypted_regex`: Fields to encrypt

---

### Deployment Surfaces
**Evidence:** S1, S4

**FluxCD Resources:**
- GitRepository: Source repositories
- HelmRepository: Helm chart sources
- HelmRelease: Service deployments
- Kustomization: Manifest application

**Deployment Pattern:**
```
GitRepository → HelmRelease → Helm Chart → Kubernetes Resources
```

---

### Flux Wiring
**Evidence:** S4

**Bootstrap:**
```bash
flux bootstrap git \
  --url=ssh://git@github.com/${GIT_REPO}.git \
  --branch=main \
  --private-key-file=${HOME}/.ssh/${CLUSTER_NAME}_id_ed25519 \
  --path=applications/overlays/${CLUSTER_NAME}
```

**GitRepository Pattern:**
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

**Kustomization Pattern:**
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

---

### Gateway Surfaces
**Evidence:** S5

**Gateway API Resources:**
- Gateway: Entry point configuration
- HTTPRoute: Routing rules
- ReferenceGrant: Cross-namespace references

**Cert-Manager Integration:**
```yaml
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - example.com
    secretName: example-tls
```

---

### Observability
**Evidence:** S6

**Metrics:**
- Prometheus scraping via ServiceMonitor/PodMonitor
- RED/USE metrics required
- Remote write to Mimir for long-term storage

**Logs:**
- Loki ingestion via OpenTelemetry OTLP
- Structured JSON logs required
- LogQL for querying

**Traces:**
- Tempo ingestion via OpenTelemetry OTLP
- TraceQL for querying
- Distributed tracing across services

**Dashboards:**
- Grafana for visualization
- Dashboard JSON in Git (gap)
- Preconfigured infrastructure dashboards

---

### Security Controls
**Evidence:** S7

**Secret Management:**
- SOPS with age encryption
- Sealed Secrets (alternative)
- No plaintext secrets in Git

**Policy Enforcement:**
- Kyverno for validation, mutation, generation
- Pod Security Admission (not configured)
- Network Policies (not implemented)

**Authentication:**
- Keycloak for OIDC
- RBAC Manager for access control

**Supply Chain:**
- Image scanning (not integrated)
- Signature verification (not configured)
- SBOM generation (not implemented)

---



## B1) Proposed Diátaxis Documentation Map

| Path | Type | Audience | Goal | Prerequisites | Evidence |
|------|------|----------|------|---------------|----------|
| `docs/index.md` | Overview | All | Understand repo purpose, structure, and navigation | None | S1, S4, ecosystem.md |
| `docs/tutorials/getting-started.md` | Tutorial | New users | Deploy first service end-to-end | Git, kubectl, flux CLI | S4, S1 |
| `docs/how-to/add-new-service.md` | How-to | Platform engineers | Add a new platform service | Tutorial complete | S1, S4 |
| `docs/how-to/configure-helm-values.md` | How-to | Platform engineers | Customize service configuration | Basic Helm knowledge | S1 |
| `docs/how-to/manage-secrets.md` | How-to | Platform engineers | Encrypt/decrypt secrets with SOPS | SOPS installed | S7 |
| `docs/how-to/migrate-to-components.md` | How-to | Platform engineers | Migrate service to Kustomize components | Kustomize knowledge | S2 |
| `docs/how-to/configure-gateway.md` | How-to | Platform engineers | Configure Gateway API routing | Gateway API basics | S5 |
| `docs/how-to/setup-observability.md` | How-to | Platform engineers | Configure metrics/logs/traces | Prometheus/Grafana basics | S6 |
| `docs/how-to/troubleshoot-flux.md` | How-to | Platform engineers | Debug FluxCD reconciliation issues | FluxCD basics | S4 |
| `docs/how-to/update-service-version.md` | How-to | Platform engineers | Upgrade a service version | None | S1, S4 |
| `docs/reference/directory-structure.md` | Reference | All | Understand repository layout | None | S1, S4 |
| `docs/reference/helm-values-schema.md` | Reference | Platform engineers | HelmRelease configuration options | None | S1 |
| `docs/reference/flux-resources.md` | Reference | Platform engineers | FluxCD resource specifications | None | S4 |
| `docs/reference/service-catalog.md` | Reference | All | Available platform services | None | S1 |
| `docs/reference/kustomize-patterns.md` | Reference | Platform engineers | Kustomization patterns used | None | S1, S4 |
| `docs/reference/sops-configuration.md` | Reference | Platform engineers | SOPS encryption rules | None | S7 |
| `docs/explanation/architecture.md` | Explanation | Architects | System design and decisions | None | S1-S8, A-CODE-REVIEW |
| `docs/explanation/gitops-workflow.md` | Explanation | All | How GitOps works in openCenter | None | S4 |
| `docs/explanation/three-tier-values.md` | Explanation | Platform engineers | Why three-tier Helm values | None | S1 |
| `docs/explanation/enterprise-components.md` | Explanation | Platform engineers | Enterprise vs community editions | None | S1 |
| `docs/explanation/security-model.md` | Explanation | Security engineers | Security controls and gaps | None | S7, A-CODE-REVIEW |

---

## B2) Information Architecture Rules

### Documentation Structure

```
docs/
├── index.md                    # Landing page with navigation
├── tutorials/                  # Learning-oriented
│   └── getting-started.md
├── how-to/                     # Task-oriented
│   ├── add-new-service.md
│   ├── configure-helm-values.md
│   ├── manage-secrets.md
│   ├── migrate-to-components.md
│   ├── configure-gateway.md
│   ├── setup-observability.md
│   ├── troubleshoot-flux.md
│   └── update-service-version.md
├── reference/                  # Information-oriented
│   ├── directory-structure.md
│   ├── helm-values-schema.md
│   ├── flux-resources.md
│   ├── service-catalog.md
│   ├── kustomize-patterns.md
│   └── sops-configuration.md
└── explanation/                # Understanding-oriented
    ├── architecture.md
    ├── gitops-workflow.md
    ├── three-tier-values.md
    ├── enterprise-components.md
    └── security-model.md
```

### Naming Conventions

- **Files:** kebab-case (e.g., `getting-started.md`)
- **Headings:** Title Case for H1, Sentence case for H2+
- **Code blocks:** Always specify language (```yaml, ```bash, ```go)
- **Links:** Relative paths from docs root (e.g., `../reference/service-catalog.md`)

### Cross-Linking Rules

1. **Tutorials** link to:
   - Reference pages for detailed specs
   - Explanation pages for concepts
   - How-to guides for next steps

2. **How-to guides** link to:
   - Reference pages for syntax
   - Explanation pages for context
   - Related how-to guides

3. **Reference pages** link to:
   - Other reference pages for related specs
   - Explanation pages for concepts
   - NO tutorials or how-to guides

4. **Explanation pages** link to:
   - Reference pages for specifications
   - Other explanation pages for related concepts
   - How-to guides for implementation

### Versioning Strategy

- Documentation lives in `main` branch
- Version-specific docs in `docs/versions/v1.x/` (future)
- Current version assumed unless specified
- Breaking changes documented in `CHANGELOG.md`

### Style Rules

1. **Voice:** Second person ("you"), active voice
2. **Tense:** Present tense for current state, future for planned features
3. **Code examples:** Complete, runnable, tested
4. **Placeholders:** Use `<angle-brackets>` for user-supplied values
5. **Warnings:** Use admonitions (> **Warning:** ...)
6. **Evidence:** Every doc ends with "Evidence" section listing source files

### Quality Standards

- **Accuracy:** All facts must be evidenced from repository
- **Completeness:** Cover all common tasks and configurations
- **Clarity:** Assume reader has prerequisite knowledge only
- **Consistency:** Use same terminology throughout
- **Maintainability:** Update docs with code changes

---

## B3) Generate Documentation Files

### Minimum Viable Documentation Set

Based on evidence analysis and user needs, generate:

1. **docs/index.md** - Landing page
2. **docs/tutorials/getting-started.md** - First deployment tutorial
3. **docs/how-to/** (6 guides minimum):
   - add-new-service.md
   - configure-helm-values.md
   - manage-secrets.md
   - configure-gateway.md
   - setup-observability.md
   - troubleshoot-flux.md
4. **docs/reference/** (4 pages minimum):
   - directory-structure.md
   - service-catalog.md
   - flux-resources.md
   - helm-values-schema.md
5. **docs/explanation/** (3 pages minimum):
   - architecture.md
   - gitops-workflow.md
   - three-tier-values.md

### Documentation Generation Order

1. **Reference first** - Establish facts
2. **Explanation second** - Provide context
3. **How-to third** - Enable tasks
4. **Tutorial last** - Complete learning path

---

## B4) Documentation Quality Checks

### Validation Checklist

- [ ] **Diátaxis Separation:** Each doc clearly fits one quadrant
- [ ] **Evidence Citations:** All facts cite source files with paths
- [ ] **No Speculation:** No "should", "might", "probably" without VERIFY tag
- [ ] **Link Validity:** All internal links resolve correctly
- [ ] **Code Validity:** All code examples are syntactically correct
- [ ] **Terminology Consistency:** Same terms used throughout
- [ ] **Prerequisite Clarity:** Prerequisites stated upfront
- [ ] **Completeness:** All common tasks covered
- [ ] **Accuracy:** Facts match repository state
- [ ] **Maintainability:** Docs can be updated with code changes

### Known Gaps to Document

From A-CODE-REVIEW.md findings:

1. **Security gaps** (Critical):
   - Network Policies not implemented
   - Pod Security Policies not enforced
   - Kyverno policies not deployed
   - Image scanning not integrated

2. **Testing gaps** (High):
   - No automated testing
   - No validation scripts
   - No integration tests

3. **Observability gaps** (Medium):
   - No dashboards-as-code
   - No SLO definitions
   - No runbooks

4. **Documentation gaps** (Medium):
   - No architecture diagrams
   - No troubleshooting guides
   - No disaster recovery procedures

### TODO List for Documentation Completion

1. Generate reference documentation (facts-only)
2. Generate explanation documentation (context and decisions)
3. Generate how-to guides (task-oriented)
4. Generate tutorial (learning-oriented)
5. Create docs/index.md with navigation
6. Validate all links and code examples
7. Review for Diátaxis compliance
8. Add evidence citations to all pages
9. Create CONTRIBUTING.md for doc updates
10. Add documentation CI checks

---

## Next Steps

**Phase 4 Execution Plan:**

1. **B3.1:** Generate reference documentation
   - directory-structure.md
   - service-catalog.md
   - flux-resources.md
   - helm-values-schema.md

2. **B3.2:** Generate explanation documentation
   - architecture.md
   - gitops-workflow.md
   - three-tier-values.md

3. **B3.3:** Generate how-to guides
   - add-new-service.md
   - configure-helm-values.md
   - manage-secrets.md
   - configure-gateway.md
   - setup-observability.md
   - troubleshoot-flux.md

4. **B3.4:** Generate tutorial
   - getting-started.md

5. **B3.5:** Generate landing page
   - index.md

6. **B4:** Quality validation
   - Run validation checklist
   - Fix issues
   - Generate final TODO list

---

**Status:** B0-B2 complete, B3.1 (reference docs) COMPLETE, ready for B3.2 (explanation docs)

## B3 Progress

### B3.1: Reference Documentation (COMPLETE ✅)

**Completed:**
- ✅ `docs/reference/directory-structure.md` - Complete repository structure reference
- ✅ `docs/reference/service-catalog.md` - All 22+ platform services documented
- ✅ `docs/reference/flux-resources.md` - Complete FluxCD resource specifications
- ✅ `docs/reference/helm-values-schema.md` - Three-tier values pattern reference
- ✅ `docs/reference/kustomize-patterns.md` - Kustomize patterns and components
- ✅ `docs/reference/sops-configuration.md` - SOPS encryption configuration

### B3.2: Explanation Documentation (IN PROGRESS)

**Completed:**
- ✅ `docs/explanation/architecture.md` - System design and architectural decisions

**Remaining:**
- ⏳ `docs/explanation/gitops-workflow.md`
- ⏳ `docs/explanation/three-tier-values.md`
- ⏳ `docs/explanation/enterprise-components.md`
- ⏳ `docs/explanation/security-model.md`

### B3.3: How-to Guides (NOT STARTED)

**Planned:**
- ⏳ `docs/how-to/add-new-service.md`
- ⏳ `docs/how-to/configure-helm-values.md`
- ⏳ `docs/how-to/manage-secrets.md`
- ⏳ `docs/how-to/configure-gateway.md`
- ⏳ `docs/how-to/setup-observability.md`
- ⏳ `docs/how-to/troubleshoot-flux.md`

### B3.4: Tutorial (NOT STARTED)

**Planned:**
- ⏳ `docs/tutorials/getting-started.md`

### B3.5: Landing Page (NOT STARTED)

**Planned:**
- ⏳ `docs/index.md`

### B4: Quality Validation (NOT STARTED)

---

**Next Steps:** Continue with remaining reference docs, then proceed to explanation, how-to, tutorial, and landing page

