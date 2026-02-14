# S7: Security & Governance Evidence Pack

## Scope Summary

Analyzed security controls, governance policies, secret management, RBAC, and supply chain security. Focus on:
- Secret management (SOPS, Sealed Secrets)
- Policy enforcement (Kyverno)
- RBAC and authentication (Keycloak, rbac-manager)
- Pod security standards
- Network policies
- Supply chain security
- Audit and compliance

## Evidence Index

**Primary Sources:**
1. `applications/base/services/kyverno/policy-engine/README.md`
2. `applications/base/services/sealed-secrets/README.md`
3. `applications/base/services/keycloak/` - IAM service
4. `docs/kyverno-config-guide.md`
5. `docs/service-standards-and-lifecycle.md` - Security requirements (lines 48-55)
6. `llms.txt` - SOPS workflow (lines 209-262)
7. `applications/policies/` - Policy directories

## Repo-Derived Facts

### Dual Secret Management Strategy
**Evidence:** SOPS and Sealed Secrets both present
- **Citation:** `llms.txt` lines 209-262, `sealed-secrets/README.md`
- **SOPS:**
  - Age encryption with keys in Kubernetes secrets
  - Flux decryption during reconciliation
  - Encrypted secrets in Git
- **Sealed Secrets:**
  - Controller-based decryption
  - GitOps-friendly encrypted secrets
  - Namespace or cluster-wide keys
- **Fact:** Two secret management solutions available

### Kyverno Policy Engine
**Evidence:** Kubernetes-native policy enforcement
- **Citation:** `kyverno/policy-engine/README.md`
- **Capabilities:**
  - Validation policies (enforce compliance)
  - Mutation policies (auto-configure resources)
  - Generation policies (create supporting resources)
  - Admission webhooks (real-time evaluation)
  - Policy reports (violation tracking)
- **Integration:** Prometheus, Grafana monitoring
- **Namespace:** `kyverno`

### Keycloak IAM
**Evidence:** Identity and access management
- **Citation:** `applications/base/services/keycloak/` structure
- **Components:**
  - Postgres database
  - Keycloak operator
  - Keycloak instance
  - OIDC RBAC definitions
- **Purpose:** Authentication and authorization
- **Namespace:** `keycloak`

### RBAC Manager
**Evidence:** Automated RBAC management
- **Citation:** `applications/base/services/rbac-manager/`
- **Purpose:** Simplify RBAC configuration
- **Namespace:** `rbac-manager`

### Security Requirements
**Evidence:** Comprehensive security standards
- **Citation:** `docs/service-standards-and-lifecycle.md` lines 48-55
- **Required:**
  - SBOM and image scanning
  - CVE budget defined
  - Image signature verification (Cosign)
  - PSS restricted or justified exceptions
  - Rootless containers
  - Read-only filesystem
  - Drop all capabilities
  - Network policies (default-deny)
  - SOPS or external secret store
  - No plaintext secrets in Git
  - Audit logs preserved
  - Compliance mapping (ISO 27001, SOC 2, NIST 800-53)

### SOPS Workflow
**Evidence:** Age-based encryption
- **Citation:** `llms.txt` lines 209-262
- **Steps:**
  1. Generate age keypair
  2. Configure `.sops.yaml` with public key
  3. Encrypt files: `sops -e -i secret.yaml`
  4. Create K8s secret with age key
  5. Configure Flux decryption
- **Fact:** Secrets encrypted at rest in Git

### Policy Directories
**Evidence:** Policy structure exists but empty
- **Citation:** `applications/policies/` directory
- **Subdirectories:**
  - `network-policies/` - placeholder.txt
  - `pod-security-policies/` - placeholder.txt
  - `rbac/` - placeholder.txt
- **Fact:** Policy framework exists but not implemented

## Risks & Findings

### CRITICAL: No Network Policies Implemented
- **Severity:** Critical
- **Impact:** No network segmentation, lateral movement possible
- **Evidence:** `applications/policies/network-policies/placeholder.txt`
- **Root Cause:** Documented requirement but not implemented
- **Recommendation:** Implement default-deny network policies
- **Effort:** 2-3 weeks (all namespaces)
- **Risk:** Compliance failure, security breach, lateral movement

### CRITICAL: No Pod Security Admission
- **Severity:** Critical
- **Impact:** Containers may run with excessive privileges
- **Evidence:** `applications/policies/pod-security-policies/placeholder.txt`
- **Root Cause:** PSS enforcement not configured
- **Recommendation:** Enable Pod Security Admission with restricted baseline
- **Effort:** 1-2 weeks (testing + rollout)
- **Risk:** Container escape, privilege escalation

### CRITICAL: No Kyverno Policies Found
- **Severity:** Critical
- **Impact:** No automated policy enforcement
- **Evidence:** Kyverno installed but no ClusterPolicy resources found
- **Root Cause:** Policy engine present but policies not deployed
- **Recommendation:** Implement validation, mutation, generation policies
- **Effort:** 2-3 weeks
- **Risk:** Non-compliant deployments, security gaps

