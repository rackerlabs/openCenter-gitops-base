# Reflector Deployment Spec

This spec covers the deployment of Kubernetes Reflector for automatic secret replication across namespaces and the consolidation of OCI credentials.

## Related Specs

This spec was extracted from the `kustomize-components-migration` spec. While the two specs are related, Reflector deployment is an independent project that can be executed separately.

## Overview

Reflector enables automatic secret replication across namespaces, allowing us to consolidate OCI credentials from 11+ per-service files to a single source secret per cluster. This reduces credential management complexity by 91%.

## Files

- `requirements.md` - Requirements for Reflector deployment and OCI consolidation
- `design.md` - Architecture and design for secret replication
- `tasks.md` - Implementation tasks for deploying Reflector

## Quick Start

1. Review requirements in `requirements.md`
2. Review design in `design.md`
3. Execute tasks in `tasks.md` sequentially

## Key Benefits

- **91% reduction** in OCI credential files (from 11+ per cluster to 1 per cluster)
- **Automatic replication** - secrets replicate within 60 seconds
- **Simplified rotation** - update one secret, all services get the new credentials
- **Centralized management** - single source of truth for OCI credentials
