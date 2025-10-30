# HyperDX OSS V2

HyperDX is a comprehensive observability platform that provides logs, traces, and metrics in a unified interface. It offers a modern alternative to traditional observability stacks with advanced correlation capabilities and developer-friendly features.

## Overview

HyperDX OSS V2 is a complete observability solution that includes:
- **Unified Observability**: Logs, traces, and metrics in one platform
- **Advanced Correlation**: Automatic correlation between different telemetry types
- **Developer Experience**: Modern UI with powerful search and filtering
- **OpenTelemetry Native**: Built-in support for OpenTelemetry standards
- **Cost Effective**: Efficient storage and querying with ClickHouse backend

## Configuration

### Chart Information
- **Chart**: hdx-oss-v2
- **Version**: 0.8.1
- **App Version**: 2.7.0
- **Repository**: https://hyperdxio.github.io/helm-charts

### Namespace
Deployed in the `observability` namespace alongside other monitoring components.

### Architecture Components

#### HyperDX Application
- **Purpose**: Main web application and API server
- **Ports**: 3000 (frontend), 8000 (API), 4320 (OpAMP)
- **Features**:
  - Web-based observability dashboard
  - Advanced search and filtering capabilities
  - Correlation between logs, traces, and metrics
  - Alert management and dashboards

#### MongoDB
- **Purpose**: Metadata and configuration storage
- **Version**: 5.0.14-focal
- **Port**: 27017
- **Storage**: 10Gi persistent volume
- **Features**:
  - User configurations and dashboards
  - Alert rules and notification settings
  - Application metadata storage

#### ClickHouse
- **Purpose**: High-performance analytics database for telemetry data
- **Version**: 25.7-alpine
- **Ports**: 8123 (HTTP), 9000 (native), 9363 (metrics)
- **Storage**: 20Gi data + 5Gi logs
- **Features**:
  - Columnar storage for fast analytics
  - Efficient compression for large datasets
  - Real-time ingestion and querying
  - Prometheus metrics endpoint

#### OpenTelemetry Collector
- **Purpose**: Telemetry data ingestion and processing
- **Ports**: 4317 (gRPC), 4318 (HTTP), 8888 (health)
- **Features**:
  - OTLP protocol support
  - Data processing and enrichment
  - Integration with ClickHouse backend
  - OpAMP management protocol

### Security Hardening

The deployment includes comprehensive security configurations:

#### Resource Management
- CPU and memory limits defined for all components
- Resource requests set for proper scheduling
- Startup, liveness, and readiness probes configured

#### Network Security
- ClusterIP services for internal-only access
- Ingress disabled by default (requires explicit configuration)
- ClickHouse access restricted to cluster CIDRs only
- Secure default passwords (should be overridden in production)

#### Storage Security
- Persistent volumes for data durability
- Configurable storage classes
- PVC retention option for data preservation

#### Node Placement
- Linux node selectors for all components
- Tolerations support for specialized nodes
- Anti-affinity rules can be configured

### Key Features

#### Unified Observability
- Single pane of glass for logs, traces, and metrics
- Automatic correlation between different data types
- Context switching between telemetry types
- Distributed tracing visualization

#### Advanced Search
- Full-text search across all telemetry data
- Structured query language support
- Time-based filtering and aggregation
- Custom field extraction and parsing

#### Developer Experience
- Modern, responsive web interface
- Real-time data streaming
- Collaborative features (shared dashboards, alerts)
- API access for programmatic integration

#### Performance
- ClickHouse backend for fast analytics
- Efficient data compression and storage
- Horizontal scaling capabilities
- Optimized for high-volume environments

### Customization

#### Frontend Configuration
Update the frontend URL for production deployments:

```yaml
hyperdx:
  frontendUrl: "https://hyperdx.example.com"
  ingress:
    enabled: true
    host: "hyperdx.example.com"
    tls:
      enabled: true
      secretName: "hyperdx-tls"
```

#### Resource Scaling
Adjust resources based on data volume:

```yaml
clickhouse:
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "4Gi"
      cpu: "2000m"
  persistence:
    dataSize: 100Gi
    logSize: 20Gi
```

#### Security Configuration
Override default passwords and API keys:

```yaml
hyperdx:
  apiKey: "your-secure-api-key"
clickhouse:
  config:
    users:
      appUserPassword: "your-secure-app-password"
      otelUserPassword: "your-secure-otel-password"
```

