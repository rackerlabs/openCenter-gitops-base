# Design Document: Kustomize Components Migration

## Overview

This design implements a migration from parallel community/enterprise directory structures to Kustomize Components for 16 services in the openCenter-gitops-base repository. The migration eliminates 55 edition-specific files with ~60% duplicate content, prevents copy-paste errors, and reduces version upgrade touchpoints from 6 to 2 locations per service.

The design uses Kustomize Components (`kind: Component`) to make enterprise configuration a composable add-on rather than a parallel directory tree. It maintains backward compatibility through thin wrapper kustomizations and validates output equivalence at each step.

A parallel effort deploys Kubernetes Reflector to consolidate OCI credentials from 11+ files per cluster to a single source secret that automatically replicates to all service namespaces.

## Architecture

### Component-Based Service Structure

The new architecture transforms each service from parallel directories to a layered composition:

```
<service>/
├── kustomization.yaml              # Base (produces community deployment)
├── source.yaml                     # Community HelmRepository
├── namespace.yaml
├── helmrelease.yaml
├── helm-values/
│   └── values-vX.Y.Z.yaml
├── enterprise/
│   └── kustomization.yaml          # Thin wrapper: includes base + component
└── components/
    └── enterprise/
        ├── kustomization.yaml      # Component: patches + enterprise values
        └── helm-values/
            └── hardened-values-vX.Y.Z.yaml
```

**Base Layer**: The root kustomization produces a working community deployment by default. It includes namespace, source, helmrelease, and generates a secret from base values.

**Component Layer**: The enterprise component adds three things:
1. Global enterprise OCI source (`opencenter-cloud`)
2. Patches to remove community source and update HelmRelease sourceRef
3. Enterprise hardened values secret

**Compatibility Layer**: The thin wrapper at `enterprise/kustomization.yaml` includes both base and component, preserving existing customer overlay paths.

### Reflector-Based Credentials Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ flux-system namespace                                           │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Secret: oci-creds                                        │   │
│  │ Type: kubernetes.io/dockerconfigjson                     │   │
│  │ Annotations:                                             │   │
│  │   reflector.v1.k8s.emberstack.com/reflection-allowed     │   │
│  │   reflector.v1.k8s.emberstack.com/reflection-allowed-    │   │
│  │     namespaces: "cert-manager,metallb-system,..."        │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                  │
└──────────────────────────────┼──────────────────────────────────┘
                               │
                               │ Reflector watches and replicates
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐      ┌───────────────┐     ┌───────────────┐
│ cert-manager  │      │ metallb-system│     │ kyverno       │
│               │      │               │     │               │
│ oci-creds     │      │ oci-creds     │     │ oci-creds     │
│ (replicated)  │      │ (replicated)  │     │ (replicated)  │
└───────────────┘      └───────────────┘     └───────────────┘
```

Reflector runs as a managed service and watches the source secret in flux-system. When the secret is created or updated, Reflector automatically replicates it to all namespaces in the allowed list within seconds.

## Components and Interfaces

### Migration Script

**Purpose**: Automate the conversion of a service from parallel directories to component structure.

**Interface**:
```bash
migrate-service.sh <service-name> [--service-type standard|observability|special]
```

**Inputs**:
- Service name (e.g., "cert-manager")
- Service type (optional, auto-detected if not provided)
- Current service directory structure

**Outputs**:
- Base kustomization.yaml at service root
- Component kustomization.yaml at `components/enterprise/`
- Thin wrapper at `enterprise/kustomization.yaml`
- Preserved original files (namespace, helmrelease, source, helm-values)

**Behavior**:
1. Detect service type by analyzing directory structure
2. Extract community kustomization resources and secretGenerator
3. Extract enterprise kustomization patches and enterprise secretGenerator
4. Generate base kustomization with community configuration
5. Generate component with enterprise patches and secretGenerator
6. Generate thin wrapper that includes base + component
7. Preserve all original resource files in place

### Validation Script

**Purpose**: Verify that migrated service produces byte-identical output.

**Interface**:
```bash
validate-migration.sh <service-name>
```

**Inputs**:
- Service name
- Baseline output (generated before migration)
- Current service structure (after migration)

**Outputs**:
- Success/failure status
- Diff output if differences detected
- Validation report

**Behavior**:
1. Generate baseline output: `kubectl kustomize <service>/community > baseline-community.yaml`
2. Generate baseline output: `kubectl kustomize <service>/enterprise > baseline-enterprise.yaml`
3. Generate new output: `kubectl kustomize <service> > new-community.yaml`
4. Generate new output: `kubectl kustomize <service>/enterprise > new-enterprise.yaml`
5. Compare: `diff baseline-community.yaml new-community.yaml`
6. Compare: `diff baseline-enterprise.yaml new-enterprise.yaml`
7. Report success if both diffs are empty, failure otherwise

### Reflector Deployment

**Purpose**: Deploy Kubernetes Reflector as a managed service.

**Interface**: FluxCD HelmRelease resource

**Configuration**:
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: reflector
  namespace: reflector-system
spec:
  chart:
    spec:
      chart: reflector
      version: 7.1.288
      sourceRef:
        kind: HelmRepository
        name: emberstack
  values:
    rbac:
      enabled: true
```

