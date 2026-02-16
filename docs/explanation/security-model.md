---
doc_type: explanation
title: "Security Model and Known Gaps"
audience: "security engineers, platform engineers, architects"
---

# Security Model and Known Gaps

**Purpose:** For security engineers, platform engineers, and architects, explains the security controls and architecture in openCenter-gitops-base, the SOPS encryption model, policy enforcement approach, and known security gaps identified in code review.

## Security Architecture

openCenter implements defense in depth through multiple security layers:

**Perimeter security** controls traffic entering the cluster through Envoy Gateway and Istio. TLS certificates from cert-manager encrypt traffic. Gateway API resources define routing rules. This layer protects against external threats.

**Network segmentation** isolates workloads within the cluster through network policies. Each namespace has ingress and egress rules defining allowed communication. This layer prevents lateral movement after a breach.

**Workload security** restricts what containers can do through Pod Security Admission and security contexts. Containers run as non-root users, with read-only filesystems, and without privileged capabilities. This layer limits the impact of container compromise.

**Policy enforcement** validates and mutates resources through Kyverno admission webhooks. Policies enforce security standards, inject required configuration, and generate supporting resources. This layer ensures consistent security posture.

**Secret management** protects sensitive data through SOPS encryption. Secrets are encrypted at rest in Git and decrypted by FluxCD during deployment. This layer prevents credential exposure.

**Identity and access** controls who can do what through Keycloak (authentication) and RBAC (authorization). Users authenticate with OIDC and receive permissions based on their role. This layer enforces least privilege.

This layered approach means an attacker must breach multiple controls to cause significant damage.

## SOPS Encryption Model

SOPS (Secrets OPerationS) encrypts secrets before they're committed to Git. The encryption uses age, a modern encryption tool with simple key management.

**Key generation** creates an age keypair:

```bash
age-keygen -o ${HOME}/config/sops/age/${CLUSTER_NAME}_keys.txt
```

This generates a private key (for decryption) and a public key (for encryption). The public key goes in `.sops.yaml` in the repository. The private key stays out of Git.

**Encryption** uses the public key to encrypt files:

```bash
sops -e -i secret.yaml
```

SOPS encrypts the values but leaves keys in plaintext. This makes encrypted files readable (you can see what secrets exist) but protects the sensitive data.

**Decryption** happens automatically during deployment. FluxCD reads the private key from a Kubernetes secret and uses it to decrypt SOPS-encrypted files before applying them to the cluster.

The `.sops.yaml` file defines encryption rules:

```yaml
creation_rules:
  - path_regex: .*.yaml
    encrypted_regex: ^(data|stringData|password|token|key|secret)$
    age: age1abc123...
```

This encrypts specific fields (data, password, token) in YAML files using the specified age public key. Other fields remain plaintext.

## Why SOPS

SOPS provides several advantages over alternatives:

**Git-friendly** - Encrypted files are still YAML. Git diffs show which secrets changed (though not the values). Merge conflicts are rare because SOPS preserves structure.

**Selective encryption** - Only sensitive fields are encrypted. Metadata (names, namespaces, labels) remains plaintext, making files readable and searchable.

**Key management** - Age keys are simple files. No complex PKI infrastructure. No key servers. No certificates. Just a keypair.

**Audit trail** - Every secret change is a Git commit. You can see who changed what secret, when, and why (from the commit message).

**Disaster recovery** - Secrets are in Git. If you lose the cluster, you can rebuild it from Git. You just need the age private key.

## SOPS Limitations

SOPS is not perfect:

**Key loss is catastrophic** - If you lose the age private key, you cannot decrypt secrets. There's no key recovery. You must regenerate all secrets and re-encrypt them with a new key.

**No key rotation** - Rotating keys requires re-encrypting all secrets. There's no automated rotation. You must manually decrypt with the old key and re-encrypt with the new key.

**No access control** - Anyone with the age private key can decrypt all secrets. There's no per-secret or per-user access control. Everyone has all secrets or no secrets.

**No audit logging** - SOPS doesn't log who decrypted what secret when. Git shows who changed secrets, but not who read them.

**Manual process** - Developers must remember to encrypt secrets before committing. There's no automatic encryption. Accidentally committing plaintext secrets is possible.

These limitations are acceptable for openCenter's threat model but may not work for all environments.

## Policy Enforcement with Kyverno

