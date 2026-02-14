# Service Catalog Reference

**Type:** Reference  
**Audience:** All users  
**Last Updated:** 2026-02-14

This document lists all platform services available in openCenter-gitops-base with their configurations, versions, and dependencies.

---

## Core Platform Services

### cert-manager

**Purpose:** Automated TLS certificate management  
**Namespace:** `cert-manager`  
**Chart Repository:** Jetstack  
**Current Version:** v1.18.2  
**Dependencies:** None

**Key Features:**
- Automatic certificate issuance and renewal
- Let's Encrypt integration
- Internal CA support
- Certificate injection into Ingress/Gateway resources

**Configuration Surfaces:**
- ClusterIssuer resources for certificate authorities
- Certificate resources for TLS certificates
- Ingress annotations for automatic certificate provisioning

---

### Harbor

**Purpose:** Container registry with security scanning  
**Namespace:** `harbor`  
**Chart Repository:** Harbor  
**Dependencies:** cert-manager (for TLS)

**Key Features:**
- OCI-compliant container registry
- Vulnerability scanning
- Image signing and verification
- Replication across registries
- RBAC and project management

**Configuration Surfaces:**
- Harbor admin portal
- Robot accounts for CI/CD
- Replication policies
- Scan policies

---

### Keycloak

**Purpose:** Identity and access management (IAM)  
**Namespace:** `keycloak`  
**Chart Repository:** Bitnami  
**Dependencies:** PostgreSQL (included as sub-component)

**Multi-Component Structure:**
- `00-postgres/` - PostgreSQL database
- `10-operator/` - Keycloak operator
- `20-keycloak/` - Keycloak instance
- `30-oidc-rbac/` - OIDC RBAC definitions

**Key Features:**
- OIDC/SAML authentication
- User federation (LDAP/AD)
- Social login integration
- Multi-realm support

**Configuration Surfaces:**
- Keycloak admin console
- Realm configuration
- Client definitions
- Identity provider mappings

---

### Kyverno

**Purpose:** Kubernetes policy engine  
**Namespace:** `kyverno`  
**Chart Repository:** Kyverno  
**Dependencies:** None

**Key Features:**
- Policy validation, mutation, and generation
- Image verification
- Pod security enforcement
- Resource quota management

**Configuration Surfaces:**
- ClusterPolicy resources
- Policy resources (namespaced)
- PolicyReport for compliance status

---

### Longhorn

**Purpose:** Distributed block storage  
**Namespace:** `longhorn-system`  
**Chart Repository:** Longhorn  
**Dependencies:** None

**Key Features:**
- Replicated block storage
- Snapshot and backup
- Volume encryption
- Disaster recovery

**Configuration Surfaces:**
- StorageClass definitions
- Longhorn UI
- Backup targets
- Volume snapshots

---

### MetalLB

**Purpose:** Load balancer for bare metal  
**Namespace:** `metallb-system`  
**Chart Repository:** MetalLB  
**Dependencies:** None

**Key Features:**
- Layer 2 and BGP modes
- IP address pool management
- Service LoadBalancer support

**Configuration Surfaces:**
- IPAddressPool resources
- L2Advertisement or BGPAdvertisement
- BGP peer configuration

---

### Velero

**Purpose:** Backup and disaster recovery  
**Namespace:** `velero`  
**Chart Repository:** VMware  
**Dependencies:** Object storage (S3-compatible)

**Key Features:**
- Cluster backup and restore
- Scheduled backups
- Volume snapshots
- Migration between clusters

**Configuration Surfaces:**
- Backup schedules
- Backup storage locations
- Volume snapshot locations
- Restore configurations

---

## Storage Drivers

### vSphere CSI

**Purpose:** VMware vSphere storage driver  
**Namespace:** `vmware-system-csi`  
**Chart Repository:** VMware  
**Dependencies:** vSphere infrastructure

**Key Features:**
- Dynamic volume provisioning
- Volume snapshots
- Volume expansion
- Topology-aware scheduling

**Configuration Surfaces:**
- StorageClass definitions
- vSphere credentials
- Datastore mappings

---

### OpenStack Cinder CSI

**Purpose:** OpenStack block storage driver  
**Namespace:** `openstack-csi`  
**Chart Repository:** Kubernetes Cloud Provider  
**Dependencies:** OpenStack infrastructure

