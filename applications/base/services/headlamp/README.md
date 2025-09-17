# Headlamp Kubernetes Dashboard with OIDC

This directory contains the Headlamp Kubernetes dashboard configuration with OIDC authentication support for secure access to the cluster.

## Overview

Headlamp is a Kubernetes web UI that provides:
- Real-time cluster monitoring
- Resource management capabilities
- Plugin extensibility
- OIDC authentication integration
- Multi-cluster support

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│  Ingress/NGINX   │───▶│    Headlamp     │
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
   Valid Redirect URIs: https://headlamp.example.com/*
   Web Origins: https://headlamp.example.com
   ```
3. Note the client secret from the Credentials tab

#### Required Scopes

Ensure your OIDC provider supports these scopes:
- `openid` - Required for OIDC
- `profile` - User profile information
- `email` - User email address
- `groups` - User group membership (for RBAC)

### Secret Configuration

1. **Create the OIDC secret** using the template:

   ```bash
   # Copy and edit the template
   cp applications/base/services/headlamp/oidc-secret-template.yaml /tmp/headlamp-oidc.yaml

   # Edit with your OIDC provider details
   nano /tmp/headlamp-oidc.yaml
   ```

2. **For production environments**, use sealed-secrets:

   ```bash
   # Create the secret and seal it
   kubectl create secret generic headlamp-oidc-config \
     --namespace kube-system \
     --from-literal=clientID="your-client-id" \
     --from-literal=clientSecret="your-client-secret" \
     --from-literal=issuerURL="https://your-provider.com/realms/your-realm" \
     --from-literal=scopes="openid profile email groups" \
     --from-literal=callbackURL="https://headlamp.example.com/oidc-callback" \
     --dry-run=client -o yaml | \
   kubeseal -o yaml > applications/base/services/headlamp/sealed-oidc-secret.yaml
   ```

3. **Apply the secret**:

   ```bash
   kubectl apply -f /tmp/headlamp-oidc.yaml
   # OR for sealed secrets:
   kubectl apply -f applications/base/services/headlamp/sealed-oidc-secret.yaml
   ```

### Domain Configuration

Update the ingress configuration in `helm-values/hardened-values-0.24.0.yaml`:

```yaml
ingress:
  hosts:
    - host: headlamp.your-domain.com  # Replace with your domain
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: headlamp-tls
      hosts:
        - headlamp.your-domain.com
```

### RBAC Configuration

Create appropriate RBAC permissions for OIDC users:

```yaml
# Example: Read-only access for developers
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: headlamp-developers
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- kind: User
  name: "developer@example.com"
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: "developers"
  apiGroup: rbac.authorization.k8s.io
```

## Deployment

### Using Flux CD (Recommended)

1. **Ensure the secret exists** in the cluster
2. **Update parent kustomization** to include headlamp:

   ```yaml
   # In applications/overlays/your-cluster/kustomization.yaml
   resources:
     - ../../base/services/headlamp
   ```

3. **Commit and push** changes to trigger Flux reconciliation

### Manual Deployment

```bash
# Deploy using kubectl
kubectl kustomize applications/base/services/headlamp | kubectl apply -f -

# Monitor deployment
kubectl get pods -n kube-system -l app.kubernetes.io/name=headlamp
kubectl get helmrelease headlamp -n kube-system
```

## Access and Usage

### Accessing Headlamp

1. Navigate to `https://headlamp.your-domain.com`
2. Click "Sign in with OIDC"
3. Complete the OIDC authentication flow
4. Access the Kubernetes dashboard

### Features Available

- **Cluster Overview**: Nodes, resources, and cluster status
- **Workload Management**: Deployments, pods, services
- **Configuration**: ConfigMaps, secrets, RBAC
- **Storage**: PVs, PVCs, storage classes
- **Networking**: Services, ingress, network policies
- **Custom Resources**: CRDs and custom resources

## Security Features

### Network Security

