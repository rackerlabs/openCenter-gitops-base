# Tempo – Base Configuration

This directory contains the **base manifests** for deploying [Grafana Tempo](https://grafana.com/oss/tempo/), a horizontally-scalable, distributed tracing backend designed for cloud-native environments.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About Grafana Tempo:**

- Provides a **highly scalable, cost-effective tracing solution** optimized for collecting and storing distributed traces from Kubernetes clusters and microservices.
- Deployed in **Distributed mode** with separate read and write paths for high availability and horizontal scaling.
- Integrates natively with **OpenTelemetry** for trace collection using the OTLP protocol, enabling seamless ingestion without additional agents.
- Stores trace data in **object storage** instead of databases, reducing operational overhead and storage costs.
- Persists incoming spans using a **Write-Ahead Log (WAL)** and periodically compacts data into **Parquet blocks** for efficient long-term retention.
- Supports querying through **TraceQL**, a query language purpose-built for filtering and analyzing trace data.
- Automatically integrates with **Grafana** for unified visualization of **traces, logs, and metrics**.
