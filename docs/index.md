---
doc_type: overview
title: "openCenter-gitops-base Documentation"
---

# openCenter-gitops-base Documentation

**Purpose:** For all audiences, provides navigation to documentation for deploying and managing production-ready Kubernetes platform services using FluxCD GitOps.

## What is openCenter-gitops-base?

openCenter-gitops-base is a centralized library of production-ready, security-hardened Kubernetes platform services deployed via GitOps. It provides 22+ core services and a complete observability stack that form the foundation of openCenter Kubernetes clusters.

**Key characteristics:**
- **GitOps-native:** All services deployed and managed via FluxCD
- **Security-hardened:** Production-ready configurations with security best practices
- **Standardized:** Consistent deployment patterns across all services
- **Customizable:** Three-tier values hierarchy for environment-specific configuration
- **Observable:** Complete monitoring, logging, and tracing stack included

**Services included:** cert-manager, Harbor, Keycloak, Kyverno, Longhorn, MetalLB, Velero, Gateway API, Prometheus, Grafana, Loki, Tempo, and more. See [Service Catalog](reference/service-catalog.md) for the complete list.

## How This Repository Fits in the Ecosystem

openCenter-gitops-base is one component of the larger openCenter platform:

- **openCenter-cli** generates customer cluster repositories that reference this base repository
- **Customer clusters** deploy services by pointing FluxCD at specific paths in this repository
- **Base configurations** are customized via overlays in customer repositories
- **Version pinning** via Git tags ensures reproducible deployments

For the complete ecosystem architecture, see [ecosystem.md](../ecosystem.md).

## Quick Start by Role

### New to openCenter?

**Start here:** [Getting Started Tutorial](tutorials/getting-started.md)

Follow the step-by-step guide to deploy your first service (cert-manager) and understand the GitOps workflow. Takes 30-45 minutes.

### Platform Engineers

**Common tasks:**
- [Add a New Service](how-to/add-new-service.md) - Deploy additional platform services
- [Configure Helm Values](how-to/configure-helm-values.md) - Customize service configuration
- [Manage Secrets with SOPS](how-to/manage-secrets.md) - Encrypt sensitive data
- [Troubleshoot Flux](how-to/troubleshoot-flux.md) - Debug reconciliation issues
- [Configure Gateway API](how-to/configure-gateway.md) - Set up ingress routing
- [Setup Observability](how-to/setup-observability.md) - Deploy monitoring stack

**Reference documentation:**
- [Service Catalog](reference/service-catalog.md) - All available services
- [Directory Structure](reference/directory-structure.md) - Repository layout
- [Flux Resources](reference/flux-resources.md) - GitRepository, HelmRelease, Kustomization specs
- [Helm Values Schema](reference/helm-values-schema.md) - Three-tier values pattern
- [Kustomize Patterns](reference/kustomize-patterns.md) - Components and overlays
- [SOPS Configuration](reference/sops-configuration.md) - Secret encryption

### Architects and Decision Makers

**Understand the system:**
- [Architecture Overview](explanation/architecture.md) - System design and decisions
- [GitOps Workflow](explanation/gitops-workflow.md) - How FluxCD manages deployments
- [Three-Tier Values](explanation/three-tier-values.md) - Configuration hierarchy rationale
- [Enterprise Components](explanation/enterprise-components.md) - Community vs enterprise editions
- [Security Model](explanation/security-model.md) - Security controls and gaps

**Analysis and review:**
- [Code Review](analysis/A-CODE-REVIEW.md) - Comprehensive security and architecture review
- [Executive Summary](analysis/EXECUTIVE-SUMMARY.md) - Key findings and recommendations
- [Evidence Packs](analysis/) - Detailed analysis of all platform components

## Documentation Structure

