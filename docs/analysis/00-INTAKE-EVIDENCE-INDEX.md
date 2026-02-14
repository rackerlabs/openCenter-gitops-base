# Phase 0: Intake & Evidence Index

## What I Reviewed

**Repository:** openCenter-gitops-base  
**Analysis Date:** 2026-02-14  
**Scope:** Complete multi-agent architecture review and Diátaxis documentation generation

### Inputs Received

**Primary Evidence:**
- `llms.txt` - Comprehensive operator guidance (589 lines)
- Repository structure with 22+ platform services
- Documentation in `docs/` (25+ configuration guides)
- Infrastructure-as-Code in `iac/`
- Kustomize migration tooling in `tools/`
- GitHub Actions workflow
- Pre-commit hooks and linting configuration

**Repository Statistics:**
- Services: 22 core platform services
- Observability: 4-component stack (Prometheus, Loki, Tempo, OTel)
- Documentation: 25+ service-specific guides
- Policies: Network, Pod Security, RBAC (placeholders)
- IAC: OpenTofu/Terraform modules for OpenStack/vSphere

### Gaps Identified

**Missing Evidence:**
- Actual Helm values file contents (need sampling)
- Complete Kustomize component implementations
- Detailed OpenTofu module configurations
- Actual policy definitions (only placeholders found)
- Test suites/validation scripts
- CI/CD release pipeline (only PR validation found)
- Monitoring dashboards-as-code
- Runbooks/incident response procedures

**Verification Needed:**
- FluxCD version compatibility matrix
- Kubernetes version support range
- Service dependency graph
- Upgrade/rollback procedures
- Disaster recovery testing
- Security scanning integration
- Performance benchmarks

## Minimal Assumptions

1. **Platform:** Multi-cloud (OpenStack, vSphere primary)
2. **GitOps:** FluxCD v2.7.0+ 
3. **Kubernetes:** v1.32.5 target
4. **Target:** Production enterprise platform
5. **Audience:** Platform engineers, SREs
6. **Security:** SOPS with age encryption
7. **Scope:** Infrastructure manifests only (no app code)

## Evidence Index

### Kubernetes Manifests

- `applications/base/services/*/namespace.yaml` - 22+ namespace definitions
- `applications/base/services/*/helmrelease.yaml` - Flux HelmRelease CRDs
- `applications/base/services/*/kustomization.yaml` - Kustomize configs
- `applications/base/services/*/components/enterprise/` - Enterprise components

### FluxCD/GitOps
- Flux bootstrap pattern (llms.txt lines 19-35)
- GitRepository sources (llms.txt lines 37-52)
- HelmRelease with drift detection (llms.txt lines 95-125)
- Kustomization with dependencies (llms.txt lines 355-388)
- SOPS decryption (llms.txt lines 237-262)

### Gateway/Ingress
- `applications/base/services/gateway-api/` - Gateway API CRDs
- `applications/base/services/istio/` - Service mesh (base + istiod)
- Certificate ingress annotations (llms.txt lines 280-301)

### Observability
- `applications/base/services/observability/kube-prometheus-stack/`
- `applications/base/services/observability/loki/`
- `applications/base/services/observability/opentelemetry-kube-stack/`
- Tempo mentioned but directory not found in listing

### Security
- `applications/base/services/cert-manager/` - TLS automation
- `applications/base/services/keycloak/` - IAM (4 components)
- `applications/base/services/kyverno/` - Policy engine
- `applications/base/services/sealed-secrets/` - Secret encryption
- SOPS/age workflow (llms.txt lines 209-235)

### Infrastructure-as-Code
- `iac/cloud/` - Cloud provider modules
- `iac/cni/` - CNI configurations
- `iac/provider/` - Provider-specific configs
- OpenTofu backend config (llms.txt lines 327-336)
- Cluster variables (llms.txt lines 338-346)

### CI/CD
- `.github/workflows/pre-commit.yaml` - PR validation
- `.pre-commit-config.yaml` - Local hooks (shellcheck, yamllint, black)
- `.yamllint` - YAML linting rules
- `.ansible-lint` - Ansible playbook linting

### Configuration
- Hardened Helm values pattern (llms.txt lines 348-366)
- Node scheduling (llms.txt lines 368-388)
- Required labels (llms.txt lines 390-408)

**Evidence Sources:** 50+ files analyzed
