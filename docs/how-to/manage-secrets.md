---
doc_type: how-to
title: "Manage Secrets with SOPS"
audience: "platform engineers"
---

# Manage Secrets with SOPS

**Purpose:** For platform engineers, shows how to encrypt and decrypt secrets using SOPS with age encryption, covering key generation, configuration, and GitOps integration.

## Prerequisites

- SOPS installed (`sops --version`)
- age installed (`age --version`)
- Git access to repository
- kubectl access to cluster

## Install Tools

### Install SOPS

```bash
# macOS
brew install sops

# Linux
curl -LO https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64
sudo mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops
sudo chmod +x /usr/local/bin/sops
```

### Install age

```bash
# macOS
brew install age

# Linux
curl -LO https://github.com/FiloSottile/age/releases/download/v1.1.1/age-v1.1.1-linux-amd64.tar.gz
tar xzf age-v1.1.1-linux-amd64.tar.gz
sudo mv age/age /usr/local/bin/
sudo mv age/age-keygen /usr/local/bin/
```

## Steps

### 1. Generate age keypair

```bash
# Create directory for keys
mkdir -p ~/.config/sops/age/

# Generate keypair for cluster
age-keygen -o ~/.config/sops/age/k8s-sandbox_keys.txt
```

Output:
```
# created: 2024-02-14T10:30:00Z
# public key: age1abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567
AGE-SECRET-KEY-1ABC123DEF456GHI789JKL012MNO345PQR678STU901VWX234YZ567
```

Save the public key (starts with `age1`).

### 2. Configure SOPS for repository

Create `.sops.yaml` in repository root:

```yaml
creation_rules:
  # Encrypt all YAML files in secrets/ directory
  - path_regex: secrets/.*\.yaml$
    age: age1abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567
  
  # Encrypt override values with sensitive data
  - path_regex: applications/overlays/.*/.*override.*\.yaml$
    encrypted_regex: ^(data|stringData|password|token|key|secret|cert|ca|tls)$
    age: age1abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567
  
  # Encrypt all files in infrastructure/credentials/
  - path_regex: infrastructure/.*/credentials/.*
    age: age1abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567
```

Commit `.sops.yaml`:

```bash
git add .sops.yaml
git commit -m "feat(security): configure SOPS encryption"
git push origin main
```

### 3. Create secret file

Create `secrets/database-credentials.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: my-service
type: Opaque
stringData:
  username: admin
  password: super-secret-password
  connection-string: postgresql://admin:super-secret-password@postgres:5432/mydb
```

### 4. Encrypt secret

```bash
# Encrypt in place
sops -e -i secrets/database-credentials.yaml

# Or encrypt to new file
sops -e secrets/database-credentials.yaml > secrets/database-credentials.enc.yaml
```

Encrypted file looks like:

```yaml
apiVersion: v1
kind: Secret
metadata:
    name: database-credentials
    namespace: my-service
type: Opaque
stringData:
    username: ENC[AES256_GCM,data:abc123,iv:def456,tag:ghi789,type:str]
    password: ENC[AES256_GCM,data:jkl012,iv:mno345,tag:pqr678,type:str]
    connection-string: ENC[AES256_GCM,data:stu901,iv:vwx234,tag:yz567,type:str]
sops:
    kms: []
    gcp_kms: []
    azure_kv: []
    hc_vault: []
    age:
        - recipient: age1abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567
            -----END AGE ENCRYPTED FILE-----
    lastmodified: "2024-02-14T10:35:00Z"
    mac: ENC[AES256_GCM,data:abc123,iv:def456,tag:ghi789,type:str]
    pgp: []
    encrypted_regex: ^(data|stringData)$
    version: 3.8.1
```

### 5. Commit encrypted secret

```bash
git add secrets/database-credentials.yaml
git commit -m "feat(secrets): add database credentials"
git push origin main
```

### 6. Create age key secret in cluster

```bash
# Create namespace if needed
kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -

# Create secret with age private key
kubectl create secret generic sops-age \
  --from-file=age.agekey=${HOME}/.config/sops/age/k8s-sandbox_keys.txt \
  -n flux-system
```

Verify:

```bash
kubectl get secret sops-age -n flux-system
```

### 7. Configure FluxCD Kustomization for decryption

In customer overlay `applications/overlays/k8s-sandbox/kustomization.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-service
  namespace: flux-system
spec:
  interval: 5m
  path: ./applications/overlays/k8s-sandbox/services/my-service
  prune: true
  sourceRef:
    kind: GitRepository
    name: platform-config
  
  # Enable SOPS decryption
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

### 8. Apply and verify

```bash
# Force reconciliation
flux reconcile kustomization my-service -n flux-system

# Check secret was decrypted and applied
kubectl get secret database-credentials -n my-service

# Verify decrypted values (base64 encoded)
kubectl get secret database-credentials -n my-service -o jsonpath='{.data.username}' | base64 -d
```

## Decrypt Locally

To view or edit encrypted secrets:

```bash
# View decrypted content
sops -d secrets/database-credentials.yaml

