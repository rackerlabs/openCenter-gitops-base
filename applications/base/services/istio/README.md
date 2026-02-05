# Istio – Base Configuration

This directory contains the **base manifests** for deploying [Istio](https://istio.io/), a service mesh platform that provides traffic management, security, and observability for microservices.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About Istio:**

- Provides **service mesh capabilities** for Kubernetes, enabling advanced traffic management, security, and observability for microservices.
- Supports **automatic sidecar injection** to transparently add service mesh functionality to applications without code changes.
- Offers **mutual TLS (mTLS)** for secure service-to-service communication with automatic certificate management.
- Enables **fine-grained traffic control** including load balancing, circuit breaking, retries, failovers, and fault injection.
- Provides **observability features** including distributed tracing, metrics collection, and access logging for all service communications.
- Supports **advanced deployment patterns** such as canary deployments, A/B testing, and blue-green deployments through traffic splitting.
- Integrates with **Prometheus, Grafana, Jaeger, and Kiali** for comprehensive monitoring and visualization.
- Offers **policy enforcement** and **rate limiting** capabilities to control and secure service interactions.
- Works seamlessly with **Kubernetes Gateway API** and traditional Ingress resources for external traffic management.
- Commonly used in production environments requiring **zero-trust security**, **traffic observability**, and **resilient microservices architecture**.

## Architecture

Istio is deployed in three main components:

### 1. Base (CRDs and Cluster Resources)
- Contains Custom Resource Definitions (CRDs) required by Istio
- Includes cluster-wide resources and configurations
- Must be installed first before other components

### 2. Istiod (Control Plane)
- The unified control plane that manages and configures the service mesh
- Handles service discovery, configuration distribution, and certificate management
- Provides automatic sidecar injection for workloads
- Deployed in the `istio-system` namespace

### 3. Gateway (Ingress Gateway)
- Manages inbound traffic to the service mesh
- Acts as a load balancer at the edge of the mesh
- Supports HTTP, HTTPS, TCP, and gRPC protocols
- Deployed in the `istio-ingress` namespace

## Installation Order

The components must be installed in the following order due to dependencies:

1. **istio-base** - Installs CRDs and base resources
2. **istiod** - Installs the control plane (depends on istio-base)
3. **gateway** - Installs the ingress gateway (depends on istiod)

This dependency chain is enforced through FluxCD's `dependsOn` field in the HelmRelease manifests.

## Directory Structure

```
istio/
├── README.md                    # This file
├── source.yaml                  # Helm repository definition
├── base/                        # Istio base component (CRDs)
│   ├── namespace.yaml
│   ├── helmrelease.yaml
│   ├── kustomization.yaml
│   └── helm-values/
│       └── hardened-values-1.28.2.yaml
├── istiod/                      # Istio control plane
│   ├── helmrelease.yaml
│   ├── kustomization.yaml
│   └── helm-values/
│       └── hardened-values-1.28.2.yaml
└── gateway/                     # Istio ingress gateway
    ├── namespace.yaml
    ├── helmrelease.yaml
    ├── kustomization.yaml
    └── helm-values/
        └── hardened-values-1.28.2.yaml
```

## Configuration

### Hardened Values

Each component includes hardened configuration values that follow security best practices:

- **Resource limits** to prevent resource exhaustion
- **Security contexts** with non-root users and dropped capabilities
- **High availability** with multiple replicas and pod disruption budgets
- **Auto-scaling** enabled for dynamic workload handling
- **mTLS enabled** by default for secure service communication
- **Minimal logging** to reduce noise while maintaining observability

### Customization

To customize Istio for your cluster:

1. Create an overlay directory in your cluster repository
2. Reference this base using Kustomize remote bases
3. Add a `Secret` named `istio-base-values-override`, `istiod-values-override`, or `istio-gateway-values-override` with your custom values
4. The override values will be merged with the base hardened values

Example overlay structure:
```
applications/overlays/my-cluster/services/istio/
├── base/
│   └── values-override.yaml
├── istiod/
│   └── values-override.yaml
└── gateway/
    └── values-override.yaml
```

## Common Customizations

### Istiod (Control Plane)
- Adjust replica count for control plane
- Configure tracing backends (Jaeger, Zipkin)
- Modify outbound traffic policy (ALLOW_ANY vs REGISTRY_ONLY)
- Configure trust domain for multi-cluster setups

### Gateway (Ingress)
- Change service type (LoadBalancer, NodePort, ClusterIP)
- Configure load balancer IP and source ranges
- Add custom ports for additional protocols
- Adjust resource limits based on traffic volume
- Configure service annotations for cloud provider integration

## Monitoring

Istio provides extensive telemetry data:

- **Metrics**: Exposed via Prometheus endpoints on port 15020
- **Tracing**: Can be configured to send traces to Jaeger or Zipkin
- **Access Logs**: JSON-formatted logs sent to stdout
- **Dashboards**: Compatible with Grafana for visualization

## Security Considerations

- **mTLS** is enabled by default for all service-to-service communication
- **Automatic certificate rotation** is handled by Istiod
- **Authorization policies** can be applied to control access between services
- **Security contexts** enforce non-root execution and capability restrictions
- **Network policies** should be used in conjunction with Istio for defense in depth

## Version

Current version: **1.28.2**

## References

- [Istio Documentation](https://istio.io/latest/docs/)
- [Istio Helm Installation](https://istio.io/latest/docs/setup/install/helm/)
- [Istio Security Best Practices](https://istio.io/latest/docs/ops/best-practices/security/)
- [Istio Performance and Scalability](https://istio.io/latest/docs/ops/deployment/performance-and-scalability/)
