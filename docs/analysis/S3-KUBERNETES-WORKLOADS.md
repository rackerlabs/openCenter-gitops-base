# S3: Kubernetes Workloads & Manifests Evidence Pack

## Scope Summary

Analyzed Kubernetes workload patterns, resource definitions, scheduling, security contexts, and operational standards. Focus on:
- Workload types and patterns
- Pod security standards
- Resource management
- Scheduling and placement
- Health checks and lifecycle
- Multi-tenancy and isolation

## Evidence Index

**Primary Sources:**
1. `docs/service-standards-and-lifecycle.md` - Comprehensive standards (600+ lines)
2. `applications/base/services/*/helmrelease.yaml` - 22+ HelmRelease CRDs
3. `applications/base/services/*/namespace.yaml` - Namespace definitions
4. `llms.txt` - Deployment patterns
5. `README.md` - Service catalog

## Repo-Derived Facts

### Workload Deployment Pattern
**Evidence:** All workloads deployed via Flux HelmRelease
- **Citation:** `docs/service-standards-and-lifecycle.md` lines 95-125
- **Pattern:** HelmRelease → Helm Chart → Deployment/StatefulSet/DaemonSet
- **Fact:** No raw Deployment manifests; all via Helm for consistency

### 22 Platform Services Catalog
**Evidence:** Complete service inventory
- **Citation:** `README.md` lines 18-60
- **Services by Category:**
  - **Security:** cert-manager, keycloak, kyverno, sealed-secrets
  - **Storage:** longhorn, vsphere-csi, openstack-csi, external-snapshotter
  - **Networking:** metallb, gateway-api, istio
  - **Operations:** velero, headlamp, weave-gitops, rbac-manager
  - **Data:** postgres-operator, strimzi-kafka-operator
  - **Platform:** olm, openstack-ccm
- **Observability:** kube-prometheus-stack, loki, tempo, opentelemetry

### Node Scheduling Strategy
**Evidence:** Taint-based workload isolation
- **Citation:** `docs/service-standards-and-lifecycle.md` lines 175-220
- **Taints:**
  - `workload=system:NoSchedule` - Platform services
  - `workload=app:NoSchedule` - Tenant apps
  - `class=gpu:NoSchedule` - GPU workloads
  - `class=spot:NoSchedule` - Spot instances
  - `class=storage:NoSchedule` - Storage nodes
- **Policy:** Platform services MUST tolerate system taint
- **Example:**
  ```yaml
  tolerations:
    - key: workload
      operator: Equal
      value: system
      effect: NoSchedule
  nodeSelector:
    workload: system
  ```


### Required Label Policy
**Evidence:** Comprehensive labeling standard
- **Citation:** `docs/service-standards-and-lifecycle.md` lines 222-280
- **Kubernetes-recommended labels:**
  - `app.kubernetes.io/name`
  - `app.kubernetes.io/instance`
  - `app.kubernetes.io/version`
  - `app.kubernetes.io/component`
  - `app.kubernetes.io/part-of`
  - `app.kubernetes.io/managed-by` (must be `fluxcd`)
- **openCenter-specific labels:**
  - `opencenter.io/owner` - Team/email
  - `opencenter.io/tier` - platform|shared|tenant
  - `opencenter.io/data-sensitivity` - public|internal|confidential|restricted
  - `opencenter.io/rto` - Recovery Time Objective (e.g., `4h`)
  - `opencenter.io/rpo` - Recovery Point Objective (e.g., `1h`)
  - `opencenter.io/sla` - Service Level Agreement (e.g., `99.9`)
  - `opencenter.io/backup-profile` - none|daily|hourly
- **Enforcement:** Kyverno/Gatekeeper policies (documented but not found in repo)

### Pod Security Standards
**Evidence:** Strict security requirements
- **Citation:** `docs/service-standards-and-lifecycle.md` lines 48-52
- **Requirements:**
  - PSS `restricted` or justified exceptions
  - Rootless where possible
  - Read-only filesystem
  - Drop all capabilities
  - No privilege escalation
- **Example:**
  ```yaml
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containerSecurityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop: [ALL]
    readOnlyRootFilesystem: true
  ```
- **Citation:** `llms.txt` lines 348-366

### Network Policy Requirement
**Evidence:** Default-deny with least privilege
- **Citation:** `docs/service-standards-and-lifecycle.md` line 53
- **Policy:** Default-deny egress/ingress with explicit allow rules
- **Status:** Documented but policies directory has placeholders only
- **Location:** `applications/policies/network-policies/placeholder.txt`

### Multi-Tenancy Model
**Evidence:** Namespace-based isolation
- **Citation:** `docs/service-standards-and-lifecycle.md` lines 40-41
- **Pattern:** Each service in dedicated namespace
- **Isolation:** RBAC, resource quotas, network policies
- **Fact:** 22+ namespaces for platform services

### Health Check Requirements
**Evidence:** Mandatory probes
- **Citation:** `docs/service-standards-and-lifecycle.md` line 39
- **Required:** Health endpoints, readiness, liveness
- **Documented:** Ports and protocols must be documented
- **Fact:** Enforced via Helm chart defaults

