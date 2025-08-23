
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
│   │   ├── genestack
│   │   │   └── placeholder.txt
│   │   └── managed-services
│   │       ├── cert-manager
│   │       ├── ingress-nginx
│   │       ├── keycloak
│   │       └── sealed-secrets
│   ├── overlays
│   │   ├── delta
│   │   │   ├── flux-system
│   │   │   ├── kustomization.yaml
│   │   │   └── managed-services
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
