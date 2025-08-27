# Flux CD Bootstrap Guide

## Prerequisites

Before bootstrapping Flux CD, you need the following tools installed:

1. **kubectl** - Kubernetes command-line tool
2. **flux** - Flux CD CLI
3. **git** - Version control system
4. A **Kubernetes cluster** (local or remote)
5. A **GitHub/GitLab** repository for GitOps

## Installation Instructions

### 1. Install kubectl

#### Mac (using Homebrew)
```bash
brew install kubectl
```

#### Mac (using curl)
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

#### Linux (using curl)
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

#### Linux (using package manager)
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y kubectl

# CentOS/RHEL/Fedora
sudo yum install kubectl
# or for newer versions
sudo dnf install kubectl
```

### 2. Install Flux CLI

#### Mac (using Homebrew)
```bash
brew install fluxcd/tap/flux
```

#### Mac/Linux (using curl)
```bash
curl -s https://fluxcd.io/install.sh | sudo bash
```

#### Alternative installation (manual)
```bash
# Download the latest release
curl -s https://api.github.com/repos/fluxcd/flux2/releases/latest \
  | grep browser_download_url \
  | grep linux_amd64 \
  | cut -d '"' -f 4 \
  | wget -i -

# Extract and install
tar -xzf flux_*_linux_amd64.tar.gz
sudo mv flux /usr/local/bin/
```

### 3. Install Git

#### Mac
```bash
# Git is usually pre-installed, but you can update it
brew install git
```

#### Linux
```bash
# Ubuntu/Debian
sudo apt-get install git

# CentOS/RHEL/Fedora
sudo yum install git
# or
sudo dnf install git
```

### 4. Set up a Kubernetes Cluster

You need a running Kubernetes cluster. Options include:

#### Local Development Clusters
```bash
# Option 1: Docker Desktop (Mac/Linux)
# Enable Kubernetes in Docker Desktop settings

# Option 2: Minikube
brew install minikube  # Mac
# or
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

minikube start

# Option 3: Kind (Kubernetes in Docker)
brew install kind  # Mac
# or
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

kind create cluster --name flux-cluster
```

## Flux CD Bootstrap Process

### 1. Verify Prerequisites

```bash
# Check kubectl connection
kubectl cluster-info

# Check Flux CLI installation
flux --version

# Check Git configuration
git config --global user.name
git config --global user.email
```

### 2. Pre-flight Check

Run Flux pre-flight checks to ensure your cluster is ready:

```bash
flux check --pre
```

### 3. Create GitHub Personal Access Token

1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Generate a new token with the following scopes:
   - `repo` (full control of private repositories)
   - `workflow` (if using GitHub Actions)

### 4. Export Environment Variables

```bash
export GITHUB_TOKEN="your-github-token"
export GITHUB_USER="your-github-username"
export GITHUB_REPO="your-flux-repo-name"
```

### 5. Bootstrap Flux CD

#### Basic Bootstrap (GitHub)
```bash
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=$GITHUB_REPO \
  --branch=main \
  --path=./clusters/my-cluster \
  --personal
```

#### Bootstrap with Custom Options
```bash
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=$GITHUB_REPO \
  --branch=main \
  --path=./clusters/production \
  --personal \
  --components-extra=image-reflector-controller,image-automation-controller
```

#### Bootstrap from Specific Branch
```bash
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=$GITHUB_REPO \
  --branch=production \
  --path=./clusters/production \
  --personal
```

#### Bootstrap for GitLab
```bash
export GITLAB_TOKEN="your-gitlab-token"

flux bootstrap gitlab \
  --owner=$GITLAB_USER \
  --repository=$GITLAB_REPO \
  --branch=main \
  --path=./clusters/my-cluster \
  --token-auth
```

### 6. Verify Bootstrap

```bash
# Check Flux system components
flux get all -A

# Watch the bootstrap process
kubectl get pods -n flux-system -w

# Check Git repository sync
flux get sources git
```

## Advanced Branch and Tag Configuration

### Deploying from Specific Branches

#### 1. Bootstrap from Non-Main Branch
```bash
# Bootstrap Flux to track a specific branch (e.g., staging)
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=$GITHUB_REPO \
  --branch=staging \
  --path=./clusters/staging \
  --personal
```

#### 2. Create GitRepository Source for Different Branch
```bash
# Create a Git source that tracks a specific branch
flux create source git my-app \
  --url=https://github.com/$GITHUB_USER/my-app-repo \
  --branch=development \
  --interval=1m \
  --export > ./clusters/my-cluster/my-app-source.yaml
```

### Deploying from Specific Tags

#### 1. Create GitRepository Source with Tag
```bash
# Deploy from a specific tag
flux create source git my-app \
  --url=https://github.com/$GITHUB_USER/my-app-repo \
  --tag=v1.2.3 \
  --interval=1m \
  --export > ./clusters/my-cluster/my-app-source.yaml
```

#### 2. Create GitRepository with SemVer Tag Range
```bash
# Deploy from latest tag matching semantic version pattern
flux create source git my-app \
  --url=https://github.com/$GITHUB_USER/my-app-repo \
  --tag=">=1.0.0 <2.0.0" \
  --interval=5m \
  --export > ./clusters/my-cluster/my-app-source.yaml