Kyverno enforces security policies through Kubernetes admission webhooks. When someone creates or updates a resource, Kyverno intercepts the request and applies policies.

**Validation policies** reject resources that don't meet requirements. For example, a policy might require all pods to have resource limits, or all ingresses to have TLS enabled. If a resource violates the policy, Kyverno rejects it with an error message.

**Mutation policies** automatically fix resources to meet requirements. For example, a policy might inject security contexts into pods that don't have them, or add required labels to all resources. The user submits a resource, Kyverno modifies it, and the modified resource is created.

**Generation policies** create supporting resources automatically. For example, a policy might create a network policy for every namespace, or create a service account for every deployment. When the trigger resource is created, Kyverno generates the supporting resources.

This approach makes security policies enforceable and automatic. Developers don't need to remember security requirements - Kyverno enforces them.

## Known Security Gaps

Code review identified critical security gaps that must be addressed before production deployment:

### Critical Gap: No Network Policies

**Status:** Network policies are documented in standards but not implemented. The `applications/policies/network-policies/` directory contains only a placeholder file.

**Impact:** Without network policies, any pod can communicate with any other pod. An attacker who compromises one service can access all services. This violates defense in depth and fails compliance requirements (ISO 27001, SOC 2, PCI-DSS).

**Root cause:** Policy framework exists but policies were never deployed.

**Remediation:** Implement default-deny network policies for all namespaces. Create allow rules for known service-to-service communication. Use Kyverno generation policies to automatically create network policies for new namespaces.

**Effort:** 2-3 weeks for design, implementation, and testing across 22+ namespaces.

### Critical Gap: No Pod Security Enforcement

**Status:** Pod Security Standards are documented but not enforced. No namespace labels for `pod-security.kubernetes.io/*` exist.

**Impact:** Containers may run with excessive privileges (root user, privileged mode, host network). This enables container escape and privilege escalation attacks.

**Root cause:** Pod Security Admission controller is not configured.

**Remediation:** Enable Pod Security Admission. Label namespaces with `pod-security.kubernetes.io/enforce: restricted`. Use `baseline` for namespaces requiring privileged access (with documented justification). Audit existing workloads for compliance.

**Effort:** 1-2 weeks for audit, remediation, and rollout.

### Critical Gap: No Kyverno Policies Deployed

**Status:** Kyverno is installed but no ClusterPolicy resources exist.

**Impact:** No automated policy enforcement. Non-compliant deployments are possible. Security standards documented in `docs/service-standards-and-lifecycle.md` are not enforced.

**Root cause:** Policy engine is present but policies were never implemented.

**Remediation:** Implement validation policies (required labels, security contexts), mutation policies (inject security contexts, tolerations), and generation policies (network policies, RBAC). Enable policy reports for visibility.

**Effort:** 2-3 weeks for policy development and testing.

### High Gap: No Image Scanning

**Status:** Image scanning is mentioned in standards but no scanner is integrated.

**Impact:** Vulnerable images may be deployed. CVEs in base images or dependencies go undetected.

**Root cause:** Trivy or similar scanner is not integrated in CI/CD.

**Remediation:** Integrate Trivy in CI/CD pipeline. Scan all images before deployment. Define CVE budget and exceptions. Block critical/high CVEs.

**Effort:** 1 week for integration and policy definition.

### High Gap: No Image Signature Verification

**Status:** Cosign is mentioned but no verification policies exist.

**Impact:** Unsigned images may be deployed. Supply chain attacks through malicious images are possible.

**Root cause:** Signing infrastructure and verification policies are not implemented.

**Remediation:** Implement Kyverno image verification policies. Sign all platform images with Cosign. Configure key management (KMS or Kubernetes secrets). Monitor verification failures.

**Effort:** 1-2 weeks for signing infrastructure and verification policies.

### High Gap: No mTLS Between Services

**Status:** Istio is present but no PeerAuthentication resources exist.

**Impact:** Service-to-service traffic is not encrypted. Man-in-the-middle attacks are possible within the cluster.

**Root cause:** Service mesh is installed but not fully configured.

**Remediation:** Enable strict mTLS for all namespaces. Create PeerAuthentication resources. Test service-to-service communication. Monitor mTLS metrics.

**Effort:** 2-3 days for configuration and testing.

### Medium Gap: No Audit Logging

**Status:** Audit logs are mentioned in standards but no configuration exists.

**Impact:** Difficult to investigate security incidents. No record of who did what in the cluster.

