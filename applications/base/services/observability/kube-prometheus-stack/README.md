# Kube Prometheus Stack – Base Configuration

This directory contains the **base manifests** for deploying the [Kube Prometheus Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack), a comprehensive Kubernetes monitoring solution that bundles **Prometheus**, **Alertmanager**, **Grafana**, and related exporters.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About Kube Prometheus Stack:**

- Provides a fully integrated monitoring stack for **Kubernetes clusters and workloads**.  
- Includes **Prometheus Operator** for managing Prometheus, Alertmanager, and related monitoring resources declaratively.  
- Deploys **Grafana** with preconfigured dashboards for nodes, pods, networking, and application metrics.  
- Automatically discovers targets and scrapes metrics using **ServiceMonitor** and **PodMonitor** CRDs.  
- Integrates with **Alertmanager** for alert routing, notification management, and on-call workflows.  
- Supports **custom alerting rules**, **recording rules**, and **Prometheus remote write** configurations.  
- Commonly used to gain real-time visibility into cluster performance, resource utilization, and application health.  
