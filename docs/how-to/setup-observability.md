---
doc_type: how-to
title: "Set Up Service Observability"
audience: "platform engineers"
---

# Set Up Service Observability

**Purpose:** For platform engineers, shows how to configure metrics, logs, and traces for a service, covering Prometheus scraping, Loki log shipping, and Tempo distributed tracing.

## Prerequisites

- Observability stack deployed (kube-prometheus-stack, Loki, Tempo, OpenTelemetry)
- Service deployed in cluster
- Service exposes metrics endpoint
- kubectl access to cluster

## Observability Requirements

All platform services must provide:

- **Metrics:** RED/USE metrics (Rate, Errors, Duration / Utilization, Saturation, Errors)
- **Logs:** Structured JSON logs with correlation IDs
- **Traces:** Distributed tracing via OpenTelemetry OTLP
- **Dashboards:** Grafana dashboard JSON in repository
- **Alerts:** PrometheusRule with actionable runbooks

## Steps

### 1. Configure Prometheus metrics scraping

Create ServiceMonitor for automatic scraping:

Create `applications/overlays/k8s-sandbox/services/my-service/servicemonitor.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-service
  namespace: my-service
  labels:
    app.kubernetes.io/name: my-service
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: my-service
  
  endpoints:
    - port: metrics
      path: /metrics
      interval: 30s
      scrapeTimeout: 10s
      
      # Optional: relabel metrics
      relabelings:
        - sourceLabels: [__meta_kubernetes_pod_name]
          targetLabel: pod
        - sourceLabels: [__meta_kubernetes_namespace]
          targetLabel: namespace
```

For non-standard ports:

```yaml
endpoints:
  - port: http
    path: /actuator/prometheus  # Spring Boot example
    interval: 30s
```

Apply:

```bash
kubectl apply -f applications/overlays/k8s-sandbox/services/my-service/servicemonitor.yaml
```

Verify scraping:

```bash
# Check ServiceMonitor
kubectl get servicemonitor my-service -n my-service

# Check Prometheus targets
kubectl port-forward -n observability svc/kube-prometheus-stack-prometheus 9090:9090

# Open browser: http://localhost:9090/targets
# Search for "my-service"
```

### 2. Configure structured logging

Update service to output JSON logs:

Example application configuration:

```yaml
# For Go applications
logging:
  format: json
  level: info
  output: stdout

# For Node.js (Winston)
logging:
  format: json
  transports:
    - type: console
      level: info

# For Python (structlog)
logging:
  format: json
  level: INFO
  handlers:
    - stream: ext://sys.stdout
```

Required log fields:

```json
{
  "timestamp": "2024-02-14T10:30:00Z",
  "level": "info",
  "message": "Request processed",
  "service": "my-service",
  "trace_id": "abc123def456",
  "span_id": "ghi789jkl012",
  "user_id": "user-123",
  "request_id": "req-456",
  "duration_ms": 45,
  "status_code": 200
}
```

### 3. Configure Loki log collection

OpenTelemetry collector automatically scrapes pod logs. Verify configuration:

```bash
# Check OpenTelemetry collector
kubectl get pods -n observability -l app.kubernetes.io/name=opentelemetry-collector

# Check collector configuration
kubectl get configmap opentelemetry-collector -n observability -o yaml
```

Add log parsing annotations to pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-service
  annotations:
    # Parse JSON logs
    loki.grafana.com/scrape: "true"
    loki.grafana.com/format: "json"
spec:
  containers:
    - name: my-service
      image: my-service:1.0.0
```

Query logs in Grafana:

```bash
# Port-forward to Grafana
kubectl port-forward -n observability svc/kube-prometheus-stack-grafana 3000:80

# Open browser: http://localhost:3000
# Navigate to Explore > Loki
# Query: {namespace="my-service"}
```

### 4. Configure distributed tracing

Add OpenTelemetry SDK to application:

Example for Go:

```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/sdk/trace"
)

