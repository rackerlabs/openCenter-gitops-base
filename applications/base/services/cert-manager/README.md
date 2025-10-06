# Cert-manager – Base Configuration

This directory contains the **base manifests** for deploying [Cert-manager](https://cert-manager.io/). It is intended to be consumed by **cluster repositories** as a remote base, with the option to provide cluster-specific overrides.

## Cert-Manager

- Automates the management and renewal of TLS certificates in Kubernetes clusters.
- Supports multiple certificate sources such as Let's Encrypt, HashiCorp Vault, and private PKI.
- Uses custom resources like Issuer, ClusterIssuer, and Certificate to define how certificates are requested and managed.
- Stores issued certificates and private keys securely in Kubernetes Secrets.
- Handles ACME challenges, certificate revocation, and self-signed certificates.
- Minimizes manual intervention and prevents downtime from expired certificates.
- Commonly used to secure ingress controllers, internal services, and any workloads requiring TLS.
- Simplifies certificate lifecycle management and enhances overall cluster security.
