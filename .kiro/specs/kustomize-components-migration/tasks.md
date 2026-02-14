# Implementation Plan: Kustomize Components Migration

## Overview

This implementation plan migrates 16 services from parallel community/enterprise directories to Kustomize Components. The implementation is organized into 5 phases with validation at each step to ensure zero regressions.

**Note**: Reflector deployment and OCI credentials consolidation have been moved to a separate spec: `.kiro/specs/reflector-deployment/`

## Tasks

- [ ] 1. Set up migration tooling infrastructure
  - [x] 1.1 Create Go module for migration tools
    - Initialize Go module in `tools/kustomize-migration/`
    - Set up project structure with cmd/ and pkg/ directories
    - Add dependencies: gopkg.in/yaml.v3 for YAML parsing
    - _Requirements: 13.1, 13.2, 13.3, 13.4_
  
  - [x] 1.2 Implement YAML parsing utilities
    - Create pkg/kustomize package for parsing kustomization.yaml files
    - Implement functions to extract resources, patches, and secretGenerators
    - Implement functions to detect service type (standard, observability, special)
    - _Requirements: 13.7_
  
  - [x] 1.3 Implement file system utilities
    - Create pkg/fs package for file operations
    - Implement functions to read/write YAML files
    - Implement functions to create directories and preserve file permissions
    - Implement functions to detect existing file structure
    - _Requirements: 13.6_

- [x] 2. Implement migration script core logic
  - [x] 2.1 Implement base kustomization generator
    - Create function to generate base kustomization.yaml at service root
    - Extract resources from community kustomization (namespace, source, helmrelease)
    - Extract secretGenerator for base values from community kustomization
    - Write base kustomization to service root
    - _Requirements: 1.1, 4.7_
  
  - [x] 2.2 Implement enterprise component generator
    - Create function to generate component kustomization.yaml
    - Set apiVersion to kustomize.config.k8s.io/v1alpha1 and kind to Component
    - Add global enterprise source to resources
    - Generate HelmRepository deletion patch
    - Generate HelmRelease sourceRef update patch
    - Extract enterprise secretGenerator from enterprise kustomization
    - Write component to components/enterprise/
    - _Requirements: 1.2, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_
  
  - [x] 2.3 Implement thin wrapper generator
    - Create function to generate thin wrapper kustomization.yaml
    - Add "../" to resources (includes base)
    - Add "../components/enterprise" to components
    - Write wrapper to enterprise/kustomization.yaml
    - _Requirements: 1.3_
  
  - [x] 2.4 Implement service type detection
    - Create function to detect standard Helm service pattern
    - Create function to detect observability service pattern (shared namespace/sources)
    - Create function to detect special case patterns (OLM, Keycloak)
    - Return service type enum for migration strategy selection
    - _Requirements: 1.4, 1.5_

- [x] 3. Implement validation script
  - [x] 3.1 Implement baseline output generator
    - Create function to run `kubectl kustomize` on original structure
    - Generate baseline for community path: `<service>/community`
    - Generate baseline for enterprise path: `<service>/enterprise`
    - Save baseline outputs to temporary files
    - _Requirements: 2.1_
  
  - [x] 3.2 Implement new output generator
    - Create function to run `kubectl kustomize` on migrated structure
    - Generate output for community path: `<service>`
    - Generate output for enterprise path: `<service>/enterprise`
    - Save new outputs to temporary files
    - _Requirements: 2.2_
  
  - [x] 3.3 Implement output comparison
    - Create function to compare two YAML files byte-by-byte
    - Report success if files are identical
    - Report failure with diff output if files differ
    - Exit with appropriate status code
    - _Requirements: 2.3, 2.4_
  
  - [ ]* 3.4 Write property test for output equivalence
    - **Property 1: Migration Output Equivalence**
    - **Validates: Requirements 2.1, 2.2, 2.3**
    - Generate random service structures with varying configurations
    - Migrate each service
    - Verify byte-identical output for community and enterprise paths
    - Run 100 iterations

- [x] 4. Phase 1: Pilot migration (cert-manager)
  - [x] 4.1 Generate baseline output for cert-manager
    - Run validation script to capture baseline
    - Save baseline outputs for comparison
    - _Requirements: 2.1_
  
  - [x] 4.2 Migrate cert-manager to component pattern
    - Run migration script on cert-manager
    - Verify base kustomization created at root
    - Verify enterprise component created
    - Verify thin wrapper created
    - _Requirements: 1.1, 1.2, 1.3, 9.1_
  
  - [x] 4.3 Validate cert-manager migration
    - Run validation script
    - Verify output equivalence for community path
    - Verify output equivalence for enterprise path
    - Fix any issues if validation fails
    - _Requirements: 2.3_
  
  - [ ]* 4.4 Write unit tests for cert-manager migration
    - Test base kustomization structure
    - Test component structure
    - Test thin wrapper structure
    - Test backward compatibility with customer overlays
    - _Requirements: 3.1, 3.2_