**RBAC Permissions**:
- Read: secrets in flux-system namespace
- Write: secrets in allowed namespaces (cert-manager, metallb-system, etc.)
- Watch: secrets with reflection annotations

### OCI Credentials Consolidation Script

**Purpose**: Consolidate per-service OCI credentials into single source secret.

**Interface**:
```bash
consolidate-oci-creds.sh <customer> <cluster>
```

**Inputs**:
- Customer name
- Cluster name
- Existing per-service oci-creds.yaml files

**Outputs**:
- Single oci-creds.yaml in flux-system namespace with Reflector annotations
- Updated service kustomizations (removed oci-creds.yaml references)
- Deleted per-service oci-creds.yaml files

**Behavior**:
1. Read OCI credentials from any existing service oci-creds.yaml
2. Create flux-system/oci-creds.yaml with Reflector annotations
3. List all service namespaces requiring OCI access
4. Add namespace list to reflection-allowed-namespaces annotation
5. Encrypt with SOPS
6. Remove oci-creds.yaml from all service directories
7. Update service kustomizations to remove resource reference

## Data Models

### Base Kustomization Structure

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - source.yaml
  - helmrelease.yaml
secretGenerator:
  - name: <service>-values-base
    namespace: <service-namespace>
    type: Opaque
    files:
      - values.yaml=helm-values/values-vX.Y.Z.yaml
    options:
      disableNameSuffixHash: true
```

**Fields**:
- `resources`: List of YAML files to include (namespace, source, helmrelease)
- `secretGenerator`: Generates secret from base values file
- `secretGenerator.name`: Secret name referenced by HelmRelease
- `secretGenerator.namespace`: Target namespace for secret
- `secretGenerator.files`: Maps secret key to values file path
- `secretGenerator.options.disableNameSuffixHash`: Prevents Kustomize from adding hash suffix

### Enterprise Component Structure

```yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
resources:
  - ../../../global/enterprise/source.yaml
patches:
  # Remove community HelmRepository
  - target:
      kind: HelmRepository
      name: <community-repo-name>
    patch: |
      $patch: delete
      apiVersion: source.toolkit.fluxcd.io/v1
      kind: HelmRepository
      metadata:
        name: <community-repo-name>
  
  # Patch HelmRelease to use enterprise source
  - target:
      group: helm.toolkit.fluxcd.io
      version: v2
      kind: HelmRelease
      name: <service-name>
    patch: |
      - op: replace
        path: /spec/chart/spec/sourceRef/name
        value: opencenter-cloud

secretGenerator:
  - name: <service>-values-enterprise
    namespace: <service-namespace>
    type: Opaque
    files:
      - hardened-enterprise.yaml=helm-values/hardened-values-vX.Y.Z.yaml
    options:
      disableNameSuffixHash: true
```

**Fields**:
- `apiVersion`: Must be `kustomize.config.k8s.io/v1alpha1` for Components
- `kind`: Must be `Component`
- `resources`: Includes global enterprise source
- `patches[0]`: Deletes community HelmRepository using strategic merge patch
- `patches[1]`: Updates HelmRelease sourceRef using JSON patch
- `secretGenerator`: Generates secret from enterprise hardened values

### Thin Wrapper Structure

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../
components:
  - ../components/enterprise
```

