# Adding Windows Worker nodes to an openCenter Kubernetes cluster

## Requirements
* A working openCenter cluster with at least 1 linux worker node.
* Windows servers added to the oc_windows_workers group in the ansible inventory. Must be accessible via `SSH`. Yes SSH.
* 


The main.tf file will require additional local variables and variables passed to the openTofu modules.

| Option | Default | Type | Description |
| :------- | :------: | :-------: | -------: |
| image_id_windows | "" | string | Glance image ID for Windows Server |
| flavor_worker_windows | "" | string | Openstack Flavor name |
| windows_user | "Administrator" | string | Admin user for Windows Server |
| windows_admin_password | "" | String | Password for Admin user of Windows Server|
| worker_node_bfv_size_windows | 0 | number | Volume Size of root disk for Windows Server |
| worker_node_bfv_type_windows | "local" |  string | Volume type. Can be either "local" or "volume" |


The Openstack Nova module needs to get the values passed

```

source = "github.com/rackerlabs/openCenter-gitops-base.git//iac/cloud/openstack/openstack-nova?ref=main" {
    ...
    size_worker_windows = {
        count  = local.worker_count_windows
        flavor = local.flavor_worker_windows
    }
    windows_admin_password  = local.windows_admin_password
    windows_user  = local.windows_user
    worker_node_bfv_type_windows = local.worker_node_bfv_type_windows
    worker_node_bfv_size_windows = local.worker_node_bfv_size_windows
}
```

There is an ansible collection in `github.com/rackerlabs/opencenter-windows.git` that can be used to configure the windows nodes as workers and have them join the cluster.

Set the collections path to the local cluster inventory file.

```bash

source venv/bin/activate
export ANSIBLE_COLLECTIONS_PATHS=${PWD}/inventory/
export ANSIBLE_INVENTORY=${PWD}/inventory/inventory.yaml

 ```

requirements.yml

```yaml
---
collections:
  - name: https://github.com/rackerlabs/opencenter-windows.git
    type: git
    version: main
```

Install the collection

```bash
ansible-galaxy collection install -r requirements.yml
```

windows-worker.yaml

```yaml
- name: Join Windows to Kubernetes cluster
  hosts: oc_windows_nodes
  gather_facts: yes
  collections:
    - rackerlabs.opencenter_windows_workers
  tasks:
    - name: Gather variables for each operating system
      ansible.builtin.import_role:
        name: kubespray/roles/kubespray_defaults

    - name: Setup win-containerd
      ansible.builtin.include_role:
        name: win-containerd

    - name: Setup win-kubeadm
      ansible.builtin.include_role:
        name: win-kubeadm
```

`ansible-playbook windows-workers.yaml`

## Post Join steps
Taint the nodes to avoid confusing the scheduler
`kubectl taint node mig-dev-win0 node.kubernetes.io/os=windows:NoSchedule`


Once Calico has been deployed via the Tigera Operator the IPAM Config must get patched.

`kubectl patch ipamconfigurations default --type merge --patch='{"spec": {"strictAffinity": true}}'`

