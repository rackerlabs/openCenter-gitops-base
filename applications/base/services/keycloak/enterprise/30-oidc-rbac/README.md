# Default RBAC Configuration (OIDC + rbac-manager)

This configuration provides a **structured and scalable role-based access control (RBAC)** setup for Kubernetes clusters integrated with **OIDC providers such as Keycloak**.  
It defines clear access boundaries for different teams (admins, observability, platform, security, namespace admins, etc.) and leverages **rbac-manager** for automated creation and reconciliation of RBAC bindings.

By using **namespace labels** and centralized **OIDC groups**, the configuration enables **multi-team, least-privilege access management** that is both **GitOps-friendly and self-maintaining**.

---

## Prerequisites

1. **[rbac-manager](https://github.com/FairwindsOps/rbac-manager)** must be installed in the cluster.  
   - This controller manages `RBACDefinition` CRDs and automatically creates RoleBindings and ClusterRoleBindings defined in this configuration.

2. **OIDC integration** must be enabled on the Kubernetes API server.  
   - The OIDC provider (e.g., Keycloak) should expose user groups (such as `oidc:cluster-admins`, `oidc:observability`, etc.) in the `groups` claim of the OIDC token.

---

## What this configuration enables

| Group | Description |
|--------|--------------|
| **oidc:cluster-admins** | Full cluster-admin access to manage all resources. |
| **oidc:read-only** | Cluster-wide read-only access using the built-in `view` role. |
| **oidc:namespace-admins** | Admin rights only in namespaces labeled `rbac.opencenter.io/admin="true"`. |
| **oidc:security-team** | Cluster-wide read access + admin rights in security-labeled namespaces. |
| **oidc:observability** | Read access to workloads, nodes, logs, metrics, and monitoring CRDs (no Secrets). |
| **oidc:platform-team** | Permission to manage only `RBACDefinition` CRDs used by rbac-manager. |
| **oidc:k8s-ops**  | Broad, read-only cluster visibility for operations teams. |

---

## Namespace Label Usage

Namespace labels provide **dynamic, label-driven authorization** so that access adjusts automatically without editing RBAC definitions whenever a new namespace is created.

| Label | Purpose |
|--------|----------|
| `rbac.opencenter.io/admin="true"` | Grants admin privileges to members of `oidc:namespace-admins`. |
| `security.opencenter.io/managed="true"` | Grants admin privileges to `oidc:security-team` in those namespaces. |

**NOTE:** When these labels are added or removed, **rbac-manager automatically updates** the corresponding RoleBindings - ensuring RBAC stays consistent with namespace state.

---

## Deployment

For both **in-cluster IDP (Keycloak)** and **external OIDC providers**, the default RBAC configuration can be deployed via your **GitOps tool (FluxCD)** from your overlay cluster repository.  
Just make sure the required **OIDC groups** (`oidc:cluster-admins`, `oidc:observability`, `oidc:namespace-admins`, etc.) are created in the identity provider before users attempt to log in.

---

## Structure Overview

- **ClusterRole: `observability-extras`** - Extends `view` with nodes, logs, metrics, and monitoring CRDs.  
- **ClusterRole: `rbacmanager-crd-admin`** - Manages rbac-manager `RBACDefinition` CRDs.  
- **ClusterRole: `k8s-ops`** - Provides consolidated, read-only access for operations teams.  
- **RBACDefinitions:**  
  - `oidc-cluster-admins` - Full cluster control  
  - `oidc-read-only` - Safe cluster-wide read access  
  - `oidc-observability` - Read + observability extras  
  - `oidc-namespace-admins` - Admin in namespaces labeled for delegation  
  - `oidc-security-team` - Cluster read + admin in security namespaces  
  - `oidc-platform-team` - Manage rbac-manager CRDs  
  - `oidc-k8s-ops` - Bind OIDC ops group to `k8s-ops` role  

---

## Summary

This RBAC configuration provides a **secure, modular, and OIDC-driven access model** for Kubernetes clusters.  
It separates team privileges, leverages **namespace labels for delegated control**, and uses **rbac-manager** to keep bindings synchronized automatically.  
Whether you're running an **in-cluster Keycloak** or connecting to an **external IdP**, this setup ensures consistent, auditable, and GitOps-friendly RBAC management across all environments.
