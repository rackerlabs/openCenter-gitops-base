resource "openstack_lb_loadbalancer_v2" "k8s" {

  loadbalancer_provider = var.loadbalancer_provider
  # availability_zone     = var.availability_zone
  name                  = "${var.naming_prefix}k8s"
  vip_subnet_id         = var.subnet_id
  vip_address           = var.vrrp_ip
}

resource "openstack_lb_pool_v2" "k8s" {
  
  lb_method       = "SOURCE_IP"
  protocol        = "TCP"
  name            = "${var.naming_prefix}k8s"
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8s.id
}

resource "openstack_lb_pool_v2" "rke2" {
  count          = var.rke2_enable == false ? 0 : 1
  lb_method       = "SOURCE_IP"
  protocol        = "TCP"
  name            = "${var.naming_prefix}rke2"
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8s.id
}

resource "openstack_lb_monitor_v2" "k8s" {
  depends_on = [ openstack_lb_pool_v2.k8s ]
  delay       = 30
  max_retries = 3
  name        = "${var.naming_prefix}k8s"
  pool_id     = openstack_lb_pool_v2.k8s.id
  timeout     = 5
  type        = "TCP"
}

resource "openstack_lb_monitor_v2" "rke2" {
  count = var.rke2_enable == false ? 0 : 1
  depends_on = [ openstack_lb_pool_v2.rke2 ]
  delay       = 30
  max_retries = 3
  name        = "${var.naming_prefix}rke2"
  pool_id     = openstack_lb_pool_v2.rke2[0].id
  timeout     = 5
  type        = "TCP"
}


resource "openstack_lb_member_v2" "rke2" {
  depends_on = [ openstack_lb_pool_v2.rke2[0] ]
  count         = var.rke2_enable == false ? 0 : var.server_count
  address       = var.master_ips[count.index]
  name          = "${var.naming_prefix}${count.index}"
  pool_id       = openstack_lb_pool_v2.rke2[0].id
  subnet_id     = var.subnet_id
  protocol_port = var.rke_server_port
}

resource "openstack_lb_member_v2" "k8s" {
  depends_on = [ openstack_lb_pool_v2.k8s ]
  count         = var.server_count
  address       = var.master_ips[count.index]
  name          = "${var.naming_prefix}${count.index}"
  pool_id       = openstack_lb_pool_v2.k8s.id
  subnet_id     = var.subnet_id
  protocol_port = var.k8s_api_port
}

resource "openstack_lb_listener_v2" "k8s" {

  default_pool_id = openstack_lb_pool_v2.k8s.id
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8s.id
  name            = "${var.naming_prefix}k8s"
  protocol        = "TCP"
  protocol_port   = 443
}

resource "openstack_lb_listener_v2" "rke2_api" {
  count = var.rke2_enable == false ? 0 : 1
  default_pool_id = openstack_lb_pool_v2.k8s.id
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8s.id
  name            = "${var.naming_prefix}rke2-api"
  protocol        = "TCP"
  protocol_port   = var.k8s_api_port
}

resource "openstack_lb_listener_v2" "rke2_server" {
  count = var.rke2_enable == false ? 0 : 1
  default_pool_id = openstack_lb_pool_v2.rke2[0].id
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8s.id
  name            = "${var.naming_prefix}rke2-server"
  protocol        = "TCP"
  protocol_port   = var.rke_server_port
}

resource "openstack_networking_floatingip_v2" "k8s" {
  count   = var.floatingip_pool == "" ? 0 : 1
  pool    = var.floatingip_pool
  port_id = openstack_lb_loadbalancer_v2.k8s.vip_port_id
}
