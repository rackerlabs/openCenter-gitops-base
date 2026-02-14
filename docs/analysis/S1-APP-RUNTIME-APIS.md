# S1: App Runtime & APIs Evidence Pack

## Scope Summary

Analyzed application runtime patterns, API surfaces, and service interfaces in openCenter-gitops-base. This repository contains **infrastructure manifests only** - no application code. Analysis focuses on:
- Service deployment patterns via HelmRelease
- API exposure patterns (Ingress, Gateway API)
- Service-to-service communication
- Runtime configuration surfaces

## Evidence Index

**Primary Sources:**
1. `llms.txt` - HelmRelease patterns (lines 95-125)
2. `applications/base/services/cert-manager/helmrelease.yaml`
3. `applications/base/services/gateway-api/` - Gateway API resources
4. `applications/base/services/keycloak/` - Multi-component service
5. `docs/cert-manager-config-guide.md` - Certificate ingress
6. `docs/service-standards-and-lifecycle.md` - Service standards
7. `README.md` - Service catalog

## Repo-Derived Facts

### No Application Code
**Evidence:** Repository structure shows only Kubernetes manifests
- **Citation:** `applications/base/services/` contains only YAML manifests
- **Fact:** This is a GitOps infrastructure repository, not an application codebase
- **Impact:** No runtime code to analyze; focus on declarative configs

### HelmRelease as Primary Deployment Pattern
**Evidence:** All services use Flux HelmRelease CRDs
- **Citation:** `llms.txt` lines 95-125, `applications/base/services/cert-manager/helmrelease.yaml`
- **Pattern:**
  ```yaml
  apiVersion: helm.toolkit.fluxcd.io/v2
  kind: HelmRelease
  spec:
    interval: 5m
    timeout: 10m
    driftDetection:
      mode: enabled
  ```
- **Fact:** 22+ services follow this pattern
- **Configuration:** Values from Kubernetes Secrets via `valuesFrom`

### Three-Tier Values Hierarchy
**Evidence:** HelmRelease valuesFrom configuration

- **Citation:** `applications/base/services/cert-manager/helmrelease.yaml` lines 28-36
- **Hierarchy:**
  1. Base values (required): `cert-manager-values-base`
  2. Override values (optional): `cert-manager-values-override`
  3. Enterprise values (optional): `cert-manager-values-enterprise`
- **Fact:** Enables environment-specific customization without base modification

### Service Catalog
**Evidence:** 22 core services + 4 observability components
- **Citation:** `README.md` lines 18-60
- **Core Services:**
  - cert-manager, harbor, keycloak, kyverno
  - longhorn, metallb, velero
  - vsphere-csi, openstack-csi, openstack-ccm
  - gateway-api, istio, headlamp, weave-gitops
  - olm, postgres-operator, rbac-manager
  - sealed-secrets, external-snapshotter, strimzi-kafka-operator
- **Observability:** kube-prometheus-stack, loki, tempo, opentelemetry-kube-stack

### API Exposure Patterns
**Evidence:** Multiple ingress/gateway options
- **Citation:** `docs/cert-manager-config-guide.md` lines 280-301
- **Patterns:**
  1. **Ingress with cert-manager:** Automatic TLS via annotations
  2. **Gateway API:** Next-gen ingress (`applications/base/services/gateway-api/`)
  3. **Istio:** Service mesh for advanced routing
- **Fact:** Services can choose ingress method based on requirements

### Multi-Component Services
**Evidence:** Keycloak has 4 sub-components
- **Citation:** `applications/base/services/keycloak/` directory structure
- **Components:**
  - `00-postgres/` - Database
  - `10-operator/` - Keycloak operator
  - `20-keycloak/` - Keycloak instance
  - `30-oidc-rbac/` - RBAC definitions
- **Pattern:** Ordered deployment via naming convention

## Risks & Findings

### MEDIUM: No API Gateway Rate Limiting Evidence
- **Severity:** Medium
- **Impact:** Services may be vulnerable to abuse without rate limits
- **Evidence:** No rate limiting configuration found in gateway-api or istio
- **Root Cause:** Gateway API rate limiting may be configured elsewhere
- **Recommendation:** Document rate limiting strategy or implement
- **Effort:** 2-4 hours (documentation) or 1-2 days (implementation)
- **Risk:** API abuse, resource exhaustion

### LOW: No Service Mesh Observability Config
- **Severity:** Low
- **Impact:** Missing distributed tracing from service mesh
- **Evidence:** Istio present but no telemetry config found
- **Recommendation:** Configure Istio + OTel integration
- **Effort:** 4-8 hours


## Doc Inputs (Diátaxis-Aware)

### Tutorial Topics
- "Deploy Your First Service with HelmRelease"
- "Expose a Service via Gateway API with TLS"

### How-to Topics
- "Configure Multi-Tier Helm Values"
- "Enable Rate Limiting on Gateway API"
- "Add Custom Ingress Annotations"
- "Deploy Multi-Component Services"

### Reference Topics
- **HelmRelease Configuration Reference**
  - interval, timeout, driftDetection
  - install/upgrade remediation
  - valuesFrom hierarchy
- **Service Catalog Reference**
  - Service name, namespace, purpose, version
  - Dependencies, prerequisites
  - Configuration surfaces

### Explanation Topics
- "Why HelmRelease Instead of Helm CLI"
- "Three-Tier Values Architecture Rationale"
- "Gateway API vs Ingress vs Service Mesh"

## Unknowns + VERIFY Steps

1. **Gateway API Rate Limiting**
   - **Unknown:** Rate limiting configuration location
   - **VERIFY:** Check `applications/base/services/gateway-api/` for HTTPRoute policies
   - **Expected:** RateLimitPolicy or similar CRD

2. **Istio Telemetry Integration**
   - **Unknown:** Istio + OpenTelemetry wiring
   - **VERIFY:** Check `applications/base/services/istio/` for telemetry config
   - **Expected:** Telemetry API resources

3. **Service Health Checks**
   - **Unknown:** Liveness/readiness probe standards
   - **VERIFY:** Sample Helm values files for probe configuration
   - **Expected:** Standardized probe settings

4. **API Versioning Strategy**
   - **Unknown:** How services handle API version upgrades
   - **VERIFY:** Check upgrade documentation
   - **Expected:** Blue/green or canary patterns

## Cross-Cutting Alerts

- **Security:** No mTLS configuration found for service-to-service (check Istio)
- **Observability:** Service-level SLOs not defined (check Prometheus rules)
- **Operations:** No chaos engineering or fault injection evidence