**Fields**:
- `resources`: Includes parent directory (base kustomization)
- `components`: Includes enterprise component

This minimal structure provides backward compatibility by preserving the `<service>/enterprise` path that customer overlays reference.

### Reflector Source Secret Structure

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: oci-creds
  namespace: flux-system
  annotations:
    reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
    reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces: "cert-manager,metallb-system,kyverno,istio-system,observability,postgres-operator,rbac-system,vmware-system-csi,gateway-api,headlamp,keycloak"
type: kubernetes.io/dockerconfigjson
stringData:
  .dockerconfigjson: |
    {
      "auths": {
        "ghcr.io": {
          "username": "opencenter-bot",
          "password": "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        }
      }
    }
```

**Fields**:
- `metadata.name`: Must be `oci-creds` (referenced by global enterprise source)
- `metadata.namespace`: Must be `flux-system`
- `metadata.annotations`: Reflector configuration
- `reflector.v1.k8s.emberstack.com/reflection-allowed`: Enables reflection
- `reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces`: Explicit namespace list
- `type`: Must be `kubernetes.io/dockerconfigjson` for OCI registry auth
- `stringData[".dockerconfigjson"]`: Docker config JSON with registry credentials

### Service Type Classification

**Standard Helm Service**:
- Single HelmRelease
- Standard community/enterprise directories
- Single values file per edition
- Examples: cert-manager, metallb, headlamp, rbac-manager, postgres-operator, gateway-api, vsphere-csi

**Observability Service**:
- Located under `observability/` parent directory
- Shared namespace (`observability/namespace/`)
- Shared sources (`observability/sources/`)
- May have multiple values files
- Examples: kube-prometheus-stack, loki, opentelemetry-kube-stack

**Special Case Service**:
- Non-standard structure requiring custom migration logic
- OLM: Uses image patches instead of Helm, no HelmRelease
- Keycloak: Multi-component with 4 sub-components (postgres, operator, keycloak, oidc-rbac)

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Migration Output Equivalence

*For any* service that is migrated, generating output from the new structure should produce byte-identical YAML compared to the baseline output from the original structure, for both community and enterprise paths.

**Validates: Requirements 2.1, 2.2, 2.3**

### Property 2: Backward Compatibility Preservation

*For any* customer overlay that references a service path (community or enterprise), the overlay should continue to produce valid output after migration without requiring any modifications to the overlay configuration.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

### Property 3: Component Structure Consistency

*For any* migrated service, the enterprise component should be located at `components/enterprise/kustomization.yaml`, have `kind: Component`, include the global enterprise source, include patches for source replacement, and include a secretGenerator for enterprise values.

**Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 4.6**

### Property 4: No Configuration Duplication

*For any* migrated service, the base secretGenerator configuration should appear exactly once in the base kustomization, and should not be duplicated in the enterprise component or thin wrapper.

**Validates: Requirements 4.7, 10.3**

### Property 5: Secret Replication Consistency

*For any* namespace in the Reflector allowed list, when the source oci-creds secret exists in flux-system, a replicated secret with identical content should exist in that namespace with the same name.

**Validates: Requirements 7.1, 7.4**

### Property 6: Secret Replication Timeliness

*For any* update to the source oci-creds secret in flux-system, all replicated secrets in allowed namespaces should be updated to match within 60 seconds.

**Validates: Requirements 7.2**

### Property 7: OCI Credentials Consolidation

*For any* cluster after OCI consolidation, exactly one oci-creds.yaml file should exist in the flux-system namespace, and zero oci-creds.yaml files should exist in service directories.

**Validates: Requirements 6.1, 6.6, 10.2**

### Property 8: Version Upgrade Touchpoints

*For any* service after migration, upgrading the service version should require modifying exactly 2 files: the base values filename and the enterprise values filename (if enterprise exists).

**Validates: Requirements 11.1, 11.2, 11.3**

### Property 9: Rollback Completeness

*For any* migrated service, performing a git revert should restore the original community/enterprise directory structure with all original files intact and customer overlays continuing to work.

**Validates: Requirements 15.1, 15.2, 15.3, 15.4**

### Property 10: Global Enterprise Source Configuration

*For any* deployment, the global enterprise HelmRepository should be named `opencenter-cloud`, reference `oci-creds` secret in flux-system namespace, use type `oci`, and have URL `oci://ghcr.io/opencenter-cloud`.

**Validates: Requirements 8.1, 8.2, 8.3, 8.4**

### Property 11: Reflector Namespace Replication

*For any* new namespace added to the reflection-allowed-namespaces annotation, the Reflector should replicate the oci-creds secret to that namespace.

**Validates: Requirements 7.3**

### Property 12: File Count Reduction

*For all* services after migration with thin wrappers, the total count of edition-specific files should be 22 (reduced from 55), representing a 60% reduction.

**Validates: Requirements 10.1**

## Error Handling

### Migration Failures

**Validation Failure**: If output equivalence validation fails, the migration script should:
1. Print the diff showing differences between baseline and new output
2. Exit with non-zero status code
3. Leave the repository in a state where `git revert` can restore original structure
4. Log the specific files that differ

**Missing Files**: If expected files (namespace.yaml, helmrelease.yaml, etc.) are missing, the migration script should:
1. Print error message identifying missing file
2. Exit with non-zero status code before making any changes
3. Suggest checking service structure

**Invalid Service Type**: If service structure doesn't match any known pattern, the migration script should:
1. Print error message with detected structure
2. Suggest manual migration or script enhancement
3. Exit with non-zero status code

### Reflector Failures

**Pod Not Running**: If Reflector pod is not running:
1. Check pod status: `kubectl get pods -n reflector-system`
2. Check pod logs: `kubectl logs -n reflector-system deploy/reflector`
3. Check HelmRelease status: `kubectl get helmrelease -n reflector-system reflector`
4. Alert platform team if pod is crash-looping

**Replication Lag**: If secret replication takes longer than 60 seconds:
1. Check Reflector logs for errors
2. Verify source secret has correct annotations
3. Verify target namespace exists
4. Verify target namespace is in allowed list
5. Alert if lag exceeds 5 minutes

**Replication Failure**: If secret is not replicated to target namespace:
1. Verify source secret exists: `kubectl get secret oci-creds -n flux-system`
2. Verify Reflector annotations are correct
3. Verify target namespace is in allowed list
4. Check Reflector RBAC permissions
5. Check Reflector logs for permission errors

### OCI Credentials Failures

**Authentication Failure**: If HelmRelease fails with authentication error:
1. Verify oci-creds secret exists in service namespace
2. Verify secret content is valid Docker config JSON
3. Verify credentials are not expired
4. Verify OCI registry is accessible
5. Rotate credentials if compromised

**Missing Secret**: If oci-creds secret is missing from service namespace:
1. Verify source secret exists in flux-system
2. Verify Reflector is running
3. Verify namespace is in allowed list
4. Manually create secret as temporary workaround
5. Investigate Reflector logs

## Testing Strategy

### Unit Tests

Unit tests validate specific examples, edge cases, and error conditions:

**Migration Script Tests**:
- Test migration of standard Helm service with single values file
- Test migration of observability service with shared namespace
- Test migration of service with multiple values files
- Test error handling for missing files
- Test error handling for invalid service structure

**Validation Script Tests**:
- Test validation success when outputs are identical
- Test validation failure when outputs differ
- Test baseline generation for community path
- Test baseline generation for enterprise path

**OCI Consolidation Script Tests**:
- Test consolidation with 11 service directories
- Test namespace list generation
- Test removal of per-service files
- Test kustomization update to remove resource reference

### Property-Based Tests

Property-based tests verify universal properties across all inputs. Each test should run a minimum of 100 iterations.

**Property Test 1: Migration Output Equivalence**
- **Tag**: Feature: kustomize-components-migration, Property 1: Migration Output Equivalence
- Generate random service structures (varying number of values files, namespace locations)
- Migrate each service
- Verify output equivalence for both community and enterprise paths
- Validates: Property 1

**Property Test 2: Backward Compatibility Preservation**
- **Tag**: Feature: kustomize-components-migration, Property 2: Backward Compatibility Preservation
- Generate random customer overlays referencing service paths
- Migrate services
- Verify overlays produce valid output without modification
- Validates: Property 2

**Property Test 3: No Configuration Duplication**
- **Tag**: Feature: kustomize-components-migration, Property 4: No Configuration Duplication
- For any migrated service, parse base kustomization and component
- Verify base secretGenerator appears exactly once
- Verify no duplication in component or wrapper
- Validates: Property 4

**Property Test 4: Secret Replication Consistency**
- **Tag**: Feature: kustomize-components-migration, Property 5: Secret Replication Consistency
- Generate random namespace lists
- Create source secret with namespace list annotation
- Verify replicated secret exists in each namespace with identical content
- Validates: Property 5

**Property Test 5: OCI Credentials Consolidation**
- **Tag**: Feature: kustomize-components-migration, Property 7: OCI Credentials Consolidation
- Generate random cluster structures with per-service oci-creds files
- Run consolidation
- Verify exactly one oci-creds.yaml in flux-system
- Verify zero oci-creds.yaml in service directories
- Validates: Property 7

### Integration Tests

Integration tests verify end-to-end workflows:

**Full Service Migration**:
1. Create test service with community/enterprise directories
2. Run migration script
3. Run validation script
4. Verify success
5. Deploy to test cluster
6. Verify HelmRelease reconciles successfully

**Reflector Deployment and Replication**:
1. Deploy Reflector to test cluster
2. Create source secret in flux-system with annotations
3. Wait for replication
4. Verify secrets exist in all target namespaces
5. Update source secret
6. Verify replicated secrets update within 60 seconds

**OCI Credentials Consolidation**:
1. Create test cluster overlay with per-service oci-creds files
2. Run consolidation script
3. Verify single source secret created
4. Verify per-service files removed
5. Deploy to test cluster
6. Verify all HelmReleases can authenticate to OCI registry

### Manual Validation

Manual validation for aspects not easily automated:

**Visual Inspection**:
- Review migrated service structure for correctness
- Verify component patches target correct resources
- Verify thin wrapper includes correct paths

**Documentation Review**:
- Verify service template reflects new pattern
- Verify guides are accurate and complete
- Verify examples work as documented

**Production Deployment**:
- Deploy pilot service (cert-manager) to non-production cluster
- Monitor for issues over 24-48 hours
- Verify no regressions in functionality
- Proceed with remaining services only after pilot success

## Implementation Notes

### Service-Specific Variations

**Istio**: Has multiple sub-components (base, istiod) with shared sources. Migration should handle sub-component structure.

**Kyverno**: Has two sub-components (policy-engine, default-ruleset). The policy-engine follows standard pattern. Contains copy-paste bug (metallb metadata) that should be fixed during migration.

**Keycloak**: Has four sub-components (postgres, operator, keycloak, oidc-rbac). Each sub-component may need individual migration or may be treated as a single unit.

**OLM**: Uses image patches instead of Helm. No HelmRelease exists. Migration should handle image patch pattern.

**Observability Services**: Share namespace and sources at parent level. Migration should preserve shared resources and only migrate service-specific kustomizations.

### Migration Order

The migration should follow this order to minimize risk:

1. **Pilot (cert-manager)**: Standard service, well-understood, low risk
2. **Standard Services**: metallb, headlamp, rbac-manager, postgres-operator, gateway-api, vsphere-csi
3. **Kyverno**: Fix copy-paste bug during migration
4. **Istio**: Handle multi-component structure
5. **Observability Services**: Handle shared namespace and sources
6. **OLM**: Handle non-Helm pattern
7. **Keycloak**: Handle complex multi-component structure

### Reflector Deployment Timing

Reflector should be deployed early (parallel with Phase 1-2 service migrations) so that OCI consolidation can begin as soon as multiple services are migrated. This allows testing of the Reflector pattern while service migrations are ongoing.

### Thin Wrapper Removal

Thin wrappers provide backward compatibility but add one file per service. In the future, after all customer overlays are updated to reference service roots directly, thin wrappers can be removed to achieve the final file count of 11 files (from original 55).

This is optional and should only be done after coordinating with all customers to update their overlay paths.

### SOPS Encryption

All oci-creds.yaml files must be encrypted with SOPS before committing. The consolidation script should handle encryption automatically:

```bash
sops -e -i <customer>/applications/overlays/<cluster>/flux-system/oci-creds.yaml
```

### Validation Automation

Validation should be automated in CI/CD pipeline:
1. Run validation script for each migrated service
2. Fail pipeline if validation fails
3. Require manual approval before merging migration PRs
4. Run integration tests in test cluster before production deployment
