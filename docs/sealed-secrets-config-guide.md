# Sealed Secrets Configuration Guide

## Overview
Sealed Secrets provides a way to encrypt secrets into SealedSecret resources, which can be safely stored in Git repositories and automatically decrypted by the controller running in the cluster.

## Key Configuration Choices

### Controller Configuration
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sealed-secrets-controller
  namespace: kube-system
spec:
  template:
    spec:
      containers:
      - name: sealed-secrets-controller
        image: quay.io/bitnami/sealed-secrets-controller:latest
        command:
        - controller
        args:
        - --update-status
        - --key-renew-period=720h  # 30 days
        - --key-cutoff-time=2h
        env:
        - name: SEALED_SECRETS_UPDATE_STATUS
          value: "true"
```
**Why**: 
- Update status provides feedback on SealedSecret processing
- Key rotation ensures cryptographic freshness
- Cutoff time prevents replay attacks with old keys

### Key Management Configuration
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sealed-secrets-key
  namespace: kube-system
  labels:
    sealedsecrets.bitnami.com/sealed-secrets-key: active
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-cert>
  tls.key: <base64-encoded-private-key>
```
**Why**: Pre-created keys enable key backup and disaster recovery scenarios

### Scope Configuration
```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: mysecret
  namespace: myapp
spec:
  encryptedData:
    password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEQAx...
  template:
    metadata:
      name: mysecret
      namespace: myapp
    type: Opaque
```
**Why**: Template metadata ensures proper secret creation with correct namespace and type

## Common Pitfalls

### Key Loss and Recovery
**Problem**: Sealed secrets cannot be decrypted after controller restart or key loss

**Solution**: Implement proper key backup and recovery procedures

**Verification**:
```bash
# Backup current keys
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-keys.yaml

# Verify key is active
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key=active

# Check controller logs for key issues
kubectl logs -n kube-system -l name=sealed-secrets-controller
```

### Encryption Scope Issues
**Problem**: SealedSecrets encrypted for wrong scope cannot be decrypted in target namespace

**Solution**: Use correct kubeseal scope flags when encrypting secrets

### Certificate Fetch Failures
**Problem**: kubeseal cannot fetch public certificate from controller

**Solution**: Ensure controller is accessible and certificate endpoint is working

```bash
# Test certificate fetch
kubeseal --fetch-cert --controller-name=sealed-secrets-controller --controller-namespace=kube-system

# Verify controller service
kubectl get svc -n kube-system sealed-secrets-controller

# Check controller readiness
kubectl get pods -n kube-system -l name=sealed-secrets-controller
```

## Required Secrets

### TLS Certificate and Private Key
The controller automatically generates these, but they can be pre-created for backup purposes

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sealed-secrets-key
  namespace: kube-system
  labels:
    sealedsecrets.bitnami.com/sealed-secrets-key: active
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-certificate>
  tls.key: <base64-encoded-private-key>
```

**Key Fields**:
- `tls.crt`: Public certificate for encryption (automatically generated)
- `tls.key`: Private key for decryption (automatically generated)

### Backup Keys
For disaster recovery, old keys should be preserved

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sealed-secrets-key-backup
  namespace: kube-system
  labels:
    sealedsecrets.bitnami.com/sealed-secrets-key: ""
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-old-cert>
  tls.key: <base64-encoded-old-key>
```

**Key Fields**:
- `tls.crt`: Old public certificate (for reference)
- `tls.key`: Old private key (for decrypting old secrets)

## Verification
```bash
# Check controller status
kubectl get pods -n kube-system -l name=sealed-secrets-controller

# Verify service is accessible
kubectl get svc -n kube-system sealed-secrets-controller

# Test certificate fetch
kubeseal --fetch-cert > public.pem

# List sealed secrets
kubectl get sealedsecrets -A
```

## Usage Examples

### Create SealedSecret from Command Line
```bash
# Create secret and encrypt it
echo -n mypassword | kubectl create secret generic mysecret --dry-run=client --from-file=password=/dev/stdin -o yaml | kubeseal -o yaml > mysealedsecret.yaml

# Apply the sealed secret
kubectl apply -f mysealedsecret.yaml

# Verify secret was created
kubectl get secret mysecret
```

### Encrypt Existing Secret
```bash
# Get existing secret
kubectl get secret mysecret -o yaml > mysecret.yaml

# Remove managed fields and encrypt
cat mysecret.yaml | kubeseal -o yaml > mysealedsecret.yaml

# Apply sealed secret
kubectl apply -f mysealedsecret.yaml
```

### Namespace-scoped Encryption
```bash
# Encrypt for specific namespace
echo -n mypassword | kubectl create secret generic mysecret --dry-run=client --from-file=password=/dev/stdin -o yaml | kubeseal --scope namespace-wide -o yaml > mysealedsecret.yaml
```

### Cluster-wide Encryption
```bash
# Encrypt for any namespace
echo -n mypassword | kubectl create secret generic mysecret --dry-run=client --from-file=password=/dev/stdin -o yaml | kubeseal --scope cluster-wide -o yaml > mysealedsecret.yaml
```

### Key Rotation and Backup
```bash
# Backup current keys before rotation
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-backup-$(date +%Y%m%d).yaml

# Force key rotation (restart controller)
kubectl delete pod -n kube-system -l name=sealed-secrets-controller

# Verify new key is generated
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key=active
```

Sealed Secrets enables GitOps-friendly secret management by allowing encrypted secrets to be stored in version control. Implement proper key backup and rotation procedures to ensure long-term secret accessibility.