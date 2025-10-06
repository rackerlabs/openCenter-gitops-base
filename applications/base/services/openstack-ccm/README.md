# OpenStack Cloud Controller Manager (CCM) – Base Configuration

This directory contains the **base manifests** for deploying the [OpenStack Cloud Controller Manager(CCM)](https://github.com/kubernetes/cloud-provider-openstack), which integrates Kubernetes with OpenStack cloud services for networking, storage, and instance management.  
It is designed to be **consumed by cluster repositories** as a remote base, allowing each cluster to apply **custom overrides** as needed.

**About OpenStack Cloud Controller Manager:**

- Enables Kubernetes to interact directly with **OpenStack APIs** for managing cloud resources.  
- Handles Kubernetes **node lifecycle management**, such as attaching instance metadata and updating node addresses.  
- Provides **LoadBalancer service integration** by provisioning OpenStack **Octavia** load balancers.  
- Updates node routes and network configurations in coordination with OpenStack **Neutron**.  
- Commonly used in private or hybrid cloud environments where Kubernetes clusters run on OpenStack infrastructure.  
- Improves automation, consistency, and observability of Kubernetes workloads on OpenStack-based platforms.  
