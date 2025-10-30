# Tempo Distributed

Grafana Tempo is an open source, easy-to-use, and high-scale distributed tracing backend. This deployment uses the distributed (microservices) mode for production scalability.

## Overview

This service deploys Tempo in distributed mode with the following components:
- **Distributor**: Receives trace spans from various protocols and distributes them to ingesters
- **Ingester**: Writes trace data to storage and serves queries for recent traces
- **Querier**: Handles trace queries and searches
- **Query Frontend**: Provides query optimization and caching for trace queries
- **Compactor**: Compacts trace blocks and handles retention
- **Gateway**: Provides a single entry point for all Tempo services

## Configuration

### Chart Information
- **Chart**: grafana/tempo-distributed
- **Version**: 1.52.4
- **App Version**: 2.9.0
- **Repository**: https://grafana.github.io/helm-charts

### Security Hardening
- All containers run as non-root user (UID 10001)
- Read-only root filesystem enabled
- All Linux capabilities dropped
- Security profiles enforced (seccomp)
- Privilege escalation disabled

### Resource Configuration
- Ingester: 3 replicas, 512Mi-1Gi memory, 10Gi storage
- Distributor: 2 replicas, 256Mi-512Mi memory
- Querier: 2 replicas, 256Mi-512Mi memory
- Query Frontend: 2 replicas, 256Mi-512Mi memory
- Compactor: 1 replica, 256Mi-512Mi memory
- Gateway: 2 replicas, 128Mi-256Mi memory

### Trace Ingestion Protocols
Supports multiple trace ingestion protocols:
- **Jaeger**: gRPC (14250), Thrift HTTP (14268), Thrift Compact (6831), Thrift Binary (6832)
- **Zipkin**: HTTP (9411)
- **OpenTelemetry**: gRPC (4317), HTTP (4318)
- **OpenCensus**: gRPC (55678)

### Storage
- Uses local filesystem storage by default
- Persistent volumes enabled for ingesters
- For production, consider configuring object storage (S3, GCS, etc.)

### Monitoring
- ServiceMonitor enabled for Prometheus scraping
- Integrates with existing monitoring stack

## Usage

### Accessing Tempo
The Tempo gateway service provides a single entry point:
```
http://tempo-distributed-gateway.tempo-distributed.svc.cluster.local:80
```

### Sending Traces
Configure your applications to send traces to Tempo:

**Jaeger gRPC:**
```
tempo-distributed-distributor.tempo-distributed.svc.cluster.local:14250
```

**OpenTelemetry gRPC:**
```
tempo-distributed-distributor.tempo-distributed.svc.cluster.local:4317
```

**OpenTelemetry HTTP:**
```
http://tempo-distributed-distributor.tempo-distributed.svc.cluster.local:4318
```

**Zipkin:**
```
http://tempo-distributed-distributor.tempo-distributed.svc.cluster.local:9411
```

### Grafana Integration
Configure Grafana data source:
```yaml
datasources:
  - name: Tempo
    type: tempo
    url: http://tempo-distributed-gateway.tempo-distributed.svc.cluster.local:80
    access: proxy
```

### Querying Traces
Use Tempo's search API:
```bash
# Search traces
curl "http://tempo-distributed-gateway.tempo-distributed.svc.cluster.local:80/api/search?tags=service.name=my-service"

# Get specific trace
curl "http://tempo-distributed-gateway.tempo-distributed.svc.cluster.local:80/api/traces/{trace-id}"
```

## Production Considerations

### Object Storage
For production deployments, configure object storage:
```yaml
tempo:
  config: |
    storage:
      trace:
        backend: s3
        s3:
          bucket: tempo-traces
          endpoint: s3.amazonaws.com
          region: us-east-1
```

### Retention
Configure trace retention policies:
```yaml
tempo:
  config: |
    compactor:
      compaction:
        block_retention: 168h  # 7 days
```

### Scaling
Adjust replica counts based on trace volume:
- Increase ingester replicas for higher write throughput
- Increase querier replicas for better query performance
- Scale distributor for higher ingestion rates

### High Availability
- Configure multiple replicas for all components
- Use anti-affinity rules to spread replicas across nodes
- Consider zone-aware deployment for multi-AZ clusters

### Performance Tuning
- Adjust block duration based on trace volume
- Configure appropriate resource limits
- Enable memcached for query caching in high-volume environments

## Integration with OpenTelemetry

### OpenTelemetry Collector Configuration
Configure the OpenTelemetry Collector to send traces to Tempo:
```yaml
exporters:
  otlp:
    endpoint: tempo-distributed-distributor.tempo-distributed.svc.cluster.local:4317
    tls:
      insecure: true

service:
  pipelines:
    traces:
      exporters: [otlp]
```

### Application Instrumentation
Configure your applications to send traces:
```bash
# Environment variables for OpenTelemetry
export OTEL_EXPORTER_OTLP_ENDPOINT=http://tempo-distributed-distributor.tempo-distributed.svc.cluster.local:4318
export OTEL_RESOURCE_ATTRIBUTES=service.name=my-service,service.version=1.0.0
```

## Troubleshooting

### Common Issues
1. **Ingestion Issues**: Check distributor logs and ensure correct endpoints
2. **Storage Issues**: Verify persistent volume permissions and space
3. **Query Performance**: Consider enabling caching and adjusting resource limits
4. **Protocol Issues**: Verify trace format and protocol compatibility

### Useful Commands
```bash
# Check pod status
kubectl get pods -n tempo-distributed

# View distributor logs
kubectl logs -n tempo-distributed -l app.kubernetes.io/component=distributor

# View ingester logs
kubectl logs -n tempo-distributed -l app.kubernetes.io/component=ingester

# Port forward to access Tempo directly
kubectl port-forward -n tempo-distributed svc/tempo-distributed-gateway 3200:80

# Check trace ingestion
curl http://localhost:3200/ready
```

### Debugging Traces
```bash
# Search for traces by service
curl "http://localhost:3200/api/search?tags=service.name=my-service&limit=10"

# Get trace by ID
curl "http://localhost:3200/api/traces/{trace-id}"

# Check metrics
curl http://localhost:3200/metrics
```

## References
- [Tempo Documentation](https://grafana.com/docs/tempo/)
- [Tempo Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/tempo-distributed)
- [Tempo Configuration](https://grafana.com/docs/tempo/latest/configuration/)
- [OpenTelemetry Integration](https://grafana.com/docs/tempo/latest/getting-started/opentelemetry/)
- [Jaeger Integration](https://grafana.com/docs/tempo/latest/getting-started/jaeger/)