variable "deploy_cluster" {
  type    = bool
  default = false
}

variable "calico_nat_outgoing" {
  type    = bool
  default = true
}

variable "calico_interface_autodetect" {
  type    = string
  default = "first-found"
}

variable "calico_interface_autodetect_cidr" {
  type    = string
  default = ""
}

variable "calico_encapsulation_type" {
  type    = string
  default = "VXLAN"
}

variable "calico_version" {
  type    = string
  default = "3.29.4" # adjust as needed
}

variable "chart_name" {
  type    = string
  default = "calico"
}

variable "chart_namespace" {
  type    = string
  default = "tigera-operator"
}

variable "chart_repo" {
  type    = string
  default = "https://docs.tigera.io/calico/charts"
}

variable "cluster_name" {
  type    = string
  default = ""
}

variable "cni_iface" {
  type    = string
  default = ""
}

variable "k8s_api_port" {
  type    = number
  default = 6443
}

variable "k8s_internal_ip" {
  type        = string
  default     = ""
  description = "The internal IP address used as a VIP for the kube-apiserver."
}

variable "subnet_nodes" {
  type    = string
  default = "10.0.0.0/22"
}

variable "subnet_pods" {
  type    = string
  default = "10.42.0.0/16"
}

variable "subnet_services" {
  type    = string
  default = "10.43.0.0/16"
}

variable "windows_dataplane" {
  type    = string
  default = ""
}