**Root cause:** Kubernetes audit logging is not configured.

**Remediation:** Configure Kubernetes audit logging. Send logs to Loki or external SIEM. Define retention policies. Create alerts for suspicious activity.

**Effort:** 1-2 days for configuration.

### Medium Gap: No RBAC Policies

**Status:** RBAC manager is present but no policies exist in `applications/policies/rbac/`.

**Impact:** Unclear access controls. Potential for excessive permissions.

**Root cause:** RBAC framework exists but policies were never defined.

**Remediation:** Define and implement RBAC policies. Implement least-privilege service accounts. Document RBAC model. Test with non-admin users.

**Effort:** 1-2 weeks for policy definition and testing.

## Security Maturity Assessment

Based on code review findings:

**Architecture:** Strong foundation with defense in depth layers, but critical gaps in enforcement.

**Secret Management:** Good encryption model with SOPS, but key management needs improvement (backup, rotation, recovery).

**Policy Enforcement:** Framework is present (Kyverno) but policies are not deployed. This is the most critical gap.

**Network Security:** No network segmentation. No mTLS. These are critical gaps for production.

**Supply Chain:** No image scanning or signature verification. High risk for production.

**Access Control:** Framework is present (Keycloak, RBAC manager) but policies are unclear.

**Audit and Compliance:** No audit logging. No compliance mapping. Medium risk.

**Overall Maturity:** 2/5 - Framework is present but enforcement is missing. Not production-ready.

## Remediation Priority

**Phase 1 (Critical - 4-6 weeks):**
1. Implement network policies
2. Enable Pod Security Admission
3. Deploy Kyverno policies
4. Configure mTLS
5. Integrate image scanning

**Phase 2 (High - 2-3 weeks):**
6. Configure audit logging
7. Implement RBAC policies
8. Document secret management (backup, rotation, recovery)
9. Add image signature verification
10. Enable dependency scanning

**Phase 3 (Medium - 2-3 weeks):**
11. Map controls to compliance frameworks
12. Generate compliance evidence
13. Conduct security audit
14. Document security procedures

**Total Effort:** 8-12 weeks to achieve production-ready security posture.

## Trade-offs and Design Decisions

**SOPS vs Sealed Secrets** - openCenter includes both. SOPS is simpler and more Git-friendly. Sealed Secrets provides better access control (controller-based decryption). The repository doesn't document when to use each. This creates confusion but provides flexibility.

**Kyverno vs OPA** - Kyverno is Kubernetes-native and easier to use. OPA is more powerful but requires learning Rego. openCenter chose Kyverno for simplicity.

**Age vs GPG** - Age is simpler than GPG. No key servers, no web of trust, no complex configuration. Age keys are just files. This makes SOPS easier to use but provides less flexibility than GPG.

**Admission webhooks vs runtime enforcement** - Kyverno enforces policies at admission time (when resources are created). This prevents non-compliant resources from being created but doesn't detect runtime violations. Runtime enforcement (Falco, Tetragon) would catch runtime violations but adds complexity.

**Zero-retry upgrades** - HelmRelease upgrades don't retry automatically. This prevents repeated failed upgrades but requires manual intervention. The trade-off favors safety over automation.

These decisions reflect openCenter's priorities: simplicity, maintainability, and safety over maximum flexibility and automation.

## Evidence

This explanation is based on the following repository analysis:

- SOPS encryption workflow: `llms.txt` lines 209-262
- SOPS configuration: `.sops.yaml` files throughout repository
- Kyverno policy engine: `applications/base/services/kyverno/policy-engine/README.md`
- Security requirements: `docs/service-standards-and-lifecycle.md` lines 48-55
- Keycloak IAM: `applications/base/services/keycloak/` directory structure
- Network policy gaps: `applications/policies/network-policies/placeholder.txt`
- Pod Security gaps: `applications/policies/pod-security-policies/placeholder.txt`
- RBAC gaps: `applications/policies/rbac/placeholder.txt`
- Security findings: `docs/analysis/S7-SECURITY-GOVERNANCE.md`
- Code review security assessment: `docs/analysis/A-CODE-REVIEW.md` sections A3, A11
- Image scanning gaps: `docs/analysis/S7-SECURITY-GOVERNANCE.md` HIGH findings
- mTLS gaps: `docs/analysis/A-CODE-REVIEW.md` section A11
