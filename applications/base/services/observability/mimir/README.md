# Mimir – Base Configuration

This directory contains the **base manifests** for deploying [Grafana Mimir](https://grafana.com/oss/mimir/), a horizontally-scalable, highly-available metrics storage system designed for cloud-native environments.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About Grafana Mimir:**

- Provides a **centralized, multi-tenant metrics backend** fully compatible with Prometheus and PromQL.
- Designed for **high ingestion throughput** and **large-scale time-series storage** across multiple Kubernetes clusters.
- Stores long-term metrics in **object storage**, enabling **cost-efficient retention** and improved durability.
- Separates **read and write paths** to enable independent scaling for heavy queries or high ingestion workloads.
- Uses advanced **caching**, **sharding**, and **compaction** for efficient querying and optimized storage layout.
- Integrates natively with **Grafana** for unified visualization alongside logs and traces.
