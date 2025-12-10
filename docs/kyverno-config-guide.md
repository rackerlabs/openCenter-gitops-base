# Kyverno Configuration Guide

## Overview
Kyverno is a Kubernetes-native policy engine that validates, mutates, and generates configurations using policies defined as Kubernetes resources.

## Key Configuration Choices

### Policy Validation Configuration
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: enforce
  background: true
  rules:
  - name: check-labels
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Required labels are missing"
      pattern:
        metadata:
          labels:
            app.kubernetes.io/name: "?*"
            app.kubernetes.io/version: "?*"
```
**Why**: 
- Validation policies enforce compliance and best practices
- Background scanning evaluates existing resources
- Pattern matching provides flexible validation rules

### Resource Mutation Configuration
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-security-context
spec:
  rules:
  - name: add-security-context
    match:
      any:
      - resources:
          kinds:
          - Pod
    mutate:
      patchStrategicMerge:
        spec:
          securityContext:
            runAsNonRoot: true
            runAsUser: 1000
```
**Why**: Mutation policies automatically apply security configurations and reduce manual configuration overhead

### Resource Generation Configuration
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: generate-network-policy
spec:
  rules:
  - name: generate-netpol
    match:
      any:
      - resources:
          kinds:
          - Namespace
    generate:
      kind: NetworkPolicy
      name: default-deny
      namespace: "{{request.object.metadata.name}}"
      data:
        spec:
          podSelector: {}
          policyTypes:
          - Ingress
          - Egress
```
**Why**: Generation policies automatically create supporting resources and ensure consistent configurations

## Common Pitfalls

### Policy Conflicts and Ordering
**Problem**: Multiple policies conflict or produce unexpected results due to execution order

**Solution**: Use policy priorities and careful rule design to avoid conflicts

**Verification**:
```bash
# Check policy reports for conflicts
kubectl get policyreport -A

# Review policy execution order
kubectl describe clusterpolicy <policy-name>

# Check admission controller logs
kubectl logs -n kyverno -l app.kubernetes.io/component=admission-controller
```

### Background Scanning Performance
**Problem**: Background scanning consumes excessive resources or causes performance issues

**Solution**: Tune background scanning settings and use resource filters to limit scope

### Webhook Failures
**Problem**: Admission webhook failures block resource creation

**Solution**: Configure failure policies and ensure webhook availability

```bash
# Check webhook configuration
kubectl get validatingadmissionpolicy

# Verify webhook endpoints
kubectl get endpoints -n kyverno

# Test webhook connectivity
kubectl logs -n kyverno -l app.kubernetes.io/component=admission-controller
```

## Required Secrets

### Webhook TLS Certificates
Kyverno automatically manages webhook certificates

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: kyverno-svc.kyverno.svc.kyverno-tls-pair
  namespace: kyverno
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-cert>
  tls.key: <base64-encoded-key>
```

**Key Fields**:
- `tls.crt`: TLS certificate for webhook server (automatically generated)
- `tls.key`: TLS private key for webhook server (automatically generated)

### Image Registry Credentials
For image verification policies, registry credentials may be required

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: registry-creds
  namespace: kyverno
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-docker-config>
```

**Key Fields**:
- `.dockerconfigjson`: Docker registry credentials (required for private registries)

## Verification
```bash
# Check Kyverno pods are running
kubectl get pods -n kyverno

# Verify cluster policies
kubectl get clusterpolicy

# Check policy reports
kubectl get policyreport -A

# View policy violations
kubectl describe policyreport <report-name> -n <namespace>
```

## Usage Examples

### Pod Security Standards Policy
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: pod-security-standards
spec:
  validationFailureAction: enforce
  rules:
  - name: check-security-context
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Containers must run as non-root"
      pattern:
        spec:
          securityContext:
            runAsNonRoot: true
          containers:
          - securityContext:
              allowPrivilegeEscalation: false
              capabilities:
                drop:
                - ALL
```

### Image Verification Policy
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-images
spec:
  validationFailureAction: enforce
  rules:
  - name: verify-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
    verifyImages:
    - imageReferences:
      - "registry.example.com/*"
      attestors:
      - entries:
        - keys:
            publicKeys: |-
              -----BEGIN PUBLIC KEY-----
              <public-key-content>
              -----END PUBLIC KEY-----
```

Kyverno provides powerful policy management capabilities for Kubernetes. Start with simple validation policies and gradually implement more complex mutation and generation rules as needed.