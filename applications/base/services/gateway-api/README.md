# Envoy Gateway API – Base Configuration

This directory contains the **base manifests** for deploying the [Envoy Gateway](https://gateway.envoyproxy.io/) as a managed service.
It is intended to be consumed by **cluster repositories** as a remote base, with the option to provide cluster-specific overrides.

- `namespace.yaml` - Defines the `envoy-gateway-system` namespace.
- `envoyproxy-source.yaml` - Defines the helm repository to install `envoy-gateway-api`.
- `helmrelease.yaml` - FluxCD `HelmRelease` for deploying Envoy Gateway from the configured Helm repository.
- `helm-values/hardened_values_v0.0.0.yaml` - Default “hardened” baseline values.
  These are designed as production-ready defaults.
- `kustomization.yaml` – Wires together the namespace, HelmRelease, and default values.
  Also generates a `Secret` (`envoy-gateway-api-values-base`) from the hardened values.

## Usage in a Cluster Repository

A cluster repository should reference this base using a FluxCD `Kustomization` that points to the GitRepository containing this repo.

Example `Kustomization` in the cluster repo:

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: envoy-gateway-api-base
  namespace: flux-system
spec:
  interval: 1m
  prune: true
  sourceRef:
    kind: GitRepository
    name: opencenter-gateway-api #<= its the base flux gitrepository resource
    namespace: flux-system
  path: base/services/gateway-api
  targetNamespace: envoy-gateway-system
  wait: true
```

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: opencenter-gateway-api
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/pratik705/opencenter1.git
  ref:
    branch: main
```

This will deploy Envoy Gateway with the default hardened configuration.

## Overriding Values

User can provide **cluster-specific overrides** without modifying this base.

1. Create a folder in the cluster repo:

   ```
   applications/overlays/<cluster>/services/gateway-api/helm-values/
   └── override_values.yaml
   ```

2. Reference both hardened values (from this base) and local overrides in a `Secret` (via `secretGenerator` or plain YAML). Example in cluster repo:

```yaml
namespace: envoy-gateway-system

secretGenerator:
  - name: envoy-gateway-api-values-override
    namespace: envoy-gateway-system
    type: Opaque
    files:
      - override.yaml=helm-values/override_values.yaml
    options:
      disableNameSuffixHash: true
```

3. The base HelmRelease is configured with `valuesFrom` so both hardened and override values are merged.
   - Hardened defaults provide a secure baseline.
   - Overrides take precedence when defined.

## Example Override (cluster repo)

`helm-values/override_values.yaml`:

```yaml
replicaCount: 2
```

This overrides replica count and service configuration while keeping the rest of the hardened defaults intact.

## Adding Additional Resources

User may also add **extra Kubernetes resources** (NetworkPolicies, ConfigMaps, etc.) alongside the override values.
These will be applied together with the base and override.

Example in cluster repo:

```
applications/overlays/<cluster>/services/gateway-api/
├── helm-values/
│   └── override_values.yaml
├── networkpolicy.yaml
├── opencenter-source.yaml
└── kustomization.yaml
```

`kustomization.yaml:`

```yaml
namespace: envoy-gateway-system

resources:
  - "./opencenter-source.yaml"
  - "./networkpolicy.yaml"

secretGenerator:
  - name: envoy-gateway-api-values-override
    namespace: envoy-gateway-system
    type: Opaque
    files:
      - override.yaml=helm-values/override_values.yaml
    options:
      disableNameSuffixHash: true
```
