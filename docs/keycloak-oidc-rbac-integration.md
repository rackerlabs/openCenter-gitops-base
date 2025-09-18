# Keycloak OIDC Authentication and RBAC Management System

This document describes the complete Keycloak OIDC authentication system with automated RBAC management, policy enforcement, and security monitoring implemented in the openCenter GitOps platform.

## Overview

The openCenter platform implements a comprehensive identity and access management solution that provides:

- **Centralized Authentication**: Keycloak OIDC provider for single sign-on
- **Automated RBAC Management**: Dynamic role-based access control
- **Policy Enforcement**: Admission control and compliance validation
- **Security Monitoring**: Runtime threat detection and audit logging
- **Metrics and Observability**: Comprehensive monitoring and alerting

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User/Client   │───▶│    Keycloak      │───▶│   Kubernetes    │
│                 │    │   (OIDC IdP)     │    │   API Server    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │  RBAC Manager   │◀───│   Admission     │
                       │                 │    │   Controllers   │
                       └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Monitoring    │    │   Policy        │
                       │   & Alerting    │    │   Engines       │
                       └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Prometheus    │    │ Kyverno/OPA     │
                       │   Grafana       │    │ Gatekeeper      │
                       └─────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
                                                ┌─────────────────┐
                                                │     Falco       │
                                                │  (Runtime       │
                                                │   Security)     │
                                                └─────────────────┘
```

## Components

### 1. Keycloak - Identity Provider

**Purpose**: Centralized OIDC authentication and user management

**Configuration**:
- **High Availability**: 3 replicas with PostgreSQL backend
- **Metrics Enabled**: Prometheus integration for monitoring
- **OIDC Scopes**: `openid`, `profile`, `email`, `groups`
- **Group Claims**: Automatic group mapping for RBAC

**Key Features**:
- Multi-realm support for different environments
- LDAP/Active Directory integration
- Social login providers
- Admin console for user management
- Token validation and refresh

**Location**: `applications/base/services/keycloak/`

### 2. RBAC Manager - Automated RBAC

**Purpose**: Dynamic role-based access control management

**Configuration**:
- **OIDC Integration**: Automatic role assignment based on groups
- **Template-Based**: Pre-configured role templates
- **Monitoring**: Prometheus metrics for RBAC operations

**Key Features**:
- Automatic ClusterRoleBinding creation
- Group-based role assignment
- Namespace-specific permissions
- Audit trail for RBAC changes

**Templates**:
- `developer-template`: Read-only access for developers
- `admin-template`: Cluster admin access for administrators
- `namespace-developer-template`: Edit access scoped to namespaces

**Location**: `applications/base/services/rbac-manager/`

### 3. Kyverno - Policy Engine

**Purpose**: Kubernetes-native policy management and governance

**Configuration**:
- **Multi-Controller**: Admission, background, cleanup, reports
- **OIDC Context**: User information in policy decisions
- **High Availability**: Multiple replicas with anti-affinity

**Key Features**:
- Validate, mutate, and generate resources
- Background scanning of existing resources
- Policy exceptions and exclusions
- Grafana dashboard integration
- OIDC user context in policies

**Location**: `applications/base/services/kyverno/`

### 4. OPA Gatekeeper - Admission Control

**Purpose**: Open Policy Agent for constraint-based governance

**Configuration**:
- **Webhook-Based**: Admission controller integration
- **OIDC Support**: User context in constraint evaluation
- **Mutation Support**: Resource modification capabilities

**Key Features**:
- Constraint template library
- Violation audit and logging
- External data provider support
- Metrics and monitoring
- Policy violation alerts

**Location**: `applications/base/services/gatekeeper/`

### 5. Falco - Runtime Security

**Purpose**: Runtime threat detection and security monitoring

**Configuration**:
- **eBPF Driver**: Modern eBPF for syscall monitoring
- **Custom Rules**: OIDC and RBAC-specific detection
- **DaemonSet**: Node-level security monitoring

**Key Features**:
- OIDC authentication failure detection
- RBAC permission denied monitoring
- Privileged container detection
- Suspicious network activity alerts
- Integration with Prometheus and alerting

**Location**: `applications/base/services/falco/`

## Integration Workflows

### Authentication Flow

1. **User Authentication**:
   ```
   User → Headlamp/Client → Keycloak OIDC → JWT Token → Kubernetes API
   ```

2. **Token Validation**:
   ```
   Kubernetes API → OIDC Validation → User Info + Groups → RBAC Check
   ```

3. **Access Decision**:
   ```
   RBAC Check → Policy Validation → Admission Control → Resource Access
   ```

### RBAC Management Flow

1. **Group Assignment**:
   ```
   Keycloak Groups → OIDC Token Claims → RBAC Manager → ClusterRoleBindings
   ```

2. **Role Templates**:
   ```
   RBAC Manager Templates → Automatic Role Assignment → Namespace Permissions
   ```

3. **Monitoring**:
   ```
   RBAC Changes → Prometheus Metrics → Grafana Dashboards → Alerts
   ```

### Policy Enforcement Flow

1. **Admission Control**:
   ```
   Resource Creation → Kyverno/Gatekeeper → Policy Evaluation → Allow/Deny
   ```

2. **Background Scanning**:
   ```
   Existing Resources → Policy Engine → Compliance Reports → Remediation
   ```

3. **Runtime Monitoring**:
   ```
   System Calls → Falco Rules → Security Events → Alerts
   ```

## Deployment Instructions

### Prerequisites

1. **Infrastructure Components**:
   - PostgreSQL (for Keycloak backend)
   - cert-manager (for TLS certificates)
   - ingress-nginx (for external access)
   - kube-prometheus-stack (for monitoring)

2. **Required Secrets**:
   - Keycloak admin credentials
   - Database connection details
   - TLS certificates

### Step 1: Deploy Keycloak

```bash
# Ensure PostgreSQL is running
kubectl get pods -n keycloak -l app=postgres-cluster

