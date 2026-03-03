# Prometheus Blackbox Exporter

The Prometheus Blackbox Exporter enables blackbox probing of endpoints over HTTP, HTTPS, DNS, TCP, and ICMP protocols. It's used for synthetic monitoring and endpoint availability checks.

## Overview

This service deploys the Prometheus Blackbox Exporter using Flux CD and Helm. The configuration follows Zero Trust security principles suitable for regulated environments.

## Features

- HTTP/HTTPS endpoint monitoring
- TCP connection checks
- DNS resolution testing
- ICMP ping probes
- SSL/TLS certificate validation
- Custom probe modules

## Architecture

- **Namespace**: `blackbox-exporter`
- **Replicas**: 2 (high availability)
- **Chart**: `prometheus-community/prometheus-blackbox-exporter`
- **Version**: 9.1.0

## Security Hardening

The deployment includes:

- Non-root user execution (UID 65534)
- Read-only root filesystem
- Dropped all capabilities
- Seccomp profile enabled
- Pod anti-affinity for distribution
- Resource limits and requests
- ServiceMonitor for Prometheus integration

## Configuration

### Base Configuration

The base hardened values are in `helm-values/hardened-values.yaml` and include:

- Default probe modules (http_2xx, tcp_connect, icmp, dns)
- Security contexts
- Resource limits
- High availability settings

### Overlay Configuration

Customer-specific overrides can be provided via:
```yaml
# In overlay directory
blackbox-exporter-values-override secret
```

## Probe Modules

### HTTP Probes

- `http_2xx`: Basic HTTP GET with 2xx status code validation
- `http_post_2xx`: HTTP POST with 2xx status code validation

### TCP Probes

- `tcp_connect`: Simple TCP connection test

### ICMP Probes

- `icmp`: ICMP ping probe

### DNS Probes

- `dns_tcp`: DNS query over TCP
- `dns_udp`: DNS query over UDP

## ServiceMonitor Configuration

To monitor endpoints, configure targets in the ServiceMonitor:

```yaml
serviceMonitor:
  enabled: true
  targets:
    - name: example-http
      url: https://example.com
      module: http_2xx
    - name: example-tcp
      url: example.com:443
      module: tcp_connect
```

## Usage with Prometheus

The blackbox exporter integrates with Prometheus via the ServiceMonitor CRD. Prometheus will scrape metrics about probe results.

Example Prometheus query:
```promql
probe_success{job="blackbox-exporter"}
```

## Customization

### Adding Custom Probe Modules

Add custom modules in the override values:

```yaml
config:
  modules:
    custom_http:
      prober: http
      timeout: 10s
      http:
        valid_status_codes: [200, 201]
        method: POST
        headers:
          Content-Type: application/json
        body: '{"key": "value"}'
```

### Monitoring Additional Endpoints

Update the ServiceMonitor targets in your overlay:

```yaml
serviceMonitor:
  targets:
    - name: api-health
      url: https://api.example.com/health
      module: http_2xx
      interval: 60s
```

## Integration with kube-prometheus-stack

If using kube-prometheus-stack, ensure ServiceMonitor labels match the Prometheus selector:

```yaml
serviceMonitor:
  enabled: true
  defaults:
    labels:
      prometheus: kube-prometheus
```

## Troubleshooting

### Check Deployment Status

```bash
kubectl get helmrelease -n blackbox-exporter
kubectl get pods -n blackbox-exporter
```

### View Logs

```bash
kubectl logs -n blackbox-exporter -l app.kubernetes.io/name=prometheus-blackbox-exporter
```

### Test Probe Manually

```bash
kubectl port-forward -n blackbox-exporter svc/blackbox-exporter 9115:9115
curl "http://localhost:9115/probe?target=https://example.com&module=http_2xx"
```

### Common Issues

1. **ICMP probes not working**: ICMP requires NET_RAW capability. Add to securityContext if needed:
   ```yaml
   securityContext:
     capabilities:
       add: ["NET_RAW"]
   ```

2. **DNS resolution failures**: Check cluster DNS configuration and network policies.

3. **Timeout errors**: Increase probe timeout in module configuration.

## References

- [Blackbox Exporter GitHub](https://github.com/prometheus/blackbox_exporter)
- [Helm Chart Documentation](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter)
- [Prometheus Documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#probe_config)
