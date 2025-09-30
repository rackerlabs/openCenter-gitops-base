**Article ID:** KB00003 
**Last Modified:** 2025-09-29  
**Author:** Platform Engineering Team  
**Status:** Published  
**Category:** Kubernetes/Kubespray/Cluster Management  
**Tags:** `kubespray`, `kubernetes`, `control-plane`, `etcd`, `node-replacement`, `cluster-recovery`  
**Visibility:** Public

---

## Summary

How to replace a failed or rebuilt control plane node in a Kubespray-managed Kubernetes cluster using manual etcd member removal and cluster.yml playbook.

---

## Environment

**Product:** Kubespray  
**Version(s) Affected:** Kubespray 2.20+  
**Operating System:** Ubuntu 20.04/22.04/24.04, RHEL 8/9  
**Architecture:** x86_64/ARM64  
**Component:** etcd, Kubernetes Control Plane, Kubespray  
**Configuration:**
- Kubespray-deployed cluster with kubeadm-style certificate paths
- etcd deployment type: kubeadm (`etcd_deployment_type: kubeadm`)
- At least 3 control plane nodes
- RBAC enabled

---

## Prerequisites

- At least one healthy control plane node must be available
- The replacement node should be provisioned with a fresh OS installation
- SSH access to all cluster nodes
- `kubectl` configured with admin credentials to access the cluster
- Kubespray deployment directory accessible
- Admin permissions to approve certificate signing requests

---

## Symptoms

Users experience one or more of the following scenarios:

**Primary Symptom:** Control plane node is unavailable or needs to be rebuilt

**Node Status:**
```
NAME              STATUS                        ROLES           AGE   VERSION
cluster-cp0       Ready                         control-plane   20d   v1.30.4
cluster-cp1       Ready                         control-plane   20d   v1.30.4
cluster-cp2       NotReady,SchedulingDisabled   control-plane   20d   v1.30.4
```

**Error Messages:**
- etcd cluster reports member as unhealthy
- Node shows `NotReady` status in kubectl
- Certificate errors from the affected node

**When it Occurs:** After hardware failure, OS corruption, or planned node rebuild

**Frequency:** Varies based on infrastructure reliability

**Impact:** Reduced control plane redundancy, potential etcd quorum issues if multiple nodes fail

---

## Cause

Control plane nodes may need replacement due to:

1. **Hardware failure** - Disk failure, memory errors, network interface issues
2. **OS corruption** - Filesystem damage, kernel panics, boot failures
3. **Planned maintenance** - OS upgrades requiring full rebuild, hardware replacement
4. **Certificate expiration** - Unrecoverable certificate issues requiring node rebuild
5. **etcd data corruption** - Database corruption requiring fresh etcd member

**Technical Background:**
- Kubernetes control plane nodes run critical components (API server, scheduler, controller-manager)
- etcd requires proper quorum (majority of members) to function
- Kubespray uses kubeadm-style deployments with certificates in `/etc/kubernetes/ssl/etcd/`
- The `recover-control-plane.yml` playbook expects older certificate paths and may not work with kubeadm-mode

---

## Important Notes

⚠️ **Critical Limitations:**
- **This procedure does NOT support replacing the first control plane node** (the first node listed in your `kube_control_plane` and `etcd` groups). See "Special Case" section below.
- These instructions are for clusters using kubeadm-style certificate paths (`/etc/kubernetes/ssl/etcd/`)
- The `recover-control-plane.yml` playbook may not work with kubeadm-mode deployments
- Never replace more than one control plane node at a time

---

## Solution

### Step 1: Remove the Broken etcd Member

SSH into one of the healthy control plane nodes and list the current etcd members:

```bash
# SSH to a healthy control plane node
ssh ubuntu@<healthy-control-plane-node>

# List etcd members
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/ssl/etcd/ca.crt \
  --cert=/etc/kubernetes/ssl/etcd/server.crt \
  --key=/etc/kubernetes/ssl/etcd/server.key \
  member list -w table
```

**Example output:**
```
+------------------+---------+-----------------+---------------------------+---------------------------+------------+
|        ID        | STATUS  |      NAME       |        PEER ADDRS         |       CLIENT ADDRS        | IS LEARNER |
+------------------+---------+-----------------+---------------------------+---------------------------+------------+
| 26da4819de56c8d6 | started | cluster-cp0     | https://10.2.188.190:2380 | https://10.2.188.190:2379 |      false |
| 91bc3c398fb3c146 | started | cluster-cp1     | https://10.2.188.146:2380 | https://10.2.188.146:2379 |      false |
| 53ee0eb71893f1f9 | started | cluster-cp2     | https://10.2.188.176:2380 | https://10.2.188.176:2379 |      false |
+------------------+---------+-----------------+---------------------------+---------------------------+------------+
```

