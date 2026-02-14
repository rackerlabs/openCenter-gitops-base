# Requirements Document: Kustomize Components Migration

## Introduction

This document specifies the requirements for migrating the openCenter-gitops-base repository from parallel community/enterprise directory structures to Kustomize Components. The migration addresses systematic duplication, copy-paste errors, and high maintenance burden across 16 services while maintaining backward compatibility with existing customer overlays.

## Glossary

- **Service**: A Kubernetes application managed by FluxCD HelmRelease (e.g., cert-manager, metallb)
- **Community_Edition**: The base service configuration using public Helm repositories
- **Enterprise_Edition**: Service configuration using private OCI registry with hardened values
- **Component**: A Kustomize resource of `kind: Component` that provides composable configuration additions
- **Base_Kustomization**: The root kustomization.yaml that produces a working community deployment
- **Customer_Overlay**: A customer-specific Kustomize overlay that references base services
- **OCI_Credentials**: Docker registry credentials for accessing private OCI Helm repositories
- **Reflector**: Kubernetes operator that replicates secrets across namespaces
- **Output_Equivalence**: Property where migrated service produces byte-identical YAML output
- **Thin_Wrapper**: A minimal kustomization.yaml that includes base + component for backward compatibility
- **Standard_Helm_Service**: Service with single HelmRelease and standard community/enterprise pattern
- **Observability_Service**: Services under observability/ with shared namespace and sources
- **Special_Case_Service**: Services with non-standard patterns (OLM, Keycloak)
- **Migration_Script**: Automated tool for converting service structure to component pattern
- **Baseline_Output**: YAML output from current service structure before migration
- **HelmRepository**: FluxCD source resource defining Helm chart repository location
- **HelmRelease**: FluxCD resource defining Helm chart deployment configuration
- **SecretGenerator**: Kustomize feature for generating Kubernetes secrets from files

## Requirements

### Requirement 1: Service Migration to Kustomize Components

**User Story:** As a platform engineer, I want to migrate services from parallel community/enterprise directories to Kustomize Components, so that I can eliminate duplication and reduce maintenance burden.

#### Acceptance Criteria

1. WHEN a Standard_Helm_Service is migrated, THE Migration_System SHALL create a Base_Kustomization at the service root that produces a working Community_Edition deployment
2. WHEN a Standard_Helm_Service is migrated, THE Migration_System SHALL create an enterprise Component under `components/enterprise/` that adds Enterprise_Edition configuration
3. WHEN a Standard_Helm_Service is migrated, THE Migration_System SHALL create a Thin_Wrapper at `enterprise/kustomization.yaml` that includes the base and component
4. WHEN an Observability_Service is migrated, THE Migration_System SHALL handle shared namespace and source references correctly
5. WHEN a Special_Case_Service is migrated, THE Migration_System SHALL handle non-standard patterns (image patches for OLM, multi-component structure for Keycloak)
6. WHEN any service is migrated, THE Migration_System SHALL preserve all existing functionality without modification to behavior

### Requirement 2: Output Equivalence Validation

**User Story:** As a platform engineer, I want to validate that migrated services produce identical output, so that I can ensure no regressions are introduced.

#### Acceptance Criteria

1. WHEN a service migration is complete, THE Validation_System SHALL generate Baseline_Output from the original structure
2. WHEN a service migration is complete, THE Validation_System SHALL generate new output from the migrated structure
3. WHEN comparing outputs, THE Validation_System SHALL verify byte-identical YAML for both community and enterprise paths
4. WHEN outputs differ, THE Validation_System SHALL report the specific differences and fail the migration
5. IF validation fails, THEN THE Migration_System SHALL support rollback via git revert

### Requirement 3: Backward Compatibility

**User Story:** As a platform engineer, I want existing customer overlays to continue working unchanged, so that I can migrate services without coordinating customer updates.

#### Acceptance Criteria

1. WHEN a Customer_Overlay references `<service>/community`, THE System SHALL produce valid output after migration
2. WHEN a Customer_Overlay references `<service>/enterprise`, THE System SHALL produce valid output after migration
3. WHEN a Customer_Overlay uses existing FluxCD Kustomization paths, THE System SHALL continue working without modification
4. THE System SHALL maintain all existing service paths during migration
5. THE System SHALL NOT require any changes to Customer_Overlay configurations

### Requirement 4: Component Structure

**User Story:** As a platform engineer, I want enterprise components to follow a consistent structure, so that services are easy to understand and maintain.

#### Acceptance Criteria

1. THE Component SHALL be located at `<service>/components/enterprise/kustomization.yaml`
2. THE Component SHALL have `kind: Component` and `apiVersion: kustomize.config.k8s.io/v1alpha1`
3. THE Component SHALL include the global enterprise source from `global/enterprise/source.yaml`
4. THE Component SHALL include a patch to delete the community HelmRepository
5. THE Component SHALL include a patch to update the HelmRelease sourceRef to use `opencenter-cloud`
6. THE Component SHALL include a SecretGenerator for enterprise hardened values
7. THE Component SHALL NOT duplicate any configuration from the Base_Kustomization

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