# Deploy Keycloak with monitoring
kubectl apply -k applications/base/services/keycloak/

# Wait for Keycloak to be ready
kubectl wait --for=condition=Ready keycloak/keycloak -n keycloak --timeout=300s

# Check metrics endpoint
kubectl port-forward -n keycloak svc/keycloak-service 8080:8080
curl http://localhost:8080/metrics
```

### Step 2: Configure OIDC Provider

1. **Access Keycloak Admin Console**:
   ```bash
   # Get admin credentials
   kubectl get secret keycloak-initial-admin -n keycloak -o jsonpath='{.data.username}' | base64 -d
   kubectl get secret keycloak-initial-admin -n keycloak -o jsonpath='{.data.password}' | base64 -d

   # Access via port-forward or ingress
   kubectl port-forward -n keycloak svc/keycloak-service 8080:8080
   # Open http://localhost:8080/admin
   ```

2. **Create Realm and Client**:
   - Create a new realm (e.g., `openstack`)
   - Create OIDC client for each service
   - Configure redirect URIs and scopes
   - Set up group mappers

3. **Configure User Groups**:
   ```
   Groups:
   - admins (cluster-admin access)
   - developers (read-only access)
   - observability-team (comprehensive monitoring access)
   - monitoring-users (dashboard read-only access)
   - security-team (audit and security namespace access)
   - platform-team (infrastructure management)
   - namespace-{name}-developers (namespace edit access)
   ```

### Step 3: Deploy RBAC Manager

```bash
# Deploy RBAC Manager
kubectl apply -k applications/base/services/rbac-manager/

# Verify deployment
kubectl get pods -n rbac-system
kubectl logs -n rbac-system deployment/rbac-manager

