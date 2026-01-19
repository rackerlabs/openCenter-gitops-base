# Istio – Base Configuration

This directory contains the **base manifests** for deploying [Istio](https://istio.io/), a service mesh for securing, connecting, and observing microservices.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About Istio:**

- Provides **traffic management** with routing, retries, timeouts, and fault injection.  
- Enables **mTLS and zero-trust security** between services with policy enforcement.  
- Adds **observability** via telemetry, tracing, and access logs.  
- Supports **ingress and egress gateways** for controlled north-south traffic.  
- Works with standard Kubernetes services without app code changes.  
- Scales across namespaces and clusters with flexible sidecar injection.  
- Useful for platform teams, SREs, and developers operating complex service topologies.  
