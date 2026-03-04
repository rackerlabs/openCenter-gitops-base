# Kyverno - Base Configuration

This directory contains the **base manifests** for deploying [Kyverno](https://kyverno.io/), a Kubernetes-native policy engine used to enforce security, governance, and compliance policies as Kubernetes resources.

## Public Repository Scope

- This public repository contains **community/base** Kyverno assets only.
- Enterprise-specific values, chart source changes, and enterprise-only resources must be delivered from a **private enterprise repository** as an overlay/component on top of this base.

## Directory Layout

- `policy-engine/`: Helm-based Kyverno controller deployment base.
- `default-ruleset/`: Default policy ruleset resources.

## Kyverno

- Defines and enforces policies as Kubernetes-native resources.
- Validates, mutates, and generates resources through admission controls.
- Produces policy reports for compliance visibility.
- Commonly used to implement workload security and platform governance controls.