# Check RBAC templates
kubectl get rbacbindings -A
```

### Step 4: Deploy Policy Engines

```bash
# Deploy Kyverno
kubectl apply -k applications/base/services/kyverno/

# Deploy OPA Gatekeeper
kubectl apply -k applications/base/services/gatekeeper/

# Verify policy engines
kubectl get pods -n kyverno
kubectl get pods -n gatekeeper-system

# Check CRDs
kubectl get clusterpolicies
kubectl get constrainttemplates
```

### Step 5: Deploy Runtime Security

```bash
# Deploy Falco
kubectl apply -k applications/base/services/falco/

# Verify Falco deployment
kubectl get pods -n falco
kubectl logs -n falco daemonset/falco

# Check custom rules
kubectl get configmap falco-custom-rules -n falco -o yaml
```

### Step 6: Configure Service Integration

```bash
# Deploy Headlamp with OIDC
kubectl apply -k applications/base/services/headlamp/

# Create OIDC secret for Headlamp
kubectl create secret generic headlamp-oidc-config \
  --namespace kube-system \
  --from-literal=clientID="headlamp" \
  --from-literal=clientSecret="your-client-secret" \
  --from-literal=issuerURL="https://auth.example.com/realms/openstack" \
  --from-literal=scopes="openid profile email groups" \
  --from-literal=callbackURL="https://headlamp.example.com/oidc-callback"
```

## Configuration Examples

### Keycloak Group Mapping

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

### RBAC Manager Templates

```yaml
# Developer access
apiVersion: rbacmanager.reactiveops.io/v1beta1
kind: RBACDefinition
metadata:
  name: oidc-developers
spec:
  rbacBindings:
    - name: developers-view
      subjects:
        - kind: Group
          name: "oidc:developers"
      roleRef:
        kind: ClusterRole
        name: view

---
# Observability team - comprehensive monitoring
apiVersion: rbacmanager.reactiveops.io/v1beta1
kind: RBACDefinition
metadata:
  name: oidc-observability-team
spec:
  rbacBindings:
    - name: observability-cluster-reader
      subjects:
        - kind: Group
          name: "oidc:observability-team"
      roleRef:
        kind: ClusterRole
        name: cluster-reader
    - name: observability-monitoring-resources
      subjects:
        - kind: Group
          name: "oidc:observability-team"
      roleRef:
        kind: ClusterRole
        name: system:monitoring
```

### Kyverno Policy Example

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: Audit
  background: true
  rules:
    - name: check-labels
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Required labels missing"
        pattern:
          metadata:
            labels:
              app: "?*"
              version: "?*"
```

### OPA Gatekeeper Constraint

```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: must-have-labels
spec:
  match:
    - apiGroups: [""]
      kinds: ["Pod"]
  parameters:
    labels:
      - key: "app"
      - key: "version"
```

### Falco Custom Rule

```yaml
- rule: OIDC Authentication Failure
  desc: Detect failed OIDC authentication attempts
  condition: >
    k8s_audit and ka.verb=create and
    ka.target.resource=tokenreviews and
    ka.response_code>=400
  output: >
    OIDC authentication failed
    (user=%ka.user.name verb=%ka.verb uri=%ka.uri.param
    resp=%ka.response_code reason=%ka.response_reason)
  priority: WARNING
  tags: [oidc, authentication, security]
```

## Monitoring and Observability

### Overview

The openCenter platform provides comprehensive monitoring and observability through the `kube-prometheus-stack`, with RBAC integration for different user roles and access patterns.

#### Observability Team RBAC

The observability team requires comprehensive cluster-wide access to monitor all resources effectively:

**Cluster-Wide Permissions:**
- `cluster-reader`: Read access to all cluster resources across namespaces
- `system:monitoring`: Access to metrics endpoints and monitoring APIs
- Node-level monitoring: CPU, memory, disk, network metrics from all nodes
- Event collection: Cluster events for alerting and troubleshooting
- Custom resource access: ServiceMonitors, PrometheusRules, Alertmanager configs

