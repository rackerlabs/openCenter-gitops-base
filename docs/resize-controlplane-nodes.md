# KB00002 - Resize the control-plane nodes in Openstack Fex using IaC

---

## Article Information

**Article ID:** KB00002  
**Last Modified:** 2025-09-30  
**Author:** Platform Engineering Team  
**Status:** Published  
**Category:** Kubernetes/IAC/Resource Management 
**Tags:** `kubernetes`, `resource-management`, `resize`, `control-plane`
**Visibility:** Public  

---

## Issue Summary

**How to resize the Kubernetes Control Plane nodes using Openstack Flex and Infrastructure as Code**

---

## Environment

**Product:** openCenter		
**Version(s) Affected:** Kubernetes 1.19+ 	
**Operating System:** Linux (Ubuntu 24.04)  
**Architecture:** x86_64/ARM64  
**Component:** Openstack Flex Instances 		
**Configuration:** Control Plane instance flavor  

### Additional Environment Details


---

## Symptoms

Users experience one or more of the following scenarios:

- **Primary Symptom:** Kubernetes Control Plane nodes have low resources available.
- **Error Messages:** 

  ```
  Pods get OOMKilled
  Kubelet under MemoryPressure
  0/2 nodes are available: 1 Insufficient memory, 1 node(s) had taints that the pod didn't tolerate.
    
  ```
- **When it Occurs:** When nodes are deployed with limited resources. For example, smaller than 8GB of RAM.
- **Impact:** App restarts and poor user experience due to control plane lag.

---

## Root Cause

Kubernetes running openCenter needs at least 8GB of RAM to operate as per best practices.

---

## Resolution

### Prerequisites
- [ ] Customer Openstack Flex Application Credentials exported from password safe
- [ ] Customer AWS S3 access credentials exported from password safe
- [ ] kubectl configured with admin kubeconfig from password safe
- [ ] cluster `.bin` directory added to session $PATH
- [ ] Activate cluster virtual environment
- [ ] Set the ANSIBLE_INVENTORY environment variable

### Solution Steps

#### Option 1: Resize in place

1. **Log into openCenter-prod**

```bash
# ssh ubuntu@63.131.145.180
```
2. **Set up the environment variables and cluster access.**

```bash
cd /etc/openCenter/5918681-computacenter-united-states-inc/infrastructure/clusters/dev

# Export Openstack Flex Application Credentials
export TF_VAR_os_application_credential_id="APP-CRED-ID"
export TF_VAR_os_application_credential_secret="SUPER-SECRET"

# Kubectl configured with admin privileges
export KUBECONFIG=${PWD}/kubeconfig.yaml

# Export the .bin directory to path
export BIN=${PWD}/.bin
export PATH=${BIN}:${PATH}

# Activate cluster virtual environment
source venv/bin/activate

# Set the ansible inventory
export ANSIBLE_INVENTORY=${PWD}/inventory/inventory.yaml
```

3. **Verify Terraform state**

We first need to verify that Terraform is in a good state and not expecting to make any changes. If any are in the plan, see about consolidating them or applying them if safe.

```bash
#  terraform plan
module.kubespray-cluster.local_file.os_hardening_playbook[0]: Refreshing state... [id=6f058510853569692b2199d4deaa21d2f21b3614]
module.kubespray-cluster.null_resource.clone_kubespray[0]: Refreshing state... [id=7314489616640206576]
module.openstack-nova.module.user_data_bastion.data.cloudinit_config.config: Reading...
...

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.

``` 
   
4. **Verify cluster state**

We first need to verify that the cluster control-plane nodes are in `Ready` state. If they are `NotReady` any ansible playbooks or changes may fail.

