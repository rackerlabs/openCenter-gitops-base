


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
├── applications/            # managed applications
│   ├── common/
│   │   ├── keycloak
    │   ├── ingress-controllers/
    │   ├── cert-manager/
    │   │   ├── kustomization.yaml
    │   └   └── helm-values.yaml
    │   │   ├── kustomization.yaml
    │   └   └── helm-release.yaml
    │   ├── monitoring/
    │   └── logging/
│   ├── base/
│   │   ├── flux-system/
│   │   ├── sitecore/
│   │   ├── openstack/
│   │   │   └── base   # /etc/genestack/
│   │   ├── managedServices/
│   │   └── common/
│   ├── overlays/
│   │   ├── production/
│   │   │   ├── flux-system
│   │   │   └── kustomization.yaml
│   │   ├── staging/
│   └── └── development/
    ├── platform-services/             # Core Managed services base
    │   ├── ingress-controllers/
    │   ├── cert-manager/
    │   │   ├── kustomization.yaml
    │   └   └── helm-values.yaml
    │   │   ├── kustomization.yaml
    │   └   └── helm-release.yaml
    │   ├── monitoring/
    │   └── logging/
    └── policies/
        ├── network-policies/
        ├── pod-security-policies/
        └── rbac/
```