### Resource Management
**Evidence:** No explicit resource limits found
- **Citation:** Absence in sampled manifests
- **Gap:** No resource requests/limits in base HelmRelease
- **Assumption:** Configured in Helm values files (not examined)

### Backup/DR Labels
**Evidence:** RTO/RPO labeling for backup automation
- **Citation:** `docs/service-standards-and-lifecycle.md` lines 265-270
- **Labels:**
  - `opencenter.io/rto: 4h`
  - `opencenter.io/rpo: 1h`
  - `opencenter.io/backup-profile: daily`
- **Purpose:** Velero backup automation based on labels

## Risks & Findings

### CRITICAL: Network Policies Not Implemented
- **Severity:** Critical
- **Impact:** No network segmentation; lateral movement possible
- **Evidence:** `applications/policies/network-policies/placeholder.txt`
- **Root Cause:** Policies documented but not implemented
- **Recommendation:** Implement default-deny network policies per namespace
- **Effort:** 1-2 weeks for all 22 services
- **Risk:** Compliance failure, security breach

### HIGH: Pod Security Policies Not Enforced
- **Severity:** High
- **Impact:** Workloads may run with excessive privileges
- **Evidence:** `applications/policies/pod-security-policies/placeholder.txt`
- **Root Cause:** PSS enforcement not configured
- **Recommendation:** Enable Pod Security Admission with restricted baseline
- **Effort:** 1 week (testing + rollout)
- **Risk:** Container escape, privilege escalation

### HIGH: No Resource Limits Visible
- **Severity:** High
- **Impact:** Resource exhaustion, noisy neighbor issues
- **Evidence:** No limits in base HelmRelease manifests
- **Root Cause:** May be in Helm values (not examined)
- **Recommendation:** Verify resource limits in all services
- **Effort:** 2-3 days (audit + remediation)
- **Risk:** Cluster instability, OOM kills

### MEDIUM: Label Enforcement Not Active
- **Severity:** Medium
- **Impact:** Inconsistent labeling, backup/monitoring gaps
- **Evidence:** Kyverno policies documented but not found in repo
- **Recommendation:** Implement Kyverno ClusterPolicy for required labels
- **Effort:** 1-2 days
- **Risk:** Operational blind spots

### MEDIUM: No PodDisruptionBudgets Found
- **Severity:** Medium
- **Impact:** Uncontrolled disruption during node maintenance
- **Evidence:** No PDB manifests in service directories
- **Recommendation:** Add PDBs for all stateful services
- **Effort:** 1 week
- **Risk:** Service outages during upgrades

### LOW: No HorizontalPodAutoscalers
- **Severity:** Low
- **Impact:** Manual scaling required
- **Evidence:** No HPA manifests found
- **Recommendation:** Add HPAs for scalable services
- **Effort:** 1-2 weeks
- **Risk:** Performance degradation under load

## Doc Inputs (Diátaxis-Aware)

### Tutorial Topics
- "Deploy Your First Workload with Required Labels"
- "Configure Pod Security for a New Service"
- "Set Up Network Policies for Service Isolation"

### How-to Topics
- "Add Resource Limits to Existing Services"
- "Configure Node Affinity and Tolerations"
- "Create PodDisruptionBudgets for High Availability"
- "Implement HorizontalPodAutoscaler"
- "Troubleshoot Pod Scheduling Issues"
- "Audit Workload Security Posture"

### Reference Topics
- **Kubernetes Resources Reference**
  - HelmRelease spec fields
  - Required labels and their meanings
  - Toleration and nodeSelector patterns
  - Security context requirements
- **Service Catalog Reference**
  - Service name, namespace, workload type
  - Resource requirements
  - Dependencies
  - Health check endpoints
- **Scheduling Reference**
  - Node taints and their purposes
  - Toleration patterns by workload type
  - Affinity rules and use cases

### Explanation Topics
- "Workload Isolation Strategy"
- "Why Taint-Based Scheduling"
- "Label-Driven Operations (Backup, Monitoring)"
- "Pod Security Standards Rationale"

## Unknowns + VERIFY Steps

1. **Resource Limits Configuration**
   - **Unknown:** Are limits set in Helm values?
   - **VERIFY:** Sample `helm-values/*.yaml` files
   - **Expected:** CPU/memory requests and limits

2. **PodDisruptionBudgets**
   - **Unknown:** Are PDBs in Helm charts?
   - **VERIFY:** Check upstream chart defaults
   - **Expected:** PDBs for stateful services

3. **HorizontalPodAutoscalers**
   - **Unknown:** HPA configuration location
   - **VERIFY:** Check Helm values for autoscaling
   - **Expected:** HPA enabled for scalable services

4. **Network Policy Implementation**
   - **Unknown:** Are policies in Helm charts?
   - **VERIFY:** Check chart templates
   - **Expected:** NetworkPolicy resources

5. **Pod Security Admission**
   - **Unknown:** PSA enforcement level
   - **VERIFY:** Check namespace labels for pod-security.kubernetes.io/*
   - **Expected:** `pod-security.kubernetes.io/enforce: restricted`

## Cross-Cutting Alerts

- **Security:** Critical gap in network segmentation
- **Reliability:** No PDBs may cause outages during maintenance
- **Performance:** Resource limits verification needed
- **Compliance:** Label enforcement required for audit trail
