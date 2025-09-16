locals {
  bgp_config = <<EOT
peers:
%{for peer in keys(var.metallb_bgp_peers)~}
- peer-address: ${peer}
  peer-asn: ${var.metallb_bgp_peers[peer]["peer_asn"]}
  my-asn: ${var.metallb_bgp_peers[peer]["my_asn"]}
%{endfor~}
address-pools:
%{for pool_name in keys(var.metallb_bgp_address_pools)~}
- name: ${pool_name}
  protocol: bgp
  addresses:
  - ${var.metallb_bgp_address_pools[pool_name]["address_pool"]}
%{if contains(keys(var.metallb_bgp_address_pools[pool_name]), "auto_assign")~}
  auto-assign: ${var.metallb_bgp_address_pools[pool_name]["auto_assign"]}
%{endif~}
  bgp-advertisements:
  - aggregation-length: ${var.metallb_bgp_address_pools[pool_name]["bgp_advertisements_aggregation_length_local"]}
    localpref: ${var.metallb_bgp_address_pools[pool_name]["bgp_advertisements_localpref"]}
    communities:
    - no-advertise
  - aggregation-length: ${var.metallb_bgp_address_pools[pool_name]["bgp_advertisements_aggregation_length_generate"]}
%{endfor~}
bgp-communities:
  no-advertise: 65535:65282
EOT
}
