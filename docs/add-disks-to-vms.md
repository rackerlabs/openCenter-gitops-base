Maintenance objective:
Add a 100GB disk to each of the worker nodes.

 Departments involved: RPC support, RPC Manage Kubernetes SME's 
 Owning department: RPC support, RPC Managed Kubernetes SME's 
 Amount of time estimated for maintenance: 4 hours

--------------------------------------------------------------------------------
 Maintenance Steps:
--------------------------------------------------------------------------------

## Get things ready

1 - Setup the environment to work with the cluster

    * Credentials are stored in passwordsafe

```
cd /etc/openCenter/infrastructure/clusters/prosys_test
source venv/bin/activate
export BIN=${PWD}/.bin
export PATH=${BIN}:${PATH}
export ANSIBLE_INVENTORY=${PWD}/inventory/inventory.yaml
export KUBECONFIG=${PWD}/kubeconfig.yaml
export AWS_ACCESS_KEY_ID=<REPLACE ME>
export AWS_SECRET_ACCESS_KEY=<REPLACE ME>
export TF_VAR_os_application_credential_id='<REAPLCE ME>'
export TF_VAR_os_application_credential_secret="<REPLACE ME>"

```

2 - Verify the cluster state.
    
    * If there are changes in the plan review them first and work through any potential blockers for the maintenance.
  
```bash
# terraform plan
...
module.kubespray-cluster.null_resource.run_kubespray[0]: Refreshing state... [id=2694448614732380735]
module.kubespray-cluster.null_resource.copy_and_update_kubeconfig: Refreshing state... [id=812292398106547937]

No changes. Your infrastructure matches the configuration.

# kubectl get nodes
NAME              STATUS   ROLES           AGE   VERSION
prosys-prod-cp0   Ready    control-plane   31d   v1.32.8
prosys-prod-cp1   Ready    control-plane   31d   v1.32.8
prosys-prod-cp2   Ready    control-plane   31d   v1.32.8
prosys-prod-wn0   Ready    <none>          31d   v1.32.8
prosys-prod-wn1   Ready    <none>          31d   v1.32.8
prosys-prod-wn2   Ready    <none>          31d   v1.32.8
prosys-prod-wn3   Ready    <none>          31d   v1.32.8
prosys-prod-wn4   Ready    <none>          30d   v1.32.8


```

3 - Update the main.tf with the desired additional block devices

* There is a section to be added to the locals variables and another to the openstack-nova module.

**locals section**
```h
  additional_block_devices_worker = [
    {
      source_type           = "blank"
      volume_size           = 20
      volume_type           = "Performance"
      boot_index            = -1
      destination_type      = "volume"
      delete_on_termination = true
      mountpoint            = "/var/lib/longhorn"
      filesystem            = "ext4"
      label                 = "longhorn-vol"
    },
  ]
```

**module "openstack-nova"**

```
module "openstack-nova" {
  source                          = "github.com/rackerlabs/openCenter-gitops-base.git//iac/cloud/openstack/openstack-nova?ref=multi-disk1"
  availability_zone               = local.availability_zone
  additional_block_devices_worker = local.additional_block_devices_worker <---- Add this line


```


4 - Verify the plan

* If we run `terraform plan` we can review the configuration updates to be made. If we were to apply the changes it would replace all of the worker nodes at the same time which would break the cluster. We will need to use targeted apply to replace one node at a time and add it back to the cluster.


-----------------------

## Apply the changes

```bash
# kubectl get nodes
NAME              STATUS   ROLES           AGE   VERSION
prosys-prod-cp0   Ready    control-plane   31d   v1.32.8
prosys-prod-cp1   Ready    control-plane   31d   v1.32.8
prosys-prod-cp2   Ready    control-plane   31d   v1.32.8
prosys-prod-wn0   Ready    <none>          31d   v1.32.8
prosys-prod-wn1   Ready    <none>          31d   v1.32.8
prosys-prod-wn2   Ready    <none>          31d   v1.32.8
prosys-prod-wn3   Ready    <none>          31d   v1.32.8
prosys-prod-wn4   Ready    <none>          30d   v1.32.8
```

We will target one worker node at a time starting with the last one.

1 - Remove the node from the cluster

```
cd kubespray
ansible-playbook playbooks/facts.yml -b
ansible-playbook -b playbooks/remove_node.yml -e node=prosys-prod-wn4
```

2 - Apply the change only targeting the single node

```
terraform apply -target 'module.openstack-nova.module.node_worker.openstack_compute_instance_v2.node[4]'

Apply complete! Resources: 3 added, 0 changed, 1 destroyed.

```

3 - Get the node ready

Apply hardening
```
# ansible-playbook ./inventory/os_hardening_playbook.yml -b --become-user=root --limit=prosys-prod-wn4

```

4 - Find the resulting disk configuration and set it in the group vars

```
# ansible prosys-prod-wn4 -m shell -a 'fdisk -l' -b

prosys-prod-wn4 | CHANGED | rc=0 >>
Disk /dev/vda: 100 GiB, 107372085248 bytes, 209711104 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: A49C7288-9CD0-4F90-8F06-1C713F260C8C

Device       Start       End   Sectors  Size Type
/dev/vda1  2099200 209711070 207611871   99G Linux filesystem
/dev/vda14    2048     10239      8192    4M BIOS boot
/dev/vda15   10240    227327    217088  106M EFI System
/dev/vda16  227328   2097152   1869825  913M Linux extended boot

Partition table entries are not in disk order.


Disk /dev/vdb: 64 GiB, 68719476736 bytes, 134217728 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/vdc: 4 GiB, 4294967296 bytes, 8388608 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/vdd: 20 GiB, 21472739328 bytes, 41938944 sectors <----- NEW DRIVE
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

4 - Update the disk configuration in the group_vars with the same information as above.

```yaml
# cat inventory/group_vars/oc_worker_nodes.yaml
disk_config:
  - device: "/dev/vdd" <----- set the device name accordingly
    label: "longhorn-vol"
    mountpoint: "/var/lib/longhorn"
    filesystem: "ext4"
    boot_index: 1
    volume_size: 20

```

5 - Run the playbook to configure the disks

```bash
ansible-playbook -b configure-disks.yaml --limit=prosys-prod-wn4
```

6 - Add the node to the cluster

```bash
cd kubespray
ansible-playbook playbooks/facts.yml -b
ansible-playbook -b playbooks/scale.yml -e "@../inventory/k8s_hardening.yml" --limit=prosys-prod-wn4

```

## Verify things are working

1 - Verify the node is in ready state

```bash
# kubectl get nodes
NAME              STATUS   ROLES           AGE   VERSION
prosys-prod-cp0   Ready    control-plane   31d   v1.32.8
prosys-prod-cp1   Ready    control-plane   31d   v1.32.8
prosys-prod-cp2   Ready    control-plane   31d   v1.32.8
prosys-prod-wn0   Ready    <none>          31d   v1.32.8
prosys-prod-wn1   Ready    <none>          31d   v1.32.8
prosys-prod-wn2   Ready    <none>          31d   v1.32.8
prosys-prod-wn3   Ready    <none>          31d   v1.32.8
prosys-prod-wn4   Ready    <none>          20m   v1.32.8 <---- New Node Ready
```


