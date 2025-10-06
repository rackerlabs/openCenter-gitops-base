# Envoy Gateway API – Base Configuration

This directory contains the **base manifests** for deploying the [Envoy Gateway](https://gateway.envoyproxy.io/) as a managed service.
It is intended to be consumed by **cluster repositories** as a remote base, with the option to provide cluster-specific overrides.

**About Envoy Gateway:**

- Implements the Kubernetes **Gateway API** to manage north-south traffic routing for services.  
- Simplifies Envoy deployment and configuration through a controller-based approach.
- Integrates seamlessly with **Cert-Manager** for automatic TLS certificate provisioning.  
- Supports advanced traffic management features such as path-based routing, header manipulation, timeouts, retries, and rate limiting.  
- Commonly used to expose applications, APIs, and services securely to external clients.  
