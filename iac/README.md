Kubespray Provider Configuration Guide

We use OpenTofu to deploy virtual machines on OpenStack, using the outputs of the infra module, we generate the Kubespray YAML manifests, then run the Kubespray playbooks to deploy Kubernetes on the virtual machines.

**NOTE:** These steps will change once automation is built.

The terraform state file will be stored in an S3 bucket

This will configure a Ubuntu 24.04 Linux VM as a deployment node that will be used to bootstrap and deploy openCenter clusters. The VM can go away once the resulting files have been committed to a code repository.
The deployment node could be your laptop or an existing Linux VM.

- [Overview](#overview)
- [Prerequisites](#prerequisites)
  - [Required Packages](#required-packages)
- [Cluster Configuration](#cluster-configuration)
  - [Local Binary Management](#local-binary-management)
  - [Terraform Backend Setup](#terraform-backend-setup)
    - [Local Backend](#local-backend)
    - [S3 Backend](#s3-backend)
    - [If using S3 backend for Terraform state](#if-using-s3-backend-for-terraform-state)
      - [Update provider.tf to use an S3 Bucket that we will create](#update-providertf-to-use-an-s3-bucket-that-we-will-create)
      - [Create S3 Bucket](#create-s3-bucket)
      - [Create Access Policy for Bucket](#create-access-policy-for-bucket)
      - [Create AWS User (S3 backend only)](#create-aws-user-s3-backend-only)
  - [Create OpenStack Application Credentials](#create-openstack-application-credentials)
  - [Export OpenStack and AWS Credentials](#export-openstack-and-aws-credentials)
    - [OpenStack credentials (required)](#openstack-credentials-required)
    - [AWS credentials (required only when using S3 backend)](#aws-credentials-required-only-when-using-s3-backend)
  - [Configure Cluster Settings](#configure-cluster-settings)
    - [Update main.tf](#update-maintf)
- [Deploy Cluster](#deploy-cluster)
  - [Initialize terraform modules](#initialize-terraform-modules)
  - [Create OpenStack infrastructure and deploy Kubespray](#create-openstack-infrastructure-and-deploy-kubespray)
- [Post-Deployment Configuration](#post-deployment-configuration)
  - [Access the Cluster](#access-the-cluster)
  - [Deploy a CNI](#deploy-a-cni)
  - [Complete Hardening with CSR Approver](#complete-hardening-with-csr-approver)
  - [Validate Kubernetes Cluster](#validate-kubernetes-cluster)
- [Next Steps](#next-steps)
- [Configuration Options](#configuration-options)
  - [Key Infrastructure Module Variables](#key-infrastructure-module-variables)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
  - [Terraform Init Fails](#terraform-init-fails)
  - [Kubespray Deployment Fails](#kubespray-deployment-fails)
  - [CNI Deployment Issues](#cni-deployment-issues)

This article provides a complete, practical guide for deploying openCenter Kubernetes clusters on OpenStack using Terraform and Kubespray.

***

# Overview

openCenter uses Terraform to deploy virtual machines on OpenStack, then generates Kubespray YAML manifests from the infrastructure outputs, and finally runs Kubespray playbooks to deploy Kubernetes on the virtual machines. The Terraform state file is stored remotely in an S3 bucket for team collaboration.

This guide configures a Ubuntu 24.04 Linux VM as a deployment node for bootstrapping and deploying openCenter clusters. The deployment node can be your laptop or an existing Linux VM.

***

# Prerequisites

## Required Packages

- Python >=3.10 (included in Ubuntu 24.04)
- python3.10-venv
- unzip
- make
- git

# Cluster Configuration

**Initialize the new cluster:**

```bash
# clone the base repo
git clone https://github.com/rackerlabs/openCenter-gitops-base
# Create the directory for the new cluster configuration
mkdir -p /etc/opencenter/000000-opencenter-example/infrastructure/{clusters,applications/overlays}
# Copy one of the examples
cp -r openCenter-gitops-base/examples/iac/dev-cluster /etc/opencenter/000000-opencenter-example/infrastructure/clusters
cp -r openCenter-gitops-base/examples/applications/overlays/dev-cluster /etc/opencenter/000000-opencenter-example/infrastructure/applications/overlays
# Move into the cluster directory
cd /etc/opencenter/000000-opencenter-example/infrastructure/clusters/dev-cluster
```

## Local Binary Management

Create a `.bin` directory within each cluster directory to hold binaries compatible with the current cluster version. This allows different clusters to run different release versions.

**Add local binaries to PATH:**

```bash
export BIN=${PWD}/.bin
export PATH=${BIN}:${PATH}
```

Then use the provided Makefile to install binaries into the `.bin` directory.

```bash
make terraform
make kubectl
make sops
make age
make flux
make kubelogin
make helm
```

## Terraform Backend Setup

There are a couple of different options to use as a backend. For production, we recommend the S3 backend on a versioned bucket. For development and testing, local backend works fine.

### Local Backend

Set `provider.tf` with a local path to the state file.
When using local backend, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are not required.

```
terraform {
  backend "local" {
    path = "./cluster-name.tfstate"
  }
}

```

### S3 Backend

### If using S3 backend for Terraform state

#### Update provider.tf to use an S3 Bucket that we will create

Update `<REPLACE_BUCKET_NAME>`, `<REPLACE_CLUSTER_NAME>` and `<REPLACE_REGION>` with the bucket name, cluster name and region you will be using:

```hcl
terraform {
  backend "s3" {
    bucket       = "<REPLACE_BUCKET_NAME>"
    key          = "<REPLACE_CLUSTER_NAME>/tfstate/terraform.tfstate"
    region       = "<REPLACE_REGION>"
    use_lockfile = true
    encrypt      = true
  }
}
```

#### Create S3 Bucket

Create an S3 bucket to store the Terraform state file remotely:

```bash
aws s3api create-bucket --bucket <REPLACE_BUCKET_NAME> --region <REPLACE_REGION> --create-bucket-configuration LocationConstraint=<REPLACE_REGION>
```

- Give it a unique name
- Enable `Block all public access`
- Enable Bucket Versioning
- Add Tags: `production` or `dev`
- Default Encryption: Server-side encryption with Amazon S3 managed keys

#### Create Access Policy for Bucket

Create an IAM policy to allow access to the Terraform state file. Replace `BUCKET_NAME` with your S3 bucket name.

This policy supports multiple clusters using a directory structure:

```
├── BUCKET_NAME
│   ├── CLUSTER_NAME
│   │   ├── tfstate
│   │   │   └── terraform.tfstate
│   │   │   └── terraform.tfstate.tflock
```

**IAM Policy:**

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::BUCKET_NAME"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::BUCKET_NAME/*/tfstate/terraform.tfstate"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::BUCKET_NAME/*/tfstate/terraform.tfstate.tflock"
            ]
        }
    ]
}
```

#### Create AWS User (S3 backend only)

- Give it a clear name like "customer name"
- Leave console access unchecked
- Attach the policy created above
- Save the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` (required only for S3 backend)

## Create OpenStack Application Credentials

Navigate to UserCenter > Application Credentials > Create Application Credentials:

- Set a unique name
- Set an expiration (empty = no expiration)
- Roles:
  - load-balancer_member
  - reader
  - member
  - network_member
  - heat_stack_user
  - creator
- Leave Unrestricted unchecked
- Add a description

This downloads a JSON file with credentials:

```json
{
  "id": "f07a1d5ff5254c0b9cda848353169891",
  "description": null,
  "project_id": "4c07654c099f59021ac0166a84648742",
  "expires_at": null,
  "secret": "REDACTED"
}
```

## Export OpenStack and AWS Credentials

### OpenStack credentials (required)

**Option 1 - Application Credentials:**

```bash
export TF_VAR_os_application_credential_id='longidstring'
export TF_VAR_os_application_credential_secret='securesecret'
```

**Option 2 - Username and API Key:**

```bash
export TF_VAR_openstack_user_password='api-key'
export TF_VAR_openstack_user_name='user@rackspace.com'
```

### AWS credentials (required only when using S3 backend)

If you are using local backend, you can skip AWS credential exports.

```bash
export AWS_ACCESS_KEY_ID=<KEY>
export AWS_SECRET_ACCESS_KEY=<KEY>
```

***

## Configure Cluster Settings

### Update main.tf

Configure minimum required settings. The default `main.tf` is configured for OpenStack Flex in SJC3 using Kube-VIP with a floating IP to expose the Kubernetes API publicly.

Replace `<REPLACE_CLUSTER_NAME>`, `<REPLACE_PROJECT_NAME>` and `<REPLACE_SSH_PUBLIC_KEY>` with your cluster name, project name and SSH public key. Pick an available CIDR for the subnet:

```hcl
locals {
  cluster_name                            = "<REPLACE_CLUSTER_NAME>"
  openstack_tenant_name                   = "<REPLACE_PROJECT_NAME>"
  # CIDR that the OpenStack VMs will use for K8s nodes
  subnet_nodes                            = "10.2.188.0/22"
  # Kubespray Settings
  kubespray_version                       = "v2.28.1"
  kubernetes_version                      = "1.32.5"
  ssh_authorized_keys                     = ["<REPLACE_SSH_PUBLIC_KEY>"]
}
```

# Deploy Cluster

## Initialize terraform modules

**Initialize Terraform:**

```bash
terraform init
```

The init command needs to access modules in Git using SSH keys or a Git Token:

- SSH Key method: `git@github.com:rackerlabs/openCenter-gitops-base.git`
- Token method: `github.com/rackerlabs/openCenter-gitops-base.git`

## Create OpenStack infrastructure and deploy Kubespray

**Review the resources plan**

```bash
terraform plan
```

**Apply configuration:**

```bash
terraform apply
```

***

# Post-Deployment Configuration

## Access the Cluster

A kubeconfig file is copied to the local cluster directory during the Terraform apply:
At this point the nodes will be in `NotReady` state, but you have a working cluster and they will go `Ready` after installing calico in the next step.

```bash
export KUBECONFIG=${PWD}/kubeconfig.yaml
kubectl get nodes
```

An Ansible inventory file is created at `CLUSTER_DIR/inventory/inventory.yaml` pre-configured to use the bastion server for secure access.

## Deploy a CNI

Kubespray is deployed without a CNI to allow flexibility in choosing any supported CNI.

**Deploy Calico:**

```bash
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm upgrade --install calico projectcalico/tigera-operator \
  --namespace tigera-operator \
  -f ../../../applications/overlays/dev-cluster/services/calico/helm-values/override_values.yaml \
  --create-namespace
```

## Complete Hardening with CSR Approver

Part of the hardening configuration allows Kubelet to renew its certificates automatically. Deploy the `kubelet-csr-approver` by setting `kubelet_rotate_server_certificates` to `true` in the cluster's `main.tf`.

**Note:** If `kubelet_rotate_server_certificates` is true and the cluster doesn't have a CNI installed, the Kubespray playbook will fail to deploy the `kubelet-csr-approver` helm chart.

**Apply Terraform:**

```bash
terraform apply
```

**Run Ansible playbook:**

```bash
export ANSIBLE_INVENTORY=${PWD}/inventory/inventory.yaml
source venv/bin/activate
cd kubespray
ansible-playbook -f 10 -b upgrade-cluster.yml -e "@../inventory/k8s_hardening.yml"
```

## Validate Kubernetes Cluster

```bash
export KUBECONFIG=${PWD}/kubeconfig.yaml
kubectl get nodes
```

# Next Steps

Now that the cluster is ready you can follow this guide [Bootstrap Flux on openCenter Clusters](/bootstrapping-flux-for-opencenter-clusters/) to install Flux and deploy applications.

Expected output:

```
NAME               STATUS   ROLES           AGE   VERSION
dev-cp0   Ready    control-plane   17h   v1.31.4
dev-cp1   Ready    control-plane   17h   v1.31.4
dev-cp2   Ready    control-plane   17h   v1.31.4
dev-wn0   Ready    <none>          17h   v1.31.4
dev-wn1   Ready    <none>          17h   v1.31.4
```

***

# Configuration Options

## Key Infrastructure Module Variables

| Variable | Type | Default | Description |
| --- | --- | --- | --- |
| cluster_name | string | "" | Sets the name of the cluster, OpenStack project and user |
| openstack_tenant_name | string | "" | The OpenStack tenant name if it already exists |
| subnet_nodes | string | "10.0.0.0/16" | CIDR for OpenStack Network for nodes |
| subnet_services | string | "10.43.0.0/16" | CIDR to use for Kubernetes services |
| subnet_pods | string | "10.42.0.0/16" | CIDR to use for Kubernetes pods |
| use_octavia | bool | true | Use Octavia Load Balancer for Kubernetes API |
| vrrp_enabled | bool | false | Use vrrp_ip as the VIP with kube-vip (cannot be true if use_octavia is true) |
| use_designate | bool | true | Creates a DNS record using the LB floating IP and dns_zone_name |
| dns_zone_name | string | "" | DNS zone to create if use_designate is true |
| worker_count | number | 0 | Number of worker node VMs to build |
| master_count | number | 0 | Number of master node VMs to build |
| flavor_master | string | "" | OpenStack flavor for master node instances |
| flavor_worker | string | "" | OpenStack flavor for worker node instances |
| ssh_authorized_keys | list(string) | [] | List of SSH public keys for cluster access |

For a complete list of OpenStack infrastructure configuration options, refer to `iac/cloud/openstack/README.md`.

***

# Best Practices

- **Use remote state storage** in S3 with versioning enabled
- **Version your infrastructure code** in Git
- **Store sensitive credentials** in PasswordSafe
- **Deploy CNI immediately** after cluster creation
- **Apply hardening configurations** before production use
- **Document cluster specifications** in the repository
- **Test upgrades** in non-production environments first

***

# Troubleshooting

## Terraform Init Fails

- Verify Git access (SSH keys or token)
- If using S3 backend, check AWS credentials
- Ensure S3 bucket exists and is accessible

## Kubespray Deployment Fails

- Verify OpenStack credentials are valid
- Check network connectivity to OpenStack API
- Ensure sufficient quota for resources
- Review Ansible logs for specific errors

## CNI Deployment Issues

- Ensure cluster nodes are ready before CNI deployment
- Verify network configuration matches CNI requirements
- Check for conflicting network policies
