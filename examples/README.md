# OpenCenter Examples

This directory provides a reference flow to stand up:

1. Cluster infrastructure (`examples/iac/dev-cluster`)
2. Core service content using Flux (`examples/applications/overlays/dev-cluster`)

It is intended as a **starter template**. Copy and adapt for your own environment.

## Directory Layout

- `iac/dev-cluster/`
  - Terraform configuration for OpenStack infrastructure and cluster bootstrap modules.
- `applications/overlays/dev-cluster/`
  - Example Flux/Kustomize service deployment content (cert-manager, gateway-api, headlamp, metallb, etc.).

## Prerequisites

- OpenStack credentials and project access
- Terraform
- `kubectl`
- Flux CLI (for bootstrap/ops)
- Access to a Git repo for your cluster config

Note: `examples/iac/dev-cluster/Makefile` contains helper targets to install common tooling versions.

## 1) Deploy Infrastructure

Use the Terraform example in `examples/iac/dev-cluster` as a reference template for cluster infrastructure creation.

Typical flow:

```bash
terraform init
terraform plan
terraform apply
```

Before applying, replace placeholders in `provider.tf` and `main.tf` for your environment.

## 2) Deploy Service Content (Flux/Kustomize)

Use `examples/applications/overlays/dev-cluster` as a template for your cluster repo.

Recommended flow:

1. Copy `examples/applications/overlays/dev-cluster` into your cluster Git repo.
2. Bootstrap Flux in your cluster (if not already bootstrapped).
3. Point Flux `Kustomization` to your copied overlay path.

## Important Before Applying

Validate and adjust these in the example manifests:

1. Source paths currently use `./applications/overlays/dev/...` in some Flux files; if you keep `dev-cluster`, update paths accordingly.
2. GitRepository URLs/branches under `services/sources/` should match your repo strategy.
3. Domain names, hostnames, and IP ranges in service overrides must be environment-specific.
4. Encrypted secrets (if added) require your SOPS/Age setup.

## Suggested Validation

Run local checks before committing:

```bash
kustomize build examples/applications/overlays/dev-cluster/services/sources
kustomize build examples/applications/overlays/dev-cluster/services/fluxcd
kustomize build examples/applications/overlays/dev-cluster
```

Then let Flux reconcile from your cluster repo path.
