# RBAC Manager – Base Configuration

This directory contains the **base manifests** for deploying [RBAC Manager](https://github.com/FairwindsOps/rbac-manager), a Kubernetes operator that simplifies the management of RoleBindings and ClusterRoleBindings.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About RBAC Manager:**

- Automates the creation and maintenance of **Kubernetes RBAC roles and bindings** using declarative configurations.  
- Introduces the `RBACDefinition` custom resource to manage multiple roles and bindings in a single YAML file.  
- Simplifies access control management for users, groups, and service accounts across namespaces.  
- Reduces manual errors and configuration drift by keeping RBAC resources consistent and version-controlled.  
- Supports both **namespaced** and **cluster-wide** role management, making it suitable for multi-team or multi-tenant clusters.  
- Commonly used to manage platform-level access, application team permissions, and read-only auditor roles.  
- Improves security and governance by providing a consistent and automated approach to RBAC configuration.  
