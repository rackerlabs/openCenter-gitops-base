# Headlamp – Base Configuration

This directory contains the **base manifests** for deploying [Headlamp](https://headlamp.dev/), a modern web-based Kubernetes dashboard built to simplify cluster management and visualization.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About Headlamp:**

- Provides an intuitive **web UI** for exploring and managing Kubernetes clusters.  
- Supports **multi-cluster access**, RBAC-based authentication, and OIDC integration for secure user logins.  
- Offers real-time insights into workloads, pods, services, storage, and cluster resources.  
- Can be deployed both **in-cluster** or **externally** and accessed via an Ingress or LoadBalancer service.  
- Enables plugin extensions and custom views for advanced integrations.  
- Useful for developers, operators, and SREs who prefer a lightweight alternative to the classic Kubernetes Dashboard.  
- Enhances troubleshooting and visibility without requiring kubectl access.  

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│    Ingress       │───▶│    Headlamp     │
└─────────────────┘    └──────────────────┘    │     Pods        │
                                               └─────────────────┘
                                                         │
                                                         ▼
                                                ┌─────────────────┐
                                                │  Kubernetes API │
                                                │     Server      │
                                                └─────────────────┘
                                                         ▲
                                                         │
                                                ┌─────────────────┐
                                                │  OIDC Provider  │
                                                │  (Keycloak)     │
                                                └─────────────────┘
```

## OIDC Configuration

### Prerequisites

1. **OIDC Provider**: A configured OIDC provider (Keycloak, Authentik, etc.)
2. **Ingress Controller**: NGINX ingress controller with cert-manager
3. **Sealed Secrets**: For secure secret management (recommended)

### OIDC Provider Setup

#### Keycloak Example

1. Create a new client in your Keycloak realm
2. Configure the client settings:

   ```
   Client ID: headlamp
   Client Protocol: openid-connect
   Access Type: confidential
   Valid Redirect URIs: https://headlamp.example.com/oidc-callback
   ```

3. Note the client secret from the Credentials tab

#### Required Scopes

Ensure your OIDC provider supports these scopes:

- `openid` - Required for OIDC
- `profile` - User profile information
- `email` - User email address
- `groups` - User group membership (for RBAC)

### Cluster helm override values configuration

``` yaml
config:
    oidc:
        externalSecret:
            enabled: false
        secret:
            create: true
        clientID: opencenter
        clientSecret: <REPLACEME>
        issuerURL: https://auth.<account>.<env>.<region>.k8s.opencenter.cloud/realms/opencenter
        scopes: openid profile email groups
        callbackURL: https://headlamp.<account>.<env>.<region>.k8s.opencenter.cloud/oidc-callback
```

- Further manage the RBAC using `rbac-manager` service.