**Namespace-Specific Permissions:**
- `admin` access to observability namespaces for managing monitoring tools
- Full control over Prometheus, Grafana, Alertmanager configurations
- Ability to create and modify monitoring configurations

**Monitoring User Access:**
- `view` access for dashboard consumption
- Read-only access to metrics and monitoring UIs
- No ability to modify monitoring configurations

#### Group Structure for Observability

```yaml
Groups in Keycloak:
- observability-team: Full monitoring platform management
- monitoring-users: Dashboard and metrics read-only access
- developers: Basic cluster view + monitoring dashboards
```

#### Namespace Labeling for Observability

Observability namespaces should be labeled for targeted RBAC:

```bash
# Label observability namespaces
kubectl label namespace observability observability.openCenter.io/managed=true
kubectl label namespace monitoring observability.openCenter.io/managed=true
kubectl label namespace logging observability.openCenter.io/managed=true
```

**Recommended observability namespaces:**
- `observability`: Core monitoring stack (Prometheus, Grafana, Alertmanager)
- `monitoring`: Additional monitoring tools and exporters
- `logging`: Log aggregation stack (ELK/Loki)
- `tracing`: Distributed tracing (Jaeger/Zipkin)

### Prometheus Metrics

**Keycloak Metrics**:
- `keycloak_login_attempts_total`
- `keycloak_login_errors_total`
- `keycloak_active_sessions`
- `keycloak_token_requests_total`

**RBAC Manager Metrics**:
- `rbac_manager_reconcile_duration_seconds`
- `rbac_manager_rbac_bindings_total`
- `rbac_manager_errors_total`

**Kyverno Metrics**:
- `kyverno_policy_results_total`
- `kyverno_admission_requests_total`
- `kyverno_policy_execution_duration_seconds`

**Gatekeeper Metrics**:
- `gatekeeper_constraint_violations_total`
- `gatekeeper_audit_duration_seconds`
- `gatekeeper_mutation_duration_seconds`

**Falco Metrics**:
- `falco_events_total`
- `falco_dropped_events_total`
- `falco_outputs_total`

### Grafana Dashboards

1. **Keycloak Dashboard**:
   - Authentication metrics
   - User session statistics
   - Error rates and latency
   - Token lifecycle metrics

2. **RBAC Dashboard**:
   - Role binding changes
   - Permission grant/deny rates
   - User access patterns
   - Group membership changes

3. **Policy Compliance Dashboard**:
   - Policy violation trends
   - Compliance score metrics
   - Resource validation results
   - Mutation statistics

4. **Security Dashboard**:
   - Security event timeline
   - Threat detection alerts
   - Runtime security metrics
   - Audit log analysis

### Alerting Rules

```yaml
groups:
  - name: keycloak-alerts
    rules:
      - alert: KeycloakDown
        expr: up{job="keycloak"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Keycloak is down"

      - alert: HighAuthenticationFailures
        expr: rate(keycloak_login_errors_total[5m]) > 0.1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High authentication failure rate"

  - name: rbac-alerts
    rules:
      - alert: RBACManagerDown
        expr: up{job="rbac-manager"} == 0
        for: 5m
        labels:
          severity: warning

      - alert: HighRBACErrors
        expr: rate(rbac_manager_errors_total[5m]) > 0.1
        for: 5m
        labels:
          severity: warning

  - name: policy-alerts
    rules:
      - alert: PolicyViolationSpike
        expr: rate(kyverno_policy_results_total{result="fail"}[5m]) > 1
        for: 5m
        labels:
          severity: warning

      - alert: GatekeeperDown
        expr: up{job="gatekeeper"} == 0
        for: 5m
        labels:
          severity: warning

  - name: security-alerts
    rules:
      - alert: FalcoDown
        expr: up{job="falco"} == 0
        for: 5m
        labels:
          severity: critical

      - alert: SecurityThreatDetected
        expr: rate(falco_events_total{priority="Critical"}[5m]) > 0
        for: 0m
        labels:
          severity: critical
```

