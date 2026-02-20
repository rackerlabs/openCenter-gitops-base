# Applications Directory

This directory contains GitOps application manifests that are deployed as part of the openCenter cluster provisioning workflow. All applications are managed using Flux CD and follow GitOps principles for declarative, version-controlled deployments.

## Recent Changes

**ADR-001 Migration Complete (2026-02-20):** All services have been migrated to Kustomize Components pattern. The old `community/` and `enterprise/` directory structure has been replaced with a cleaner component-based approach.

- **Breaking Change:** Customer overlays must be updated. See [Customer Overlay Migration Guide](docs/customer-overlay-migration-guide.md)
- **New Structure:** Services now use `components/enterprise/` for enterprise features
- **Benefits:** 60% file reduction, simplified version upgrades, zero duplication

For details, see:
- [ADR-001: Kustomize Components Pattern](../ADRS/ADR-001-kustomize-components-for-enterprise-pattern.md)
- [Service Structure Reference](docs/service-structure.md)
- [Customer Overlay Migration Guide](docs/customer-overlay-migration-guide.md)

## Directory Structure

```
applications/
├── base/                   # Base application configurations
│   ├── managed-services/   # Rackspace-managed services
│   └── services/           # Core cluster services
│       └── observability/  # Observability stack components
└── policies/               # Security and network policies
    ├── network-policies/   # Kubernetes network policies
    ├── pod-security-policies/ # Pod security standards
    └── rbac/              # Role-based access controls
```

## Available Applications

### Core Services

| Service | Namespace | Purpose | Documentation |
|---------|-----------|---------|---------------|
| **[cert-manager](applications/base/services/cert-manager/)** | `cert-manager` | Automated TLS certificate management | [README](applications/base/services/cert-manager/README.md) |
| **[external-snapshotter](applications/base/services/external-snapshotter/)** | `kube-system` | Volume snapshot management | [README](applications/base/services/external-snapshotter/README.md) |
| **[gateway-api](applications/base/services/gateway-api/)** | `gateway-system` | Next-generation ingress API | [README](applications/base/services/gateway-api/README.md) |
| **[harbor](applications/base/services/harbor/)** | `harbor` | Container registry with security scanning | [README](applications/base/services/harbor/README.md) |
| **[headlamp](applications/base/services/headlamp/)** | `headlamp` | Modern Kubernetes dashboard | [README](applications/base/services/headlamp/README.md) |
| **[keycloak](applications/base/services/keycloak/)** | `keycloak` | Identity and access management | [README](applications/base/services/keycloak/README.md) |
| **[kyverno](applications/base/services/kyverno/)** | `kyverno` | Kubernetes-native policy engine | [README](applications/base/services/kyverno/README.md) |
| **[longhorn](applications/base/services/longhorn/)** | `longhorn-system` | Distributed block storage | [README](applications/base/services/longhorn/README.md) |
| **[metallb](applications/base/services/metallb/)** | `metallb-system` | Load balancer for bare-metal clusters | [README](applications/base/services/metallb/README.md) |
| **[olm](applications/base/services/olm/)** | `olm` | Operator Lifecycle Manager | [README](applications/base/services/olm/README.md) |
| **[openstack-ccm](applications/base/services/openstack-ccm/)** | `kube-system` | OpenStack Cloud Controller Manager | [README](applications/base/services/openstack-ccm/README.md) |
| **[openstack-csi](applications/base/services/openstack-csi/)** | `kube-system` | OpenStack Cinder CSI driver | [README](applications/base/services/openstack-csi/README.md) |
| **[postgres-operator](applications/base/services/postgres-operator/)** | `postgres-operator` | PostgreSQL cluster management | [README](applications/base/services/postgres-operator/README.md) |
| **[rbac-manager](applications/base/services/rbac-manager/)** | `rbac-manager` | RBAC management automation | [README](applications/base/services/rbac-manager/README.md) |
| **[sealed-secrets](applications/base/services/sealed-secrets/)** | `kube-system` | GitOps-friendly secret management | [README](applications/base/services/sealed-secrets/README.md) |
| **[velero](applications/base/services/velero/)** | `velero` | Backup and disaster recovery | [README](applications/base/services/velero/README.md) |
| **[vsphere-csi](applications/base/services/vsphere-csi/)** | `vmware-system-csi` | vSphere storage integration | [README](applications/base/services/vsphere-csi/README.md) |
| **[weave-gitops](applications/base/services/weave-gitops/)** | `flux-system` | GitOps dashboard for Flux | [README](applications/base/services/weave-gitops/README.md) |

