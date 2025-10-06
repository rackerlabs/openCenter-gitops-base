# Harbor – Base Configuration

This directory contains the **base manifests** for deploying [Harbor](https://goharbor.io/), a cloud-native registry that stores, signs, and scans container images and Helm charts.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About Harbor:**

- Acts as a **secure and centralized container registry** for storing and managing OCI images and Helm charts.  
- Provides **role-based access control(RBAC)** and **OIDC authentication** for user and project management.  
- Supports **vulnerability scanning**, **image signing (Notary)**, and **content trust** to enhance supply chain security.  
- Integrates with **Trivy** for image vulnerability scanning and **ChartMuseum** for Helm chart management.  
- Can serve as a **private OCI registry** for GitOps workflows and Flux/Kustomize-based deployments.  
- Features an intuitive web UI, REST API, and CLI tools for efficient image lifecycle management.  
- Improves compliance, security, and performance for enterprise container environments.  
