
```
TODO: Templatize the overlays files to allow for setting cluster name dynamically
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
│   ├── overlays
│   │   ├── cluster-example
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
```