### Observability Stack

| Component | Namespace | Purpose | Documentation |
|-----------|-----------|---------|---------------|
| **[observability](applications/base/services/observability/)** | `observability` | Complete observability stack | [README](applications/base/services/observability/README.md) |
| **[kube-prometheus-stack](applications/base/services/observability/kube-prometheus-stack/)** | `observability` | Prometheus, Grafana, Alertmanager | [README](applications/base/services/observability/kube-prometheus-stack/README.md) |
| **[loki](applications/base/services/observability/loki/)** | `observability` | Log aggregation and storage | [README](applications/base/services/observability/loki/README.md) |
| **[tempo](applications/base/services/observability/tempo/)** | `observability` | Distributed tracing backend | [README](applications/base/services/observability/tempo/README.md) |
| **[opentelemetry-kube-stack](applications/base/services/observability/opentelemetry-kube-stack/)** | `observability` | OpenTelemetry collection framework | [README](applications/base/services/observability/opentelemetry-kube-stack/README.md) |

### Managed Services

| Service | Namespace | Purpose | Documentation |
|---------|-----------|---------|---------------|
| **[alert-proxy](applications/base/managed-services/alert-proxy/)** | `rackspace` | Rackspace alert aggregation | [README](applications/base/managed-services/alert-proxy/README.md) |

### Security Policies

| Policy | Scope | Purpose |
|--------|-------|---------|
| **[network-policies](applications/policies/network-policies/)** | Various | Kubernetes network segmentation |
| **[pod-security-policies](applications/policies/pod-security-policies/)** | Various | Pod security standards enforcement |
| **[rbac](applications/policies/rbac/)** | Various | Role-based access control |

## Deployment Architecture

All applications follow these patterns:

### Flux CD Integration
- **HelmRepository**: Defines Helm chart sources
- **HelmRelease**: Manages application deployments
- **Kustomization**: Handles plain Kubernetes manifests
- **GitRepository**: References external Git sources

### Common Configuration
- **Interval**: 5-minute reconciliation cycles
- **Timeout**: 10-minute installation/upgrade timeouts
- **Drift Detection**: Enabled for configuration consistency
- **Remediation**: 3-retry policy with last-failure remediation

### Namespace Organization
- `cert-manager`: TLS certificate management
- `gateway-system`: Gateway API controllers
- `harbor`: Container registry and security scanning
- `headlamp`: Kubernetes dashboard
- `keycloak`: Identity and access management
- `kyverno`: Policy engine and governance
- `longhorn-system`: Distributed storage
- `metallb-system`: Load balancing for bare-metal
- `observability`: Complete monitoring, logging, and tracing stack
- `olm`: Operator lifecycle management
- `postgres-operator`: PostgreSQL database management
- `rbac-manager`: RBAC automation
- `velero`: Backup and disaster recovery
- `vmware-system-csi`: vSphere storage integration
- `flux-system`: GitOps controllers and dashboards
- `rackspace`: Managed services

## Usage

Applications are automatically deployed during cluster provisioning via the openCenter workflow:

1. **Cluster Bootstrap**: Infrastructure provisioning
2. **Flux Installation**: GitOps controller setup
3. **Application Deployment**: Flux processes application manifests
4. **Configuration Sync**: Continuous reconciliation with Git state