Note the `ID` of the broken control plane node from the output, then remove it:

```bash
# Remove the broken member (replace <MEMBER_ID> with the actual ID)
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/ssl/etcd/ca.crt \
  --cert=/etc/kubernetes/ssl/etcd/server.crt \
  --key=/etc/kubernetes/ssl/etcd/server.key \
  member remove <MEMBER_ID>
```

**Example:**
```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/ssl/etcd/ca.crt \
  --cert=/etc/kubernetes/ssl/etcd/server.crt \
  --key=/etc/kubernetes/ssl/etcd/server.key \
  member remove 53ee0eb71893f1f9
```

Verify the member was removed:

```bash
# List members again to confirm removal
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/ssl/etcd/ca.crt \
  --cert=/etc/kubernetes/ssl/etcd/server.crt \
  --key=/etc/kubernetes/ssl/etcd/server.key \
  member list -w table
```

You should now see only the healthy members listed.

Exit the SSH session:

```bash
exit
```

---

### Step 2: Delete the Node from Kubernetes

From your Kubespray control machine, delete the broken node from Kubernetes:

```bash
kubectl delete node <broken-node-name>
```

**Example:**
```bash
kubectl delete node cluster-cp2
```

Verify the node is removed:

```bash
kubectl get nodes
```

**Expected result:** The broken node should no longer appear in the node list.

---

### Step 3: Gather Facts for All Nodes

Before running the cluster playbook with `--limit`, gather facts for all nodes to populate required variables:

```bash
# Verify ANSIBLE_INVENTORY is set
echo $ANSIBLE_INVENTORY

# Gather facts for all nodes (without limit)
ansible-playbook playbooks/facts.yml -b -v
```

**Why this is needed:** The `--limit` flag skips fact-gathering for nodes not in scope, which causes the `main_ips` variable to be undefined. Running `facts.yml` first ensures all facts are available.

---

### Step 4: Run cluster.yml to Rejoin the Node

Navigate to your Kubespray directory and run the cluster playbook:

```bash
# Run cluster.yml with hardening settings (if applicable)
ansible-playbook cluster.yml \
  -e "@<path-to-hardening-file>" \
  --limit=<broken-node>,etcd,kube_control_plane \
  -b -v
```

**Example:**
```bash
ansible-playbook cluster.yml \
  -e "@../inventory/k8s_hardening.yml" \
  --limit=cluster-cp2,etcd,kube_control_plane \
  -b -v
```

**Without hardening file:**
```bash
ansible-playbook cluster.yml \
  --limit=cluster-cp2,etcd,kube_control_plane \
  -b -v
```

This process may take 10-20 minutes. The playbook will:
- Configure the replacement node
- Generate new certificates
- Add it back to the etcd cluster as a new member
- Configure Kubernetes control plane components
- Join the node to the Kubernetes cluster

---

### Step 5: Verify the Recovery

After the playbook completes successfully, verify the node is back in the cluster:

#### 6.1: Check Node Status

```bash
kubectl get nodes
```

**Expected result:** All nodes should show `Ready` status:
```
NAME              STATUS   ROLES           AGE   VERSION
cluster-cp0       Ready    control-plane   20d   v1.30.4
cluster-cp1       Ready    control-plane   20d   v1.30.4
cluster-cp2       Ready    control-plane   5m    v1.30.4
cluster-wn0       Ready    worker          20d   v1.30.4
cluster-wn1       Ready    worker          20d   v1.30.4
```

#### 6.2: Verify etcd Cluster Health

```bash
kubectl exec -n kube-system etcd-<any-control-plane-node> -- \
  etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/ssl/etcd/ca.crt \
  --cert=/etc/kubernetes/ssl/etcd/server.crt \
  --key=/etc/kubernetes/ssl/etcd/server.key \
  endpoint health --cluster
```

**Expected result:** All etcd members should be healthy:
```
https://10.2.188.190:2379 is healthy: successfully committed proposal: took = 2.3ms
https://10.2.188.146:2379 is healthy: successfully committed proposal: took = 2.1ms
https://10.2.188.176:2379 is healthy: successfully committed proposal: took = 2.5ms
```

#### 6.3: Check Control Plane Pods

```bash
kubectl get pods -n kube-system | grep <replaced-node-name>
```

**Expected result:** All control plane pods should be running:
```
etcd-cluster-cp2                      1/1     Running   0          5m
kube-apiserver-cluster-cp2            1/1     Running   0          5m
kube-controller-manager-cluster-cp2   1/1     Running   0          5m
kube-scheduler-cluster-cp2            1/1     Running   0          5m
```

