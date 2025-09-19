resource "local_file" "calico_values" {
  content = templatefile("${path.module}/calico-values.tpl",
    {
      cni_iface                        = var.cni_iface
      subnet_pods                      = var.subnet_pods
      subnet_services                  = var.subnet_services
      windows_dataplane                = var.windows_dataplane
      calico_nat_outgoing              = var.calico_nat_outgoing == true ? "Enabled" : "Disabled"
      calico_encapsulation_type        = var.calico_encapsulation_type
      calico_interface_autodetect      = var.calico_interface_autodetect
      calico_interface_autodetect_cidr = var.calico_interface_autodetect_cidr
      calico_version                   = var.calico_version
      k8s_internal_ip                 = var.k8s_internal_ip
      k8s_api_port                     = var.k8s_api_port
  })

  filename = "${path.root}/../../../applications/overlays/${var.cluster_name}/services/calico/helm-values/override_values.yaml"
  file_permission = "0644"

}