### Manual Application Management

```bash
# Check application status
kubectl get helmreleases -A

# View application logs
kubectl logs -n flux-system deploy/helm-controller

# Force reconciliation
flux reconcile helmrelease <app-name> -n <namespace>
```

### Customization

Applications can be customized through:

1. **Helm Values**: Override default chart values
2. **Kustomizations**: Patch base configurations
3. **Overlays**: Environment-specific modifications
4. **ConfigMaps/Secrets**: Runtime configuration

## Security Considerations

- All Helm repositories use HTTPS
- Applications follow least-privilege access patterns
- Network policies enforce traffic segmentation
- Pod security standards prevent privilege escalation
- Secrets are encrypted using sealed-secrets or SOPS

## Monitoring and Observability

The observability stack provides comprehensive monitoring, logging, and tracing:

### Metrics and Monitoring
- **[Kube-Prometheus-Stack](applications/base/services/observability/kube-prometheus-stack/)**: Prometheus, Grafana, and Alertmanager
- **Metrics Collection**: Application and infrastructure metrics
- **Dashboards**: Pre-configured Grafana dashboards for Kubernetes and applications
- **Alerting**: Production-ready alerting rules with notification routing

### Logging
- **[Loki](applications/base/services/observability/loki/)**: Cost-effective log aggregation and storage
- **Log Collection**: Kubernetes and application logs via OpenTelemetry
- **Log Querying**: LogQL for powerful log filtering and analysis
- **Retention**: Configurable log retention policies

### Tracing
- **[Tempo](applications/base/services/observability/tempo/)**: Distributed tracing backend
- **Trace Collection**: OpenTelemetry-based trace ingestion
- **Trace Analysis**: TraceQL for trace querying and analysis
- **Integration**: Unified view with metrics and logs in Grafana

### Data Collection
- **[OpenTelemetry](applications/base/services/observability/opentelemetry-kube-stack/)**: Unified observability framework
- **Auto-instrumentation**: Automatic telemetry collection for applications
- **Data Processing**: Transformation, filtering, and enrichment pipelines
- **Multi-backend Export**: Support for multiple observability backends

## Support and Maintenance

- **Updates**: Managed through GitOps workflow with Flux CD
- **Backup**: [Velero](applications/base/services/velero/) provides application and persistent volume backup/restore
- **Security**: Regular security updates via Flux automation and [Kyverno](applications/base/services/kyverno/) policies
- **Monitoring**: Health checks via [Prometheus/Grafana](applications/base/services/observability/)
- **Storage**: [Longhorn](applications/base/services/longhorn/) for distributed block storage or [vSphere CSI](applications/base/services/vsphere-csi/)/[OpenStack CSI](applications/base/services/openstack-csi/) for cloud storage
- **Secrets Management**: [Sealed Secrets](applications/base/services/sealed-secrets/) for GitOps-friendly secret encryption
- **Identity Management**: [Keycloak](applications/base/services/keycloak/) for OIDC authentication and authorization

## Documentation

For detailed configuration and troubleshooting information, see the individual service documentation:

- **Service Templates**: [docs/templates/](docs/templates/) - Templates for creating new service documentation
- **Configuration Guides**: Each service directory contains comprehensive README files with:
  - Configuration options and examples
  - Cluster-specific override guidance
  - Verification and troubleshooting steps
  - References to upstream documentation

## Getting Started

1. **Review Service Documentation**: Check individual service README files for configuration requirements
2. **Customize Overrides**: Create cluster-specific configuration overrides as needed
3. **Deploy via GitOps**: Commit changes to trigger Flux reconciliation
4. **Monitor Deployment**: Use [Weave GitOps](applications/base/services/weave-gitops/) or [Headlamp](applications/base/services/headlamp/) dashboards to monitor deployment status
5. **Verify Services**: Follow verification steps in each service's documentation

For application-specific documentation, see individual application directories and their respective upstream documentation.
