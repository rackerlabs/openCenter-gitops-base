# Kube-Prometheus-Stack Configuration Guide

## Overview
Kube-Prometheus-Stack provides a complete monitoring solution with Prometheus, Grafana, Alertmanager, and related components for Kubernetes cluster and application monitoring.

## Key Configuration Choices

### Prometheus Configuration
```yaml
prometheus:
  prometheusSpec:
    retention: 30d
    retentionSize: 50GB
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: longhorn
          resources:
            requests:
              storage: 100Gi
    resources:
      requests:
        memory: 2Gi
        cpu: 1000m
      limits:
        memory: 4Gi
        cpu: 2000m
```
**Why**: 
- Persistent storage ensures metrics survive pod restarts
- Retention policies manage storage usage and costs
- Resource limits prevent memory issues in large clusters

### Grafana Configuration
```yaml
grafana:
  persistence:
    enabled: true
    storageClassName: longhorn
    size: 10Gi
  adminPassword: <secure-password>
  grafana.ini:
    server:
      root_url: https://grafana.example.com
    auth.generic_oauth:
      enabled: true
      name: Keycloak
      client_id: grafana
      client_secret: <client-secret>
      auth_url: https://auth.example.com/realms/opencenter/protocol/openid-connect/auth
      token_url: https://auth.example.com/realms/opencenter/protocol/openid-connect/token
```
**Why**: OIDC integration provides centralized authentication and persistent storage preserves dashboards and settings

### Alertmanager Configuration
```yaml
alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: longhorn
          resources:
            requests:
              storage: 10Gi
  config:
    global:
      smtp_smarthost: 'smtp.example.com:587'
      smtp_from: 'alerts@example.com'
    route:
      group_by: ['alertname', 'cluster']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'web.hook'
    receivers:
    - name: 'web.hook'
      email_configs:
      - to: 'admin@example.com'
        subject: 'Alert: {{ .GroupLabels.alertname }}'
```
**Why**: Persistent storage maintains alert state and SMTP configuration enables email notifications

## Common Pitfalls

### High Memory Usage
**Problem**: Prometheus consumes excessive memory causing OOM kills

**Solution**: Tune retention settings, increase memory limits, or implement recording rules to reduce cardinality

**Verification**:
```bash
# Check Prometheus memory usage
kubectl top pod -n observability -l app.kubernetes.io/name=prometheus

# Review Prometheus metrics
kubectl port-forward -n observability svc/prometheus-operated 9090:9090
# Access http://localhost:9090/metrics
```

### Missing Metrics
**Problem**: Expected metrics are not appearing in Prometheus

**Solution**: Verify ServiceMonitor selectors match service labels and check scrape configuration

### Grafana Dashboard Issues
**Problem**: Dashboards show no data or incorrect visualizations

**Solution**: Verify data source configuration and check Prometheus query syntax

```bash
# Check Grafana logs
kubectl logs -n observability deployment/grafana

# Verify data source connectivity
kubectl exec -n observability deployment/grafana -- curl -s http://prometheus-operated:9090/api/v1/query?query=up
```

## Required Secrets

### Grafana Admin Password
Grafana requires an admin password for initial setup

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: grafana-admin
  namespace: observability
type: Opaque
stringData:
  admin-password: your-secure-password
```

**Key Fields**:
- `admin-password`: Grafana admin user password (required)

### OIDC Client Secret
For Grafana OIDC authentication

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: grafana-oidc
  namespace: observability
type: Opaque
stringData:
  client-secret: your-oidc-client-secret
```

**Key Fields**:
- `client-secret`: OIDC client secret for Grafana authentication (required for OIDC)

## Verification
```bash
# Check all monitoring pods
kubectl get pods -n observability

# Verify Prometheus targets
kubectl port-forward -n observability svc/prometheus-operated 9090:9090
# Access http://localhost:9090/targets

# Check Grafana access
kubectl port-forward -n observability svc/grafana 3000:80
# Access http://localhost:3000

# Verify Alertmanager
kubectl port-forward -n observability svc/alertmanager-operated 9093:9093
```

## Usage Examples

### Custom ServiceMonitor
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp-metrics
  namespace: observability
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### Custom PrometheusRule
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: myapp-alerts
  namespace: observability
spec:
  groups:
  - name: myapp.rules
    rules:
    - alert: MyAppDown
      expr: up{job="myapp"} == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "MyApp is down"
        description: "MyApp has been down for more than 5 minutes"
```

### Grafana Dashboard ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-dashboard
  namespace: observability
  labels:
    grafana_dashboard: "1"
data:
  myapp-dashboard.json: |
    {
      "dashboard": {
        "title": "MyApp Dashboard",
        "panels": [
          {
            "title": "Request Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(http_requests_total[5m])"
              }
            ]
          }
        ]
      }
    }
```

The Kube-Prometheus-Stack provides comprehensive monitoring capabilities. Start with default configurations and gradually customize based on your specific monitoring requirements and resource constraints.