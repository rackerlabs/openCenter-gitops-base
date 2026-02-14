# S5: Envoy Gateway / Ingress / Traffic Policies Evidence Pack

## Scope Summary

Analyzed gateway, ingress, and traffic management patterns. Focus on:
- Gateway API implementation (Envoy Gateway)
- Istio service mesh configuration
- TLS/certificate management integration
- Traffic policies (routing, rate limiting, auth)
- Edge observability

## Evidence Index

**Primary Sources:**
1. `applications/base/services/gateway-api/README.md`
2. `applications/base/services/gateway-api/helmrelease.yaml`
3. `applications/base/services/istio/README.md`
4. `docs/cert-manager-config-guide.md`
5. `llms.txt` - Certificate ingress patterns (lines 280-301)

## Repo-Derived Facts

### Gateway API with Envoy Gateway
**Evidence:** Envoy Gateway implements Kubernetes Gateway API
- **Citation:** `applications/base/services/gateway-api/README.md`
- **Purpose:** North-south traffic routing
- **Features:**
  - Path-based routing
  - Header manipulation
  - Timeouts and retries
  - Rate limiting
  - TLS termination
- **Integration:** Cert-Manager for automatic TLS
- **Namespace:** `envoy-gateway-system`

### Envoy Gateway HelmRelease
**Evidence:** Standard Flux deployment pattern
- **Citation:** `applications/base/services/gateway-api/helmrelease.yaml`
- **Chart:** `gateway-helm` from envoyproxy repository
- **Version:** `v0.0.0-latest` (concerning - not pinned)
- **Reconciliation:** 5-minute interval
- **Values:** Base + enterprise + override tiers

### Istio Service Mesh
**Evidence:** Two-component deployment (base + istiod)
- **Citation:** `applications/base/services/istio/README.md`
- **Components:**
  - `base/` - CRDs and base resources
  - `istiod/` - Control plane
- **Features:**
  - Traffic management (routing, retries, timeouts, fault injection)
  - mTLS and zero-trust security
  - Telemetry, tracing, access logs
  - Ingress/egress gateways
  - Sidecar injection
- **Namespace:** `istio-system`

### TLS Certificate Automation
**Evidence:** Cert-Manager integration with ingress
- **Citation:** `docs/cert-manager-config-guide.md`
- **Pattern:** Ingress annotations trigger certificate issuance
  ```yaml
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  spec:
    tls:
    - hosts:
      - example.com
      secretName: example-tls
  ```
- **Issuers:** ClusterIssuer for cross-namespace certificates
- **Challenges:** HTTP01 and DNS01 supported
- **Renewal:** Automatic within 30 days of expiry

### Certificate Issuers
**Evidence:** Let's Encrypt integration
- **Citation:** `docs/cert-manager-config-guide.md` lines 8-22
- **Production:** `letsencrypt-prod` ClusterIssuer
- **Staging:** Implied for testing (avoid rate limits)
- **Challenges:**
  - HTTP01: Works with most ingress controllers
  - DNS01: Enables wildcard certificates
- **Providers:** Cloudflare DNS example provided

### Ingress Pattern
**Evidence:** Automatic certificate provisioning
- **Citation:** `llms.txt` lines 280-301
- **Annotation:** `cert-manager.io/cluster-issuer`
- **TLS Secret:** Auto-created by cert-manager
- **Fact:** No manual certificate management required

## Risks & Findings

### CRITICAL: Envoy Gateway Version Not Pinned
- **Severity:** Critical
- **Impact:** Unpredictable upgrades, potential breaking changes
- **Evidence:** `helmrelease.yaml` line 23: `version: v0.0.0-latest`
- **Root Cause:** Placeholder version not replaced
- **Recommendation:** Pin to specific stable version
- **Effort:** 1 hour
- **Risk:** Production outages from automatic upgrades

### HIGH: No Rate Limiting Configuration Found
- **Severity:** High
- **Impact:** Services vulnerable to abuse, DDoS
- **Evidence:** No RateLimitPolicy or similar CRDs found
- **Root Cause:** Rate limiting mentioned but not implemented
- **Recommendation:** Implement Gateway API RateLimitPolicy
- **Effort:** 1-2 days
- **Risk:** Service degradation, resource exhaustion

### HIGH: No mTLS Configuration Evidence
- **Severity:** High
- **Impact:** Service-to-service traffic not encrypted
- **Evidence:** Istio present but no PeerAuthentication CRDs found
- **Root Cause:** mTLS mentioned but not configured
- **Recommendation:** Enable strict mTLS for all namespaces
- **Effort:** 2-3 days (testing + rollout)
- **Risk:** Man-in-the-middle attacks, compliance failure

