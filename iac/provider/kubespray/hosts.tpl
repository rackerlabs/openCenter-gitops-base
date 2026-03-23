all:
  vars:
    cloud_name: "${cluster_name}"
    ansible_ssh_common_args: '-o IdentityFile=${ssh_key_path} -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -o IdentityFile=${ssh_key_path} -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p -q ${ssh_user}@${address_bastion}"'
    ansible_user: "${ssh_user}"
    ansible_python_interpreter: /usr/bin/python3
    k8s_internal_ip: ${k8s_internal_ip}
    kube_version: ${kubernetes_version}
  children:
    k8s_cluster:
      vars:
        cluster_name: cluster.local
%{ if k8s_api_ip != k8s_internal_ip ~}
        supplementary_addresses_in_ssl_keys: [${k8s_api_ip},k8s.${dns_zone_name},${k8s_internal_ip}]
%{ else ~}
        supplementary_addresses_in_ssl_keys: [k8s.${dns_zone_name},${k8s_internal_ip}]
%{ endif ~}
      children:
        kube_control_plane:
          children:
            oc_controlplane_nodes: null     
        etcd:
          children:
            oc_controlplane_nodes: null
        kube_node:
          children:
            oc_worker_nodes: null

oc_controlplane_nodes:
%{ if length(controlplane_node_labels) > 0 ~}
  vars:
    node_labels:
%{ for key, value in controlplane_node_labels ~}
      "${key}": "${value}"
%{ endfor ~}
%{ endif ~}
  hosts:
%{ for master in master_nodes ~}
    ${master.name}:
      ansible_host: ${master.access_ip_v4}
%{endfor ~}

oc_worker_nodes:
%{ if length(worker_node_labels) > 0 ~}
  vars:
    node_labels:
%{ for key, value in worker_node_labels ~}
      "${key}": "${value}"
%{ endfor ~}
%{ endif ~}
  hosts:
%{ for worker in worker_nodes ~}
    ${worker.name}:
      ansible_host: ${worker.access_ip_v4}
%{endfor ~}

%{~ if length(windows_nodes) > 0 }
oc_windows_nodes:
  hosts:
%{ for worker in windows_nodes ~}
    ${worker.name}:
      ansible_host: ${worker.access_ip_v4}
%{endfor ~}
  vars:
    ansible_user: Administrator
    ansible_connection: ssh
    ansible_shell_type: cmd
%{endif}