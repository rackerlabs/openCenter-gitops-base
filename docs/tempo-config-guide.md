# Tempo Configuration Guide

## Overview
Tempo is a distributed tracing backend that provides cost-effective trace storage and querying capabilities, designed to work seamlessly with Grafana and OpenTelemetry.

## Key Configuration Choices

### Storage Configuration
```yaml
tempo:
  storage:
    trace:
      backend: s3
      s3:
        endpoint: s3.amazonaws.com
        bucket: tempo-traces
        region: us-east-1
        access_key: <access-key>
        secret_key: <secret-key>
        insecure: false
  retention: 30d
```
**Why**: 
- Object storage provides cost-effective, scalable trace storage
- S3-compatible storage offers flexibility across cloud providers
- Retention policies manage storage costs and compliance requirements

### Distributor Configuration
```yaml
tempo:
  distributor:
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      jaeger:
        protocols:
          grpc:
            endpoint: 0.0.0.0:14250
          thrift_http:
            endpoint: 0.0.0.0:14268
```
**Why**: Multiple receiver protocols support different tracing clients and migration scenarios

### Query Configuration
```yaml
tempo:
  query_frontend:
    search:
      duration_slo: 5s
      throughput_bytes_slo: 1.073741824e+09  # 1GB
    trace_by_id:
      duration_slo: 5s
  querier:
    max_concurrent_queries: 20
    search:
      external_hedge_requests_at: 8s
      external_hedge_requests_up_to: 2
```
**Why**: Query limits and SLOs prevent resource exhaustion and ensure consistent performance

## Common Pitfalls

### High Ingestion Rate Issues
**Problem**: Tempo cannot keep up with high trace ingestion rates

**Solution**: Scale distributors and ingesters, tune batch sizes, and implement sampling

**Verification**:
```bash
# Check distributor metrics
kubectl port-forward -n observability svc/tempo-distributor 3200:3200
curl http://localhost:3200/metrics | grep tempo_distributor

# Monitor ingestion rate
kubectl logs -n observability deployment/tempo-distributor | grep "ingestion rate"
```

### Query Performance Problems
**Problem**: TraceQL queries are slow or time out

**Solution**: Use proper time ranges, limit search scope, and optimize query patterns

### Storage Backend Issues
**Problem**: Tempo cannot write traces to or read from object storage

**Solution**: Verify storage credentials, bucket permissions, and network connectivity

```bash
# Check ingester logs
kubectl logs -n observability deployment/tempo-ingester

# Verify storage configuration
kubectl exec -n observability deployment/tempo-querier -- \
  wget -qO- 'http://localhost:3200/ready'

# Test object storage connectivity
kubectl exec -n observability deployment/tempo-ingester -- \
  aws s3 ls s3://tempo-traces/ --region us-east-1
```

## Required Secrets

### Object Storage Credentials
Tempo requires credentials for accessing trace storage

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tempo-storage
  namespace: observability
type: Opaque
stringData:
  access-key: your-access-key
  secret-key: your-secret-key
```

**Key Fields**:
- `access-key`: S3 access key ID (required)
- `secret-key`: S3 secret access key (required)

### Gateway Authentication
For multi-tenant deployments, authentication credentials may be required

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tempo-gateway-auth
  namespace: observability
type: Opaque
stringData:
  htpasswd: |
    tenant1:$2y$10$...
    tenant2:$2y$10$...
```

**Key Fields**:
- `htpasswd`: HTTP basic auth credentials file (required for gateway auth)

## Verification
```bash
# Check Tempo pods are running
kubectl get pods -n observability -l app.kubernetes.io/name=tempo

# Verify Tempo services
kubectl get svc -n observability -l app.kubernetes.io/name=tempo

# Test Tempo API
kubectl port-forward -n observability svc/tempo-query-frontend 3200:3200
curl http://localhost:3200/ready

# Query traces
curl -G -s "http://localhost:3200/api/search" \
  --data-urlencode 'q={service.name="myservice"}' \
  --data-urlencode 'limit=10'
```

## Usage Examples

### Query Traces with TraceQL
```bash
# Find traces by service name
{service.name="myservice"}

# Filter by duration
{service.name="myservice" && duration > 100ms}

# Search by span attributes
{span.http.status_code=500}

# Complex query with multiple conditions
{service.name="frontend" && span.http.method="POST" && duration > 1s}
```

### Configure OpenTelemetry to Send Traces
```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
spec:
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
    exporters:
      otlp/tempo:
        endpoint: http://tempo-distributor:4317
        tls:
          insecure: true
    service:
      pipelines:
        traces:
          receivers: [otlp]
          exporters: [otlp/tempo]
```

### Configure Grafana Data Source
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tempo-datasource
  namespace: observability
data:
  datasource.yaml: |
    apiVersion: 1
    datasources:
    - name: Tempo
      type: tempo
      access: proxy
      url: http://tempo-query-frontend:3200
      isDefault: false
      editable: true
      jsonData:
        tracesToLogs:
          datasourceUid: loki
          tags: ['job', 'instance', 'pod', 'namespace']
        tracesToMetrics:
          datasourceUid: prometheus
          tags: [{ key: 'service.name', value: 'service' }]
        serviceMap:
          datasourceUid: prometheus
```

### Set Up Trace Sampling
```yaml
tempo:
  distributor:
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
    # Sampling configuration
    log_received_traces: true
  global_overrides:
    max_traces_per_user: 10000
    max_bytes_per_trace: 5000000  # 5MB
```

Tempo provides efficient distributed tracing storage and querying. Focus on proper sampling strategies and retention policies to balance observability needs with storage costs.