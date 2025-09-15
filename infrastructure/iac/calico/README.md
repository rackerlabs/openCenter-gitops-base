Calico

The Calico IaC module takes inputs to generate the Calico Operator Helm values file.
filename: cni-values.yaml


| Key | Type | Default | Description |
| --- | --- | --- | --- |
| cni_iface | string | ""  | Interface detection based on interfaces that match the given string. When calico_interface_autodetect="interface" |
| calico_interface_autodetect | string | "first-found" | Provides configuration options for auto-detecting node addresses. "first-found", "cidr", "interface" |
| calico_interface_autodetect_cidr | string | ""  | CIDRS enables IP auto-detection based on which addresses on the nodes are within one of the provided CIDRs. When calico_interface_autodetect="cidr" |
| calico_encapsulation_type | string | "VXLAN" | Calico encapsulation type (IPIP, VXLAN, None) |
| calico_nat_outgoing | bool | true | NAT Outgoing specifies if NAT will be enabled or disabled for outgoing traffic. |
| calico_version | string | ""  | Version of Calico to deploy. Currently not used as the chart version is specified in the Helm install command. |
| windows_dataplane | string | ""  | WindowsDataplane is used to select the dataplane used for Windows nodes. If not specified, it is disabled and the operator will not render the Calico Windows nodes daemonset.  Set to "HNS" when using Windows nodes. |
| chart_name | string | "calico" | Name of the chart within the repository to install. |
| chart_namespace | string | "tigera-operator" | Namespace where the chart will be installed. |
| chart_repo | string | "https://docs.tigera.io/calico/charts" | URL of the Helm Chart repository. |
| k8s_api_port | number | 6443 | Port number for Kubernetes API server |
| k8s_internal_ip | string | ""  | The internal IP address used as a VIP for the kube-apiserver. Can be the vrrp_ip or control-plane\[0\] |
| subnet_nodes | string | "10.0.0.0/22" | CIDR for Openstack Network for nodes (VMs or Baremetal Server CIDR). |
| subnet_services | string | "10.43.0.0/16" | CIDR to use for Kubernetes services. |
| subnet_pods | string | "10.42.0.0/16" | CIDR to use for Kubernetes pods. |

The configuration options are unsed in the values file:

```
# imagePullSecrets is a special helm field which, when specified, creates a secret
# containing the pull secret which is used to pull all images deployed by this helm chart and the resulting operator.
# this field is a map where the key is the desired secret name and the value is the contents of the imagePullSecret.
#
# Example: --set-file imagePullSecrets.gcr=./pull-secret.json
imagePullSecrets: {}

installation:
  enabled: true
  kubernetesProvider: ""
  calicoNetwork:
    windowsDataplane: "${windows_dataplane}"
    nodeAddressAutodetectionV4:
%{ if calico_interface_autodetect == "interface" ~}
      interface: "${cni_iface}"
%{ endif ~}
%{ if calico_interface_autodetect == "cidr" ~}
      cidr: "${calico_interface_autodetect_cidr}"
%{ endif ~}
%{ if calico_interface_autodetect == "first-found" ~}
      firstFound: true
%{ endif ~}
    ipPools:
      - cidr: "${subnet_pods}"
        encapsulation: "${calico_encapsulation_type}"
        natOutgoing: ${calico_nat_outgoing}
  serviceCIDRs:
    - "${subnet_services}"

  # imagePullSecrets are configured on all images deployed by the tigera-operator.
  # secrets specified here must exist in the tigera-operator namespace; they won't be created by the operator or helm.
  # imagePullSecrets are a slice of LocalObjectReferences, which is the same format they appear as on deployments.
  #
  # Example: --set installation.imagePullSecrets[0].name=my-existing-secret
  imagePullSecrets: []

# apiServer configures the Calico API server, needed for interacting with
# the projectcalico.org/v3 suite of APIs.
apiServer:
  enabled: true

# goldmane configures the Calico Goldmane flow aggregator.
goldmane:
  enabled: true

# whisker configures the Calico Whisker observability UI.
whisker:
  enabled: true

defaultFelixConfiguration:
  enabled: false

certs:
  node:
    key:
    cert:
    commonName:
  typha:
    key:
    cert:
    commonName:
    caBundle:

# Whether or not the tigera/operator should manange CustomResourceDefinitions
# needed to run itself and Calico. If disabled, you must manage these resources out-of-band.
manageCRDs: true

# Resource requests and limits for the tigera/operator pod.
resources: {}

# Common labels for all resources created by this chart
additionalLabels: {}

# Tolerations for the tigera/operator pod.
tolerations:
- effect: NoExecute
  operator: Exists
- effect: NoSchedule
  operator: Exists

# NodeSelector for the tigera/operator pod.
nodeSelector:
  kubernetes.io/os: linux

# Affinity for the tigera/operator pod.
affinity: {}

# PriorityClassName for the tigera/operator pod.
priorityClassName: ""

# Custom annotations for the tigera/operator pod.
podAnnotations: {}

# Custom labels for the tigera/operator pod.
podLabels: {}

# Custom DNS configuration for the tigera/operator pod.
dnsConfig: {}
# Image and registry configuration for the tigera/operator pod.
tigeraOperator:
  image: tigera/operator
  version: v1.38.3
  registry: quay.io
calicoctl:
  image: docker.io/calico/ctl
  tag: v3.30.2

kubeletVolumePluginPath: /var/lib/kubelet

# Optionally configure the host and port used to access the Kubernetes API server.
kubernetesServiceEndpoint:
  host: "${k8s_internal_ip}"
  port: "${k8s_api_port}"



```