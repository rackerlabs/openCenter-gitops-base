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


# Optionally configure the host and port used to access the Kubernetes API server.
kubernetesServiceEndpoint:
  host: "${k8s_internal_ip}"
  port: "${k8s_api_port}"

