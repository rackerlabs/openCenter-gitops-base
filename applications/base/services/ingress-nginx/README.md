# NGINX Ingress Controller – Base Configuration

This directory contains the **base manifests** for deploying the [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/), a Kubernetes-native ingress controller that manages external access to services within the cluster.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About NGINX Ingress Controller:**

- Routes and load-balances external HTTP and HTTPS traffic to Kubernetes services using standard **Ingress** resources.  
- Provides advanced traffic management features such as **path-based routing**, **SSL termination**, and **request/response annotations**.  
- Supports integration with **Cert-Manager** for automatic TLS certificate provisioning and renewal.  
- Enables detailed **metrics** and **access logging** for observability through Prometheus and Grafana.  
- Commonly used as a secure entry point for applications, APIs, and internal services deployed on Kubernetes.  
