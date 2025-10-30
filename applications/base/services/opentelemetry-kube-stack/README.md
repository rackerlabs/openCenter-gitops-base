# OpenTelemetry Kube Stack

The OpenTelemetry Kube Stack is a comprehensive observability solution that provides a complete OpenTelemetry setup for Kubernetes clusters. It includes the OpenTelemetry Operator, collectors, and essential monitoring components.

## Overview

This chart deploys:
- **OpenTelemetry Operator**: Manages OpenTelemetry collectors and instrumentation
- **OpenTelemetry Collector**: Collects, processes, and exports telemetry data
- **Kube State Metrics**: Exposes cluster-level metrics about Kubernetes objects
- **Node Exporter**: Collects hardware and OS metrics from cluster nodes

## Configuration

### Chart Information
- **Chart**: opentelemetry-kube-stack
- **Version**: 0.11.1
- **App Version**: 0.129.1
- **Repository**: https://open-telemetry.github.io/opentelemetry-helm-charts

### Namespace
Deployed in the `observability` namespace alongside other monitoring components.

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
- CPU and memory limits defined for all components
- Resource requests set for proper scheduling
- Memory limiter processor configured for collectors

#### Network Security
- OTLP receivers configured on standard ports (4317/4318)
- Service monitors enabled for Prometheus integration
- Node selectors for Linux-only deployment

### Key Features

#### OpenTelemetry Operator
- Manages collector lifecycle and configuration
- Supports auto-instrumentation for applications
- Webhook-based configuration validation

#### Collector Configuration
- OTLP receivers for traces, metrics, and logs
- Batch processing for efficient data handling
- Memory limiting to prevent resource exhaustion
- Logging exporter for initial setup (can be customized)

#### Monitoring Integration
- Prometheus ServiceMonitor resources enabled
- Kube State Metrics for cluster-level observability
- Node Exporter for infrastructure metrics
- Compatible with existing Prometheus stack

### Customization

#### Collector Configuration
The default collector configuration can be extended by modifying the `config` section in the hardened values file. Common customizations include:

```yaml
config:
  exporters:
    otlp:
      endpoint: "your-backend:4317"
      tls:
        insecure: false
    prometheusremotewrite:
      endpoint: "https://prometheus.example.com/api/v1/write"
```

#### Resource Scaling
Adjust resource limits based on cluster size and telemetry volume:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### Dependencies

This chart has dependencies on:
- OpenTelemetry CRDs (installed automatically)
- Kubernetes 1.19+ for proper ServiceMonitor support
- Prometheus Operator (for ServiceMonitor resources)

### Compatibility

#### Existing Services
The configuration is designed to work alongside existing observability services:
- **kube-prometheus-stack**: Kubernetes service monitors disabled to avoid conflicts
- **Prometheus CRDs**: Installation disabled (uses existing CRDs)
- **Grafana**: Compatible with OpenTelemetry data sources

#### OpenTelemetry Operator
This deployment may conflict with the existing `opentelemetry-operator` service. Consider:
- Using this as a replacement for the standalone operator
- Disabling the operator component if only collectors are needed
- Coordinating CRD management between deployments

### Monitoring and Observability

#### Health Checks
Monitor the deployment status:
```bash
kubectl get helmrelease opentelemetry-kube-stack -n observability
kubectl get pods -n observability -l app.kubernetes.io/name=opentelemetry-kube-stack
```

#### Collector Status
Check OpenTelemetry collector status:
```bash
kubectl get opentelemetrycollector -n observability
kubectl logs -n observability -l app.kubernetes.io/component=opentelemetry-collector
```

#### Metrics Availability
Verify metrics collection:
```bash
kubectl port-forward -n observability svc/opentelemetry-kube-stack-collector 8888:8888
curl http://localhost:8888/metrics
```

### Troubleshooting

#### Common Issues

1. **CRD Conflicts**: If OpenTelemetry CRDs already exist, disable installation:
   ```yaml
   crds:
     installOtel: false
   ```

2. **Resource Constraints**: Increase resource limits if collectors are OOMKilled:
   ```yaml
   resources:
     limits:
       memory: "1Gi"
   ```

3. **Webhook Failures**: If admission webhooks cause issues:
   ```yaml
   opentelemetry-operator:
     admissionWebhooks:
       failurePolicy: "Ignore"
   ```

#### Debug Commands
```bash
# Check operator logs
kubectl logs -n observability -l app.kubernetes.io/name=opentelemetry-operator

# Describe collector resources
kubectl describe opentelemetrycollector -n observability

# Check service monitor status
kubectl get servicemonitor -n observability
```

### Integration Examples

#### Application Instrumentation
Enable auto-instrumentation for applications:
```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: my-instrumentation
spec:
  exporter:
    endpoint: http://opentelemetry-kube-stack-collector:4317
  propagators:
    - tracecontext
    - baggage
```

#### Custom Exporters
Configure exporters for your observability backend:
```yaml
config:
  exporters:
    jaeger:
      endpoint: jaeger-collector:14250
      tls:
        insecure: true
    prometheus:
      endpoint: "0.0.0.0:8889"
```

This deployment provides a solid foundation for OpenTelemetry-based observability in Kubernetes environments with enterprise-grade security and monitoring capabilities.