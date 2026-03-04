# Keycloak - Base Configuration

This directory contains the **base manifests** for deploying [Keycloak](https://www.keycloak.org/), an IAM solution for authentication, authorization, and OIDC/SAML-based SSO.

## Public Repository Scope

- This public repository contains the **community/base** Keycloak deployment only.
- Enterprise-specific image rewrites, private catalog sources, and enterprise-only resources must be delivered from a **private enterprise repository** as an overlay/component on top of this base.

## Stage Layout

- `00-postgres/`: PostgreSQL backing database resources.
- `10-operator/`: OLM operator group and subscription resources.
- `20-keycloak/`: Keycloak custom resource.
- `30-oidc-rbac/`: Optional default OIDC RBAC resources.