```bash
# kubectl get nodes
NAME                  STATUS   ROLES           AGE   VERSION
prosys.dev.dfw3-cp0   Ready    control-plane   13d   v1.32.8
prosys.dev.dfw3-cp1   Ready    control-plane   13d   v1.32.8
prosys.dev.dfw3-cp2   Ready    control-plane   13d   v1.32.8
prosys.dev.dfw3-wn0   Ready    <none>          13d   v1.32.8
prosys.dev.dfw3-wn1   Ready    <none>          13d   v1.32.8
prosys.dev.dfw3-wn2   Ready    <none>          13d   v1.32.8
prosys.dev.dfw3-wn3   Ready    <none>          13d   v1.32.8

``` 
5. **Record cluster utilization**

	Record the resource utilization before making changes to then compare once the nodes have been resized.
	
```
kubectl top nodes
NAME                  CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
prosys.dev.dfw3-cp0   151m         4%     2744Mi          90%
prosys.dev.dfw3-cp1   121m         3%     1975Mi          64%
prosys.dev.dfw3-cp2   165m         4%     2389Mi          78%
prosys.dev.dfw3-wn0   45m          1%     1283Mi          18%
prosys.dev.dfw3-wn1   112m         3%     2664Mi          37%
prosys.dev.dfw3-wn2   39m          1%     1355Mi          19%
prosys.dev.dfw3-wn3   123m         3%     1943Mi          27%

```
   
6. **Update the flavor in the main.tf **

```bash
# vi main.tf

# CHANGE FROM
flavor_master                           = "gp.5.4.4"
# CHANGE TO
flavor_master                           = "gp.5.4.8"

```

7. **Get the terraform resource address**

	To find the resource name you can run `terraform state list` to get the resource addresses.
	We are looking for the `openstack_compute_instance_v2.node` addresses

```
#  terraform state list
...
module.openstack-nova.module.node_master.openstack_compute_instance_v2.node[0] <--
module.openstack-nova.module.node_master.openstack_compute_instance_v2.node[1] <--
module.openstack-nova.module.node_master.openstack_compute_instance_v2.node[2] <-- 
module.openstack-nova.module.node_master.openstack_networking_port_v2.node[0]
module.openstack-nova.module.node_master.openstack_networking_port_v2.node[1]
module.openstack-nova.module.node_master.openstack_networking_port_v2.node[2]
module.openstack-nova.module.node_worker.openstack_compute_instance_v2.node[0]
module.openstack-nova.module.node_worker.openstack_compute_instance_v2.node[1]
module.openstack-nova.module.node_worker.openstack_compute_instance_v2.node[2]
module.openstack-nova.module.node_worker.openstack_compute_instance_v2.node[3]
module.openstack-nova.module.node_worker.openstack_networking_port_v2.node[0]
module.openstack-nova.module.node_worker.openstack_networking_port_v2.node[1]
module.openstack-nova.module.node_worker.openstack_networking_port_v2.node[2]
module.openstack-nova.module.node_worker.openstack_networking_port_v2.node[3]
...

```
8. **Apply the change one node at a time**

	Using a targeted apply we will resize one node at a time starting with the last node. 
	Respond `yes` if the plan looks correct like below.
	
```bash
# terraform apply -target 'module.openstack-nova.module.node_master.openstack_compute_instance_v2.node[2]'

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
~ update in-place

Terraform will perform the following actions:

# module.openstack-nova.module.node_master.openstack_compute_instance_v2.node[0] will be updated in-place
~ resource "openstack_compute_instance_v2" "node" {
    ~ flavor_name         = "gp.0.4.4" -> "gp.0.4.8"
      id                  = "23c97fc1-8ae9-4932-8425-9ada7078ead5"
      name                = "dev-cluster-cp0"
      tags                = []
      # (18 unchanged attributes hidden)

      # (3 unchanged blocks hidden)
  }

Plan: 0 to add, 1 to change, 0 to destroy.
╷
│ Warning: Resource targeting is in effect
│
│ You are creating a plan with the -target option, which means that the result of this plan may not represent all of the changes requested by the current configuration.
│
│ The -target option is not for routine use, and is provided only for exceptional situations such as recovering from errors or mistakes, or when Terraform specifically
│ suggests to use it as part of an error message.
╵

Do you want to perform these actions?
Terraform will perform the actions described above.
Only 'yes' will be accepted to approve.

Enter a value: yes

module.openstack-nova.module.node_master.openstack_compute_instance_v2.node[0]: Modifying... [id=23c97fc1-8ae9-4932-8425-9ada7078ead5]
module.openstack-nova.module.node_master.openstack_compute_instance_v2.node[0]: Still modifying... [id=23c97fc1-8ae9-4932-8425-9ada7078ead5, 00m10s elapsed]
module.openstack-nova.module.node_master.openstack_compute_instance_v2.node[0]: Still modifying... [id=23c97fc1-8ae9-4932-8425-9ada7078ead5, 00m20s elapsed]
module.openstack-nova.module.node_master.openstack_compute_instance_v2.node[0]: Still modifying... [id=23c97fc1-8ae9-4932-8425-9ada7078ead5, 00m30s elapsed]
module.openstack-nova.module.node_master.openstack_compute_instance_v2.node[0]: Still modifying... [id=23c97fc1-8ae9-4932-8425-9ada7078ead5, 00m40s elapsed]
module.openstack-nova.module.node_master.openstack_compute_instance_v2.node[0]: Modifications complete after 42s [id=23c97fc1-8ae9-4932-8425-9ada7078ead5]
╷
│ Warning: Applied changes may be incomplete


```
	