### Dependencies

This chart includes all necessary components:
- MongoDB for metadata storage
- ClickHouse for telemetry data storage
- OpenTelemetry Collector for data ingestion
- HyperDX application for the web interface

### Compatibility

#### Existing Services
The configuration is designed to work alongside existing observability services:
- **kube-prometheus-stack**: Can coexist with Prometheus/Grafana
- **loki**: Complementary log aggregation (can send logs to HyperDX)
- **tempo**: Can replace or complement distributed tracing
- **opentelemetry-kube-stack**: Alternative OpenTelemetry deployment

#### Data Sources
HyperDX can receive data from:
- OpenTelemetry SDKs and collectors
- Prometheus remote write
- Fluentd/Fluent Bit log forwarders
- Jaeger tracing data
- Custom HTTP/gRPC endpoints

### Monitoring and Observability

#### Health Checks
Monitor the deployment status:
```bash
kubectl get helmrelease hyperdx -n observability
kubectl get pods -n observability -l app.kubernetes.io/name=hyperdx
```

#### Component Status
Check individual component health:
```bash
# HyperDX application
kubectl logs -n observability -l app.kubernetes.io/component=hyperdx

# ClickHouse status
kubectl logs -n observability -l app.kubernetes.io/component=clickhouse

# MongoDB status
kubectl logs -n observability -l app.kubernetes.io/component=mongodb

# OTEL Collector status
kubectl logs -n observability -l app.kubernetes.io/component=otel-collector
```

#### Metrics Access
Access component metrics:
```bash
# ClickHouse metrics
kubectl port-forward -n observability svc/hyperdx-clickhouse 9363:9363
curl http://localhost:9363/metrics

# OTEL Collector health
kubectl port-forward -n observability svc/hyperdx-otel-collector 8888:8888
curl http://localhost:8888/metrics
```

### Troubleshooting

#### Common Issues

1. **ClickHouse Connection Issues**
   - Check cluster CIDR configuration
   - Verify network policies allow internal traffic
   - Ensure persistent volumes are properly mounted

2. **High Memory Usage**
   - Increase resource limits for ClickHouse
   - Configure data retention policies
   - Monitor query performance

3. **Data Ingestion Problems**
   - Check OTEL Collector logs
   - Verify endpoint configurations
   - Test connectivity to ClickHouse

#### Debug Commands
```bash
# Check all HyperDX resources
kubectl get all -n observability -l app.kubernetes.io/name=hyperdx

# Describe problematic pods
kubectl describe pod -n observability <pod-name>

# Check persistent volume claims
kubectl get pvc -n observability

# View service endpoints
kubectl get endpoints -n observability
```

### Integration Examples

#### Sending Logs to HyperDX
Configure applications to send logs via OTLP:
```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: app-collector
spec:
  config: |
    exporters:
      otlphttp:
        endpoint: http://hyperdx-otel-collector:4318
    service:
      pipelines:
        logs:
          exporters: [otlphttp]
```

#### Prometheus Remote Write
Send Prometheus metrics to HyperDX:
```yaml
prometheus:
  prometheusSpec:
    remoteWrite:
      - url: http://hyperdx-otel-collector:4318/v1/metrics
        writeRelabelConfigs:
          - sourceLabels: [__name__]
            regex: 'hyperdx_.*'
            action: keep
```

#### Application Instrumentation
Instrument applications to send telemetry:
```javascript
// Node.js example
const { NodeSDK } = require('@opentelemetry/sdk-node');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: 'http://hyperdx-otel-collector:4317',
  }),
  metricExporter: new OTLPMetricExporter({
    url: 'http://hyperdx-otel-collector:4317',
  }),
});

sdk.start();
```

### Production Considerations

#### Security
- Change default passwords and API keys
- Enable TLS for ingress
- Configure proper authentication
- Restrict network access with policies

#### Performance
- Size ClickHouse storage appropriately
- Configure data retention policies
- Monitor resource usage and scale accordingly
- Use dedicated storage classes for performance

#### High Availability
- Increase replica counts for stateless components
- Configure ClickHouse clustering for large deployments
- Set up backup strategies for persistent data
- Implement proper monitoring and alerting

This deployment provides a comprehensive observability platform with modern features and developer-friendly interfaces, suitable for both development and production environments.