# OpenTelemetry Operator

The OpenTelemetry Operator is a Kubernetes operator that manages OpenTelemetry Collector instances and auto-instrumentation of workloads using OpenTelemetry instrumentation libraries.

## Overview

This service deploys the OpenTelemetry Operator in the `observability` namespace with security hardening and high availability configuration.

## Features

- **Auto-instrumentation**: Automatically inject OpenTelemetry instrumentation into applications
- **Collector Management**: Deploy and manage OpenTelemetry Collector instances
- **CRD Management**: Provides custom resources for OpenTelemetry configuration
- **Webhook Support**: Admission webhooks for sidecar injection and validation

## Configuration

### Chart Information
- **Chart**: `opentelemetry/opentelemetry-operator`
- **Version**: `0.98.0`
- **App Version**: `0.137.0`
- **Repository**: https://open-telemetry.github.io/opentelemetry-helm-charts

### Security Hardening

The deployment includes the following security measures:

- **Non-root execution**: All containers run as non-root user (65532)
- **Read-only root filesystem**: Containers use read-only root filesystems
- **Dropped capabilities**: All Linux capabilities are dropped
- **Security profiles**: Uses RuntimeDefault seccomp profile
- **Resource limits**: CPU and memory limits configured for all containers

### High Availability

- **Replica count**: 2 replicas for high availability
- **Pod Disruption Budget**: Ensures minimum availability during disruptions
- **Leader election**: Enabled to prevent split-brain scenarios
- **Anti-affinity**: Distributes pods across nodes (when configured)

### Monitoring

- **ServiceMonitor**: Enabled for Prometheus metrics collection
- **Metrics endpoint**: Exposes metrics on port 8080
- **Health checks**: Readiness and liveness probes configured

## Custom Resources

The operator provides the following custom resources:

- **OpenTelemetryCollector**: Manages collector deployments
- **Instrumentation**: Configures auto-instrumentation for applications
- **OpAMPBridge**: Manages OpAMP bridge instances

## Dependencies

- **cert-manager**: Required for TLS certificate management of admission webhooks
- **Prometheus Operator**: Optional, for ServiceMonitor support

## Usage

After deployment, you can create OpenTelemetry resources:

```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
  namespace: observability
spec:
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
    processors:
      batch:
    exporters:
      logging:
        loglevel: debug
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch]
          exporters: [logging]
```

## Troubleshooting

### Common Issues

1. **Webhook failures**: Ensure cert-manager is deployed and healthy
2. **CRD conflicts**: Check for existing OpenTelemetry CRDs if upgrading
3. **RBAC issues**: Verify cluster-admin permissions during installation

### Useful Commands

```bash
# Check operator status
kubectl get pods -n observability -l app.kubernetes.io/name=opentelemetry-operator

# View operator logs
kubectl logs -n observability -l app.kubernetes.io/name=opentelemetry-operator

# Check CRDs
kubectl get crd | grep opentelemetry

# Verify webhooks
kubectl get validatingwebhookconfiguration | grep opentelemetry
kubectl get mutatingwebhookconfiguration | grep opentelemetry
```

## References

- [OpenTelemetry Operator Documentation](https://opentelemetry.io/docs/kubernetes/operator/)
- [Helm Chart Repository](https://github.com/open-telemetry/opentelemetry-helm-charts)
- [OpenTelemetry Specification](https://opentelemetry.io/docs/specs/)