# Operator Lifecycle Manager (OLM) - Base Configuration

This directory contains the **base manifests** for deploying the [Operator Lifecycle Manager (OLM)](https://olm.operatorframework.io/), a Kubernetes component that manages installation, upgrade, and lifecycle of Operators.

## Public Repository Scope

- This public repository contains the **community/base** OLM deployment only.
- Enterprise-specific manifest patches, private registry rewrites, and enterprise-only resources must be delivered from a **private enterprise repository** as an overlay/component on top of this base.

## OLM

- Installs and manages Operators using Kubernetes-native resources.
- Provides `CatalogSource`, `Subscription`, and `OperatorGroup` driven workflows.
- Handles Operator dependency resolution and upgrades.
- Supports internal and external operator catalogs.
