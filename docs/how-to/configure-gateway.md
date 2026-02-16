---
doc_type: how-to
title: "Configure Gateway API Routing"
audience: "platform engineers"
---

# Configure Gateway API Routing

**Purpose:** For platform engineers, shows how to configure Gateway API routing for services, covering Gateway creation, HTTPRoute configuration, TLS termination, and cross-namespace references.

## Prerequisites

- Gateway API installed in cluster
- Envoy Gateway deployed
- cert-manager configured for TLS
- Service deployed and accessible via ClusterIP

## Steps

### 1. Verify Gateway API installation

```bash
# Check Gateway API CRDs
kubectl get crd | grep gateway.networking.k8s.io

# Expected CRDs:
# gateways.gateway.networking.k8s.io
# httproutes.gateway.networking.k8s.io
# referencegrants.gateway.networking.k8s.io

# Check Envoy Gateway
kubectl get pods -n envoy-gateway-system
```

### 2. Create Gateway

Create `applications/base/services/gateway-api/gateway.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: platform-gateway
  namespace: envoy-gateway-system
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  gatewayClassName: envoy
  
  listeners:
    # HTTP listener (redirects to HTTPS)
    - name: http
      protocol: HTTP
      port: 80
      hostname: "*.example.com"
      allowedRoutes:
        namespaces:
          from: All
    
    # HTTPS listener with TLS
    - name: https
      protocol: HTTPS
      port: 443
      hostname: "*.example.com"
      allowedRoutes:
        namespaces:
          from: All
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: platform-gateway-tls
            namespace: envoy-gateway-system
```

Apply:

```bash
kubectl apply -f applications/base/services/gateway-api/gateway.yaml
```

Verify:

```bash
kubectl get gateway platform-gateway -n envoy-gateway-system
kubectl describe gateway platform-gateway -n envoy-gateway-system
```

### 3. Create TLS certificate

Create `applications/base/services/gateway-api/certificate.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: platform-gateway-tls
  namespace: envoy-gateway-system
spec:
  secretName: platform-gateway-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - "*.example.com"
    - example.com
  # For wildcard certificates, use DNS01 challenge
  # For single domain, use HTTP01 challenge
```

Apply:

```bash
kubectl apply -f applications/base/services/gateway-api/certificate.yaml
```

Verify certificate issuance:

```bash
kubectl get certificate platform-gateway-tls -n envoy-gateway-system
kubectl describe certificate platform-gateway-tls -n envoy-gateway-system

# Check secret was created
kubectl get secret platform-gateway-tls -n envoy-gateway-system
```

### 4. Create HTTPRoute for service

Create `applications/overlays/k8s-sandbox/services/my-service/httproute.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-service
  namespace: my-service
spec:
  parentRefs:
    - name: platform-gateway
      namespace: envoy-gateway-system
      sectionName: https
  
  hostnames:
    - my-service.example.com
  
  rules:
    # Default route to service
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: my-service
          port: 8080
          weight: 100
```

Apply:

```bash
kubectl apply -f applications/overlays/k8s-sandbox/services/my-service/httproute.yaml
```

### 5. Create ReferenceGrant for cross-namespace access

When HTTPRoute in one namespace references Gateway in another, create ReferenceGrant:

Create `applications/base/services/gateway-api/referencegrant.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-httproutes-to-gateway
  namespace: envoy-gateway-system
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: my-service
  to:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: platform-gateway
```

For multiple namespaces, use wildcard:

```yaml
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: "*"  # Allow all namespaces
```

Apply:

```bash
kubectl apply -f applications/base/services/gateway-api/referencegrant.yaml
```

### 6. Verify routing

Check HTTPRoute status:

```bash
kubectl get httproute my-service -n my-service
kubectl describe httproute my-service -n my-service
```

Test endpoint:

```bash
# Get Gateway external IP
GATEWAY_IP=$(kubectl get gateway platform-gateway -n envoy-gateway-system -o jsonpath='{.status.addresses[0].value}')

# Test HTTP (should redirect to HTTPS)
curl -v http://my-service.example.com --resolve my-service.example.com:80:${GATEWAY_IP}

# Test HTTPS
curl -v https://my-service.example.com --resolve my-service.example.com:443:${GATEWAY_IP}
```

## Advanced Routing Patterns

### Path-based routing

Route different paths to different services:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api-routes
  namespace: my-service
spec:
  parentRefs:
    - name: platform-gateway
      namespace: envoy-gateway-system
  
  hostnames:
    - api.example.com
  
  rules:
    # Route /v1/* to v1 service
    - matches:
        - path:
            type: PathPrefix
            value: /v1
      backendRefs:
        - name: my-service-v1
          port: 8080
    
    # Route /v2/* to v2 service
    - matches:
        - path:
            type: PathPrefix
            value: /v2
      backendRefs:
        - name: my-service-v2
          port: 8080
    
    # Default route
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: my-service-v1
          port: 8080
