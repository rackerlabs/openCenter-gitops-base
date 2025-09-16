provider "helm" {
  kubernetes {
    config_path = "${path.root}/kube_config_cluster.yml"
  }
}

provider "kubernetes" {
  config_path = "${path.root}/kube_config_cluster.yml"
}

resource "kubernetes_namespace" "metallb" {
  metadata {
    name = "metallb-system"
  }
  depends_on = [var.module_depends_on]
}


resource "helm_release" "metallb" {
  name       = "metallb"
  repository = var.metallb_helm_repo
  chart      = "metallb"
  version    = var.metallb_helmchart_version
  namespace  = var.metallb_namespace

  dynamic "set" {
    for_each = var.metallb_helmchart_vals
    content {
      name  = set.value.name
      value = set.value.val
    }
  }

  depends_on = [var.module_depends_on]
}

resource "kubernetes_config_map" "config" {
  metadata {
    name      = "metallb-config"
    namespace = "metallb-system"
  }

  data = {
    config = var.metallb_protocol == "bgp" ? local.bgp_config : local.layer2_config
  }
  depends_on = [helm_release.metallb, kubernetes_namespace.metallb]
}

resource "openstack_networking_port_v2" "metallb" {
  name       = "k8s-metallb"
  count      = var.metallb_reserve_range ? 1 : 0
  network_id = var.network_id

  # Currently blocked due to OpenStack policy violation

  dynamic "fixed_ip" {
    for_each = range(var.metallb_host_count)

    content {
      subnet_id  = var.subnet_id
      ip_address = cidrhost(var.metallb_cidr_prefix, var.metallb_host_start + fixed_ip.value)
    }
  }
}
