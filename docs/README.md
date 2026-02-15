# openCenter-gitops-base Documentation

**Version:** 1.0  
**Last Updated:** 2026-02-14  
**Status:** Production-ready platform with identified security gaps

---

## Overview

openCenter-gitops-base is a **GitOps-managed Kubernetes platform** that provides 22+ production-ready infrastructure services using FluxCD. It delivers a complete stack including observability, storage, security, and networking components for Kubernetes clusters on OpenStack and vSphere.

### Key Features

- **GitOps-First Architecture** - FluxCD manages all deployments from Git
- **Comprehensive Service Catalog** - 22 platform services + 4-component observability stack
- **Dual Edition Support** - Community and Enterprise editions from single codebase
- **Multi-Cloud Ready** - OpenStack and vSphere support with extensible provider model
- **Security-Conscious** - SOPS encryption, hardened Helm values, policy framework
- **Production-Grade** - High availability, disaster recovery, monitoring built-in

### Quick Links

- [Architecture Overview](#architecture)
- [Getting Started](#getting-started)
- [Service Catalog](#service-catalog)
- [Security Model](#security)
- [Operations Guide](#operations)
- [Reference Documentation](#reference-documentation)

---

## Documentation Structure

This documentation follows the [Diátaxis framework](https://diataxis.fr/) with four distinct types:

### 📚 Tutorials (Learning-Oriented)

*Coming soon - Step-by-step guides for learning the platform*

### 🔧 How-To Guides (Task-Oriented)

*Coming soon - Practical guides for specific tasks*

### 📖 Reference (Information-Oriented)

Complete technical specifications and configurations:

- **[Directory Structure](reference/directory-structure.md)** - Repository layout and organization
- **[Service Catalog](reference/service-catalog.md)** - All 22+ platform services with configurations
- **[FluxCD Resources](reference/flux-resources.md)** - GitRepository, HelmRelease, Kustomization specs
- **[Helm Values Schema](reference/helm-values-schema.md)** - Three-tier values pattern reference
- **[Kustomize Patterns](reference/kustomize-patterns.md)** - Kustomization patterns and components
- **[SOPS Configuration](reference/sops-configuration.md)** - Secret encryption and management

### 💡 Explanation (Understanding-Oriented)

Conceptual documentation explaining design decisions:

- **[Architecture](explanation/architecture.md)** - System design, ADRs, data flows, trade-offs
- *Coming soon: GitOps Workflow, Three-Tier Values, Enterprise Components, Security Model*

---

## Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Git Repository (Source of Truth)             │
│                    openCenter-gitops-base                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ FluxCD Reconciliation (5-15min)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                           │
│                                                                 │
│  Platform Services → Observability → Networking → Applications │
└─────────────────────────────────────────────────────────────────┘
```

**For detailed architecture:** See [Architecture Explanation](explanation/architecture.md)

### Core Components

**GitOps Layer:**
- FluxCD v2.7.0 (source, kustomize, helm controllers)
- Git-based reconciliation (15min sources, 5min resources)
- SOPS secret decryption with age encryption

**Platform Services:**
- cert-manager (TLS certificates)
- Kyverno (policy engine)
- Keycloak (identity management)
- Longhorn (distributed storage)
- Velero (backup/disaster recovery)

**Observability Stack:**
- Prometheus + Grafana (metrics)
- Loki (log aggregation)
- Tempo (distributed tracing)
- OpenTelemetry (telemetry collection)

**Networking:**
- MetalLB (load balancing)
- Envoy Gateway / Istio (ingress)
- Calico (CNI)
- Gateway API (next-gen ingress)

---

## Service Catalog

### Platform Services (22 services)

| Service | Purpose | Namespace | Dependencies |
|---------|---------|-----------|--------------|
| cert-manager | TLS certificate management | cert-manager | None |
| Harbor | Container registry | harbor | cert-manager |
| Keycloak | Identity & access management | keycloak | PostgreSQL |
| Kyverno | Policy engine | kyverno | None |
| Longhorn | Distributed storage | longhorn-system | None |
| MetalLB | Load balancer | metallb-system | None |
| Velero | Backup & DR | velero | Object storage |
| Envoy Gateway | Gateway API implementation | envoy-gateway-system | Gateway API |
| Istio | Service mesh | istio-system | None |
| Headlamp | Kubernetes UI | headlamp | None |
| Weave GitOps | FluxCD UI | flux-system | FluxCD |

**For complete catalog:** See [Service Catalog Reference](reference/service-catalog.md)

### Observability Services (4 components)

| Service | Purpose | Namespace | Storage |
|---------|---------|-----------|---------|
| kube-prometheus-stack | Metrics & alerting | monitoring | Local + remote write |
| Loki | Log aggregation | loki | Object storage |
| Tempo | Distributed tracing | tempo | Object storage |
| OpenTelemetry | Telemetry collection | opentelemetry | N/A |

---

## Getting Started

### Prerequisites

- Kubernetes cluster (v1.29+)
- kubectl CLI
- flux CLI (v2.7.0+)
- SOPS CLI (for secret management)
- age CLI (for encryption keys)

### Bootstrap FluxCD

```bash
# Set variables
export GIT_REPO="your-org/your-repo"
export CLUSTER_NAME="your-cluster"

# Install Flux CLI
curl -s https://fluxcd.io/install.sh | sudo FLUX_VERSION=2.7.0 bash

# Bootstrap Flux
flux bootstrap git \
  --url=ssh://git@github.com/${GIT_REPO}.git \
  --branch=main \
  --private-key-file=${HOME}/.ssh/${CLUSTER_NAME}_id_ed25519 \
  --path=applications/overlays/${CLUSTER_NAME}

# Verify installation
flux get all -A
```

### Create Deploy Key

```bash
# Generate deploy key for base repository
flux create secret git opencenter-base \
  --ssh-key-algorithm=ed25519 \
  --url=ssh://git@github.com/rackerlabs/openCenter-gitops-base.git \
  -n flux-system

# Add public key to GitHub as read-only deploy key
```

### Setup SOPS Encryption

```bash
# Generate age keypair
mkdir -p ${HOME}/.config/sops/age
age-keygen -o ${HOME}/.config/sops/age/${CLUSTER_NAME}_keys.txt

# Create Kubernetes secret with age key
kubectl create secret generic sops-age \
  --from-file=age.agekey=${HOME}/.config/sops/age/${CLUSTER_NAME}_keys.txt \
  -n flux-system

# Configure .sops.yaml with age public key
# See: reference/sops-configuration.md
```

**For detailed setup:** See existing service guides in `docs/` directory

---

## Security

### Current Security Posture

**Implemented:**
- ✅ SOPS encryption for secrets in Git
- ✅ Age asymmetric encryption
- ✅ TLS certificates via cert-manager
- ✅ Keycloak for authentication
- ✅ Kyverno policy engine installed
- ✅ Pod Security Standards labels on namespaces

**Critical Gaps (Must Fix Before Production):**
- ❌ Network policies not implemented
- ❌ Pod Security Admission not configured
- ❌ Kyverno policies not deployed
- ❌ Image scanning not integrated
- ❌ Image signature verification not configured
- ❌ mTLS not configured (Istio available but not enabled)

### Security Architecture

**Trust Boundaries:**
1. External → Cluster: TLS termination at gateway
2. Cluster → Services: Network policies (NOT IMPLEMENTED)
3. Services → Data: RBAC, encryption at rest
4. GitOps → Cluster: SSH keys, SOPS decryption
5. Operators → Cluster: Keycloak OIDC

**Secret Management:**
- Secrets encrypted with SOPS before committing to Git
- Age keys stored securely outside Git
- FluxCD decrypts automatically during reconciliation
- Kubernetes Secrets for runtime

**For detailed security:** See [Architecture - Security](explanation/architecture.md#security-architecture)

---

## Operations

### Day 1: Cluster Bootstrap

1. Provision infrastructure (OpenTofu/Terraform)
2. Deploy Kubernetes (Kubespray)
3. Bootstrap FluxCD
4. Create SOPS age key
5. Configure GitRepository sources
6. FluxCD deploys platform services automatically

### Day 2: Service Management

1. Add/update service manifests in Git
2. Commit and push changes
3. FluxCD detects changes (15min for sources, 5min for resources)
4. FluxCD reconciles cluster state
5. Monitor via Grafana dashboards
6. Respond to alerts (when configured)

### Common Operations

**Force Reconciliation:**
```bash
flux reconcile source git opencenter-cert-manager
flux reconcile helmrelease cert-manager -n cert-manager --with-source
```

**Check Status:**
```bash
flux get all -A
flux get helmreleases -A
kubectl get helmrelease -A
```

**View Logs:**
```bash
flux logs --level=error --all-namespaces
kubectl logs -n flux-system deploy/helm-controller
```

**Suspend/Resume:**
```bash
flux suspend helmrelease cert-manager -n cert-manager
flux resume helmrelease cert-manager -n cert-manager
```

**For detailed operations:** See [FluxCD Resources Reference](reference/flux-resources.md)

---

## Configuration

### Three-Tier Helm Values

openCenter uses a three-tier values hierarchy:

1. **Base values** (required) - Security-hardened defaults
2. **Override values** (optional) - Cluster-specific customization
3. **Enterprise values** (optional) - Enterprise edition features

**Example:**
```yaml
valuesFrom:
  - kind: Secret
    name: service-values-base      # Required
  - kind: Secret
    name: service-values-override  # Optional
    optional: true
  - kind: Secret
    name: service-values-enterprise  # Optional
    optional: true
```

**For detailed configuration:** See [Helm Values Schema Reference](reference/helm-values-schema.md)

### Kustomize Components

Enterprise edition differences are implemented as Kustomize components:

```
service/
├── kustomization.yaml              # Base (community)
├── helmrelease.yaml
└── components/
    └── enterprise/
        ├── kustomization.yaml      # Component
        └── helm-values/
```

**Benefits:**
- 60% file reduction vs parallel directories
- Eliminates duplication
- Prevents copy-paste errors
- Backward compatible

**For detailed patterns:** See [Kustomize Patterns Reference](reference/kustomize-patterns.md)

---

## Reference Documentation

### Complete Reference Library

- **[Directory Structure](reference/directory-structure.md)** - Repository organization and naming conventions
- **[Service Catalog](reference/service-catalog.md)** - All services with configurations and dependencies
- **[FluxCD Resources](reference/flux-resources.md)** - GitRepository, HelmRelease, Kustomization specifications
- **[Helm Values Schema](reference/helm-values-schema.md)** - Three-tier values pattern and examples
- **[Kustomize Patterns](reference/kustomize-patterns.md)** - Kustomization patterns, components, and best practices
- **[SOPS Configuration](reference/sops-configuration.md)** - Secret encryption rules and workflows

### Service-Specific Guides

Located in `docs/` directory:

- `adding-new-service.md` - How to add a new platform service
- `onboarding-service-overlay.md` - Service overlay configuration
- `cert-manager-config-guide.md` - Certificate management
- `harbor-config-guide.md` - Container registry
- `keycloak-config-guide.md` - Identity management
- `kube-prometheus-stack-config-guide.md` - Monitoring
- `kyverno-config-guide.md` - Policy engine
- `loki-config-guide.md` - Log aggregation
- `longhorn-config-guide.md` - Storage
- `metallb-config-guide.md` - Load balancing
- `tempo-config-guide.md` - Distributed tracing
- `velero-config-guide.md` - Backup/DR
- `vsphere-csi-config-guide.md` - vSphere storage

---

## Analysis & Review

### Comprehensive Code Review

A complete architecture, security, and operations review has been conducted:

**Analysis Documents:**
- **[Code Review](analysis/A-CODE-REVIEW.md)** - Executive summary, findings, recommendations
- **[Evidence Packs](analysis/)** - 8 detailed analysis packs (S1-S8)
  - S1: App Runtime & APIs
  - S2: Build & Dev Tooling
  - S3: Kubernetes Workloads
  - S4: FluxCD / GitOps
  - S5: Envoy Gateway / Traffic
  - S6: Observability
  - S7: Security & Governance
  - S8: CI/CD & Release

### Key Findings

**Critical Issues (6):**
1. Network Policies Not Implemented
2. Pod Security Policies Not Enforced
3. No Kyverno Policies Deployed
4. Envoy Gateway Version Not Pinned (v0.0.0-latest)
5. No Automated Testing
6. No Dashboards-as-Code

**High Priority Issues (10):**
- No resource limits verification
- No mTLS between services
- No rate limiting on gateways
- No alert rules or runbooks
- No SLO definitions
- No image scanning
- No RBAC policies
- No release automation
- SOPS key backup not documented
- No Flux monitoring dashboards

**Recommendation:** DO NOT deploy to production until critical security gaps addressed (4-6 weeks estimated effort)

**For complete review:** See [Code Review](analysis/A-CODE-REVIEW.md)

---

## Architecture Decisions

### Key ADRs

**ADR-001: GitOps with FluxCD**
- Decision: Use FluxCD for GitOps-based cluster management
- Rationale: Declarative, automated, auditable, drift detection
- Trade-offs: Reconciliation delays, requires FluxCD expertise

**ADR-002: HelmRelease for Service Deployment**
- Decision: Deploy all services via FluxCD HelmRelease CRD
- Rationale: Standardization, Helm ecosystem, values management
- Trade-offs: Requires Helm charts, complex values merging

**ADR-003: Three-Tier Helm Values**
- Decision: Use base, override, enterprise values hierarchy
- Rationale: Separation of concerns, no base modification, dual edition support
- Trade-offs: More complex than single values file

**ADR-004: Kustomize Components for Enterprise**
- Decision: Use Kustomize components for enterprise differences
- Rationale: Eliminates duplication, prevents errors, backward compatible
- Trade-offs: Kustomize v5.0+ required, less widely known

**ADR-005: SOPS for Secret Management**
- Decision: Use SOPS with age encryption for secrets
- Rationale: Git-safe, asymmetric encryption, FluxCD integration
- Trade-offs: Age key loss = secret recovery failure

**For detailed ADRs:** See [Architecture Explanation](explanation/architecture.md#key-architectural-decisions)

---

## Troubleshooting

### Common Issues

**FluxCD Reconciliation Failures:**
```bash
# Check status
flux get all -A

# View events
kubectl describe gitrepository <name> -n flux-system
kubectl describe helmrelease <name> -n <namespace>

# Force reconciliation
flux reconcile source git <name>
flux reconcile helmrelease <name> -n <namespace> --with-source
```

**SOPS Decryption Failures:**
```bash
# Verify sops-age secret exists
kubectl get secret sops-age -n flux-system

# Recreate if missing
kubectl create secret generic sops-age \
  --from-file=age.agekey=${HOME}/.config/sops/age/${CLUSTER_NAME}_keys.txt \
  -n flux-system
```

**HelmRelease Install/Upgrade Failures:**
```bash
# Check HelmRelease status
kubectl describe helmrelease <name> -n <namespace>

# View Helm controller logs
kubectl logs -n flux-system deploy/helm-controller

# Suspend and resume
flux suspend helmrelease <name> -n <namespace>
flux resume helmrelease <name> -n <namespace>
```

**For detailed troubleshooting:** See individual reference documents

---

## Contributing

### Adding a New Service

1. Create service directory: `applications/base/services/<service-name>/`
2. Add required files:
   - `namespace.yaml` - Namespace definition
   - `source.yaml` - HelmRepository or GitRepository
   - `helmrelease.yaml` - HelmRelease resource
   - `kustomization.yaml` - Kustomization manifest
   - `helm-values/values-<version>.yaml` - Helm values
3. Follow naming conventions (kebab-case)
4. Include required labels (app.kubernetes.io/*, opencenter.io/*)
5. Add service documentation
6. Test with `kubectl kustomize`
7. Submit pull request

**For detailed guide:** See `docs/adding-new-service.md`

### Documentation Standards

- Follow Diátaxis framework (Tutorial, How-to, Reference, Explanation)
- Include evidence citations with file paths
- Use repo-relative paths
- Keep code examples complete and runnable
- Update documentation with code changes

---

## Support & Resources

### Internal Resources

- **Repository:** https://github.com/rackerlabs/openCenter-gitops-base
- **Issues:** GitHub Issues
- **Discussions:** GitHub Discussions

### External Resources

- **FluxCD Documentation:** https://fluxcd.io/docs/
- **Kustomize Documentation:** https://kubectl.docs.kubernetes.io/
- **SOPS Documentation:** https://github.com/mozilla/sops
- **Gateway API:** https://gateway-api.sigs.k8s.io/
- **Diátaxis Framework:** https://diataxis.fr/

### Related Repositories

- **openCenter-cli** - Cluster initialization and configuration
- **openCenter-customer-app-example** - Application deployment patterns
- **openCenter-AirGap** - Disconnected deployment packaging
- **opencenter-windows** - Windows worker node support

**For ecosystem overview:** See workspace-level `ecosystem.md` steering file

---

## Version History

### v1.0 (Current)

- 22 platform services + 4-component observability stack
- FluxCD v2.7.0 GitOps management
- Kustomize components for enterprise edition
- SOPS encryption with age
- Multi-cloud support (OpenStack, vSphere)
- Comprehensive documentation (reference, explanation)

### Known Issues

- Network policies not implemented (CRITICAL)
- Pod Security Admission not configured (CRITICAL)
- Kyverno policies not deployed (CRITICAL)
- No automated testing (HIGH)
- No dashboards-as-code (HIGH)
- Envoy Gateway version unpinned (CRITICAL)

**For complete findings:** See [Code Review](analysis/A-CODE-REVIEW.md)

---

## License

[License information to be added]

---

## Acknowledgments

Built with:
- FluxCD for GitOps
- Kustomize for configuration management
- SOPS for secret encryption
- Helm for package management
- Kubernetes for container orchestration

---

**Last Updated:** 2026-02-14  
**Documentation Version:** 1.0  
**Platform Version:** Production-ready with identified gaps
