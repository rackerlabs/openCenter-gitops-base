# Loki Distributed

Grafana Loki is a horizontally-scalable, highly-available, multi-tenant log aggregation system inspired by Prometheus. This deployment uses the distributed (microservices) mode for production scalability.

## Overview

This service deploys Loki in distributed mode with the following components:
- **Distributor**: Receives log streams and distributes them to ingesters
- **Ingester**: Writes log data to storage and serves queries for recent data
- **Querier**: Handles queries for log data
- **Query Frontend**: Provides query optimization and caching
- **Compactor**: Compacts index files for better query performance
- **Index Gateway**: Serves index queries
- **Ruler**: Evaluates recording and alerting rules
- **Gateway**: Provides a single entry point for all Loki services

## Configuration

### Chart Information
- **Chart**: grafana/loki-distributed
- **Version**: 0.80.5
- **App Version**: 2.9.13
- **Repository**: https://grafana.github.io/helm-charts

### Security Hardening
- All containers run as non-root user (UID 10001)
- Read-only root filesystem enabled
- All Linux capabilities dropped
- Security profiles enforced (seccomp)
- Privilege escalation disabled

### Resource Configuration
- Ingester: 2 replicas, 256Mi-512Mi memory
- Distributor: 2 replicas, 128Mi-256Mi memory
- Querier: 2 replicas, 128Mi-256Mi memory
- Query Frontend: 2 replicas, 128Mi-256Mi memory
- Gateway: 2 replicas, 64Mi-128Mi memory
- Compactor: 1 replica, 128Mi-256Mi memory
- Index Gateway: 2 replicas, 128Mi-256Mi memory
- Ruler: 1 replica, 128Mi-256Mi memory

### Storage
- Uses filesystem storage by default (suitable for single-node or development)
- Persistence enabled with 10Gi storage
- For production, consider configuring object storage (S3, GCS, etc.)

### Monitoring
- ServiceMonitor enabled for Prometheus scraping
- Integrates with AlertManager for rule evaluation

## Usage

### Accessing Loki
The Loki gateway service provides a single entry point:
```
http://loki-distributed-gateway.loki-distributed.svc.cluster.local:80
```

### Grafana Integration
Configure Grafana data source:
```yaml
datasources:
  - name: Loki
    type: loki
    url: http://loki-distributed-gateway.loki-distributed.svc.cluster.local:80
    access: proxy
```

### Log Ingestion
Configure log shippers (Promtail, Fluent Bit, etc.) to send logs to:
```
http://loki-distributed-gateway.loki-distributed.svc.cluster.local:80/loki/api/v1/push
```

## Production Considerations

### Object Storage
For production deployments, configure object storage:
```yaml
loki:
  config: |
    common:
      storage:
        s3:
          endpoint: s3.amazonaws.com
          bucketnames: loki-chunks
          region: us-east-1
```

### Retention
Configure log retention policies:
```yaml
loki:
  config: |
    limits_config:
      retention_period: 744h  # 31 days
```

### Scaling
Adjust replica counts based on log volume:
- Increase ingester replicas for higher write throughput
- Increase querier replicas for better query performance
- Scale distributor for higher ingestion rates

## Troubleshooting

### Common Issues
1. **Storage Issues**: Ensure adequate storage and proper permissions
2. **Memory Pressure**: Adjust resource limits based on log volume
3. **Query Performance**: Consider enabling query caching and result caching

### Useful Commands
```bash
# Check pod status
kubectl get pods -n loki-distributed

# View logs
kubectl logs -n loki-distributed -l app.kubernetes.io/component=ingester

# Port forward to access Loki directly
kubectl port-forward -n loki-distributed svc/loki-distributed-gateway 3100:80
```

## References
- [Loki Documentation](https://grafana.com/docs/loki/)
- [Loki Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/loki-distributed)
- [Loki Configuration](https://grafana.com/docs/loki/latest/configuration/)