# Edit encrypted file (decrypts, opens editor, re-encrypts on save)
sops secrets/database-credentials.yaml

# Decrypt to file
sops -d secrets/database-credentials.yaml > /tmp/decrypted.yaml
```

## Rotate Age Keys

### 1. Generate new keypair

```bash
age-keygen -o ~/.config/sops/age/k8s-sandbox_keys_new.txt
```

### 2. Update .sops.yaml with new public key

```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    age: age1NEW_PUBLIC_KEY_HERE
```

### 3. Re-encrypt all secrets

```bash
# Re-encrypt with new key
find secrets/ -name "*.yaml" -exec sops updatekeys -y {} \;

# Or use rotate command
sops rotate -i secrets/database-credentials.yaml
```

### 4. Update cluster secret

```bash
kubectl delete secret sops-age -n flux-system

kubectl create secret generic sops-age \
  --from-file=age.agekey=${HOME}/.config/sops/age/k8s-sandbox_keys_new.txt \
  -n flux-system
```

### 5. Verify decryption still works

```bash
flux reconcile kustomization my-service -n flux-system
kubectl get secret database-credentials -n my-service
```

## Partial Encryption

Encrypt only specific fields using `encrypted_regex`:

`.sops.yaml`:

```yaml
creation_rules:
  - path_regex: applications/overlays/.*/override-values\.yaml$
    encrypted_regex: ^(password|token|apiKey|secret|privateKey)$
    age: age1abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567
```

File `override-values.yaml`:

```yaml
# Unencrypted
replicaCount: 3
logLevel: info

# Encrypted (matches regex)
database:
  password: super-secret  # Will be encrypted
  host: postgres.example.com  # Will NOT be encrypted
  
api:
  token: abc123  # Will be encrypted
  endpoint: https://api.example.com  # Will NOT be encrypted
```

After `sops -e -i override-values.yaml`:

```yaml
replicaCount: 3
logLevel: info
database:
    password: ENC[AES256_GCM,data:abc123,iv:def456,tag:ghi789,type:str]
    host: postgres.example.com
api:
    token: ENC[AES256_GCM,data:jkl012,iv:mno345,tag:pqr678,type:str]
    endpoint: https://api.example.com
sops:
    # ... encryption metadata
```

## Troubleshooting

### "no age key found" error

Ensure age key is in correct location:

```bash
ls -la ~/.config/sops/age/
```

Set SOPS_AGE_KEY_FILE environment variable:

```bash
export SOPS_AGE_KEY_FILE=${HOME}/.config/sops/age/k8s-sandbox_keys.txt
sops -d secrets/database-credentials.yaml
```

### FluxCD decryption fails

Check age secret exists:

```bash
kubectl get secret sops-age -n flux-system
```

Check Kustomization has decryption configured:

```bash
kubectl get kustomization my-service -n flux-system -o jsonpath='{.spec.decryption}'
```

View FluxCD logs:

```bash
flux logs --kind=Kustomization --name=my-service
```

### "MAC mismatch" error

File was modified after encryption. Re-encrypt:

```bash
sops -d secrets/database-credentials.yaml > /tmp/decrypted.yaml
sops -e /tmp/decrypted.yaml > secrets/database-credentials.yaml
rm /tmp/decrypted.yaml
```

### Multiple age keys

To decrypt with multiple keys, add all public keys to `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    age: >-
      age1abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567,
      age1xyz789abc012def345ghi678jkl901mno234pqr567stu890vwx123
```

## Best Practices

1. **Never commit plaintext secrets** - Always encrypt before committing
2. **Backup age keys securely** - Store in password manager or vault
3. **Use separate keys per cluster** - Limit blast radius
4. **Rotate keys periodically** - Every 90 days recommended
5. **Use encrypted_regex for partial encryption** - Keep non-sensitive data readable
6. **Test decryption in CI/CD** - Catch encryption issues early
7. **Document key locations** - Team members need access for emergencies

## Alternative: Sealed Secrets

For comparison, Sealed Secrets is also available in openCenter-gitops-base. Use SOPS when:
- You need offline encryption/decryption
- You want key management outside cluster
- You need to encrypt non-Kubernetes files

Use Sealed Secrets when:
- You want controller-based decryption
- You prefer cluster-managed keys
- You only encrypt Kubernetes Secrets

## Next Steps

- Configure Helm values with encrypted secrets (see [configure-helm-values.md](configure-helm-values.md))
- Set up observability for secret rotation (see [setup-observability.md](setup-observability.md))
- Implement secret rotation automation

## Evidence

**Sources:**
- `llms.txt` lines 209-262 - SOPS workflow
- `docs/service-standards-and-lifecycle.md` lines 48-55 - Security requirements
- S4-FLUXCD-GITOPS.md - SOPS secret management
- S7-SECURITY-GOVERNANCE.md - Dual secret management strategy
