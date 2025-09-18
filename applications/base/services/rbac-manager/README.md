# RBAC Manager

RBAC Manager is a Kubernetes operator that simplifies the management of Role Bindings and Service Accounts through declarative configuration using custom resources.

## Overview

RBAC Manager by Fairwinds allows you to define a desired state for RBAC and automatically makes the necessary changes to achieve that state, eliminating the need to directly manage role bindings and service accounts.

## Configuration

### Chart Information

- **Chart Version**: 1.21.1
- **App Version**: v1.9.2
- **Repository**: https://charts.fairwinds.com/stable
- **Image**: quay.io/reactiveops/rbac-manager:v1.9.2

### Security Features

- **Non-root execution**: Runs as user 65534
- **Read-only root filesystem**: Prevents runtime modifications
- **Dropped capabilities**: All Linux capabilities removed
- **Security profiles**: RuntimeDefault seccomp profile
- **Priority class**: system-cluster-critical for high availability

### Monitoring Integration

- **Prometheus metrics**: Enabled on port 8080
- **ServiceMonitor**: Automatic Prometheus discovery
- **Grafana dashboards**: Available for RBAC operations
- **Logging**: Structured JSON logging at info level

## Usage

### Basic RBACDefinition

Create an `RBACDefinition` custom resource to define RBAC rules:

```yaml
apiVersion: rbacmanager.reactiveops.io/v1beta1
kind: RBACDefinition
metadata:
  name: my-rbac-definition
  namespace: rbac-system
spec:
  rbacBindings:
    - name: developers-view
      subjects:
        - kind: Group
          name: "developers"
          apiGroup: rbac.authorization.k8s.io
      roleRef:
        kind: ClusterRole
        name: view
        apiGroup: rbac.authorization.k8s.io
```

### OIDC Integration

For OIDC-based authentication with group membership:

```yaml
apiVersion: rbacmanager.reactiveops.io/v1beta1
kind: RBACDefinition
metadata:
  name: oidc-developers
  namespace: rbac-system
spec:
  rbacBindings:
    - name: oidc-developers-view
      subjects:
        - kind: Group
          name: "oidc:developers"  # From OIDC group claim with prefix
          apiGroup: rbac.authorization.k8s.io
      roleRef:
        kind: ClusterRole
        name: view
        apiGroup: rbac.authorization.k8s.io
```

### Namespace-Scoped Access

Grant access to specific namespaces using namespace selectors:

```yaml
apiVersion: rbacmanager.reactiveops.io/v1beta1
kind: RBACDefinition
metadata:
  name: dev-team-access
  namespace: rbac-system
spec:
  rbacBindings:
    - name: dev-team-edit
      subjects:
        - kind: Group
          name: "oidc:namespace-development-developers"
          apiGroup: rbac.authorization.k8s.io
      roleRef:
        kind: ClusterRole
        name: edit
        apiGroup: rbac.authorization.k8s.io
      namespaceSelector:
        matchLabels:
          environment: development
```

### Observability Team Access

Monitoring teams require comprehensive cluster-wide access to effectively monitor all resources:

```yaml
apiVersion: rbacmanager.reactiveops.io/v1beta1
kind: RBACDefinition
metadata:
  name: oidc-observability-team
  namespace: rbac-system
spec:
  rbacBindings:
    # Cluster-wide read access for monitoring all resources
    - name: observability-cluster-reader
      subjects:
        - kind: Group
          name: "oidc:observability-team"
          apiGroup: rbac.authorization.k8s.io
      roleRef:
        kind: ClusterRole
        name: cluster-reader
        apiGroup: rbac.authorization.k8s.io

    # Access to monitoring APIs and metrics endpoints
    - name: observability-monitoring-resources
      subjects:
        - kind: Group
          name: "oidc:observability-team"
          apiGroup: rbac.authorization.k8s.io
      roleRef:
        kind: ClusterRole
        name: system:monitoring
        apiGroup: rbac.authorization.k8s.io

    # Admin access to observability namespaces
    - name: observability-namespace-admin
      subjects:
        - kind: Group
          name: "oidc:observability-team"
          apiGroup: rbac.authorization.k8s.io
      roleRef:
        kind: ClusterRole
        name: admin
        apiGroup: rbac.authorization.k8s.io
      namespaceSelector:
        matchLabels:
          observability.openCenter.io/managed: "true"
```

**Key Features of Observability RBAC:**
- **Cluster-wide monitoring**: Access to pods, services, nodes across all namespaces
- **Metrics collection**: Access to `/metrics` endpoints on all services
- **Node monitoring**: CPU, memory, disk, network metrics from all cluster nodes
- **Custom resources**: Manage ServiceMonitors, PrometheusRules, Alertmanager configs
- **Event access**: Collect cluster events for alerting and troubleshooting
- **Namespace admin**: Full control over monitoring tools (Prometheus, Grafana, etc.)

## Example RBAC Definitions

The service includes example RBAC definitions in `rbac-definitions/oidc-rbac-templates.yaml`:

- **oidc:developers**: Read-only cluster access
- **oidc:admins**: Full cluster admin access
- **oidc:platform-team**: Infrastructure management
- **oidc:security-team**: Audit and security namespace access
- **oidc:observability-team**: Comprehensive monitoring access (cluster-wide)
- **oidc:monitoring-users**: Read-only dashboard access
- **oidc:namespace-{env}-developers**: Namespace-specific edit access

To deploy the examples, uncomment the line in `kustomization.yaml`:

