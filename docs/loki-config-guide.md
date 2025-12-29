# Loki Configuration Guide

## Overview
Loki is a horizontally-scalable, highly-available log aggregation system designed to store and query logs from all your applications and infrastructure.

## Key Configuration Choices

### Storage Configuration
```yaml
loki:
  storage:
    type: s3
    bucketNames:
      chunks: loki-chunks
      ruler: loki-ruler
      admin: loki-admin
    s3:
      endpoint: s3.amazonaws.com
      region: us-east-1
      accessKeyId: <access-key>
      secretAccessKey: <secret-key>
      s3ForcePathStyle: false
```
**Why**: 
- Object storage provides cost-effective, scalable log storage
- Separate buckets for different data types improve organization
- S3-compatible storage offers flexibility across cloud providers

### Retention and Limits Configuration
```yaml
loki:
  limits_config:
    retention_period: 30d
    ingestion_rate_mb: 10
    ingestion_burst_size_mb: 20
    max_query_parallelism: 32
    max_streams_per_user: 10000
    max_line_size: 256KB
  compactor:
    retention_enabled: true
    retention_delete_delay: 2h
    retention_delete_worker_count: 150
```
**Why**: Retention policies manage storage costs and query limits prevent resource exhaustion

### Multi-tenancy Configuration
```yaml
loki:
  auth_enabled: true
  server:
    http_listen_port: 3100
    grpc_listen_port: 9095
  distributor:
    ring:
      kvstore:
        store: memberlist
  memberlist:
    join_members:
    - loki-memberlist
```
**Why**: Multi-tenancy provides isolation between different teams or applications

## Common Pitfalls

### High Cardinality Labels
**Problem**: Too many unique label combinations cause performance issues and high storage costs

**Solution**: Use structured logging and limit labels to low-cardinality values like service, environment, and level

**Verification**:
```bash
# Check label cardinality
kubectl exec -n observability deployment/loki-querier -- \
  wget -qO- 'http://localhost:3100/loki/api/v1/label'

# Monitor ingestion rate
kubectl logs -n observability deployment/loki-distributor | grep "ingestion rate"
```

### Query Performance Issues
**Problem**: LogQL queries are slow or time out

**Solution**: Use proper time ranges, label filters, and avoid regex operations on large datasets

### Storage Backend Issues
**Problem**: Loki cannot write to or read from object storage

**Solution**: Verify storage credentials, bucket permissions, and network connectivity

```bash
# Check Loki ingester logs
kubectl logs -n observability deployment/loki-ingester

# Verify storage configuration
kubectl exec -n observability deployment/loki-querier -- \
  wget -qO- 'http://localhost:3100/ready'

# Test object storage connectivity
kubectl exec -n observability deployment/loki-ingester -- \
  aws s3 ls s3://loki-chunks/ --region us-east-1
```

## Required Secrets

### Object Storage Credentials
Loki requires credentials for accessing object storage

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: loki-storage
  namespace: observability
type: Opaque
stringData:
  access-key-id: your-access-key
  secret-access-key: your-secret-key
```

**Key Fields**:
- `access-key-id`: S3 access key ID (required)
- `secret-access-key`: S3 secret access key (required)

### Gateway Authentication
For multi-tenant deployments, authentication credentials may be required

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: loki-gateway-auth
  namespace: observability
type: Opaque
stringData:
  htpasswd: |
    user1:$2y$10$...
    user2:$2y$10$...
```

**Key Fields**:
- `htpasswd`: HTTP basic auth credentials file (required for gateway auth)

## Verification
```bash
# Check Loki pods are running
kubectl get pods -n observability -l app.kubernetes.io/name=loki

# Verify Loki services
kubectl get svc -n observability -l app.kubernetes.io/name=loki

# Test Loki API
kubectl port-forward -n observability svc/loki 3100:3100
curl http://localhost:3100/ready

# Query logs
curl -G -s "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={job="kubernetes-pods"}' \
  --data-urlencode 'limit=10'
```

## Usage Examples

### Query Logs with LogQL
```bash
# Query logs from specific namespace
{namespace="myapp"}

# Filter by log level
{namespace="myapp"} |= "ERROR"

# Rate query for error logs
rate({namespace="myapp"} |= "ERROR" [5m])

# Extract and count HTTP status codes
{job="nginx"} | json | __error__ = "" | line_format "{{.status}}" | unwrap status | rate[5m]
```

### Configure Log Shipping with OpenTelemetry
```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
spec:
  config: |
    receivers:
      filelog:
        include:
        - /var/log/pods/*/*/*.log
        operators:
        - type: json_parser
          id: parser-docker
          output: extract_metadata_from_filepath
    exporters:
      loki:
        endpoint: http://loki:3100/loki/api/v1/push
        tenant_id: "tenant1"
    service:
      pipelines:
        logs:
          receivers: [filelog]
          exporters: [loki]
```

### Create Grafana Data Source
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-datasource
  namespace: observability
data:
  datasource.yaml: |
    apiVersion: 1
    datasources:
    - name: Loki
      type: loki
      access: proxy
      url: http://loki:3100
      isDefault: false
      editable: true
```

Loki provides cost-effective log aggregation with powerful querying capabilities. Focus on proper label design and retention policies to optimize performance and storage costs.