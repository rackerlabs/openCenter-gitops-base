resource "openstack_networking_network_v2" "network" {
  count          = var.vlan_id == "" ? 1 : 0
  name           = "${var.naming_prefix}k8s"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet" {
  count           = var.subnet_id == "" ? 1 : 0
  name            = "${var.naming_prefix}k8s"
  cidr            = var.subnet_nodes
  dns_nameservers = var.dns_nameservers
  ip_version      = 4
  network_id      = var.network_id == "" ? openstack_networking_network_v2.network[0].id : var.network_id

  allocation_pool {
    start = var.allocation_pool_start
    end   = var.allocation_pool_end
  }
}

resource "openstack_networking_router_v2" "router" {
  count = var.vlan_id == "" ? 1 : 0

  name                = "${var.naming_prefix}k8s"
  external_network_id = var.router_external_network_id
}

resource "openstack_networking_router_interface_v2" "router" {
  count = var.vlan_id == "" ? 1 : 0

  router_id = openstack_networking_router_v2.router[0].id
  subnet_id = var.subnet_id == "" ? openstack_networking_subnet_v2.subnet[0].id : var.subnet_id
}