### MEDIUM: No Gateway API HTTPRoute Examples
- **Severity:** Medium
- **Impact:** Unclear how to expose services
- **Evidence:** No HTTPRoute manifests in gateway-api directory
- **Recommendation:** Add reference HTTPRoute examples
- **Effort:** 4 hours
- **Risk:** Inconsistent routing configurations

### MEDIUM: No Istio Telemetry Configuration
- **Severity:** Medium
- **Impact:** Missing service mesh observability
- **Evidence:** Istio present but no Telemetry CRDs found
- **Recommendation:** Configure Istio telemetry for OTel integration
- **Effort:** 1-2 days
- **Risk:** Blind spots in distributed tracing

### MEDIUM: Certificate Rate Limiting Risk
- **Severity:** Medium
- **Impact:** Let's Encrypt rate limits block certificate issuance
- **Evidence:** `docs/cert-manager-config-guide.md` mentions rate limits
- **Recommendation:** Use staging for testing, monitor rate limit metrics
- **Effort:** 4 hours (monitoring setup)
- **Risk:** Certificate provisioning failures

### LOW: No Egress Gateway Configuration
- **Severity:** Low
- **Impact:** Uncontrolled external traffic
- **Evidence:** Istio egress mentioned but not configured
- **Recommendation:** Configure egress gateway for external services
- **Effort:** 1-2 days
- **Risk:** Compliance issues, untracked external dependencies

### LOW: No Fault Injection Examples
- **Severity:** Low
- **Impact:** Difficult to test resilience
- **Evidence:** Istio fault injection mentioned but no examples
- **Recommendation:** Add fault injection examples for chaos testing
- **Effort:** 4 hours
- **Risk:** Untested failure scenarios

## Doc Inputs (Diátaxis-Aware)

### Tutorial Topics
- "Expose Your First Service via Gateway API"
- "Configure TLS with Cert-Manager and Ingress"
- "Enable mTLS Between Services with Istio"

### How-to Topics
- "Create HTTPRoute for Path-Based Routing"
- "Configure Rate Limiting on Gateway"
- "Set Up Wildcard Certificates with DNS01"
- "Enable Istio Sidecar Injection"
- "Configure Istio Egress Gateway"
- "Implement Fault Injection for Testing"
- "Troubleshoot Certificate Issuance Failures"
- "Monitor Gateway API Metrics"

### Reference Topics
- **Gateway API Resources Reference**
  - Gateway, HTTPRoute, ReferenceGrant
  - Filters (header, redirect, rewrite)
  - BackendRefs and weights
- **Istio Resources Reference**
  - VirtualService, DestinationRule
  - Gateway, ServiceEntry
  - PeerAuthentication, AuthorizationPolicy
  - Telemetry configuration
- **Cert-Manager Reference**
  - ClusterIssuer, Issuer, Certificate
  - Challenge types (HTTP01, DNS01)
  - DNS provider configurations
  - Certificate lifecycle

### Explanation Topics
- "Gateway API vs Ingress vs Istio Gateway"
- "Why Envoy Gateway for North-South Traffic"
- "mTLS and Zero-Trust Architecture"
- "Certificate Automation Benefits"
- "Service Mesh Observability Model"

## Unknowns + VERIFY Steps

1. **Gateway API Version**
   - **Unknown:** Which Gateway API version is deployed?
   - **VERIFY:** Check CRD versions in cluster
   - **Expected:** v1 or v1beta1

2. **Istio Version**
   - **Unknown:** Which Istio version is deployed?
   - **VERIFY:** Check `istio/base/helmrelease.yaml`
   - **Expected:** Pinned version (e.g., 1.20.x)

3. **mTLS Mode**
   - **Unknown:** Is mTLS enabled?
   - **VERIFY:** Check for PeerAuthentication resources
   - **Expected:** STRICT mode for platform services

4. **Rate Limiting Implementation**
   - **Unknown:** How is rate limiting configured?
   - **VERIFY:** Check for RateLimitPolicy or Envoy RateLimit config
   - **Expected:** Per-route or per-gateway limits

5. **Istio Telemetry Backend**
   - **Unknown:** Where does Istio send telemetry?
   - **VERIFY:** Check Telemetry CRDs for OTel collector endpoint
   - **Expected:** OpenTelemetry collector in observability namespace

6. **Gateway Observability**
   - **Unknown:** Are gateway metrics exposed?
   - **VERIFY:** Check for ServiceMonitor or PodMonitor
   - **Expected:** Prometheus scraping of gateway metrics

## Cross-Cutting Alerts

- **Security:** mTLS not configured - service-to-service encryption missing
- **Reliability:** Envoy Gateway version not pinned - upgrade risk
- **Performance:** No rate limiting - abuse vulnerability
- **Observability:** Istio telemetry not configured - tracing gaps
