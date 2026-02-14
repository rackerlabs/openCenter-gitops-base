# Requirements Document: Reflector Deployment for Secret Replication

## Introduction

This document specifies the requirements for deploying Kubernetes Reflector to enable automatic secret replication across namespaces in openCenter clusters. Reflector will consolidate OCI credentials from 11+ per-service files to a single source secret that automatically replicates to all service namespaces.

## Glossary

- **Reflector**: Kubernetes operator that replicates secrets across namespaces based on annotations
- **Source_Secret**: The master secret in flux-system namespace that Reflector watches and replicates
- **Replicated_Secret**: A copy of the source secret created by Reflector in a target namespace
- **OCI_Credentials**: Docker registry credentials for accessing private OCI Helm repositories
- **Reflection_Annotation**: Kubernetes annotation that enables Reflector to replicate a secret
- **Allowed_Namespaces**: Explicit list of namespaces where Reflector is permitted to replicate secrets
- **Replication_Lag**: Time delay between source secret update and replicated secret update

## Requirements

### Requirement 5: Reflector Deployment

**User Story:** As a platform engineer, I want to deploy Kubernetes Reflector, so that I can replicate OCI credentials across namespaces automatically.

#### Acceptance Criteria

1. THE System SHALL deploy Reflector as a managed service in the base repository
2. THE Reflector_Service SHALL use Helm chart version 7.1.288 from the emberstack repository
3. THE Reflector_Service SHALL run in the `reflector-system` namespace
4. THE Reflector_Service SHALL have RBAC permissions to read source secrets and write to allowed namespaces
5. THE Reflector_Service SHALL be deployed before OCI credentials consolidation begins

### Requirement 6: OCI Credentials Consolidation

**User Story:** As a platform engineer, I want to consolidate duplicate OCI credentials files, so that I can manage credentials in a single location per cluster.

#### Acceptance Criteria

1. WHEN OCI credentials are consolidated, THE System SHALL create a single `oci-creds` secret in the `flux-system` namespace per cluster
2. THE `oci-creds` secret SHALL have type `kubernetes.io/dockerconfigjson`
3. THE `oci-creds` secret SHALL include annotation `reflector.v1.k8s.emberstack.com/reflection-allowed: "true"`
4. THE `oci-creds` secret SHALL include annotation `reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces` with explicit namespace list
5. THE explicit namespace list SHALL include all service namespaces requiring OCI access
6. WHEN consolidation is complete, THE System SHALL remove all per-service `oci-creds.yaml` files from customer overlays
7. WHEN consolidation is complete, THE System SHALL update service kustomizations to remove `oci-creds.yaml` resource references

### Requirement 7: Secret Replication

**User Story:** As a platform engineer, I want Reflector to automatically replicate OCI credentials, so that all services have access without manual duplication.

#### Acceptance Criteria

1. WHEN the source `oci-creds` secret is created in `flux-system`, THE Reflector SHALL replicate it to all namespaces in the allowed list
2. WHEN the source `oci-creds` secret is updated, THE Reflector SHALL update all replicated secrets within 60 seconds
3. WHEN a new namespace is added to the allowed list, THE Reflector SHALL replicate the secret to that namespace
4. THE replicated secrets SHALL have identical content to the source secret
5. THE replicated secrets SHALL be named `oci-creds` in each target namespace

### Requirement 8: Global Enterprise Source Configuration

**User Story:** As a platform engineer, I want the global enterprise source to reference the flux-system OCI credentials, so that all enterprise services use the replicated credentials.

#### Acceptance Criteria

1. THE global enterprise HelmRepository SHALL be located at `global/enterprise/source.yaml`
2. THE global enterprise HelmRepository SHALL have name `opencenter-cloud`
3. THE global enterprise HelmRepository SHALL reference `secretRef.name: oci-creds` in the `flux-system` namespace
4. THE global enterprise HelmRepository SHALL use `type: oci` and `url: oci://ghcr.io/opencenter-cloud`
5. THE global enterprise HelmRepository SHALL have `interval: 1h`

### Requirement 16: Monitoring and Validation

**User Story:** As a platform engineer, I want to monitor Reflector and validate secret replication, so that I can ensure OCI credentials are available to all services.

#### Acceptance Criteria

1. THE System SHALL provide commands to check Reflector pod health
2. THE System SHALL provide commands to verify source secret exists in flux-system
3. THE System SHALL provide commands to verify secrets are replicated to target namespaces
4. THE System SHALL provide commands to check Reflector logs for replication events
5. THE System SHALL document recommended alerts for Reflector failures and replication lag