### HIGH: No Image Scanning Evidence
- **Severity:** High
- **Impact:** Vulnerable images may be deployed
- **Evidence:** Image scanning mentioned but no scanner found
- **Root Cause:** Trivy or similar not integrated
- **Recommendation:** Integrate image scanning in CI/CD
- **Effort:** 1 week
- **Risk:** CVE exploitation, compliance failure

### HIGH: No Image Signature Verification
- **Severity:** High
- **Impact:** Unsigned images may be deployed
- **Evidence:** Cosign mentioned but no verification policies
- **Recommendation:** Implement Kyverno image verification policies
- **Effort:** 1-2 weeks
- **Risk:** Supply chain attacks, malicious images

### HIGH: No RBAC Policies Found
- **Severity:** High
- **Impact:** Unclear access controls
- **Evidence:** `applications/policies/rbac/placeholder.txt`
- **Recommendation:** Define and implement RBAC policies
- **Effort:** 1-2 weeks
- **Risk:** Unauthorized access, privilege escalation

### MEDIUM: Dual Secret Management Complexity
- **Severity:** Medium
- **Impact:** Confusion about which system to use
- **Evidence:** Both SOPS and Sealed Secrets present
- **Recommendation:** Document when to use each system
- **Effort:** 4 hours (documentation)
- **Risk:** Inconsistent secret management

### MEDIUM: No Audit Logging Configuration
- **Severity:** Medium
- **Impact:** Difficult to investigate security incidents
- **Evidence:** Audit logs mentioned but no config found
- **Recommendation:** Configure Kubernetes audit logging
- **Effort:** 1-2 days
- **Risk:** Compliance failure, forensics gaps

### MEDIUM: No Compliance Mapping
- **Severity:** Medium
- **Impact:** Unclear compliance posture
- **Evidence:** Compliance mapping required but not found
- **Recommendation:** Map controls to ISO 27001, SOC 2, NIST 800-53
- **Effort:** 2-3 weeks
- **Risk:** Audit failures, certification delays

### LOW: No SBOM Generation
- **Severity:** Low
- **Impact:** Unclear software composition
- **Evidence:** SBOM mentioned but not generated
- **Recommendation:** Generate SBOMs for all images
- **Effort:** 1 week (CI/CD integration)
- **Risk:** Supply chain visibility gaps

## Doc Inputs (Diátaxis-Aware)

### Tutorial Topics
- "Encrypt Your First Secret with SOPS"
- "Create Your First Kyverno Policy"
- "Set Up OIDC Authentication with Keycloak"

### How-to Topics
- "Encrypt Secrets with SOPS and Age"
- "Create Sealed Secrets for GitOps"
- "Implement Network Policies"
- "Enable Pod Security Admission"
- "Create Kyverno Validation Policies"
- "Configure Image Signature Verification"
- "Set Up RBAC with rbac-manager"
- "Rotate SOPS Age Keys"
- "Audit Kubernetes API Access"
- "Scan Images for Vulnerabilities"

### Reference Topics
- **SOPS Configuration Reference**
  - .sops.yaml format
  - Age key management
  - Encryption/decryption commands
- **Kyverno Policy Reference**
  - ClusterPolicy spec
  - Validation, mutation, generation rules
  - Policy reports
- **Network Policy Reference**
  - Default-deny patterns
  - Ingress/egress rules
  - Namespace selectors
- **Pod Security Standards Reference**
  - Restricted, baseline, privileged levels
  - Namespace labels
  - Exemptions
- **RBAC Reference**
  - Role, ClusterRole patterns
  - RoleBinding, ClusterRoleBinding
  - Service account best practices

### Explanation Topics
- "SOPS vs Sealed Secrets: When to Use Each"
- "Policy-as-Code with Kyverno"
- "Zero-Trust Network Architecture"
- "Pod Security Standards Rationale"
- "Supply Chain Security Strategy"

## Unknowns + VERIFY Steps

1. **Image Scanning Integration**
   - **Unknown:** Is Trivy or similar integrated?
   - **VERIFY:** Check CI/CD workflows, Harbor config
   - **Expected:** Automated image scanning

2. **Cosign Key Management**
   - **Unknown:** Where are Cosign keys stored?
   - **VERIFY:** Check for Cosign secrets, KMS integration
   - **Expected:** Keys in KMS or Kubernetes secrets

3. **Audit Log Destination**
   - **Unknown:** Where do audit logs go?
   - **VERIFY:** Check API server config, log aggregation
   - **Expected:** Loki or external SIEM

4. **Keycloak Configuration**
   - **Unknown:** What OIDC providers are configured?
   - **VERIFY:** Check Keycloak realm configuration
   - **Expected:** GitHub, Google, or corporate IdP

5. **RBAC Manager Policies**
   - **Unknown:** What RBAC definitions exist?
   - **VERIFY:** Check for RBACDefinition CRDs
   - **Expected:** Team-based access patterns

6. **Compliance Evidence**
   - **Unknown:** Where is compliance evidence stored?
   - **VERIFY:** Check for compliance/ directory or external system
   - **Expected:** Control mapping documents

## Cross-Cutting Alerts

- **CRITICAL:** Three critical security gaps (network policies, PSS, Kyverno policies)
- **Compliance:** No compliance mapping - audit risk
- **Supply Chain:** No image scanning or signature verification
- **Incident Response:** No audit logging - forensics gaps
