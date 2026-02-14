# Directory Structure Reference

**Type:** Reference  
**Audience:** All users  
**Last Updated:** 2026-02-14

This document describes the complete directory structure of the openCenter-gitops-base repository.

---

## Repository Root

```
openCenter-gitops-base/
├── .github/                    # GitHub Actions workflows and templates
├── .mise/                      # Mise task runner configuration
├── applications/               # Kubernetes application manifests
├── docs/                       # Documentation
├── iac/                        # Infrastructure as Code (OpenTofu/Terraform)
├── scripts/                    # Utility scripts
├── templates/                  # Template files for scaffolding
├── tools/                      # Development and migration tools
├── .gitignore                  # Git ignore patterns
├── .pre-commit-config.yaml     # Pre-commit hooks configuration
├── .yamllint                   # YAML linting rules
├── llms.txt                    # LLM-friendly repository documentation
├── mise.toml                   # Mise task definitions
└── README.md                   # Repository overview
```

---

## Applications Directory

The `applications/` directory contains all Kubernetes service manifests organized by deployment layer.

```
applications/
├── base/                       # Base service definitions
│   ├── services/               # Platform services
│   │   ├── calico/             # Calico CNI networking
│   │   ├── cert-manager/       # Certificate management
│   │   ├── envoy-gateway/      # Envoy Gateway API implementation
│   │   ├── gateway/            # Gateway API resources
│   │   ├── harbor/             # Container registry
│   │   ├── headlamp/           # Kubernetes UI
│   │   ├── keycloak/           # Identity and access management
│   │   ├── kube-prometheus-stack/  # Prometheus monitoring
│   │   ├── kube-vip/           # Virtual IP for control plane
│   │   ├── kyverno/            # Policy engine
│   │   ├── loki/               # Log aggregation
│   │   ├── longhorn/           # Distributed storage
│   │   ├── metallb/            # Load balancer
│   │   ├── opentelemetry-kube-stack/  # OpenTelemetry collector
│   │   ├── sealed-secrets/     # Encrypted secrets
│   │   ├── tempo/              # Distributed tracing
│   │   ├── velero/             # Backup and disaster recovery
│   │   └── vsphere-csi/        # vSphere storage driver
│   └── kustomization.yaml      # Base kustomization
├── community/                  # Community edition wrappers
│   └── services/               # Service wrappers for community
└── enterprise/                 # Enterprise edition wrappers
    └── services/               # Service wrappers for enterprise
```

### Service Directory Structure

Each service follows a standardized structure:

```
applications/base/services/<service-name>/
├── components/                 # Kustomize components (optional)
│   └── enterprise/             # Enterprise-specific resources
│       ├── kustomization.yaml
│       └── <resource-files>
├── helm-values/                # Helm chart values
│   ├── base-values-<version>.yaml
│   ├── override-values-<version>.yaml
│   └── enterprise-values-<version>.yaml
├── namespace.yaml              # Namespace definition
├── source.yaml                 # HelmRepository or GitRepository
├── helmrelease.yaml            # HelmRelease resource
└── kustomization.yaml          # Kustomization manifest
```

---

## Infrastructure as Code (iac/)

Contains OpenTofu/Terraform configurations for cluster provisioning.

```
iac/
├── modules/                    # Reusable Terraform modules
│   ├── openstack/              # OpenStack provider modules
│   ├── vmware/                 # VMware vSphere modules
│   └── kind/                   # Kind (local) modules
├── examples/                   # Example configurations
└── README.md                   # IaC documentation
```

---

## Documentation (docs/)

```
docs/
├── analysis/                   # Architecture analysis documents
│   ├── 00-INTAKE-EVIDENCE-INDEX.md
│   ├── S1-APP-RUNTIME-APIS.md
│   ├── S2-BUILD-DEV-TOOLING.md
│   ├── S3-KUBERNETES-WORKLOADS.md
│   ├── S4-FLUXCD-GITOPS.md
│   ├── S5-ENVOY-GATEWAY-TRAFFIC.md
│   ├── S6-OBSERVABILITY.md
│   ├── S7-SECURITY-GOVERNANCE.md
│   ├── S8-CICD-RELEASE.md
│   ├── A-CODE-REVIEW.md
│   └── B-DOCUMENTATION-PLAN.md
├── reference/                  # Reference documentation
│   └── directory-structure.md  # This file
├── templates/                  # Documentation templates
├── service-standards-and-lifecycle.md  # Service standards
├── adding-new-service.md       # How to add services
├── onboarding-service-overlay.md  # Service overlay guide
└── <service>-config-guide.md   # Service-specific guides
```

---

## Tools Directory

Development and migration utilities.

```
tools/
├── kustomize-migration/        # Kustomize component migration tool
│   ├── cmd/                    # CLI commands
│   ├── internal/               # Internal packages
│   ├── go.mod                  # Go module definition
│   └── README.md               # Tool documentation
└── <other-tools>/              # Additional tooling
```

---

## Scripts Directory

Utility scripts for operations and automation.

```
scripts/
├── bootstrap/                  # Cluster bootstrap scripts
├── validation/                 # Validation and testing scripts
└── utilities/                  # General utility scripts
```

---

## GitHub Workflows (.github/)

```
.github/
├── workflows/                  # GitHub Actions workflows
│   ├── ci.yaml                 # Continuous integration
│   ├── lint.yaml               # Linting checks
│   └── release.yaml            # Release automation
└── ISSUE_TEMPLATE/             # Issue templates
```

---

## Key Files

### Root Level

- **llms.txt**: LLM-friendly documentation containing repository overview, installation guides, and core concepts
- **mise.toml**: Task runner configuration defining common development tasks
- **.pre-commit-config.yaml**: Pre-commit hooks for code quality (yamllint, conventional commits, formatting)
- **.yamllint**: YAML linting rules enforcing consistent formatting
- **README.md**: Repository overview and quick start guide

### Service Level

- **namespace.yaml**: Kubernetes namespace definition with required labels
- **source.yaml**: FluxCD source (HelmRepository or GitRepository)
- **helmrelease.yaml**: FluxCD HelmRelease with installation/upgrade configuration
- **kustomization.yaml**: Kustomize manifest listing resources and components
- **helm-values/*.yaml**: Three-tier Helm values (base, override, enterprise)

---

## Directory Naming Conventions

- **Directories**: kebab-case (e.g., `kube-prometheus-stack`)
- **Files**: kebab-case with descriptive suffixes (e.g., `base-values-v1.2.3.yaml`)
- **Components**: Located in `components/<variant>/` subdirectory
- **Helm values**: Versioned with chart version (e.g., `base-values-v1.2.3.yaml`)

---

## File Organization Principles

1. **Base-first**: Base manifests in `applications/base/services/`
2. **Edition wrappers**: Community and enterprise wrappers reference base
3. **Components for variants**: Use Kustomize components for edition-specific resources
4. **Versioned values**: Helm values files include chart version in filename
5. **Self-contained services**: Each service directory is independently deployable

---

## Evidence

**Source Files:**
- `applications/base/services/*/` (all service directories)
- `applications/community/services/*/kustomization.yaml` (community wrappers)
- `applications/enterprise/services/*/kustomization.yaml` (enterprise wrappers)
- `iac/` (infrastructure code)
- `docs/` (documentation)
- `tools/kustomize-migration/` (migration tooling)
- `.github/workflows/` (CI/CD pipelines)
- `llms.txt` (repository overview)
- `mise.toml` (task definitions)