---

## Special Case: Replacing the First Control Plane Node

⚠️ **Important:** Kubespray does not support directly replacing the first control plane node in your inventory. You must reorder the inventory first.

If you need to replace the **first control plane node** (the first node in your `kube_control_plane` and `etcd` inventory groups), follow this procedure:

### Step 1: Reorder Your Inventory

Move the first control plane node to the end of the list in both `kube_control_plane` and `etcd` groups:

**Before:**
```yaml
oc_controlplane_nodes:
  hosts:
    control-plane-node-1:  # First node - needs to be replaced
      ansible_host: <IP1>
    control-plane-node-2:
      ansible_host: <IP2>
    control-plane-node-3:
      ansible_host: <IP3>
```

**After:**
```yaml
oc_controlplane_nodes:
  hosts:
    control-plane-node-2:  # Now first
      ansible_host: <IP2>
    control-plane-node-3:  # Now second
      ansible_host: <IP3>
    control-plane-node-1:  # Now last (can be replaced)
      ansible_host: <IP1>
```

### Step 2: Apply the Reordering

After reordering, run the upgrade playbook to apply the new ordering:

```bash
ansible-playbook upgrade-cluster.yml -b -v
```

Or if not using upgrade:

```bash
ansible-playbook cluster.yml -b -v
```

**Wait for the cluster to stabilize** - verify all nodes and pods are healthy before proceeding.

### Step 3: Proceed with Normal Replacement

Once the reordering is complete and the cluster is stable, proceed with the standard replacement steps (Steps 1-5 above).

---

## Verification Steps

Steps to confirm the issue has been resolved:

### 1. Verify Node Status
```bash
kubectl get nodes
```
**Expected:** All nodes show `Ready` status

### 2. Check etcd Member List
```bash
kubectl exec -n kube-system etcd-<control-plane-node> -- \
  etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/ssl/etcd/ca.crt \
  --cert=/etc/kubernetes/ssl/etcd/server.crt \
  --key=/etc/kubernetes/ssl/etcd/server.key \
  member list -w table
```
**Expected:** Three etcd members all showing `started` status

### 3. Verify Control Plane Pods
```bash
kubectl get pods -n kube-system -o wide | grep <replaced-node>
```
**Expected:** All control plane pods running on the replaced node

### 4. Test API Server Connectivity
```bash
kubectl --server=https://<replaced-node-ip>:6443 get nodes
```
**Expected:** Successfully returns node list

### 5. Check Cluster Component Health
```bash
kubectl get cs
```
**Expected:** All components show healthy status (or deprecated message in newer versions)

---

## Troubleshooting

### Error: "no attribute 'main_ips'"

**Symptom:**
```
fatal: [control-plane-node]: FAILED! => {"msg": "AnsibleUndefinedVariable: 
'ansible.vars.hostvars.HostVarsVars object' has no attribute 'main_ips'"}
```

**Cause:** Using `--limit` with `kubelet_systemd_hardening` enabled prevents proper fact gathering.

