# Percona Server for MongoDB Operator

The Percona Server for MongoDB Operator (PSMDB Operator) is a Kubernetes operator that automates the deployment, management, and operations of Percona Server for MongoDB clusters. It provides enterprise-grade MongoDB deployments with built-in security, backup, and monitoring capabilities.

## Overview

The PSMDB Operator simplifies MongoDB operations in Kubernetes by providing:
- **Automated Deployment**: Deploy MongoDB replica sets and sharded clusters
- **High Availability**: Built-in replica set management and failover
- **Security**: TLS encryption, authentication, and authorization
- **Backup & Recovery**: Automated backup scheduling and point-in-time recovery
- **Monitoring**: Integration with Percona Monitoring and Management (PMM)
- **Scaling**: Horizontal and vertical scaling operations

## Configuration

### Chart Information
- **Chart**: psmdb-operator
- **Version**: 1.21.1
- **App Version**: 1.21.0
- **Repository**: https://percona.github.io/percona-helm-charts

### Namespace
Deployed in the `psmdb-operator` namespace for proper isolation from database workloads.

### Operator Features

#### MongoDB Management
- **Replica Sets**: Automated deployment and management of MongoDB replica sets
- **Sharded Clusters**: Support for MongoDB sharded cluster deployments
- **Version Management**: Automated MongoDB version upgrades and downgrades
- **Configuration Management**: Dynamic configuration updates without downtime

#### Security Features
- **TLS Encryption**: Automatic TLS certificate management for client and inter-node communication
- **Authentication**: SCRAM-SHA-256 and x.509 certificate authentication
- **Authorization**: Role-based access control (RBAC) integration
- **Network Security**: Pod security policies and network policies support

#### Backup & Recovery
- **Scheduled Backups**: Automated backup scheduling with retention policies
- **Point-in-Time Recovery**: Restore to any point in time within the backup retention period
- **Storage Options**: Support for S3, GCS, Azure Blob, and local storage
- **Incremental Backups**: Efficient incremental backup strategies

#### Monitoring & Observability
- **PMM Integration**: Built-in Percona Monitoring and Management integration
- **Metrics Export**: Prometheus metrics for monitoring and alerting
- **Health Checks**: Comprehensive health monitoring and status reporting
- **Logging**: Structured logging with configurable log levels

### Security Hardening

The deployment includes comprehensive security configurations:

#### Container Security
- Non-root execution (`runAsNonRoot: true`)
- Specific user ID (`runAsUser: 65534`)
- Security profiles (`seccompProfile.type: RuntimeDefault`)
- Capability dropping (`capabilities.drop: [ALL]`)
- Read-only root filesystem (`readOnlyRootFilesystem: true`)
- Privilege escalation disabled (`allowPrivilegeEscalation: false`)

#### Resource Management
- CPU and memory limits defined for operator pod
- Resource requests set for proper scheduling
- Concurrency control for resource reconciliation

#### Operational Security
- Telemetry disabled for privacy (`disableTelemetry: true`)
- Namespace-scoped deployment (not cluster-wide)
- Structured logging enabled for audit trails
- Prometheus metrics for monitoring

### Key Components

#### Operator Controller
- **Purpose**: Manages MongoDB cluster lifecycle
- **Responsibilities**:
  - Custom Resource Definition (CRD) management
  - MongoDB cluster provisioning and scaling
  - Backup and restore operations
  - Security policy enforcement

#### Custom Resources
The operator manages several custom resources:

##### PerconaServerMongoDB (PSMDB)
Main resource for MongoDB cluster definition:
```yaml
apiVersion: psmdb.percona.com/v1
kind: PerconaServerMongoDB
metadata:
  name: my-cluster
spec:
  image: percona/percona-server-mongodb:7.0.14-8
  replsets:
    - name: rs0
      size: 3
      resources:
        limits:
          cpu: "1"
          memory: "1Gi"
        requests:
          cpu: "500m"
          memory: "512Mi"
```

##### PerconaServerMongoDBBackup
Resource for backup management:
```yaml
apiVersion: psmdb.percona.com/v1
kind: PerconaServerMongoDBBackup
metadata:
  name: backup1
spec:
  psmdbCluster: my-cluster
  storageName: s3-storage
```

##### PerconaServerMongoDBRestore
Resource for restore operations:
```yaml
apiVersion: psmdb.percona.com/v1
kind: PerconaServerMongoDBRestore
metadata:
  name: restore1
spec:
  clusterName: my-cluster
  backupName: backup1
```

### Customization

#### Operator Configuration
Adjust operator behavior:

```yaml
# Resource limits for operator
resources:
  requests:
    memory: "256Mi"
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "1000m"

# Increase concurrency for large deployments
maxConcurrentReconciles: "3"

# Enable debug logging
logLevel: "DEBUG"
```

#### Namespace Watching
Configure which namespaces the operator watches:

```yaml
# Watch specific namespaces
watchNamespace: "mongodb-prod,mongodb-dev"

# Or watch all namespaces (less secure)
watchAllNamespaces: true
```

#### Monitoring Integration
Enable Prometheus monitoring:

