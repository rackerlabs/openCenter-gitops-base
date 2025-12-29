# Kyverno – Base Configuration

This directory contains the **base manifests** for deploying [Kyverno](https://kyverno.io/), a Kubernetes-native policy engine that helps enforce best practices, security, and compliance through policies defined as Kubernetes resources.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About Kyverno:**

- Allows defining and enforcing **policies as Kubernetes resources** without requiring custom programming or external policy languages.  
- Enables automatic configuration management - for example, injecting labels, enforcing naming conventions, or setting security contexts.  
- Integrates with **Admission Webhooks** to evaluate policies in real time during resource creation or modification.  
- Provides **policy reports** and integrates with tools like **Prometheus** and **Grafana** for monitoring violations.  
- Commonly used to implement governance, security, and multi-tenancy controls in Kubernetes clusters.  
- Simplifies cluster compliance and enhances operational security through policy-driven automation.  
