# Mimir Distributed

Grafana Mimir is an open source, horizontally scalable, highly available, multi-tenant TSDB for long-term storage for Prometheus. This deployment uses the distributed (microservices) mode for production scalability.

## Overview

This service deploys Mimir in distributed mode with the following components:
- **Distributor**: Receives metrics from Prometheus and distributes them to ingesters
- **Ingester**: Writes metrics data to storage and serves queries for recent data
- **Querier**: Handles PromQL queries for metrics data
- **Query Frontend**: Provides query optimization, caching, and splitting
- **Store Gateway**: Serves queries for historical data from object storage
- **Compactor**: Compacts blocks and handles retention
- **Ruler**: Evaluates recording and alerting rules
- **Gateway**: Provides a single entry point for all Mimir services

## Configuration

### Chart Information
- **Chart**: grafana/mimir-distributed
- **Version**: 5.8.0
- **App Version**: 2.17.0
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
- Store Gateway: 2 replicas, 256Mi-512Mi memory, 10Gi storage
- Compactor: 1 replica, 256Mi-512Mi memory, 10Gi storage
- Ruler: 1 replica, 256Mi-512Mi memory
- Gateway: 2 replicas, 128Mi-256Mi memory

### Storage
- Uses filesystem storage by default (suitable for single-node or development)
- Persistent volumes enabled for ingesters, store-gateway, and compactor
- For production, consider configuring object storage (S3, GCS, etc.)

### Monitoring
- ServiceMonitor enabled for Prometheus scraping
- Integrates with existing AlertManager from kube-prometheus-stack

## Usage

### Accessing Mimir
The Mimir gateway service provides a single entry point:
```
http://mimir-distributed-gateway.mimir-distributed.svc.cluster.local:80
```

### Prometheus Integration
Configure Prometheus to use Mimir for remote write:
```yaml
remote_write:
  - url: http://mimir-distributed-gateway.mimir-distributed.svc.cluster.local:80/api/v1/push
```

### Grafana Integration
Configure Grafana data source:
```yaml
datasources:
  - name: Mimir
    type: prometheus
    url: http://mimir-distributed-gateway.mimir-distributed.svc.cluster.local:80/prometheus
    access: proxy
```

### Querying Metrics
Use PromQL queries against the Mimir endpoint:
```
http://mimir-distributed-gateway.mimir-distributed.svc.cluster.local:80/prometheus/api/v1/query
```

## Production Considerations

### Object Storage
For production deployments, configure object storage:
```yaml
mimir:
  config: |
    blocks_storage:
      backend: s3
      s3:
        endpoint: s3.amazonaws.com
        bucket_name: mimir-blocks
        region: us-east-1
```

### Retention
Configure metrics retention policies:
```yaml
mimir:
  config: |
    limits:
      compactor_blocks_retention_period: 8760h  # 1 year
```

### Scaling
Adjust replica counts based on metrics volume:
- Increase ingester replicas for higher write throughput
- Increase querier replicas for better query performance
- Scale distributor for higher ingestion rates
- Add store-gateway replicas for better historical query performance

### High Availability
- Configure replication factor (default: 2)
- Use anti-affinity rules to spread replicas across nodes
- Consider zone-aware deployment for multi-AZ clusters

## Troubleshooting

### Common Issues
1. **Storage Issues**: Ensure adequate storage and proper permissions
2. **Memory Pressure**: Adjust resource limits based on metrics volume
3. **Query Performance**: Consider enabling query result caching
4. **Ingestion Issues**: Check distributor and ingester logs

### Useful Commands
```bash
# Check pod status
kubectl get pods -n mimir-distributed

# View logs
kubectl logs -n mimir-distributed -l app.kubernetes.io/component=ingester

# Port forward to access Mimir directly
kubectl port-forward -n mimir-distributed svc/mimir-distributed-gateway 8080:80

# Check ring status
curl http://localhost:8080/ring
```

## References
- [Mimir Documentation](https://grafana.com/docs/mimir/)
- [Mimir Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/mimir-distributed)
- [Mimir Configuration](https://grafana.com/docs/mimir/latest/configure/)
- [Mimir Architecture](https://grafana.com/docs/mimir/latest/architecture/)