```yaml
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"
```

### Dependencies

#### Required Components
- Kubernetes 1.19+ with CustomResourceDefinition support
- StorageClass for persistent volumes
- Network policies support (optional but recommended)

#### Optional Components
- **Percona Monitoring and Management (PMM)**: For advanced monitoring
- **Backup Storage**: S3, GCS, or Azure Blob for backup storage
- **Certificate Manager**: For automated TLS certificate management

### Compatibility

#### Existing Services
The operator is designed to work alongside existing services:
- **kube-prometheus-stack**: Metrics integration via Prometheus
- **cert-manager**: TLS certificate automation
- **velero**: Cluster-level backup integration
- **sealed-secrets**: Secret management for database credentials

#### MongoDB Versions
Supports multiple MongoDB versions:
- MongoDB 4.4, 5.0, 6.0, 7.0
- Percona Server for MongoDB with enhanced security features
- Automatic version upgrade capabilities

### Monitoring and Observability

#### Health Checks
Monitor the operator deployment:
```bash
kubectl get helmrelease psmdb-operator -n psmdb-operator
kubectl get pods -n psmdb-operator -l app.kubernetes.io/name=psmdb-operator
```

#### Operator Status
Check operator functionality:
```bash
# View operator logs
kubectl logs -n psmdb-operator -l app.kubernetes.io/name=psmdb-operator

# Check custom resource definitions
kubectl get crd | grep psmdb

# List MongoDB clusters
kubectl get psmdb -A
```

#### Metrics Access
Access operator metrics:
```bash
kubectl port-forward -n psmdb-operator svc/psmdb-operator 8080:8080
curl http://localhost:8080/metrics
```

### Troubleshooting

#### Common Issues

1. **CRD Installation Problems**
   - Verify Kubernetes version compatibility
   - Check RBAC permissions for CRD creation
   - Ensure cluster-admin privileges during installation

2. **Operator Pod Crashes**
   - Check resource limits and requests
   - Verify security context compatibility
   - Review operator logs for specific errors

3. **MongoDB Cluster Issues**
   - Verify storage class availability
   - Check network policies and connectivity
   - Ensure sufficient cluster resources

#### Debug Commands
```bash
# Check operator deployment
kubectl describe deployment psmdb-operator -n psmdb-operator

# View operator events
kubectl get events -n psmdb-operator --sort-by='.lastTimestamp'

# Check RBAC permissions
kubectl auth can-i create psmdb --as=system:serviceaccount:psmdb-operator:psmdb-operator

# Validate CRDs
kubectl get crd perconaservermongodbs.psmdb.percona.com -o yaml
```

### Usage Examples

#### Basic MongoDB Cluster
Deploy a simple 3-node replica set:

```yaml
apiVersion: psmdb.percona.com/v1
kind: PerconaServerMongoDB
metadata:
  name: my-cluster
  namespace: mongodb
spec:
  crVersion: "1.21.0"
  image: percona/percona-server-mongodb:7.0.14-8
  imagePullPolicy: Always
  
  secrets:
    users: my-cluster-secrets
  
  replsets:
    - name: rs0
      size: 3
      resources:
        limits:
          cpu: "1"
          memory: "1Gi"
        requests:
          cpu: "500m"
          memory: "512Mi"
      volumeSpec:
        persistentVolumeClaim:
          resources:
            requests:
              storage: 10Gi
```

#### Backup Configuration
Set up automated backups:

```yaml
apiVersion: psmdb.percona.com/v1
kind: PerconaServerMongoDB
metadata:
  name: my-cluster
spec:
  backup:
    enabled: true
    image: percona/percona-backup-mongodb:2.7.0
    storages:
      s3-storage:
        type: s3
        s3:
          bucket: mongodb-backups
          credentialsSecret: backup-s3-credentials
          region: us-east-1
    tasks:
      - name: daily-backup
        enabled: true
        schedule: "0 2 * * *"
        keep: 7
        storageName: s3-storage
```

#### Monitoring Setup
Enable PMM monitoring:

```yaml
apiVersion: psmdb.percona.com/v1
kind: PerconaServerMongoDB
metadata:
  name: my-cluster
spec:
  pmm:
    enabled: true
    image: percona/pmm-client:2.43.1
    serverHost: pmm-server.monitoring.svc.cluster.local
```

### Production Considerations

#### Security
- Use strong authentication credentials
- Enable TLS for all connections
- Implement network policies for traffic isolation
- Regular security updates and patches

#### Performance
- Size persistent volumes appropriately
- Configure resource limits based on workload
- Use dedicated storage classes for performance
- Monitor and tune MongoDB configuration

#### High Availability
- Deploy across multiple availability zones
- Configure appropriate replica set sizes
- Implement backup and disaster recovery procedures
- Set up monitoring and alerting

#### Scaling
- Plan for horizontal scaling requirements
- Configure sharding for large datasets
- Monitor resource utilization
- Implement capacity planning procedures

This operator provides enterprise-grade MongoDB management capabilities with comprehensive security, monitoring, and operational features suitable for production environments.