# Operator Lifecycle Manager (OLM) – Base Configuration

This directory contains the **base manifests** for deploying the [Operator Lifecycle Manager (OLM)](https://olm.operatorframework.io/), a Kubernetes component that helps manage the installation, upgrade, and lifecycle of Operators.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About OLM:**

- Simplifies the **deployment and management of Operators** in Kubernetes clusters.  
- Provides a consistent framework for installing, upgrading, and uninstalling Operators using declarative resources.  
- Introduces core custom resources such as **ClusterServiceVersion (CSV)**, **CatalogSource**, **Subscription**, and **OperatorGroup**.  
- Supports **dependency resolution** between Operators to ensure smooth upgrades and compatibility.  
- Allows hosting and consuming **Operator catalogs** from internal or external registries.  
- Enables cluster administrators to control Operator permissions and namespace scopes securely.
- Improves operational consistency and reduces manual intervention in Operator lifecycle management.  