```

### Manual GitRepository YAML Configuration

#### Branch-Based Deployment
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 1m
  ref:
    branch: production  # Specific branch
  url: https://github.com/username/my-app-repo
  secretRef:
    name: github-token  # Optional: for private repos
```

#### Tag-Based Deployment
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 5m
  ref:
    tag: "v1.2.3"  # Specific tag
  url: https://github.com/username/my-app-repo
```

#### SemVer Tag Range Deployment
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 5m
  ref:
    semver: ">=1.0.0 <2.0.0"  # SemVer range
  url: https://github.com/username/my-app-repo
```

#### Commit-Based Deployment
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 1m
  ref:
    commit: "a1b2c3d4e5f6"  # Specific commit SHA
  url: https://github.com/username/my-app-repo
```

### Multi-Environment Setup Example

#### Production Environment (Tags Only)
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: my-app-prod
  namespace: flux-system
spec:
  interval: 10m
  ref:
    semver: ">=1.0.0"
  url: https://github.com/username/my-app-repo
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-app-prod
  namespace: flux-system
spec:
  interval: 5m
  path: "./deploy/production"
  prune: true
  sourceRef:
    kind: GitRepository
    name: my-app-prod
```

#### Staging Environment (Development Branch)
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: my-app-staging
  namespace: flux-system
spec:
  interval: 1m
  ref:
    branch: develop
  url: https://github.com/username/my-app-repo
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-app-staging
  namespace: flux-system
spec:
  interval: 1m
  path: "./deploy/staging"
  prune: true
  sourceRef:
    kind: GitRepository
    name: my-app-staging
```

### Useful Commands for Branch/Tag Management

```bash
# Check current Git source status
flux get sources git

# Update Git source to track different branch
flux patch source git my-app --type merge -p '{"spec":{"ref":{"branch":"new-branch"}}}'

# Update Git source to track specific tag
flux patch source git my-app --type merge -p '{"spec":{"ref":{"tag":"v2.0.0"}}}'

# Force reconciliation after changing reference
flux reconcile source git my-app

# View Git source details including current revision
flux describe source git my-app

# Suspend Git source (stop tracking)
flux suspend source git my-app

# Resume Git source
flux resume source git my-app
```

### 1. Clone Your GitOps Repository

```bash
git clone https://github.com/$GITHUB_USER/$GITHUB_REPO.git
cd $GITHUB_REPO
```

### 2. Create Your First Application

Create a simple deployment:

```bash
mkdir -p ./apps/podinfo

cat << EOF > ./apps/podinfo/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: podinfo
  template:
    metadata:
      labels:
        app: podinfo
    spec:
      containers:
      - name: podinfo
        image: ghcr.io/stefanprodan/podinfo:6.4.0
        ports:
        - containerPort: 9898
---
apiVersion: v1
kind: Service
metadata:
  name: podinfo
  namespace: default
spec:
  selector:
    app: podinfo
  ports:
  - port: 80
    targetPort: 9898
EOF
```

### 3. Create Kustomization

```bash
cat << EOF > ./apps/podinfo/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
EOF
```

### 4. Create Flux Kustomization

```bash
flux create kustomization podinfo \
  --target-namespace=default \
  --source=flux-system \
  --path="./apps/podinfo" \
  --prune=true \
  --wait=true \
  --interval=30m \
  --retry-interval=2m \
  --health-check-timeout=3m \
  --export > ./clusters/my-cluster/podinfo-kustomization.yaml
```

### 5. Commit and Push

```bash
git add -A
git commit -m "Add podinfo application"
git push
```

### 6. Watch Deployment

```bash
# Watch Flux reconciliation
flux logs --follow --tail=10

# Check kustomizations
flux get kustomizations

# Check the deployed application
kubectl get pods -l app=podinfo
```

## Troubleshooting

### Common Issues

1. **Bootstrap fails with authentication error**
   ```bash
   # Verify GitHub token has correct permissions
   curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
   ```

2. **Flux components not starting**
   ```bash
   # Check logs
   kubectl logs -n flux-system deployment/source-controller
   kubectl logs -n flux-system deployment/kustomize-controller
   ```

3. **Git repository not syncing**
   ```bash
   # Force reconciliation
   flux reconcile source git flux-system
   
   # Check source status
   flux get sources git --all-namespaces
   ```

### Useful Commands

```bash
# Suspend/resume reconciliation
flux suspend kustomization <name>
flux resume kustomization <name>

# Force reconciliation
flux reconcile kustomization <name> --with-source

# Export existing resources
flux export kustomization <name>

# Uninstall Flux (if needed)
flux uninstall --namespace=flux-system
```

## Next Steps

1. Set up image automation for automatic updates
2. Configure notifications (Slack, Discord, etc.)
3. Implement multi-tenancy with separate namespaces
4. Add Helm repositories and releases
5. Set up monitoring and alerting for GitOps workflows

Your Flux CD installation is now complete and ready for GitOps workflows!
