# Harbor Configuration Guide

## Overview
Harbor is an open-source container registry that secures artifacts with policies and role-based access control, ensures images are scanned and free from vulnerabilities, and signs images as trusted.

## Key Configuration Choices

### Database Configuration
```yaml
database:
  type: external
  external:
    host: postgres-cluster
    port: 5432
    username: harbor
    password: <password>
    coreDatabase: registry
    notaryServerDatabase: notaryserver
    notarySignerDatabase: notarysigner
```
**Why**: 
- External database provides better scalability and backup options
- Separate databases for different components improve isolation
- PostgreSQL offers better performance than internal database

### Storage Backend Configuration
```yaml
persistence:
  enabled: true
  resourcePolicy: "keep"
  persistentVolumeClaim:
    registry:
      storageClass: "longhorn"
      size: 100Gi
    chartmuseum:
      storageClass: "longhorn"
      size: 10Gi
```
**Why**: Persistent storage ensures registry data survives pod restarts and provides reliable artifact storage

### Ingress and TLS Configuration
```yaml
expose:
  type: ingress
  tls:
    enabled: true
    certSource: secret
    secret:
      secretName: harbor-tls
  ingress:
    hosts:
      core: harbor.example.com
    className: nginx
    annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
```
**Why**: Ingress provides external access with proper TLS termination and large file upload support

## Common Pitfalls

### Image Push/Pull Failures
**Problem**: Docker push/pull operations fail with authentication or network errors

**Solution**: Verify Harbor is accessible, credentials are correct, and proxy settings allow large uploads

**Verification**:
```bash
# Test Harbor connectivity
curl -k https://harbor.example.com/api/v2.0/systeminfo

# Test Docker login
docker login harbor.example.com

# Check Harbor core logs
kubectl logs -n harbor deployment/harbor-core
```

### Storage Space Issues
**Problem**: Registry runs out of storage space causing push failures

**Solution**: Monitor storage usage, implement garbage collection policies, and expand storage as needed

### Vulnerability Scanning Not Working
**Problem**: Trivy scanner fails to update vulnerability database or scan images

**Solution**: Ensure internet connectivity for vulnerability database updates and check scanner configuration

```bash
# Check Trivy scanner logs
kubectl logs -n harbor deployment/harbor-trivy

# Manually trigger vulnerability database update
kubectl exec -n harbor deployment/harbor-trivy -- trivy image --download-db-only
```

## Required Secrets

### Database Credentials
Harbor requires database credentials for PostgreSQL connection

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: harbor-database
  namespace: harbor
type: Opaque
stringData:
  password: your-database-password
```

**Key Fields**:
- `password`: PostgreSQL password for Harbor database user (required)

### Harbor Admin Credentials
Initial admin user credentials for Harbor

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: harbor-admin
  namespace: harbor
type: Opaque
stringData:
  password: your-admin-password
```

**Key Fields**:
- `password`: Harbor admin user password (required)

## Verification
```bash
# Check Harbor pods are running
kubectl get pods -n harbor

# Verify Harbor services
kubectl get svc -n harbor

# Check Harbor ingress
kubectl get ingress -n harbor

# Test Harbor API
curl -k https://harbor.example.com/api/v2.0/systeminfo
```

## Usage Examples

### Push Image to Harbor
```bash
# Tag image for Harbor
docker tag myapp:latest harbor.example.com/library/myapp:latest

# Login to Harbor
docker login harbor.example.com

# Push image
docker push harbor.example.com/library/myapp:latest
```

### Create Harbor Project via API
```bash
# Create new project
curl -X POST "https://harbor.example.com/api/v2.0/projects" \
  -H "Content-Type: application/json" \
  -u "admin:password" \
  -d '{
    "project_name": "myproject",
    "public": false,
    "storage_limit": -1
  }'
```

Harbor provides comprehensive container registry capabilities with security scanning, content trust, and role-based access control. Regular maintenance includes garbage collection, vulnerability database updates, and monitoring storage usage.