- **Network Policies**: Restrict ingress/egress traffic
- **TLS Encryption**: All traffic encrypted in transit
- **Security Headers**: Comprehensive HTTP security headers

### Authentication & Authorization

- **OIDC Integration**: Secure authentication via identity provider
- **RBAC Integration**: Kubernetes RBAC enforcement
- **Token Security**: ID tokens preferred over access tokens

### Container Security

- **Non-root execution**: Runs as non-privileged user
- **Read-only filesystem**: Immutable container filesystem
- **Security contexts**: Comprehensive security restrictions
- **Capability dropping**: Minimal Linux capabilities

## Monitoring

### Health Checks

```bash
# Check pod status
kubectl get pods -n kube-system -l app.kubernetes.io/name=headlamp

# Check service endpoints
kubectl get endpoints headlamp -n kube-system

# Check ingress status
kubectl get ingress headlamp -n kube-system
```

### Logs

```bash
# Application logs
kubectl logs -n kube-system deployment/headlamp -f

# Helm release status
kubectl describe helmrelease headlamp -n kube-system
```

## Troubleshooting

### Common Issues

#### OIDC Authentication Fails

1. **Check secret configuration**:
   ```bash
   kubectl get secret headlamp-oidc-config -n kube-system -o yaml
   ```

2. **Verify OIDC provider settings**:
   - Client ID and secret are correct
   - Callback URL matches ingress configuration
   - Required scopes are available

3. **Check application logs**:
   ```bash
   kubectl logs -n kube-system deployment/headlamp
   ```

#### Ingress Issues

1. **Verify cert-manager**:
   ```bash
   kubectl get certificate headlamp-tls -n kube-system
   ```

2. **Check ingress controller**:
   ```bash
   kubectl get ingress headlamp -n kube-system
   kubectl describe ingress headlamp -n kube-system
   ```

#### Permission Denied

1. **Check RBAC configurations**:
   ```bash
   kubectl auth can-i --list --as=system:serviceaccount:kube-system:headlamp
   ```

2. **Verify service account**:
   ```bash
   kubectl get serviceaccount headlamp -n kube-system
   kubectl describe serviceaccount headlamp -n kube-system
   ```

### Debug Commands

```bash
# Force Flux reconciliation
flux reconcile helmrelease headlamp -n kube-system

# Check all resources
kubectl get all -n kube-system -l app.kubernetes.io/name=headlamp

# Test OIDC endpoint
curl -k https://your-provider.com/realms/your-realm/.well-known/openid-configuration
```

## Customization

### Adding Custom Plugins

Mount plugin configurations via ConfigMaps:

```yaml
# Add to kustomization.yaml
configMapGenerator:
  - name: headlamp-plugins
    files:
      - plugins/my-plugin.js
```

### Environment-Specific Overrides

Create overlay-specific configurations:

```yaml
# In applications/overlays/production/headlamp-values.yaml
apiVersion: v1
kind: Secret
metadata:
  name: headlamp-values-override
  namespace: kube-system
type: Opaque
stringData:
  override.yaml: |
    replicaCount: 3
    resources:
      requests:
        cpu: 200m
        memory: 256Mi
      limits:
        cpu: 1000m
        memory: 1Gi
```

## Maintenance

### Updating Headlamp

1. **Update chart version** in `helmrelease.yaml`
2. **Update hardened values** filename to match new version
3. **Test in development** environment first
4. **Monitor deployment** after update

### Backup Considerations

- OIDC secret backup (store encrypted in secure location)
- Custom plugin configurations
- RBAC permissions for users/groups

## Integration with openCenter

Headlamp integrates with the openCenter GitOps platform:

- **Keycloak SSO**: Uses the cluster's Keycloak instance for authentication
- **cert-manager**: Automatic TLS certificate management
- **Prometheus**: Metrics collection and monitoring
- **Network Policies**: Integrated with cluster security policies
- **Backup**: Included in Velero backup schedules

For more information, see the [openCenter documentation](../../README.md).