### Requirement 9: Migration Phases

**User Story:** As a platform engineer, I want to migrate services in phases, so that I can validate each phase before proceeding and minimize risk.

#### Acceptance Criteria

1. THE Migration_System SHALL support migrating cert-manager as a pilot in Phase 1
2. THE Migration_System SHALL support migrating 8 Standard_Helm_Services in Phase 2
3. THE Migration_System SHALL support migrating 3 Observability_Services in Phase 3
4. THE Migration_System SHALL support migrating 2 Special_Case_Services in Phase 4
5. THE Migration_System SHALL support cleanup and documentation updates in Phase 5
6. THE Migration_System SHALL support Reflector deployment and OCI consolidation in Phase 6 (parallel with Phases 1-5)
7. WHEN a phase is complete, THE System SHALL allow validation before proceeding to the next phase

### Requirement 10: File Count Reduction

**User Story:** As a platform engineer, I want to reduce the number of edition-specific files, so that the repository is simpler to navigate and maintain.

#### Acceptance Criteria

1. WHEN all services are migrated with Thin_Wrappers, THE System SHALL reduce edition-specific files from 55 to 22 (60% reduction)
2. WHEN OCI credentials are consolidated, THE System SHALL reduce OCI credential files from 11 per cluster to 1 per cluster (91% reduction)
3. THE System SHALL eliminate all duplicated SecretGenerator blocks for base values
4. THE System SHALL eliminate all per-service patch files that reference HelmRelease sources

### Requirement 11: Version Upgrade Simplification

**User Story:** As a platform engineer, I want version upgrades to touch fewer files, so that upgrades are faster and less error-prone.

#### Acceptance Criteria

1. WHEN upgrading a service version after migration, THE System SHALL require updating version strings in 2 locations instead of 6
2. THE 2 locations SHALL be: the base values filename and the enterprise values filename
3. THE System SHALL NOT require updating version strings in community kustomization, enterprise kustomization, or patch files
4. WHEN upgrading OCI credentials after consolidation, THE System SHALL require updating 1 file per cluster instead of 11+ files per cluster

### Requirement 12: Copy-Paste Error Prevention

**User Story:** As a platform engineer, I want to prevent copy-paste errors, so that services don't have incorrect metadata or references.

#### Acceptance Criteria

1. THE Component pattern SHALL eliminate per-service patch files that can be copied incorrectly
2. THE Component pattern SHALL use a single global enterprise source instead of per-service sources
3. WHEN creating a new service, THE System SHALL NOT require copying patch files from other services
4. THE System SHALL fix the existing kyverno copy-paste error (metallb metadata) during migration

### Requirement 13: Migration Script Automation

**User Story:** As a platform engineer, I want an automated migration script, so that I can migrate services consistently and efficiently.

#### Acceptance Criteria

1. THE Migration_Script SHALL accept a service name as input
2. THE Migration_Script SHALL create the Base_Kustomization at the service root
3. THE Migration_Script SHALL create the enterprise Component under `components/enterprise/`
4. THE Migration_Script SHALL create the Thin_Wrapper at `enterprise/kustomization.yaml`
5. THE Migration_Script SHALL generate appropriate patches for HelmRepository deletion and HelmRelease source updates
6. THE Migration_Script SHALL preserve all existing files (namespace, helmrelease, source, helm-values)
7. THE Migration_Script SHALL handle service-specific variations (namespace location, multiple values files)

### Requirement 14: Documentation Updates

**User Story:** As a platform engineer, I want updated documentation, so that team members understand the new pattern and can apply it to new services.

#### Acceptance Criteria

1. THE System SHALL provide a service template showing the component pattern
2. THE System SHALL provide a guide for creating enterprise components
3. THE System SHALL update the "adding new service" documentation to reference the component pattern
4. THE System SHALL document the Reflector-based OCI credentials pattern
5. THE System SHALL document the credential rotation workflow with Reflector

### Requirement 15: Rollback Support

**User Story:** As a platform engineer, I want to rollback failed migrations, so that I can recover quickly if issues are discovered.

#### Acceptance Criteria

1. WHEN a migration fails validation, THE System SHALL support rollback via `git revert`
2. THE rollback SHALL restore the original community/enterprise directory structure
3. THE rollback SHALL restore all original files without data loss
4. WHEN a rollback is performed, THE Customer_Overlays SHALL continue working without modification

### Requirement 16: Monitoring and Validation

**User Story:** As a platform engineer, I want to monitor Reflector and validate secret replication, so that I can ensure OCI credentials are available to all services.

#### Acceptance Criteria

1. THE System SHALL provide commands to check Reflector pod health
2. THE System SHALL provide commands to verify source secret exists in flux-system
3. THE System SHALL provide commands to verify secrets are replicated to target namespaces
4. THE System SHALL provide commands to check Reflector logs for replication events
5. THE System SHALL document recommended alerts for Reflector failures and replication lag