## Security Considerations

### Authentication Security

1. **Token Security**:
   - Short-lived access tokens (15 minutes)
   - Refresh token rotation
   - Secure token storage
   - HTTPS-only communication

2. **Session Management**:
   - Session timeout configuration
   - Concurrent session limits
   - Session invalidation on logout
   - SSO session monitoring

### Authorization Security

1. **RBAC Best Practices**:
   - Principle of least privilege
   - Regular access reviews
   - Group-based permissions
   - Namespace isolation

2. **Policy Security**:
   - Policy version control
   - Change approval process
   - Policy testing in staging
   - Emergency policy bypass

### Runtime Security

1. **Container Security**:
   - Non-root execution
   - Read-only filesystems
   - Capability dropping
   - Security contexts

2. **Network Security**:
   - Network policies
   - TLS encryption
   - Service mesh integration
   - Ingress security

## Troubleshooting

### Common Issues

1. **Keycloak Authentication Failures**:
   ```bash
   # Check Keycloak logs
   kubectl logs -n keycloak deployment/keycloak

   # Verify OIDC configuration
   curl -k https://auth.example.com/realms/openstack/.well-known/openid-configuration

   # Test token validation
   kubectl auth can-i --list --as=system:serviceaccount:default:test
   ```

2. **RBAC Permission Issues**:
   ```bash
   # Check RBAC bindings
   kubectl get clusterrolebindings | grep oidc

   # Verify group membership
   kubectl auth can-i --list --as=user@example.com

   # Check RBAC Manager logs
   kubectl logs -n rbac-system deployment/rbac-manager
   ```

3. **Policy Violations**:
   ```bash
   # Check Kyverno policies
   kubectl get clusterpolicies
   kubectl describe clusterpolicy policy-name

   # View policy reports
   kubectl get clusterpolicyreports

   # Check Gatekeeper constraints
   kubectl get constraints
   ```

4. **Security Alerts**:
   ```bash
   # Check Falco logs
   kubectl logs -n falco daemonset/falco

   # View security events
   kubectl logs -n falco daemonset/falco | grep "Priority: Critical"

   # Check custom rules
   kubectl get configmap falco-custom-rules -n falco
   ```

### Debug Commands

```bash
# Test OIDC token validation
kubectl create token default --audience=https://kubernetes.default.svc.cluster.local

# Check API server OIDC configuration
kubectl get pods -n kube-system kube-apiserver-* -o yaml | grep oidc

# Verify service monitor discovery
kubectl get servicemonitors -A

# Test policy engine webhooks
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations

# Check admission controller logs
kubectl logs -n kyverno deployment/kyverno-admission-controller
kubectl logs -n gatekeeper-system deployment/gatekeeper-controller-manager
```

## Maintenance

### Regular Tasks

1. **Certificate Rotation**:
   - Monitor certificate expiration
   - Automated renewal via cert-manager
   - Backup certificate chains

2. **User Access Reviews**:
   - Quarterly access audits
   - Remove inactive users
   - Update group memberships
   - Review privilege escalations

3. **Policy Updates**:
   - Review policy effectiveness
   - Update compliance requirements
   - Test policy changes
   - Document policy decisions

4. **Security Updates**:
   - Monitor security advisories
   - Update component versions
   - Apply security patches
   - Vulnerability scanning

### Backup and Recovery

1. **Keycloak Backup**:
   - Database backups via PostgreSQL
   - Realm configuration exports
   - Client secret backups
   - User data exports

2. **Configuration Backup**:
   - GitOps repository backups
   - Secret backups (encrypted)
   - Policy configuration backups
   - Monitoring configuration backups

This completes the comprehensive Keycloak OIDC authentication and RBAC management system for the openCenter GitOps platform.