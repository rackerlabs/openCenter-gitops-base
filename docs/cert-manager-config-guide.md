# Cert-manager Configuration Guide

## Overview
Cert-manager automates the management and issuance of TLS certificates from various issuing sources. It ensures certificates are valid and up-to-date, and attempts to renew certificates at a configured time before expiry.

## Key Configuration Choices

### Certificate Issuers
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```
**Why**: 
- ClusterIssuer allows certificate issuance across all namespaces
- Let's Encrypt provides free, automated certificates
- HTTP01 challenge works with most ingress controllers

### DNS Challenge Configuration
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-dns
    solvers:
    - dns01:
        cloudflare:
          email: admin@example.com
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
```
**Why**: DNS01 challenges enable wildcard certificates and work behind firewalls

### Certificate Resource
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-tls
  namespace: default
spec:
  secretName: example-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - example.com
  - www.example.com
```
**Why**: Explicit certificate management provides fine-grained control over certificate lifecycle

## Common Pitfalls

### Certificate Stuck in Pending State
**Problem**: Certificate remains in pending state and is never issued

**Solution**: Check the CertificateRequest and Order resources for detailed error messages

**Verification**:
```bash
kubectl describe certificate <cert-name> -n <namespace>
kubectl get certificaterequest -n <namespace>
kubectl describe order <order-name> -n <namespace>
```

### HTTP01 Challenge Failures
**Problem**: ACME HTTP01 challenges fail due to ingress misconfiguration

**Solution**: Ensure ingress controller can route /.well-known/acme-challenge/ paths to cert-manager solver pods

### Rate Limiting Issues
**Problem**: Let's Encrypt rate limits prevent certificate issuance

**Solution**: Use staging environment for testing, implement proper retry logic

```bash
# Check rate limit status
kubectl logs -n cert-manager deployment/cert-manager | grep "rate limit"
```

## Required Secrets

### DNS Provider API Tokens
For DNS01 challenges, API tokens for your DNS provider are required

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token
  namespace: cert-manager
type: Opaque
stringData:
  api-token: your-cloudflare-api-token
```

**Key Fields**:
- `api-token`: Cloudflare API token with Zone:Read and DNS:Edit permissions (required)

### ACME Account Private Key
Automatically generated but can be pre-created for account portability

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: letsencrypt-prod
  namespace: cert-manager
type: Opaque
data:
  tls.key: <base64-encoded-private-key>
```

**Key Fields**:
- `tls.key`: ACME account private key (automatically generated if not provided)

## Verification
```bash
# Check cert-manager pods are running
kubectl get pods -n cert-manager

# Verify ClusterIssuer is ready
kubectl get clusterissuer

# Check certificate status
kubectl get certificates -A

# View certificate details
kubectl describe certificate <cert-name> -n <namespace>
```

## Usage Examples

### Automatic Certificate with Ingress Annotations
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - example.com
    secretName: example-tls
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
```

### Wildcard Certificate
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-example-com
spec:
  secretName: wildcard-example-com-tls
  issuerRef:
    name: letsencrypt-dns
    kind: ClusterIssuer
  dnsNames:
  - "*.example.com"
  - example.com
```

Certificate renewal is automatic and occurs when certificates are within 30 days of expiry. Monitor certificate expiry dates and renewal events through Prometheus metrics and Kubernetes events.