
```
kubernetes-platform/
├── README.md
├── setup.sh  # This setups things that are needed but not commit.
├── infrastructure/
│   ├── clusters/
│   │   ├── production/
│   │   │   ├── inventory/
│   │   │   ├── cluster-config/
│   │   │   ├── id_rsa
│   │   │   ├── id_rsa.pub
│   │   │   ├── main.tf  # Reference github
│   │   │   ├── provider.tf
│   │   │   ├── variables.tf
│   │   │   ├── kubeconfig.yaml
│   │   │   └── kustomization.yaml
│   │   ├── staging/
│   │   │   ├── inventory/
│   │   │   ├── cluster-config/
│   │   │   ├── flux-system/
│   │   │   ├── id_rsa
│   │   │   ├── id_rsa.pub
│   │   │   ├── main.tf
│   │   │   ├── provider.tf
│   │   │   ├── variables.tf
│   │   │   ├── kubeconfig.yaml
│   │   │   └── kustomization.yaml
│   │   └── development/
│   ├── base/
│   │   ├── networking/
│   │   ├── security/
            └── policies/
                ├── network-policies/
                ├── pod-security-policies/
                └── rbac/
│   │   └── monitoring/
├── applications
│   ├── base
│   │   ├── genestack-sources
│   │   │   ├── genestack.yaml
│   │   │   ├── gitrepository-aggregator.yaml
│   │   │   ├── kustomization.yaml
│   │   │   └── openstack-helm.yaml
│   │   ├── managed-services
│   │   │   ├── cert-manager
│   │   │   │   └── placeholder.txt
│   │   │   ├── gateway-api
│   │   │   │   └── placeholder.txt
│   │   │   ├── ingress-nginx
│   │   │   │   └── placeholder.txt
│   │   │   ├── keycloak
│   │   │   │   └── placeholder.txt
│   │   │   ├── sealed-secrets
│   │   │   │   └── placeholder.txt
│   │   │   └── sources
│   │   │       ├── bitnami.yaml
│   │   │       ├── envoyproxy.yaml
│   │   │       ├── ingress-nginx.yaml
│   │   │       ├── jetstack.yaml
│   │   │       ├── kustomization.yaml
│   │   │       └── sealed-secrets.yaml
│   ├── overlays
│   │   ├── delta
│   │   │   ├── flux-system
│   │   │   │   ├── gotk-components.yaml
│   │   │   │   ├── gotk-sync.yaml
│   │   │   │   └── kustomization.yaml
│   │   │   ├── genestack
│   │   │   │   └── fluxcd
│   │   │   ├── kustomization.yaml
│   │   │   └── managed-services
│   │   │       ├── cert-manager
│   │   │       ├── fluxcd
│   │   │       ├── gateway
│   │   │       ├── gateway-api
│   │   │       ├── ingress-nginx
│   │   │       ├── keycloak
│   │   │       └── sealed-secrets
│   │   ├── dev
│   │   │   └── placeholder.txt
│   │   └── production
│   │       └── placeholder.txt
│   └── policies
│       ├── network-policies
│       │   └── placeholder.txt
│       ├── pod-security-policies
│       │   └── placeholder.txt
│       └── rbac
│           └── placeholder.txt
```