```

### Header-based routing

Route based on HTTP headers:

```yaml
rules:
  # Route requests with specific header to canary
  - matches:
      - headers:
          - name: X-Canary
            value: "true"
    backendRefs:
      - name: my-service-canary
        port: 8080
  
  # Default route
  - backendRefs:
      - name: my-service-stable
        port: 8080
```

### Weighted traffic splitting

Canary deployment with traffic split:

```yaml
rules:
  - backendRefs:
      # 90% to stable
      - name: my-service-stable
        port: 8080
        weight: 90
      # 10% to canary
      - name: my-service-canary
        port: 8080
        weight: 10
```

### Request header manipulation

Add or modify headers:

```yaml
rules:
  - matches:
      - path:
          type: PathPrefix
          value: /
    filters:
      # Add request header
      - type: RequestHeaderModifier
        requestHeaderModifier:
          add:
            - name: X-Custom-Header
              value: "custom-value"
          set:
            - name: X-Forwarded-Proto
              value: "https"
          remove:
            - X-Internal-Header
    backendRefs:
      - name: my-service
        port: 8080
```

### URL rewriting

Rewrite request path:

```yaml
rules:
  - matches:
      - path:
          type: PathPrefix
          value: /api/v1
    filters:
      - type: URLRewrite
        urlRewrite:
          path:
            type: ReplacePrefixMatch
            replacePrefixMatch: /v1
    backendRefs:
      - name: my-service
        port: 8080
```

Request to `/api/v1/users` becomes `/v1/users` at backend.

### Redirects

HTTP to HTTPS redirect:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-redirect
  namespace: my-service
spec:
  parentRefs:
    - name: platform-gateway
      namespace: envoy-gateway-system
      sectionName: http
  
  hostnames:
    - my-service.example.com
  
  rules:
    - filters:
        - type: RequestRedirect
          requestRedirect:
            scheme: https
            statusCode: 301
```

### Timeouts and retries

Configure request timeouts:

```yaml
rules:
  - matches:
      - path:
          type: PathPrefix
          value: /
    timeouts:
      request: 30s
      backendRequest: 25s
    backendRefs:
      - name: my-service
        port: 8080
```

## Troubleshooting

### HTTPRoute not working

Check HTTPRoute status:

```bash
kubectl describe httproute my-service -n my-service
```

Look for conditions:
- `Accepted: True` - Route accepted by Gateway
- `ResolvedRefs: True` - Backend references resolved

### "Backend not found" error

Verify service exists:

```bash
kubectl get service my-service -n my-service
```

Check service port matches HTTPRoute:

```bash
kubectl get service my-service -n my-service -o jsonpath='{.spec.ports[0].port}'
```

### Cross-namespace reference denied

Check ReferenceGrant exists:

```bash
kubectl get referencegrant -n envoy-gateway-system
kubectl describe referencegrant allow-httproutes-to-gateway -n envoy-gateway-system
```

Verify namespace matches:

```bash
kubectl get httproute my-service -n my-service -o jsonpath='{.spec.parentRefs[0].namespace}'
```

### TLS certificate not ready

Check certificate status:

```bash
kubectl get certificate platform-gateway-tls -n envoy-gateway-system
kubectl describe certificate platform-gateway-tls -n envoy-gateway-system
```

Check cert-manager logs:

```bash
kubectl logs -n cert-manager -l app=cert-manager
```

### Gateway not getting external IP

Check Gateway status:

```bash
kubectl describe gateway platform-gateway -n envoy-gateway-system
```

Check LoadBalancer service:

```bash
kubectl get service -n envoy-gateway-system
```

For MetalLB, verify IP pool:

```bash
kubectl get ipaddresspool -n metallb-system
```

## Verification

Complete verification checklist:

```bash
# 1. Gateway is ready
kubectl get gateway platform-gateway -n envoy-gateway-system -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}'
# Expected: True

# 2. Certificate is ready
kubectl get certificate platform-gateway-tls -n envoy-gateway-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
# Expected: True

# 3. HTTPRoute is accepted
kubectl get httproute my-service -n my-service -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}'
# Expected: True

# 4. Service is accessible
curl -k https://my-service.example.com/health
# Expected: 200 OK
```

## Next Steps

- Configure rate limiting on Gateway
- Set up observability for Gateway metrics (see [setup-observability.md](setup-observability.md))
- Implement mTLS with Istio for service-to-service communication
- Add WAF policies for security

## Evidence

**Sources:**
- `applications/base/services/gateway-api/README.md` - Gateway API overview
- `applications/base/services/gateway-api/helmrelease.yaml` - Envoy Gateway deployment
- `docs/cert-manager-config-guide.md` - TLS certificate automation
- S5-ENVOY-GATEWAY-TRAFFIC.md - Gateway API implementation
- S1-APP-RUNTIME-APIS.md - API exposure patterns