**Key Features:**
- Dynamic volume provisioning
- Volume snapshots
- Volume types
- Availability zone support

---

### OpenStack Cloud Controller Manager

**Purpose:** OpenStack cloud provider integration  
**Namespace:** `kube-system`  
**Chart Repository:** Kubernetes Cloud Provider  
**Dependencies:** OpenStack infrastructure

**Key Features:**
- LoadBalancer service support
- Node lifecycle management
- Route management

---

## Networking Services

### Gateway API

**Purpose:** Next-generation ingress API  
**Namespace:** `gateway-system`  
**Chart Repository:** Kubernetes SIGs  
**Dependencies:** Gateway implementation (Envoy Gateway or Istio)

**Key Features:**
- Role-oriented API design
- Advanced routing (header, query param)
- Traffic splitting
- Cross-namespace routing with ReferenceGrant

**Configuration Surfaces:**
- Gateway resources
- HTTPRoute resources
- ReferenceGrant for cross-namespace access
- GatewayClass for implementation selection

---

### Envoy Gateway

**Purpose:** Gateway API implementation using Envoy  
**Namespace:** `envoy-gateway-system`  
**Chart Repository:** Envoy Gateway  
**Dependencies:** Gateway API CRDs

**Key Features:**
- High-performance proxy
- Rate limiting
- Authentication
- Observability integration

**Configuration Surfaces:**
- EnvoyGateway configuration
- EnvoyProxy resources
- Backend resources

---

### Istio

**Purpose:** Service mesh  
**Namespace:** `istio-system`  
**Chart Repository:** Istio  
**Dependencies:** None

**Key Features:**
- Traffic management
- Security (mTLS)
- Observability
- Policy enforcement

**Configuration Surfaces:**
- VirtualService for routing
- DestinationRule for load balancing
- PeerAuthentication for mTLS
- AuthorizationPolicy for access control

---

### Calico

**Purpose:** Container networking (CNI)  
**Namespace:** `kube-system`  
**Chart Repository:** Tigera  
**Dependencies:** None

**Key Features:**
- Pod networking
- Network policies
- BGP routing
- IP address management

**Configuration Surfaces:**
- NetworkPolicy resources
- IPPool resources
- BGPConfiguration

---

## Observability Stack

### kube-prometheus-stack

**Purpose:** Prometheus monitoring and alerting  
**Namespace:** `monitoring`  
**Chart Repository:** Prometheus Community  
**Dependencies:** None

**Components:**
- Prometheus Operator
- Prometheus server
- Alertmanager
- Grafana
- Node exporter
- Kube-state-metrics

**Key Features:**
- Metrics collection and storage
- Alert rules and routing
- Grafana dashboards
- ServiceMonitor/PodMonitor for scraping

**Configuration Surfaces:**
- PrometheusRule for alerts
- ServiceMonitor for scraping
- Grafana dashboards (JSON)
- Alertmanager configuration

---

### Loki

**Purpose:** Log aggregation  
**Namespace:** `loki`  
**Chart Repository:** Grafana  
**Dependencies:** Object storage (S3-compatible)

**Key Features:**
- Horizontally scalable log storage
- LogQL query language
- Label-based indexing
- Grafana integration

**Configuration Surfaces:**
- Loki configuration (YAML)
- Log retention policies
- Storage configuration
- Promtail/Fluentd/OTel collector integration

---

### Tempo

**Purpose:** Distributed tracing  
**Namespace:** `tempo`  
**Chart Repository:** Grafana  
**Dependencies:** Object storage (S3-compatible)

**Key Features:**
- Trace storage and querying
- TraceQL query language
- Multi-tenant support
- Grafana integration

**Configuration Surfaces:**
- Tempo configuration (YAML)
- Trace retention policies
- Storage configuration
- OTLP receiver endpoints

---

### OpenTelemetry Kube Stack

**Purpose:** OpenTelemetry collector for Kubernetes  
**Namespace:** `opentelemetry`  
**Chart Repository:** OpenTelemetry  
**Dependencies:** None

**Key Features:**
- Metrics, logs, and traces collection
- Protocol translation (OTLP, Prometheus, Jaeger)
- Data processing and routing
- Kubernetes metadata enrichment