- [x] 5. Checkpoint - Pilot validation complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Phase 2: Standard Helm services migration
  - [x] 6.1 Migrate metallb
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [x] 6.2 Migrate headlamp
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [x] 6.3 Migrate rbac-manager
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [x] 6.4 Migrate postgres-operator
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [x] 6.5 Migrate gateway-api
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [x] 6.6 Migrate vsphere-csi
    - Generate baseline, run migration, validate output equivalence
    - Handle CRDs directory if present
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [x] 6.7 Migrate kyverno/policy-engine
    - Generate baseline, run migration, validate output equivalence
    - Fix copy-paste error (metallb metadata in patch file)
    - _Requirements: 1.1, 1.2, 1.3, 2.3, 12.4_
  
  - [x] 6.8 Migrate istio
    - Handle multi-component structure (base, istiod)
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [x] 6.9 Migrate external-snapshotter
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [x] 6.10 Migrate harbor
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [x] 6.11 Migrate longhorn
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [x] 6.12 Migrate openstack-ccm
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [x] 6.13 Migrate openstack-csi
    - Generate baseline, run migration, validate output equivalence
    - Handle CRDs directory if present
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [x] 6.14 Migrate sealed-secrets
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [x] 6.15 Migrate strimzi-kafka-operator
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [x] 6.16 Migrate velero
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.1, 1.2, 1.3, 2.3_
  
  - [ ]* 6.17 Write property test for standard service migration
    - **Property 2: Backward Compatibility Preservation**
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
    - Generate random customer overlays referencing service paths
    - Migrate services
    - Verify overlays produce valid output without modification
    - Run 100 iterations

- [x] 7. Checkpoint - Standard services complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Phase 3: Observability services migration
  - [x] 8.1 Migrate kube-prometheus-stack
    - Handle shared namespace at observability/namespace/
    - Handle shared sources at observability/sources/
    - Handle multiple values files (alerting-rules, alertmanager, prometheus)
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.4, 2.3_
  
  - [x] 8.2 Migrate loki
    - Handle shared namespace and sources
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.4, 2.3_
  
  - [x] 8.3 Migrate opentelemetry-kube-stack
    - Handle shared namespace and sources
    - Handle extra resources (otel-collector-sa.yaml in enterprise)
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.4, 2.3_
  
  - [ ]* 8.4 Write property test for observability services
    - **Property 3: Component Structure Consistency**
    - **Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 4.6**
    - For any migrated service, verify component structure
    - Verify component location, kind, apiVersion
    - Verify global source inclusion, patches, secretGenerator
    - Run 100 iterations

- [x] 9. Checkpoint - Observability services complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Phase 4: Special case services migration
  - [x] 10.1 Migrate OLM
    - Handle non-Helm pattern (image patches instead of HelmRelease)
    - Create custom migration logic for image patch pattern
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.5, 2.3_
  
  - [x] 10.2 Migrate Keycloak
    - Handle multi-component structure (postgres, operator, keycloak, oidc-rbac)
    - Decide migration strategy (per-component or unified)
    - Generate baseline, run migration, validate output equivalence
    - _Requirements: 1.5, 2.3_
  
  - [ ]* 10.3 Write unit tests for special cases
    - Test OLM image patch migration
    - Test Keycloak multi-component migration
    - Verify output equivalence for special patterns
    - _Requirements: 1.5, 2.3_

- [ ] 11. Checkpoint - All service migrations complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 12. Phase 5: Documentation and cleanup
  - [ ] 12.1 Create service template with component pattern
    - Create docs/templates/service-with-enterprise-component.yaml
    - Include example base kustomization
    - Include example enterprise component
    - Include example thin wrapper
    - _Requirements: 14.1_
  
  - [ ] 12.2 Create enterprise component guide
    - Create docs/enterprise-components-guide.md
    - Document component structure and purpose
    - Document how to create new enterprise components
    - Document migration benefits and rationale
    - _Requirements: 14.2_
  
  - [ ] 12.3 Update "adding new service" documentation
    - Update docs/adding-new-service.md
    - Replace parallel directory pattern with component pattern
    - Reference service template and enterprise component guide
    - _Requirements: 14.3_
  
  - [ ] 12.4 Update ADR-001 status to Accepted
    - Change status from "Proposed" to "Accepted"
    - Add implementation date
    - Add link to this implementation plan
    - _Requirements: N/A_

- [ ] 13. Final validation and metrics
  - [ ] 13.1 Validate file count reduction
    - Count edition-specific files before migration (should be 55)
    - Count edition-specific files after migration (should be 22)
    - Verify 60% reduction achieved
    - _Requirements: 10.1_
  
  - [ ] 13.2 Validate version upgrade touchpoints
    - For each migrated service, identify files containing version strings
    - Verify only 2 files per service contain version strings
    - Verify files are base values filename and enterprise values filename
    - _Requirements: 11.1, 11.2_
  
  - [ ] 13.3 Validate duplication elimination
    - Verify no duplicated secretGenerator blocks for base values
    - Verify no per-service patch files exist
    - Verify all services use global enterprise source
    - _Requirements: 10.3, 10.4, 12.2_
  
  - [ ]* 13.4 Write property test for rollback completeness
    - **Property 9: Rollback Completeness**
    - **Validates: Requirements 15.1, 15.2, 15.3, 15.4**
    - For any migrated service, perform git revert
    - Verify original directory structure restored
    - Verify all original files intact
    - Verify customer overlays continue working
    - Run 100 iterations
  
  - [ ]* 13.5 Run full integration test suite
    - Deploy all migrated services to test cluster
    - Verify all HelmReleases reconcile successfully
    - Verify no regressions in functionality

- [ ] 14. Final checkpoint - Implementation complete
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- Migration is incremental with validation at each phase
- Rollback is supported via git revert at any point
- Go is used for migration and validation tooling for strong typing and excellent YAML support