9. **Verify cluster state**

We need to wait until the node has completed resizing, it goes back into `Ready` state, and all of the pods its running are successfully back online.

```bash
# kubectl get nodes
NAME                  STATUS   ROLES           AGE   VERSION
prosys.dev.dfw3-cp0   Ready    control-plane   13d   v1.32.8
prosys.dev.dfw3-cp1   Ready    control-plane   13d   v1.32.8
prosys.dev.dfw3-cp2   Ready    control-plane   13d   v1.32.8
prosys.dev.dfw3-wn0   Ready    <none>          13d   v1.32.8
prosys.dev.dfw3-wn1   Ready    <none>          13d   v1.32.8
prosys.dev.dfw3-wn2   Ready    <none>          13d   v1.32.8
prosys.dev.dfw3-wn3   Ready    <none>          13d   v1.32.8

# kubectl get pods -A -o wide | grep prosys.dev.dfw3-cp2
calico-system          calico-node-lpx59                                                 1/1     Running     3 (8d ago)      13d     10.0.5.50       prosys.dev.dfw3-cp2   <none>           <none>
calico-system          csi-node-driver-98v8z                                             2/2     Running     6 (8d ago)      13d     10.42.80.73     prosys.dev.dfw3-cp2   <none>           <none>
calico-system          goldmane-85c8f6d476-vrpdf                                         1/1     Running     0               42h     10.42.80.79     prosys.dev.dfw3-cp2   <none>           <none>
kube-system            coredns-5c54f84c97-dj56b                                          1/1     Running     0               6d8h    10.42.80.77     prosys.dev.dfw3-cp2   <none>           <none>
kube-system            dns-autoscaler-56cb45595c-p97ch                                   1/1     Running     0               6d8h    10.42.80.75     prosys.dev.dfw3-cp2   <none>           <none>
kube-system            etcd-prosys.dev.dfw3-cp2                                          1/1     Running     5 (6d8h ago)    13d     10.0.5.50       prosys.dev.dfw3-cp2   <none>           <none>
kube-system            kube-apiserver-prosys.dev.dfw3-cp2                                1/1     Running     1 (4d14h ago)   6d8h    10.0.5.50       prosys.dev.dfw3-cp2   <none>           <none>
kube-system            kube-controller-manager-prosys.dev.dfw3-cp2                       1/1     Running     7 (4d14h ago)   13d     10.0.5.50       prosys.dev.dfw3-cp2   <none>           <none>
kube-system            kube-proxy-4zqbl                                                  1/1     Running     3 (8d ago)      13d     10.0.5.50       prosys.dev.dfw3-cp2   <none>           <none>
kube-system            kube-scheduler-prosys.dev.dfw3-cp2                                1/1     Running     6 (4d14h ago)   13d     10.0.5.50       prosys.dev.dfw3-cp2   <none>           <none>
kube-system            kube-vip-prosys.dev.dfw3-cp2                                      1/1     Running     7 (4d14h ago)   13d     10.0.5.50       prosys.dev.dfw3-cp2   <none>           <none>
kube-system            kubelet-csr-approver-67b795dffd-8wqcs                             1/1     Running     3 (42h ago)     5d      10.42.80.78     prosys.dev.dfw3-cp2   <none>           <none>
kube-system            kubelet-csr-approver-67b795dffd-ggdkq                             0/1     Completed   0               6d8h    10.42.80.76     prosys.dev.dfw3-cp2   <none>           <none>
observability          observability-kube-prometheus-stack-prometheus-node-exportc7kbt   1/1     Running     0               4d19h   10.0.5.50       prosys.dev.dfw3-cp2   <none>           <none>
openstack-ccm          openstack-cloud-controller-manager-mjndk                          1/1     Running     0               4d14h   10.0.5.50       prosys.dev.dfw3-cp2   <none>           <none>
openstack-csi          openstack-cinder-csi-nodeplugin-r92gf                             3/3     Running     0               4d19h   10.0.5.50       prosys.dev.dfw3-cp2   <none>           <none>

``` 	
10. **Repeat steps 6 and 7 on the remaining control plane nodes.


