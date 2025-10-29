# Applications Directory

This directory contains GitOps application manifests that are deployed as part of the openCenter cluster provisioning workflow. All applications are managed using Flux CD and follow GitOps principles for declarative, version-controlled deployments.

## Directory Structure

```
applications/
├── base/                   # Base application configurations
│   ├── genestack-sources/  # Genestack GitOps repository sources
│   ├── managed-services/   # Rackspace-managed services
│   └── services/           # Core cluster services
└── policies/               # Security and network policies
    ├── network-policies/   # Kubernetes network policies
    ├── pod-security-policies/ # Pod security standards
    └── rbac/              # Role-based access controls
```

## Available Applications

### Quick Reference Table

| Application | Category | Namespace | Purpose |
|-------------|----------|-----------|---------|
| **cert-manager** | Core Service | `cert-manager` | Automated certificate management |
| **gateway-api** | Core Service | `gateway-api` | Kubernetes Gateway API implementation |
| **ingress-nginx** | Core Service | `ingress-nginx` | NGINX-based ingress controller |
| **keycloak** | Core Service | `keycloak` | Identity and access management |
| **kube-prometheus-stack** | Core Service | `observability` | Complete monitoring and alerting stack |
| **metallb** | Core Service | `metallb-system` | Bare metal load balancer |
| **olm** | Core Service | `olm` | Operator Lifecycle Manager |
| **opentelemetry-operator** | Core Service | `observability` | OpenTelemetry operator for auto-instrumentation |
| **sealed-secrets** | Core Service | `sealed-secrets` | Encrypted secrets management |
| **velero** | Core Service | `velero` | Cluster backup and disaster recovery |
| **alert-proxy** | Managed Service | `rackspace` | Rackspace alert aggregation |
| **genestack-repo** | Source Repository | `flux-system` | Genestack OpenStack deployment |
| **openstack-helm** | Source Repository | `flux-system` | OpenStack Helm charts |
| **network-policies** | Security Policy | Various | Kubernetes network segmentation |
| **pod-security-policies** | Security Policy | Various | Pod security standards enforcement |
| **rbac** | Security Policy | Various | Role-based access control |

### Core Services (`base/services/`)

#### **cert-manager**
- **Purpose**: Automated certificate management for Kubernetes
- **Source**: Jetstack Helm repository (`https://charts.jetstack.io`)
- **Namespace**: `cert-manager`
- **Features**:
  - Let's Encrypt integration
  - Automatic certificate renewal
  - TLS certificate provisioning for ingress

#### **gateway-api**
- **Purpose**: Kubernetes Gateway API implementation
- **Namespace**: `gateway-api`
- **Features**:
  - Next-generation ingress and traffic management
  - Advanced routing capabilities
  - Service mesh integration ready

#### **ingress-nginx**
- **Purpose**: NGINX-based ingress controller
- **Namespace**: `ingress-nginx`
- **Features**:
  - HTTP/HTTPS load balancing
  - SSL termination
  - Path-based and host-based routing

#### **keycloak**
- **Purpose**: Identity and access management
- **Namespace**: `keycloak`
- **Features**:
  - Single sign-on (SSO)
  - OAuth 2.0 and OpenID Connect
  - Multi-realm support
  - LDAP/Active Directory integration

#### **kube-prometheus-stack**
- **Purpose**: Complete monitoring and alerting stack
- **Namespace**: `observability`
- **Components**:
  - Prometheus for metrics collection
  - Grafana for visualization
  - Alertmanager for alert handling
  - Node Exporter for node metrics
- **Features**:
  - Pre-configured dashboards
  - Alert rules for common scenarios
  - ServiceMonitor auto-discovery

#### **metallb**
- **Purpose**: Bare metal load balancer for Kubernetes
- **Namespace**: `metallb-system`
- **Features**:
  - Layer 2 and BGP load balancing
  - IP address pool management
  - Service type LoadBalancer support

#### **olm**
- **Purpose**: Operator Lifecycle Manager
- **Namespace**: `olm`
- **Features**:
  - Operator installation and management
  - Dependency resolution
  - Automatic updates

#### **opentelemetry-operator**
- **Purpose**: OpenTelemetry operator for auto-instrumentation and collector management
- **Source**: OpenTelemetry Helm repository (`https://open-telemetry.github.io/opentelemetry-helm-charts`)
- **Namespace**: `observability`
- **Features**:
  - Automatic OpenTelemetry instrumentation injection
  - OpenTelemetry Collector deployment and management
  - Custom resource definitions for OpenTelemetry configuration
  - Webhook-based sidecar injection
  - Multi-language auto-instrumentation support (Java, Node.js, Python, .NET, Go)

#### **sealed-secrets**
- **Purpose**: Encrypted secrets management
- **Namespace**: `sealed-secrets`
- **Features**:
  - GitOps-friendly secret encryption
  - Public/private key encryption
  - Automatic secret decryption in cluster

#### **velero**
- **Purpose**: Cluster backup and disaster recovery
- **Namespace**: `velero`
- **Features**:
  - Backup and restore Kubernetes resources
  - Persistent volume snapshots
  - Scheduled backups
  - Cross-cluster migration

### Managed Services (`base/managed-services/`)

#### **alert-proxy**
- **Purpose**: Rackspace alert aggregation and forwarding
- **Namespace**: `rackspace`
- **Features**:
  - Alert collection from monitoring systems
  - Integration with Rackspace support systems
  - Alert routing and escalation

### Source Repositories (`base/genestack-sources/`)

#### **genestack-repo**
- **Purpose**: GitOps source for Genestack OpenStack deployment
- **Source**: `https://github.com/rackerlabs/genestack.git`
- **Version**: `release-2025.2.6`
- **Features**:
  - OpenStack deployment automation
  - Helm chart aggregation
  - GitOps workflow integration

#### **openstack-helm**
- **Purpose**: OpenStack Helm charts repository
- **Features**:
  - Production-ready OpenStack charts
  - Multi-node deployment support
  - HA configuration templates

### Security Policies (`policies/`)

#### **network-policies**
- **Purpose**: Kubernetes network segmentation
- **Status**: Template directory (placeholder.txt)
- **Planned Features**:
  - Namespace isolation
  - Ingress/egress traffic control
  - Zero-trust networking

#### **pod-security-policies**
- **Purpose**: Pod security standards enforcement
- **Status**: Template directory (placeholder.txt)
- **Planned Features**:
  - Security context enforcement
  - Privilege escalation prevention
  - Container security standards

#### **rbac**
- **Purpose**: Role-based access control
- **Features**:
  - Service account management
  - Role and ClusterRole definitions
  - Principle of least privilege

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
- `cert-manager`: Certificate management
- `ingress-nginx`: Ingress controllers
- `observability`: Monitoring and alerting
- `metallb-system`: Load balancing
- `velero`: Backup and recovery
- `keycloak`: Identity and access management
- `rackspace`: Managed services
- `gateway-api`: Next-gen traffic management

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

The kube-prometheus-stack provides comprehensive monitoring:

- **Metrics**: Application and infrastructure metrics via Prometheus
- **Dashboards**: Pre-configured Grafana dashboards
- **Alerts**: Production-ready alerting rules
- **Logs**: Integration with cluster logging stack

## Support and Maintenance

- **Updates**: Managed through GitOps workflow
- **Backup**: Velero provides application backup/restore
- **Security**: Regular security updates via Flux automation
- **Monitoring**: Health checks via Prometheus/Grafana

For application-specific documentation, see individual application directories and their respective upstream documentation.
