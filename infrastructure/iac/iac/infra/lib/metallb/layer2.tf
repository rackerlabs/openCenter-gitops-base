locals {
  layer2_config = <<EOT
address-pools:
- name: default
  protocol: layer2
  addresses:
%{if var.metallb_cidr_prefix != ""~}
  - ${cidrhost(var.metallb_cidr_prefix, var.metallb_host_start)}-${cidrhost(var.metallb_cidr_prefix, var.metallb_host_start + var.metallb_host_count - 1)}
%{endif~}
EOT
}
