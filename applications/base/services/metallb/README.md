# MetalLB – Base Configuration

This directory contains the **base manifests** for deploying [MetalLB](https://metallb.universe.tf/), a load-balancer implementation for bare-metal Kubernetes clusters.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About MetalLB:**

- Provides **LoadBalancer service functionality** in environments without a native cloud load balancer (such as bare-metal or on-premise clusters).  
- Supports both **Layer 2** and **Layer 3** modes for flexible traffic routing.  
- Allows assigning external IPs to Kubernetes services to make them accessible outside the cluster.  
- Can advertise service IPs to upstream routers, enabling real network integration with minimal complexity.  
- Works seamlessly with ingress controllers and gateways such as **NGINX**, **Envoy Gateway**, or **HAProxy**.  
- Commonly used in hybrid or on-prem environments to provide reliable, production-grade service exposure.  
- Simplifies network configuration and improves accessibility for Kubernetes workloads in non-cloud environments.  