**Configuration Surfaces:**
- OpenTelemetryCollector CRD
- Receiver, processor, exporter configuration
- Instrumentation CRD for auto-instrumentation

---

## Management and UI

### Headlamp

**Purpose:** Kubernetes web UI  
**Namespace:** `headlamp`  
**Chart Repository:** Headlamp  
**Dependencies:** None

**Key Features:**
- Cluster resource management
- RBAC-aware interface
- Plugin system
- Multi-cluster support

---

### Weave GitOps

**Purpose:** FluxCD web UI  
**Namespace:** `flux-system`  
**Chart Repository:** Weaveworks  
**Dependencies:** FluxCD

**Key Features:**
- GitOps workflow visualization
- Flux resource management
- Application deployment status
- Git repository integration

---

## Operators and Extensions

### Operator Lifecycle Manager (OLM)

**Purpose:** Operator management framework  
**Namespace:** `olm`  
**Chart Repository:** Operator Framework  
**Dependencies:** None

**Key Features:**
- Operator installation and upgrades
- Dependency resolution
- Operator catalog management

---

### PostgreSQL Operator

**Purpose:** PostgreSQL database management  
**Namespace:** `postgres-operator`  
**Chart Repository:** Zalando  
**Dependencies:** None

**Key Features:**
- PostgreSQL cluster provisioning
- High availability
- Backup and restore
- Connection pooling

---

### Strimzi Kafka Operator

**Purpose:** Apache Kafka management  
**Namespace:** `kafka`  
**Chart Repository:** Strimzi  
**Dependencies:** None

**Key Features:**
- Kafka cluster provisioning
- Topic and user management
- Kafka Connect integration
- Schema registry

---

## Security Services

### RBAC Manager

**Purpose:** Simplified RBAC management  
**Namespace:** `rbac-manager`  
**Chart Repository:** FairwindsOps  
**Dependencies:** None

**Key Features:**
- Declarative RBAC definitions
- Group-based access control
- OIDC integration

---

### Sealed Secrets

**Purpose:** Encrypted secrets in Git  
**Namespace:** `sealed-secrets`  
**Chart Repository:** Bitnami  
**Dependencies:** None

**Key Features:**
- Asymmetric encryption for secrets
- Git-safe secret storage
- Automatic decryption in cluster

**Configuration Surfaces:**
- SealedSecret resources
- Encryption keys (cluster-scoped)

---

## Storage Utilities

### External Snapshotter

**Purpose:** Volume snapshot support  
**Namespace:** `kube-system`  
**Chart Repository:** Kubernetes CSI  
**Dependencies:** CSI driver with snapshot support

**Key Features:**
- Volume snapshot creation
- Snapshot restore
- Snapshot content management

---

## Service Dependencies

```
cert-manager (no dependencies)
  └─> Harbor (TLS certificates)
  └─> Keycloak (TLS certificates)
  └─> Grafana (TLS certificates)

Keycloak
  └─> PostgreSQL (included)

Gateway API
  └─> Envoy Gateway or Istio (implementation)

kube-prometheus-stack (no dependencies)
  └─> Grafana (included)

Loki
  └─> Object storage (S3-compatible)

Tempo
  └─> Object storage (S3-compatible)

Velero
  └─> Object storage (S3-compatible)
```

---

## Service Labels

All services include standardized labels:

```yaml
metadata:
  labels:
    app.kubernetes.io/name: <service-name>
    app.kubernetes.io/instance: <instance-name>
    app.kubernetes.io/version: <version>
    app.kubernetes.io/component: <component>
    app.kubernetes.io/part-of: <platform>
    app.kubernetes.io/managed-by: fluxcd
    opencenter.io/owner: <team>
    opencenter.io/tier: platform
    opencenter.io/data-sensitivity: <level>
```

---

## Evidence

**Source Files:**
- `README.md` (service list)
- `applications/base/services/*/helmrelease.yaml` (service configurations)
- `applications/base/services/*/namespace.yaml` (namespace definitions)
- `docs/service-standards-and-lifecycle.md` (service standards)
- `docs/*-config-guide.md` (service-specific guides)
- `docs/analysis/S1-APP-RUNTIME-APIS.md` (service analysis)