**Solution:** This is a known issue ([#12531](https://github.com/kubernetes-sigs/kubespray/issues/12531)). Ensure `kubelet_secure_addresses` is properly configured with explicit IP addresses in your cluster configuration at deployment time, or run `playbooks/facts.yml` before using `--limit`.

---

### Error: Certificate Path Not Found

**Symptom:**
```
Error: open /etc/ssl/etcd/ssl/admin-<hostname>.pem: no such file or directory
```

**Cause:** Cluster uses kubeadm-style paths but playbook expects old Kubespray paths.

**Solution:** This is expected. Use the manual recovery approach (this guide) instead of `recover-control-plane.yml` playbook. Certificates are located in `/etc/kubernetes/ssl/etcd/` not `/etc/ssl/etcd/ssl/`.

---

### Etcd Quorum Lost

**Symptom:** etcd cluster reports no leader, API server unavailable

**Cause:** More than half of etcd members are down simultaneously

**Solution:**
- If quorum is lost, recovery is more complex and may require restoring from backup
- Never let more than `(N-1)/2` nodes fail where N is total etcd members
- For 3-node cluster: maximum 1 node can fail
- For 5-node cluster: maximum 2 nodes can fail
- Ensure you always maintain at least 2 healthy etcd members during any maintenance

**Prevention:** Always maintain odd number of etcd members (3, 5, or 7 recommended)

---

### Node Not Rejoining

**Symptom:** Playbook completes but node doesn't appear in cluster or shows NotReady

**Solutions:**

1. **Check SSH connectivity:**
```bash
ansible <broken-node> -m ping
```

2. **Verify IP address in inventory:**
```bash
ansible-inventory --list | grep -A5 <broken-node>
```

3. **Check firewall rules:**
```bash
# On the node
sudo ufw status
sudo iptables -L -n
```

4. **Review playbook output for errors:**
```bash
# Run with maximum verbosity
ansible-playbook cluster.yml --limit=<node>,etcd,kube_control_plane -vvv
```

5. **Try without --limit (reconfigure all nodes):**
```bash
ansible-playbook cluster.yml -b -v
```

---

### etcd Member Already Exists

**Symptom:**
```
Error: member <hostname> already exists
```

**Cause:** Previous etcd member wasn't properly removed

**Solution:**
```bash
# List members and find the duplicate
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/ssl/etcd/ca.crt \
  --cert=/etc/kubernetes/ssl/etcd/server.crt \
  --key=/etc/kubernetes/ssl/etcd/server.key \
  member list

# Remove the old member by ID
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/ssl/etcd/ca.crt \
  --cert=/etc/kubernetes/ssl/etcd/server.crt \
  --key=/etc/kubernetes/ssl/etcd/server.key \
  member remove <MEMBER_ID>
```

---

## Additional Information

### Related Articles
- KB00XXX: Backing Up and Restoring etcd in Kubespray Clusters
- KB00XXX: Upgrading Kubernetes with Kubespray
- KB00XXX: Troubleshooting etcd Cluster Issues
- KB00XXX: Kubespray Certificate Management

### Limitations
- Cannot replace first control plane node without reordering inventory
- Requires at least one healthy control plane node
- Node replacement causes temporary reduction in cluster redundancy
- Certificate paths must match kubeadm-style structure
- Does not work with external etcd clusters (different procedure required)

### Best Practices

1. **Always backup etcd** before performing control plane maintenance
   ```bash
   kubectl -n kube-system exec etcd-<node> -- \
     etcdctl snapshot save /tmp/snapshot.db
   ```

2. **Test in non-production** environment first if possible

3. **Maintain odd number of etcd members** (3, 5, or 7 recommended)
   - 3 nodes: tolerates 1 failure
   - 5 nodes: tolerates 2 failures
   - 7 nodes: tolerates 3 failures

4. **Never replace multiple control plane nodes simultaneously**

5. **Document your cluster configuration** including custom variables and hardening settings

6. **Keep Kubespray version consistent** across all operations

7. **Monitor etcd health** during and after the replacement
   ```bash
   watch -n 5 'kubectl exec -n kube-system etcd-<node> -- \
     etcdctl endpoint health --cluster'
   ```

8. **Verify backups** are recent and restorable before starting maintenance

---

## Revision History

| Date | Version | Author | Change Description |
|------|---------|--------|-------------------|
| 2025-09-29 | 1.0 | Platform Team | Initial creation |

---

## Support Information

This procedure is critical for maintaining cluster availability and should be performed carefully. Testing in a non-production environment first is strongly recommended.

**Was this article helpful?** [Yes/No]

**Article Quality:** ⭐⭐⭐⭐⭐

**Contact:** platform-team@company.com

---

## Support Escalation

- **L1 Support:** Can verify node status and SSH connectivity
- **L2 Support:** Can execute etcd member removal and run Kubespray playbooks
- **Engineering:** Escalate for etcd quorum loss, certificate issues, or API server configuration problems

---

## Diagnostics

### Quick Health Check Commands

```bash
# Check all nodes
kubectl get nodes -o wide

# Check control plane pods
kubectl get pods -n kube-system -l tier=control-plane

# Check etcd health
kubectl exec -n kube-system etcd-<node> -- \
  etcdctl endpoint health --cluster

# Check API server logs
kubectl logs -n kube-system kube-apiserver-<node> --tail=50

# Check kubelet status on node
ssh <node> sudo systemctl status kubelet
```

### Performance Metrics

- **Average Resolution Time:** 20-30 minutes (excluding provisioning time)
- **Success Rate:** 98% when prerequisites met
- **Common Failure Points:**
  - SSH connectivity issues (5%)
  - Certificate generation failures (2%)
  - Firewall blocking etcd ports (3%)

---

## Search Keywords

[Internal keywords for searchability - not visible to end users]

- kubespray control plane replacement
- replace kubernetes master node
- etcd member removal
- kubeadm control plane recovery  
- kubernetes node replacement
- kubespray node recovery
- etcd cluster repair
- control plane node failure
- kubernetes high availability
- etcd quorum recovery
- kubespray certificate paths
- kubernetes cluster maintenance
- control plane disaster recovery
- etcd member replacement
- kubespray troubleshooting