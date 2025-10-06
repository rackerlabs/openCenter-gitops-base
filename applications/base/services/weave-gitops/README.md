# Weave GitOps Dashboard – Base Configuration

This directory contains the **base manifests** for deploying the [Weave GitOps Dashboard](https://docs.gitops.weaveworks.org/), a web-based UI for managing and visualizing GitOps workflows powered by Flux.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About Weave GitOps Dashboard:**

- Provides a **web UI** to visualize and manage Flux-based GitOps deployments in Kubernetes clusters.  
- Displays **real-time status** of Flux resources such as GitRepositories, Kustomizations, and HelmReleases.  
- Simplifies monitoring of sync health, drift detection, and reconciliation events across multiple environments.  
- Offers deployment insights and audit-friendly visibility for platform and application teams.  
- Improves GitOps adoption by providing a user-friendly interface for cluster and application management.  
