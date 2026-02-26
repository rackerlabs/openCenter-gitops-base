# Envoy Gateway API – Base Configuration

This directory contains the **base manifests** for deploying the [Envoy Gateway](https://gateway.envoyproxy.io/) as a managed service.
It is intended to be consumed by **cluster repositories** as a remote base, with the option to provide cluster-specific overrides.

## Public Repository Scope

- This public repository contains the **community/base** gateway-api deployment only.
- Enterprise-specific values, chart source changes, and enterprise-only resources must be delivered from a **private enterprise repository** as an overlay/component on top of this base.

**About Envoy Gateway:**

- Implements the Kubernetes **Gateway API** to manage north-south traffic routing for services.  
- Simplifies Envoy deployment and configuration through a controller-based approach.
- Integrates seamlessly with **Cert-Manager** for automatic TLS certificate provisioning.  
- Supports advanced traffic management features such as path-based routing, header manipulation, timeouts, retries, and rate limiting.  
- Commonly used to expose applications, APIs, and services securely to external clients.  