func initTracer() {
    exporter, _ := otlptracegrpc.New(
        context.Background(),
        otlptracegrpc.WithEndpoint("opentelemetry-collector.observability.svc.cluster.local:4317"),
        otlptracegrpc.WithInsecure(),
    )
    
    tp := trace.NewTracerProvider(
        trace.WithBatcher(exporter),
        trace.WithResource(resource.NewWithAttributes(
            semconv.SchemaURL,
            semconv.ServiceNameKey.String("my-service"),
        )),
    )
    
    otel.SetTracerProvider(tp)
}
```

Configure service to send traces:

```yaml
# Environment variables for OpenTelemetry
env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "http://opentelemetry-collector.observability.svc.cluster.local:4317"
  - name: OTEL_SERVICE_NAME
    value: "my-service"
  - name: OTEL_TRACES_SAMPLER
    value: "parentbased_traceidratio"
  - name: OTEL_TRACES_SAMPLER_ARG
    value: "0.1"  # Sample 10% of traces
```

Verify traces in Grafana:

```bash
# Navigate to Explore > Tempo
# Query by trace ID or service name
```

### 5. Create Grafana dashboard

Export dashboard JSON and commit to repository:

Create `applications/overlays/k8s-sandbox/services/my-service/dashboard.json`:

```json
{
  "dashboard": {
    "title": "My Service",
    "tags": ["my-service", "platform"],
    "timezone": "browser",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{service=\"my-service\"}[5m])",
            "legendFormat": "{{method}} {{status}}"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{service=\"my-service\",status=~\"5..\"}[5m])",
            "legendFormat": "5xx errors"
          }
        ]
      },
      {
        "title": "Request Duration (p95)",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{service=\"my-service\"}[5m]))",
            "legendFormat": "p95"
          }
        ]
      }
    ]
  }
}
```

Import dashboard via ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-service-dashboard
  namespace: observability
  labels:
    grafana_dashboard: "1"
data:
  my-service.json: |
    # Paste dashboard JSON here
```

### 6. Create Prometheus alert rules

Create `applications/overlays/k8s-sandbox/services/my-service/prometheusrule.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: my-service-alerts
  namespace: my-service
  labels:
    prometheus: kube-prometheus-stack
spec:
  groups:
    - name: my-service
      interval: 30s
      rules:
        # High error rate
        - alert: MyServiceHighErrorRate
          expr: |
            rate(http_requests_total{service="my-service",status=~"5.."}[5m]) > 0.05
          for: 5m
          labels:
            severity: warning
            service: my-service
          annotations:
            summary: "High error rate for my-service"
            description: "Error rate is {{ $value | humanizePercentage }} (threshold: 5%)"
            runbook_url: "https://runbooks.example.com/my-service/high-error-rate"
        
        # High latency
        - alert: MyServiceHighLatency
          expr: |
            histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{service="my-service"}[5m])) > 1
          for: 5m
          labels:
            severity: warning
            service: my-service
          annotations:
            summary: "High latency for my-service"
            description: "P95 latency is {{ $value }}s (threshold: 1s)"
            runbook_url: "https://runbooks.example.com/my-service/high-latency"
        
        # Service down
        - alert: MyServiceDown
          expr: |
            up{job="my-service"} == 0
          for: 2m
          labels:
            severity: critical
            service: my-service
          annotations:
            summary: "My service is down"
            description: "Service has been down for more than 2 minutes"
            runbook_url: "https://runbooks.example.com/my-service/service-down"
```

Apply:

```bash
kubectl apply -f applications/overlays/k8s-sandbox/services/my-service/prometheusrule.yaml
```

Verify:

```bash
# Check PrometheusRule
kubectl get prometheusrule my-service-alerts -n my-service

# Check in Prometheus UI
kubectl port-forward -n observability svc/kube-prometheus-stack-prometheus 9090:9090
# Open: http://localhost:9090/alerts
```

### 7. Configure Alertmanager routing

Update Alertmanager configuration:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-kube-prometheus-stack-alertmanager
  namespace: observability