This documentation follows the [Diátaxis framework](https://diataxis.fr/) with four distinct types:

### Tutorials (Learning-Oriented)

**Goal:** Build confidence through guided, end-to-end walkthroughs

- [Getting Started](tutorials/getting-started.md) - Deploy your first service

**When to use:** You're new to openCenter and want to learn by doing.

### How-To Guides (Task-Oriented)

**Goal:** Complete specific tasks with minimal background

- [Add a New Service](how-to/add-new-service.md)
- [Configure Helm Values](how-to/configure-helm-values.md)
- [Manage Secrets with SOPS](how-to/manage-secrets.md)
- [Configure Gateway API](how-to/configure-gateway.md)
- [Setup Observability](how-to/setup-observability.md)
- [Troubleshoot Flux](how-to/troubleshoot-flux.md)

**When to use:** You know what you want to do and need step-by-step instructions.

### Reference (Information-Oriented)

**Goal:** Provide exact facts for lookup

- [Directory Structure](reference/directory-structure.md)
- [Service Catalog](reference/service-catalog.md)
- [Flux Resources](reference/flux-resources.md)
- [Helm Values Schema](reference/helm-values-schema.md)
- [Kustomize Patterns](reference/kustomize-patterns.md)
- [SOPS Configuration](reference/sops-configuration.md)

**When to use:** You need to look up specifications, syntax, or available options.

### Explanation (Understanding-Oriented)

**Goal:** Build mental models and understand "why"

- [Architecture Overview](explanation/architecture.md)
- [GitOps Workflow](explanation/gitops-workflow.md)
- [Three-Tier Values](explanation/three-tier-values.md)
- [Enterprise Components](explanation/enterprise-components.md)
- [Security Model](explanation/security-model.md)

**When to use:** You want to understand concepts, trade-offs, and design decisions.

## Service-Specific Documentation

Each service has detailed configuration guides:

**Core Services:**
- [cert-manager](../cert-manager-config-guide.md) - TLS certificate management
- [Harbor](../harbor-config-guide.md) - Container registry
- [Keycloak](../keycloak-config-guide.md) - Identity and access management
- [Kyverno](../kyverno-config-guide.md) - Policy engine
- [Longhorn](../longhorn-config-guide.md) - Distributed storage
- [MetalLB](../metallb-config-guide.md) - Load balancer
- [Velero](../velero-config-guide.md) - Backup and disaster recovery
- [vSphere CSI](../vsphere-csi-config-guide.md) - vSphere storage integration

**Observability:**
- [kube-prometheus-stack](../kube-prometheus-stack-config-guide.md) - Prometheus, Grafana, Alertmanager
- [Loki](../loki-config-guide.md) - Log aggregation
- [Tempo](../tempo-config-guide.md) - Distributed tracing
- [OpenTelemetry](../opentelemetry-kube-stack-config-guide.md) - Telemetry collection

**Operations:**
- [Sealed Secrets](../sealed-secrets-config-guide.md) - Secret management
- [Adding New Service](../adding-new-service.md) - Service onboarding process
- [Service Standards](../service-standards-and-lifecycle.md) - Standards and lifecycle

## Common Workflows

### Deploying a New Cluster

1. Use openCenter-cli to generate customer repository
2. Bootstrap FluxCD on the cluster
3. Configure GitRepository sources pointing to this repository
4. Create Kustomizations for desired services
5. Commit and push - FluxCD deploys automatically

See [Getting Started Tutorial](tutorials/getting-started.md) for detailed walkthrough.

### Adding a Service to Existing Cluster

1. Review [Service Catalog](reference/service-catalog.md) for available services
2. Create GitRepository source for the service
3. Create Kustomization pointing to service path
4. (Optional) Add cluster-specific overrides
5. Commit and push

See [Add a New Service](how-to/add-new-service.md) for step-by-step instructions.

### Customizing Service Configuration

1. Review service's base Helm values in `helm-values/` directory
2. Create override values Secret in your cluster overlay
3. Reference override Secret in HelmRelease valuesFrom
4. Commit and push

See [Configure Helm Values](how-to/configure-helm-values.md) for details.

### Troubleshooting Deployment Issues

1. Check Flux resource status: `flux get all`
2. Review Flux logs: `flux logs --level=error`
3. Describe failing resource: `kubectl describe <resource>`
4. Force reconciliation: `flux reconcile <resource>`

See [Troubleshoot Flux](how-to/troubleshoot-flux.md) for comprehensive guide.

## Getting Help

### Documentation Issues

If you find errors or gaps in documentation:
1. Check if the issue is already documented in [Known Gaps](analysis/A-CODE-REVIEW.md#known-gaps)
2. Review [Evidence Packs](analysis/) for detailed technical information
3. Consult service-specific configuration guides

### Technical Support

For technical issues:
1. Review [Troubleshooting Guide](how-to/troubleshoot-flux.md)
2. Check Flux logs and resource status
3. Consult service-specific documentation
4. Review [Architecture Overview](explanation/architecture.md) for system design

### Contributing

To contribute to this repository:
1. Review [Service Standards](../service-standards-and-lifecycle.md)
2. Follow [Adding New Service](../adding-new-service.md) process
3. Use [Service Templates](../templates/) for consistency
4. Ensure all changes follow GitOps principles

## Repository Information

**Repository:** [rackerlabs/openCenter-gitops-base](https://github.com/rackerlabs/openCenter-gitops-base)  
**FluxCD Version:** v2.7.0+  
**Kubernetes Version:** v1.28+  
**License:** See repository LICENSE file

**Key directories:**
- `applications/base/services/` - Core platform services
- `applications/base/services/observability/` - Monitoring, logging, tracing
- `applications/base/managed-services/` - Rackspace-managed services
- `applications/policies/` - Security and network policies
- `docs/` - Documentation (you are here)

## Next Steps

**If you're new:** Start with the [Getting Started Tutorial](tutorials/getting-started.md)

**If you're deploying services:** Browse the [Service Catalog](reference/service-catalog.md)

**If you're customizing:** Read [Configure Helm Values](how-to/configure-helm-values.md)

**If you're troubleshooting:** Check [Troubleshoot Flux](how-to/troubleshoot-flux.md)

**If you want to understand the system:** Read [Architecture Overview](explanation/architecture.md)

## Evidence

This documentation is based on comprehensive analysis of the repository:
- `docs/analysis/B-DOCUMENTATION-PLAN.md` - Documentation structure and planning
- `docs/analysis/EXECUTIVE-SUMMARY.md` - Key findings and recommendations
- `docs/analysis/S1-APP-RUNTIME-APIS.md` - Service deployment patterns
- `docs/analysis/S4-FLUXCD-GITOPS.md` - FluxCD workflow analysis
- `README.md` - Repository overview and service catalog
- `ecosystem.md` - openCenter ecosystem architecture
