# Keycloak Configuration Guide

## Overview
Keycloak is an open-source identity and access management solution that provides authentication, authorization, and single sign-on capabilities for applications and services.

## Key Configuration Choices

### Database Configuration
```yaml
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: keycloak
spec:
  instances: 2
  db:
    vendor: postgres
    host: postgres-cluster
    usernameSecret:
      name: keycloak-db-secret
      key: username
    passwordSecret:
      name: keycloak-db-secret
      key: password
```
**Why**: 
- External PostgreSQL provides better performance and scalability
- Multiple instances ensure high availability
- Separate database credentials improve security

### Hostname and TLS Configuration
```yaml
spec:
  hostname:
    hostname: auth.example.com
    strict: true
    strictBackchannel: true
  http:
    tlsSecret: keycloak-tls
```
**Why**: Proper hostname configuration ensures correct redirect URIs and prevents security issues

### Realm and Client Configuration
```yaml
apiVersion: k8s.keycloak.org/v2alpha1
kind: KeycloakRealmImport
metadata:
  name: opencenter-realm
spec:
  keycloakCRName: keycloak
  realm:
    realm: opencenter
    enabled: true
    clients:
    - clientId: headlamp
      enabled: true
      protocol: openid-connect
      publicClient: false
      redirectUris:
      - "https://headlamp.example.com/oidc-callback"
      webOrigins:
      - "https://headlamp.example.com"
```
**Why**: Realm imports provide declarative configuration management for clients and users

## Common Pitfalls

### Database Connection Issues
**Problem**: Keycloak fails to start due to database connectivity problems

**Solution**: Verify PostgreSQL is running, credentials are correct, and network policies allow connection

**Verification**:
```bash
# Check Keycloak pod logs
kubectl logs -n keycloak deployment/keycloak

# Test database connectivity
kubectl exec -n keycloak deployment/keycloak -- pg_isready -h postgres-cluster

# Verify database secret
kubectl get secret -n keycloak keycloak-db-secret -o yaml
```

### OIDC Client Configuration Errors
**Problem**: Applications fail to authenticate with "invalid redirect URI" errors

**Solution**: Ensure redirect URIs in client configuration exactly match the application's callback URLs

### Theme and Customization Issues
**Problem**: Custom themes not loading or displaying incorrectly

**Solution**: Verify theme files are properly mounted and CSS/JavaScript resources are accessible

```bash
# Check theme files in Keycloak pod
kubectl exec -n keycloak deployment/keycloak -- ls -la /opt/keycloak/themes/

# Verify theme configuration
kubectl logs -n keycloak deployment/keycloak | grep -i theme
```

## Required Secrets

### Database Credentials
Keycloak requires database credentials for PostgreSQL connection

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: keycloak-db-secret
  namespace: keycloak
type: Opaque
stringData:
  username: keycloak
  password: your-database-password
```

**Key Fields**:
- `username`: PostgreSQL username for Keycloak (required)
- `password`: PostgreSQL password for Keycloak user (required)

### Admin Credentials
Initial admin user credentials for Keycloak

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: keycloak-admin
  namespace: keycloak
type: Opaque
stringData:
  username: admin
  password: your-admin-password
```

**Key Fields**:
- `username`: Keycloak admin username (required)
- `password`: Keycloak admin password (required)

## Verification
```bash
# Check Keycloak pods are running
kubectl get pods -n keycloak

# Verify Keycloak custom resource status
kubectl get keycloak -n keycloak

# Check Keycloak service
kubectl get svc -n keycloak

# Test Keycloak admin console
curl -k https://auth.example.com/admin/
```

## Usage Examples

### Create OIDC Client for Application
```bash
# Access Keycloak admin console
# Navigate to Clients -> Create Client
# Configure client settings:
# - Client ID: myapp
# - Client Protocol: openid-connect
# - Access Type: confidential
# - Valid Redirect URIs: https://myapp.example.com/callback
```

### Configure User Federation
```yaml
apiVersion: k8s.keycloak.org/v2alpha1
kind: KeycloakRealmImport
metadata:
  name: ldap-federation
spec:
  keycloakCRName: keycloak
  realm:
    realm: opencenter
    components:
      org.keycloak.storage.UserStorageProvider:
      - name: "ldap"
        providerId: "ldap"
        config:
          connectionUrl: ["ldap://ldap.example.com:389"]
          usersDn: ["ou=users,dc=example,dc=com"]
          bindDn: ["cn=admin,dc=example,dc=com"]
          bindCredential: ["admin-password"]
```

Keycloak provides comprehensive identity management with support for multiple authentication protocols, user federation, and extensive customization options. Regular maintenance includes monitoring user sessions, updating security policies, and backing up realm configurations.