## Verification

Steps to confirm the issue has been resolved:

11. **Verify resource utilization on nodes**

```bash
kubectl top nodes
```
   Expected result: Less utilization then before.

---

### Troubleshooting Notes

**Common Issues:**

1. **Cluster not responding to kubectl commands**
   
   The kubernetes api-server is running behind Kube-VIP which works by sending ARP requests to announce the internal api-server IP from a control-plane node. Sometimes when making changes to the nodes the public Kube-VIP may stop responding.
 	We will first want to verify if the cluster is responsive on the internal address by running kubectl commands from a control-plane node.
 	
```
# ansible prosys.dev.dfw3-cp0 --become -m shell -a 'kubectl get nodes'
prosys.dev.dfw3-cp0 | CHANGED | rc=0 >>
NAME                  STATUS   ROLES           AGE   VERSION
prosys.dev.dfw3-cp0   Ready    control-plane   13d   v1.32.8
prosys.dev.dfw3-cp1   Ready    control-plane   13d   v1.32.8
prosys.dev.dfw3-cp2   Ready    control-plane   13d   v1.32.8
prosys.dev.dfw3-wn0   Ready    <none>          13d   v1.32.8
prosys.dev.dfw3-wn1   Ready    <none>          13d   v1.32.8
prosys.dev.dfw3-wn2   Ready    <none>          13d   v1.32.8
prosys.dev.dfw3-wn3   Ready    <none>          13d   v1.32.8

```
   
If the cluster is responding correctly, we need to find out which node has the Kube-VIP IP address and reboot it to force a new ARP announcement.

```
# grep cni_iface main.tf
  cni_iface                               = "enp3s0"

# ansible oc_controlplane_nodes --become -m shell -a 'ip addr show dev enp3s0'
prosys.dev.dfw3-cp1 | CHANGED | rc=0 >>
2: enp3s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 3942 qdisc mq state UP group default qlen 1000
    link/ether fa:16:3e:3e:20:e3 brd ff:ff:ff:ff:ff:ff
    inet 10.0.7.108/22 metric 100 brd 10.0.7.255 scope global dynamic enp3s0
       valid_lft 38525sec preferred_lft 38525sec
    inet6 fe80::f816:3eff:fe3e:20e3/64 scope link
       valid_lft forever preferred_lft forever
prosys.dev.dfw3-cp2 | CHANGED | rc=0 >>
2: enp3s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 3942 qdisc mq state UP group default qlen 1000
    link/ether fa:16:3e:96:bd:f9 brd ff:ff:ff:ff:ff:ff
    inet 10.0.5.50/22 metric 100 brd 10.0.7.255 scope global dynamic enp3s0
       valid_lft 38861sec preferred_lft 38861sec
    inet 10.0.4.10/32 scope global enp3s0 <-------------- KUBE-VIP IP
       valid_lft forever preferred_lft forever
    inet6 fe80::f816:3eff:fe96:bdf9/64 scope link
       valid_lft forever preferred_lft forever
prosys.dev.dfw3-cp0 | CHANGED | rc=0 >>
2: enp3s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 3942 qdisc mq state UP group default qlen 1000
    link/ether fa:16:3e:3a:a8:a0 brd ff:ff:ff:ff:ff:ff
    inet 10.0.6.61/22 metric 100 brd 10.0.7.255 scope global dynamic enp3s0
       valid_lft 39995sec preferred_lft 39995sec

```