type: Opaque
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
    
    route:
      group_by: ['alertname', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'default'
      
      routes:
        # Route my-service alerts to specific receiver
        - match:
            service: my-service
          receiver: 'my-service-team'
          continue: false
    
    receivers:
      - name: 'default'
        slack_configs:
          - api_url: 'https://hooks.slack.com/services/XXX/YYY/ZZZ'
            channel: '#alerts'
      
      - name: 'my-service-team'
        slack_configs:
          - api_url: 'https://hooks.slack.com/services/XXX/YYY/ZZZ'
            channel: '#my-service-alerts'
            title: '{{ .GroupLabels.alertname }}'
            text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

## Verification

Complete observability checklist:

```bash
# 1. Metrics are being scraped
kubectl get servicemonitor my-service -n my-service
# Check Prometheus targets UI

# 2. Logs are being collected
# Query in Grafana Loki: {namespace="my-service"}

# 3. Traces are being collected
# Query in Grafana Tempo by service name

# 4. Dashboard is available
# Check Grafana dashboards list

# 5. Alerts are configured
kubectl get prometheusrule my-service-alerts -n my-service
# Check Prometheus alerts UI
```

## Required Metrics

Implement these metrics in your service:

### RED Metrics (Request-based services)

```
# Rate
http_requests_total{method, status, endpoint}

# Errors
http_requests_total{method, status=~"5..", endpoint}

# Duration
http_request_duration_seconds{method, endpoint}
```

### USE Metrics (Resource-based services)

```
# Utilization
process_cpu_seconds_total
process_resident_memory_bytes

# Saturation
go_goroutines (for Go)
nodejs_eventloop_lag_seconds (for Node.js)

# Errors
process_open_fds (file descriptor exhaustion)
```

## Troubleshooting

### Metrics not appearing in Prometheus

Check ServiceMonitor selector:

```bash
kubectl get servicemonitor my-service -n my-service -o yaml
kubectl get service my-service -n my-service -o yaml
```

Labels must match.

Check Prometheus logs:

```bash
kubectl logs -n observability -l app.kubernetes.io/name=prometheus
```

### Logs not in Loki

Check OpenTelemetry collector:

```bash
kubectl logs -n observability -l app.kubernetes.io/name=opentelemetry-collector
```

Verify log format is JSON:

```bash
kubectl logs -n my-service -l app.kubernetes.io/name=my-service
```

### Traces not in Tempo

Check OTLP endpoint is reachable:

```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -v http://opentelemetry-collector.observability.svc.cluster.local:4317
```

Check application trace configuration:

```bash
kubectl get pod -n my-service -l app.kubernetes.io/name=my-service -o yaml | grep OTEL
```

### Alerts not firing

Check PrometheusRule is loaded:

```bash
kubectl get prometheusrule -n my-service
```

Check alert expression in Prometheus UI:

```bash
# Navigate to Prometheus > Alerts
# Click on alert to see evaluation
```

Check Alertmanager configuration:

```bash
kubectl get secret alertmanager-kube-prometheus-stack-alertmanager -n observability -o yaml
```

## Best Practices

1. **Use consistent metric names** - Follow Prometheus naming conventions
2. **Add correlation IDs** - Link logs, metrics, and traces
3. **Sample traces appropriately** - 1-10% for high-traffic services
4. **Create actionable alerts** - Include runbook links
5. **Test alerts** - Trigger alerts in non-production
6. **Monitor the monitors** - Alert on observability stack health
7. **Set SLOs** - Define service-level objectives

## Next Steps

- Define SLOs and error budgets
- Create runbooks for common incidents
- Set up synthetic monitoring with blackbox exporter
- Configure long-term metrics storage with Mimir
- Implement distributed tracing across all services

## Evidence

**Sources:**
- `applications/base/services/observability/kube-prometheus-stack/README.md` - Prometheus stack
- `applications/base/services/observability/loki/README.md` - Log aggregation
- `applications/base/services/observability/tempo/README.md` - Distributed tracing
- `applications/base/services/observability/opentelemetry-kube-stack/README.md` - Unified telemetry
- `docs/service-standards-and-lifecycle.md` lines 56-60 - Observability requirements
- S6-OBSERVABILITY.md - Observability stack architecture
