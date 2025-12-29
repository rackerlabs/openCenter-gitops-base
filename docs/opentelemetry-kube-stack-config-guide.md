# OpenTelemetry Kube Stack Configuration Guide

## Overview
OpenTelemetry Kube Stack provides a complete observability framework for collecting, processing, and exporting telemetry data (metrics, logs, and traces) from Kubernetes workloads and infrastructure.

## Key Configuration Choices

### Collector Configuration
```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
spec:
  mode: daemonset
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      k8s_cluster:
        auth_type: serviceAccount
      kubeletstats:
        collection_interval: 20s
        auth_type: serviceAccount
        endpoint: ${env:K8S_NODE_NAME}:10250
        insecure_skip_verify: true
    processors:
      batch:
        timeout: 1s
        send_batch_size: 1024
      resource:
        attributes:
        - key: cluster.name
          value: my-cluster
          action: upsert
    exporters:
      otlp/tempo:
        endpoint: http://tempo-distributor:4317
        tls:
          insecure: true
      prometheus:
        endpoint: "0.0.0.0:8889"
      loki:
        endpoint: http://loki-distributor:3100/loki/api/v1/push
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch, resource]
          exporters: [otlp/tempo]
        metrics:
          receivers: [otlp, k8s_cluster, kubeletstats]
          processors: [batch, resource]
          exporters: [prometheus]
        logs:
          receivers: [otlp]
          processors: [batch, resource]
          exporters: [loki]
```
**Why**: 
- DaemonSet mode ensures telemetry collection from all nodes
- Multiple receivers support different telemetry sources
- Processors enable data transformation and enrichment
- Multiple exporters support different backend systems

### Auto-Instrumentation Configuration
```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: default-instrumentation
spec:
  exporter:
    endpoint: http://otel-collector:4317
  propagators:
    - tracecontext
    - baggage
    - b3
  sampler:
    type: parentbased_traceidratio
    argument: "0.1"  # 10% sampling
  java:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:latest
  nodejs:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-nodejs:latest
  python:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-python:latest
```
**Why**: Auto-instrumentation reduces manual instrumentation effort and ensures consistent telemetry collection

### Target Allocator Configuration
```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector-statefulset
spec:
  mode: statefulset
  replicas: 3
  targetAllocator:
    enabled: true
    serviceAccount: opentelemetry-targetallocator-sa
    prometheusCR:
      enabled: true
  config: |
    receivers:
      prometheus:
        config:
          scrape_configs:
          - job_name: 'otel-collector'
            scrape_interval: 10s
            static_configs:
            - targets: ['0.0.0.0:8888']
```
**Why**: Target allocator distributes Prometheus scraping targets across multiple collector instances

## Common Pitfalls

### High Resource Usage
**Problem**: OpenTelemetry collectors consume excessive CPU or memory

**Solution**: Tune batch processors, implement sampling, and scale collectors horizontally

**Verification**:
```bash
# Check collector resource usage
kubectl top pod -n observability -l app.kubernetes.io/name=opentelemetry-collector

# Monitor collector metrics
kubectl port-forward -n observability svc/otel-collector 8888:8888
curl http://localhost:8888/metrics | grep otelcol_processor
```

### Data Export Failures
**Problem**: Telemetry data is not reaching backend systems

**Solution**: Verify exporter configuration, network connectivity, and backend availability

### Auto-Instrumentation Not Working
**Problem**: Applications are not automatically instrumented

**Solution**: Check instrumentation resource configuration and pod annotations

```bash
# Check instrumentation status
kubectl describe instrumentation default-instrumentation

# Verify pod annotations
kubectl get pod <pod-name> -o yaml | grep -A 5 -B 5 instrumentation

# Check operator logs
kubectl logs -n opentelemetry-operator-system deployment/opentelemetry-operator-controller-manager
```

## Required Secrets

### Backend Credentials
For authenticated backends, credentials may be required

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: otel-backend-creds
  namespace: observability
type: Opaque
stringData:
  api-key: your-backend-api-key
  endpoint: https://api.backend.com
```

**Key Fields**:
- `api-key`: Backend API key for authentication (if required)
- `endpoint`: Backend endpoint URL (if required)

### TLS Certificates
For secure communication with backends

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: otel-tls-certs
  namespace: observability
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-cert>
  tls.key: <base64-encoded-key>
  ca.crt: <base64-encoded-ca-cert>
```

**Key Fields**:
- `tls.crt`: Client certificate for mTLS (if required)
- `tls.key`: Client private key for mTLS (if required)
- `ca.crt`: CA certificate for backend verification (if required)

## Verification
```bash
# Check OpenTelemetry operator
kubectl get pods -n opentelemetry-operator-system

# Verify collector instances
kubectl get opentelemetrycollector -n observability

# Check instrumentation resources
kubectl get instrumentation -n observability

# Test collector endpoints
kubectl port-forward -n observability svc/otel-collector 4317:4317
# Send test trace using OTLP
```

## Usage Examples

### Enable Auto-Instrumentation for Application
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    metadata:
      annotations:
        instrumentation.opentelemetry.io/inject-java: "true"
        instrumentation.opentelemetry.io/container-names: "myapp"
    spec:
      containers:
      - name: myapp
        image: myapp:latest
        env:
        - name: OTEL_SERVICE_NAME
          value: myapp
        - name: OTEL_SERVICE_VERSION
          value: "1.0.0"
```

### Custom Processor Configuration
```yaml
processors:
  attributes:
    actions:
    - key: environment
      value: production
      action: upsert
    - key: sensitive_data
      action: delete
  filter:
    traces:
      span:
      - 'attributes["http.url"] == "/health"'
  transform:
    trace_statements:
    - context: span
      statements:
      - set(name, "custom_span_name") where attributes["http.method"] == "GET"
```

### Multi-Pipeline Configuration
```yaml
service:
  pipelines:
    traces/frontend:
      receivers: [otlp]
      processors: [batch, attributes/frontend]
      exporters: [otlp/tempo]
    traces/backend:
      receivers: [jaeger]
      processors: [batch, attributes/backend]
      exporters: [otlp/tempo]
    metrics/infrastructure:
      receivers: [kubeletstats, k8s_cluster]
      processors: [batch, resource]
      exporters: [prometheus]
    metrics/applications:
      receivers: [otlp]
      processors: [batch, filter/applications]
      exporters: [prometheus]
```

### Sampling Configuration
```yaml
processors:
  probabilistic_sampler:
    sampling_percentage: 10  # 10% sampling
  tail_sampling:
    decision_wait: 10s
    num_traces: 100
    expected_new_traces_per_sec: 10
    policies:
    - name: errors
      type: status_code
      status_code: {status_codes: [ERROR]}
    - name: slow
      type: latency
      latency: {threshold_ms: 1000}
    - name: random
      type: probabilistic
      probabilistic: {sampling_percentage: 1}
```

OpenTelemetry provides comprehensive observability data collection and processing. Start with basic configurations and gradually add more sophisticated processing and routing as your observability needs grow.