In this case the `prosys.dev.dfw3-cp2` node has the IP.

```
ansible prosys.dev.dfw3-cp2 --become -m shell -a 'reboot'

```
then try again running kubectl commands through the Public Kubeconfig file

```
kubectl get nodes
NAME                  STATUS   ROLES           AGE   VERSION
prosys.dev.dfw3-cp0   Ready    control-plane   14d   v1.32.8
prosys.dev.dfw3-cp1   Ready    control-plane   14d   v1.32.8
prosys.dev.dfw3-cp2   Ready    control-plane   14d   v1.32.8
prosys.dev.dfw3-wn0   Ready    <none>          14d   v1.32.8
prosys.dev.dfw3-wn1   Ready    <none>          14d   v1.32.8
prosys.dev.dfw3-wn2   Ready    <none>          14d   v1.32.8
prosys.dev.dfw3-wn3   Ready    <none>          14d   v1.32.8

```



## Additional Information

### Related Articles
- KB00003: Replacing controlplane nodes


### External References
- OpenStack Flex Documentation: https://docs.rackspacecloud.com/openstack-flex/
- Kubespray Official Documentation: https://kubespray.io/
- Kubernetes Control Plane Sizing Guide: https://kubernetes.io/docs/setup/production-environment/
- Terraform OpenStack Provider: https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs
- Kube-VIP Documentation: https://kube-vip.io/

### Known Limitations

- Resize operations require brief API server disruption (30-60 seconds per node)
- Maximum of 3 control plane nodes can be managed simultaneously
- Flavor changes must be compatible with existing disk configuration
- Rolling upgrades recommended during maintenance windows only
- Some flavors may not be available in all OpenStack regions
- Terraform state must be clean before performing resize operations

### Change History


### Customer Impact Statement

This procedure requires a rolling restart of control plane nodes, resulting in brief API server unavailability (30-60 seconds per node) during the resize operation. Applications running on worker nodes are not affected. 

Expected downtime: 2-10 minutes total across all control plane nodes
Service impact: Minimal - kubectl commands may be temporarily unresponsive
User impact: No end-user application downtime expected
Recommended execution window: During scheduled maintenance or low-traffic periods

---

## Feedback

**Was this article helpful?** [Yes/No]  
**Article Quality:** ⭐⭐⭐⭐⭐  
**Contact:** platform-team@company.com  

---

## Internal Notes (Remove from public version)

### Escalation Path
- L1 Support: 
- L2 Support: 
- Engineering: 


### Quick Commands Reference
```bash
# Check Terraform version
terraform version

# Validate Terraform configuration
terraform validate

#Apply Terraform targeted configuration
terraform apply -target 'module.openstack-nova.module.node_master.openstack_compute_instance_v2.node[0]'

# Check cluster health
kubectl get nodes
kubectl get pods -A
kubectl top nodes

# Verify control plane components
kubectl get pods -n kube-system -l tier=control-plane

# Check etcd cluster health (from control plane node)
ansible oc_controlplane_nodes --become -m shell -a 'etcdctl member list'

# Force Kube-VIP failover
ansible <node-name> --become -m shell -a 'systemctl restart kubelet'

# Verify OpenStack instance status
openstack server list --name *-cp*
```

### Metrics
- **Average Resolution Time:** 15 minutes
- **Success Rate:** 95%
- **Ticket References:** 

---

## Keywords for Search
[List of keywords to improve searchability - not visible to end users]
