# Zalando Postgres Operator - Base Configuration

This directory contains the **base manifests** for deploying the [Zalando Postgres Operator](https://github.com/zalando/postgres-operator), a Kubernetes operator that automates PostgreSQL cluster lifecycle operations.

## Public Repository Scope

- This public repository contains the **community/base** postgres-operator deployment only.
- Enterprise-specific image rewrites, private registry sourcing, and enterprise-only resources must be delivered from a **private enterprise repository** as an overlay/component on top of this base.

## Zalando Postgres Operator

- Automates provisioning, scaling, and maintenance of PostgreSQL clusters on Kubernetes.
- Manages replicas and failover for high availability.
- Supports rolling updates and PostgreSQL version upgrades.
- Exposes declarative APIs via `postgresql` custom resources.
- Commonly used for platform services requiring managed PostgreSQL.
