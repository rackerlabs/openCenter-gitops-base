# Loki – Base Configuration

This directory contains the **base manifests** for deploying [Grafana Loki](https://grafana.com/oss/loki/), a horizontally-scalable, highly-available log aggregation system designed for cloud-native environments.
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About Grafana Loki:**

- Provides a **cost-effective log aggregation solution** optimized for storing and querying logs from Kubernetes clusters and applications.
- Deployed in **Simple Scalable mode** with separate read and write paths for high availability and horizontal scaling.
- Integrates natively with **OpenTelemetry** for log collection using OTLP protocol, eliminating the need for additional log shippers.
- Indexes only metadata (labels) rather than full-text, resulting in **significantly lower storage costs** compared to traditional solutions.
- Queries logs using **LogQL**, a query language similar to PromQL, enabling powerful filtering and aggregation.
- Supports **multi-tenancy**, **retention policies**, and **compaction** for efficient long-term log storage.
- Automatically integrates with **Grafana** for unified visualization of logs alongside metrics and traces.
- Commonly used for troubleshooting application issues, audit logging, security analysis, and operational insights.
