[bastion]
${address_bastion}

[masters]
%{ for master in master_nodes ~}
${master.access_ip_v4}
%{endfor ~}

[workers]
%{ for worker in worker_nodes ~}
${worker.access_ip_v4}
%{endfor ~}

%{if address_bastion == ""~}
[masters:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o IdentityFile=./id_rsa -o UserKnownHostsFile=/dev/null'

[workers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o IdentityFile=./id_rsa -o UserKnownHostsFile=/dev/null'
%{endif~}

%{if address_bastion != ""~}
[masters:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o IdentityFile=./id_rsa -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -o IdentityFile=./id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p -q ${ssh_user}@${address_bastion}"'

[workers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o IdentityFile=./id_rsa -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -o IdentityFile=./id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p -q ${ssh_user}@${address_bastion}"'
%{endif~}




[all:vars]
ansible_user="${ssh_user}"
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=./id_rsa
ansible_ssh_extra_args='-o StrictHostKeyChecking=no'
