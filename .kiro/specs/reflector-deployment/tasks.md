# Implementation Plan: Reflector Deployment for Secret Replication

## Overview

This implementation plan deploys Kubernetes Reflector for secret replication and consolidates OCI credentials from 11+ per-service files to a single source secret per cluster. The implementation includes Reflector deployment, OCI consolidation tooling, and documentation.

## Tasks

- [ ] 1. Deploy Reflector service
  - [ ] 1.1 Create Reflector service directory structure
    - Create applications/base/managed-services/reflector/
    - Create namespace.yaml for reflector-system
    - _Requirements: 5.1, 5.3_
  
  - [ ] 1.2 Create Reflector HelmRepository source
    - Create source.yaml for emberstack Helm repository
    - Set URL to https://emberstack.github.io/helm-charts
    - _Requirements: 5.2_
  
  - [ ] 1.3 Create Reflector HelmRelease
    - Create helmrelease.yaml with chart version 7.1.288
    - Configure namespace as reflector-system
    - Enable RBAC in values
    - _Requirements: 5.1, 5.2, 5.3_
  
  - [ ] 1.4 Create Reflector kustomization
    - Create kustomization.yaml including namespace, source, helmrelease
    - _Requirements: 5.1_
  
  - [ ]* 1.5 Write unit tests for Reflector deployment
    - Verify HelmRelease structure
    - Verify correct chart version
    - Verify correct namespace
    - _Requirements: 5.1, 5.2, 5.3_

- [ ] 2. Checkpoint - Reflector deployed
  - Ensure Reflector pod is running and healthy

- [ ] 3. Implement OCI credentials consolidation
  - [ ] 3.1 Implement OCI consolidation script
    - Create Go tool to consolidate OCI credentials
    - Accept customer and cluster as parameters
    - Read existing per-service oci-creds.yaml files
    - Generate namespace list from service directories
    - _Requirements: 6.5_
  
  - [ ] 3.2 Implement source secret generator
    - Create function to generate flux-system/oci-creds.yaml
    - Set type to kubernetes.io/dockerconfigjson
    - Add Reflector annotations (reflection-allowed, reflection-allowed-namespaces)
    - Include namespace list in annotation
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  
  - [ ] 3.3 Implement per-service file cleanup
    - Create function to find all oci-creds.yaml files in service directories
    - Delete per-service oci-creds.yaml files
    - Update service kustomizations to remove oci-creds.yaml resource references
    - _Requirements: 6.6, 6.7_
  
  - [ ] 3.4 Implement SOPS encryption integration
    - Add SOPS encryption call after generating source secret
    - Use command: `sops -e -i <path>/flux-system/oci-creds.yaml`
    - _Requirements: 6.1_
  
  - [ ]* 3.5 Write property test for OCI consolidation
    - **Property 7: OCI Credentials Consolidation**
    - **Validates: Requirements 6.1, 6.6**
    - Generate random cluster structures with per-service oci-creds files
    - Run consolidation
    - Verify exactly one oci-creds.yaml in flux-system
    - Verify zero oci-creds.yaml in service directories
    - Run 100 iterations
  
  - [ ]* 3.6 Write property test for secret replication
    - **Property 5: Secret Replication Consistency**
    - **Validates: Requirements 7.1, 7.4**
    - Generate random namespace lists
    - Create source secret with namespace list annotation
    - Verify replicated secret exists in each namespace with identical content
    - Run 100 iterations

- [ ] 4. Checkpoint - OCI consolidation complete
  - Ensure all tests pass, verify single source secret per cluster

- [ ] 5. Documentation and monitoring
  - [ ] 5.1 Document Reflector-based OCI credentials pattern
    - Create docs/oci-credentials-with-reflector.md
    - Document Reflector deployment and configuration
    - Document source secret structure and annotations
    - Document namespace list management
    - _Requirements: 14.4_
  
  - [ ] 5.2 Document credential rotation workflow
    - Add section to oci-credentials-with-reflector.md
    - Document steps to rotate credentials
    - Document validation commands
    - Compare before/after workflow complexity
    - _Requirements: 14.5_
  
  - [ ] 5.3 Document monitoring and validation commands
    - Add section to oci-credentials-with-reflector.md
    - Document commands to check Reflector pod health
    - Document commands to verify source secret
    - Document commands to verify replicated secrets
    - Document commands to check Reflector logs
    - Document recommended alerts
    - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5_

- [ ] 6. Final validation
  - [ ] 6.1 Deploy Reflector to test cluster
    - Verify pod starts successfully
    - Verify RBAC permissions are correct
    - _Requirements: 5.4_
  
  - [ ] 6.2 Test secret replication
    - Create source secret with annotations
    - Verify replication to all allowed namespaces
    - Verify replication timing (< 60 seconds)
    - _Requirements: 7.1, 7.2, 7.3_
  
  - [ ] 6.3 Test OCI consolidation on sample cluster
    - Run consolidation script
    - Verify single source secret created
    - Verify per-service files removed
    - Deploy services and verify OCI authentication works
    - _Requirements: 6.1, 6.6, 6.7_

- [ ] 7. Final checkpoint - Reflector deployment complete
  - Ensure all tests pass, documentation is complete

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Reflector should be deployed early so OCI consolidation can begin
- SOPS encryption is mandatory for all oci-creds.yaml files
- Namespace list must be kept in sync with services requiring OCI access