```yaml
resources:
  - ./namespace.yaml
  - ./source.yaml
  - ./helmrelease.yaml
  - ./rbac-definitions/  # Uncomment this line
```

## Deployment

### Prerequisites

- Kubernetes 1.16+
- Helm 3.0+
- Prometheus Operator (for monitoring)

### Installation

The service is deployed via Flux CD using the GitOps pattern:

```bash
# Deploy RBAC Manager
kubectl apply -k applications/base/services/rbac-manager/

# Check deployment status
kubectl get pods -n rbac-system
kubectl get helmrelease rbac-manager -n rbac-system

# Verify CRDs are installed
kubectl get crd rbacbindings.rbacmanager.reactiveops.io
```

### Creating RBAC Definitions

1. Create your RBACDefinition YAML files
2. Apply them to the `rbac-system` namespace
3. RBAC Manager will automatically create the corresponding RoleBindings

```bash
# Apply a new RBAC definition
kubectl apply -f my-rbac-definition.yaml

# Check created bindings
kubectl get rolebindings,clusterrolebindings | grep rbac-manager
```

## Monitoring

### Metrics

RBAC Manager exposes metrics on port 8080:

- `rbac_manager_rbac_binding_reconcile_duration_seconds`
- `rbac_manager_rbac_binding_reconcile_total`
- `rbac_manager_rbac_definition_reconcile_duration_seconds`
- `rbac_manager_rbac_definition_reconcile_total`

### Health Checks

```bash
# Check pod status
kubectl get pods -n rbac-system -l app.kubernetes.io/name=rbac-manager

# View logs
kubectl logs -n rbac-system deployment/rbac-manager

# Check metrics endpoint
kubectl port-forward -n rbac-system svc/rbac-manager 8080:8080
curl http://localhost:8080/metrics
```

### Troubleshooting

Common issues and solutions:

1. **CRDs not installed**:
   ```bash
   kubectl get crd | grep rbacmanager
   # If missing, ensure installCRDs: true in values
   ```

2. **RBAC bindings not created**:
   ```bash
   kubectl describe rbacbinding <name> -n rbac-system
   kubectl logs -n rbac-system deployment/rbac-manager
   ```

3. **Permission denied errors**:
   ```bash
   kubectl auth can-i "*" "*" --as=system:serviceaccount:rbac-system:rbac-manager
   ```

## Namespace Labeling Strategy

For targeted RBAC access, label namespaces appropriately:

### Observability Namespaces

```bash
# Label monitoring and observability namespaces
kubectl label namespace observability observability.openCenter.io/managed=true
kubectl label namespace monitoring observability.openCenter.io/managed=true
kubectl label namespace logging observability.openCenter.io/managed=true
kubectl label namespace tracing observability.openCenter.io/managed=true
```

### Environment-Specific Namespaces

```bash
# Label namespaces by environment
kubectl label namespace app-dev environment=development
kubectl label namespace app-staging environment=staging
kubectl label namespace app-prod environment=production
```

### Security Namespaces

```bash
# Label security-related namespaces
kubectl label namespace falco security.openCenter.io/managed=true
kubectl label namespace gatekeeper-system security.openCenter.io/managed=true
kubectl label namespace kyverno security.openCenter.io/managed=true
```

## Integration with Keycloak OIDC

When using with Keycloak OIDC authentication:

1. **Configure Keycloak** to include group claims in tokens
2. **Create RBACDefinitions** that reference OIDC groups with `oidc:` prefix
3. **Users authenticate** via OIDC and get permissions based on group membership

### Required Kubernetes API Server Configuration

```bash
# OIDC configuration for kube-apiserver
--oidc-issuer-url=https://keycloak.example.com/auth/realms/openstack
--oidc-client-id=kubernetes
--oidc-username-claim=preferred_username
--oidc-groups-claim=groups
--oidc-username-prefix=oidc:
--oidc-groups-prefix=oidc:
```

### Keycloak Group Mapper Configuration

```json
{
  "name": "groups",
  "protocol": "openid-connect",
  "protocolMapper": "oidc-group-membership-mapper",
  "config": {
    "claim.name": "groups",
    "full.path": "false",
    "id.token.claim": "true",
    "access.token.claim": "true",
    "userinfo.token.claim": "true"
  }
}
```

### Group Structure in Keycloak

```
Recommended Keycloak Groups:
├── admins (cluster-admin access)
├── developers (read-only cluster access)
├── observability-team (comprehensive monitoring)
├── monitoring-users (dashboard read-only)
├── security-team (audit and security)
├── platform-team (infrastructure management)
└── namespace-{env}-developers (namespace-specific access)
```

## Best Practices

1. **Use descriptive names** for RBACDefinitions and bindings
2. **Group similar permissions** in single RBACDefinitions
3. **Use namespace selectors** for environment-specific access
4. **Regular audits** of RBAC bindings and access patterns
5. **Version control** all RBACDefinition YAML files
6. **Test permissions** before applying to production

## Resources

- [Official Documentation](https://rbac-manager.docs.fairwinds.com/)
- [GitHub Repository](https://github.com/FairwindsOps/rbac-manager)
- [Helm Chart](https://artifacthub.io/packages/helm/fairwinds-stable/rbac-manager)
- [Fairwinds Slack Community](https://fairwinds.com/slack)

## Security Considerations

- RBAC Manager requires cluster-admin permissions to manage RBAC
- All RBACDefinitions should be reviewed before deployment
- Use principle of least privilege when defining permissions
- Regular access reviews and cleanup of unused bindings
- Monitor RBAC changes through audit logs and metrics