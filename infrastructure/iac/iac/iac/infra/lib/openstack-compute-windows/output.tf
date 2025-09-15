output "ips_to_names" {
  value = { for nodes in openstack_compute_instance_v2.node : nodes.access_ip_v4 => nodes.name }
}

output "server_count" {
  value = length(openstack_compute_instance_v2.node[*].access_ip_v4)
}

output "ips" {
  value = openstack_compute_instance_v2.node[*].access_ip_v4
}

output "ids" {
  value = openstack_compute_instance_v2.node[*].id
}

output "nodes" {
  value = openstack_compute_instance_v2.node[*]
}