# SOPS Configuration Reference

**Type:** Reference  
**Audience:** Platform engineers  
**Last Updated:** 2026-02-14

This document describes SOPS (Secrets OPerationS) configuration and usage in openCenter-gitops-base.

---

## SOPS Overview

SOPS encrypts secrets at rest in Git repositories using age encryption. FluxCD automatically decrypts secrets during reconciliation.

**Key Features:**
- Asymmetric encryption (age public/private keys)
- Selective field encryption (encrypt only sensitive fields)
- Git-safe encrypted files
- FluxCD integration for automatic decryption

---

## Age Key Generation

### Generate Age Keypair

```bash
# Create directory
mkdir -p ${HOME}/.config/sops/age

# Generate keypair
age-keygen -o ${HOME}/.config/sops/age/${CLUSTER_NAME}_keys.txt

# Output:
# Public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
# (private key stored in file)
```

### Extract Public Key

```bash
grep "# public key:" ${HOME}/.config/sops/age/${CLUSTER_NAME}_keys.txt
```

### Store Private Key in Kubernetes

```bash
kubectl create secret generic sops-age \
  --from-file=age.agekey=${HOME}/.config/sops/age/${CLUSTER_NAME}_keys.txt \
  -n flux-system
```

---

## .sops.yaml Configuration

SOPS configuration file defines encryption rules for different file patterns.

### Basic Configuration

```yaml
creation_rules:
  - path_regex: \.yaml$
    age: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
    encrypted_regex: ^(data|stringData)$
```

### Fields

| Field | Description |
|-------|-------------|
| `path_regex` | Regular expression matching file paths |
| `age` | Age public key for encryption |
| `encrypted_regex` | Regular expression matching YAML keys to encrypt |

---

## Common Configuration Patterns

### Pattern 1: Encrypt Specific Fields Only

Encrypt only `data` and `stringData` fields in Kubernetes Secrets:

```yaml
creation_rules:
  - path_regex: \.yaml$
    age: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
    encrypted_regex: ^(data|stringData)$
```

**Use case:** Kubernetes Secret manifests where only sensitive fields need encryption

### Pattern 2: Fully Encrypt Helm Values

Encrypt entire Helm values files:

```yaml
creation_rules:
  - path_regex: '^managed-services/.*/helm-values/.*\.ya?ml$'
    age: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
```

**Use case:** Helm values files containing sensitive configuration

### Pattern 3: Multiple Rules for Different Paths

Different encryption rules for different directories:

```yaml
creation_rules:
  # Managed services helm values - fully encrypted
  - path_regex: '^managed-services/.*/helm-values/.*\.ya?ml$'
    age: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
  
  # Services helm values - fully encrypted
  - path_regex: '^services/.*/helm-values/.*\.ya?ml$'
    age: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
  
  # Services YAML - only specific fields
  - path_regex: '^services/.*/.*\.ya?ml$'
    age: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
    encrypted_regex: "^(data|stringData|credentials)$"
  
  # SSH keys and kubeconfig - fully encrypted
  - path_regex: '^(id_rsa|id_rsa\.pub|kubeconfig\.yaml|.*\.creds)$'
    age: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
```

**Use case:** Complex repository with different encryption requirements per directory

### Pattern 4: Multiple Age Keys

Use different keys for different clusters:

```yaml
creation_rules:
  # Production cluster
  - path_regex: '^applications/overlays/prod/.*\.ya?ml$'
    age: age1prod1234567890abcdefghijklmnopqrstuvwxyz1234567890abc
  
  # Staging cluster
  - path_regex: '^applications/overlays/stage/.*\.ya?ml$'
    age: age1stage1234567890abcdefghijklmnopqrstuvwxyz1234567890ab
  
  # Development cluster
  - path_regex: '^applications/overlays/dev/.*\.ya?ml$'
    age: age1dev1234567890abcdefghijklmnopqrstuvwxyz1234567890abcd
```

**Use case:** Multi-cluster repository with separate encryption keys per environment

---

## SOPS Commands

### Encrypt File

```bash
# Encrypt in place
sops -e -i secret.yaml

# Encrypt to stdout
sops -e secret.yaml > secret.enc.yaml

# Encrypt with specific age key
sops -e --age age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p secret.yaml
```

### Decrypt File

```bash
# Decrypt to stdout
sops -d secret.yaml

# Decrypt to file
sops -d secret.yaml > secret.dec.yaml

# Decrypt in place (dangerous!)
sops -d -i secret.yaml
```

### Edit Encrypted File

```bash
# Edit with default editor
sops secret.yaml

# Edit with specific editor
EDITOR=vim sops secret.yaml
```

### Rotate Keys

```bash
# Update .sops.yaml with new age key
# Then rotate all files
sops updatekeys secret.yaml
```

### View Encrypted File Metadata

```bash
# Show encryption metadata
sops -s secret.yaml
```

---

## FluxCD Integration

### Kustomization with SOPS Decryption

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: platform-config
  path: ./applications/overlays/prod/cert-manager
  prune: true
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

### Decryption Fields

| Field | Description |
|-------|-------------|
| `decryption.provider` | Decryption provider (`sops`) |
| `decryption.secretRef.name` | Secret containing age private key |

---

## Kubernetes Secret Encryption

### Before Encryption

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: app
type: Opaque
stringData:
  username: admin
  password: super-secret-password
  connection-string: postgresql://admin:super-secret-password@db:5432/app
```

### After Encryption (Selective)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: app
type: Opaque
stringData:
  username: ENC[AES256_GCM,data:YWRtaW4=,iv:...,tag:...,type:str]
  password: ENC[AES256_GCM,data:c3VwZXItc2VjcmV0LXBhc3N3b3Jk,iv:...,tag:...,type:str]
  connection-string: ENC[AES256_GCM,data:cG9zdGdyZXNxbDovL2FkbWluOnN1cGVyLXNlY3JldC1wYXNzd29yZEBkYjo1NDMyL2FwcA==,iv:...,tag:...,type:str]
sops:
  kms: []
  gcp_kms: []
  azure_kv: []
  hc_vault: []
  age:
    - recipient: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
      enc: |
        -----BEGIN AGE ENCRYPTED FILE-----
        ...
        -----END AGE ENCRYPTED FILE-----
  lastmodified: "2026-02-14T10:30:00Z"
  mac: ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]
  pgp: []
  encrypted_regex: ^(data|stringData)$
  version: 3.8.1
```

---

## Helm Values Encryption

### Before Encryption

```yaml
# helm-values/override-values-v1.18.2.yaml
replicaCount: 3

database:
  host: postgres.example.com
  port: 5432
  username: app_user
  password: my-secret-password
  database: app_db

apiKeys:
  stripe: sk_live_1234567890abcdefghijklmnop
  sendgrid: SG.1234567890abcdefghijklmnopqrstuvwxyz
```

### After Encryption (Full File)

```yaml
replicaCount: ENC[AES256_GCM,data:Mw==,iv:...,tag:...,type:int]
database:
  host: ENC[AES256_GCM,data:cG9zdGdyZXMuZXhhbXBsZS5jb20=,iv:...,tag:...,type:str]
  port: ENC[AES256_GCM,data:NTQzMg==,iv:...,tag:...,type:int]
  username: ENC[AES256_GCM,data:YXBwX3VzZXI=,iv:...,tag:...,type:str]
  password: ENC[AES256_GCM,data:bXktc2VjcmV0LXBhc3N3b3Jk,iv:...,tag:...,type:str]
  database: ENC[AES256_GCM,data:YXBwX2Ri,iv:...,tag:...,type:str]
apiKeys:
  stripe: ENC[AES256_GCM,data:c2tfbGl2ZV8xMjM0NTY3ODkwYWJjZGVmZ2hpamtsbW5vcA==,iv:...,tag:...,type:str]
  sendgrid: ENC[AES256_GCM,data:U0cuMTIzNDU2Nzg5MGFiY2RlZmdoaWprbG1ub3BxcnN0dXZ3eHl6,iv:...,tag:...,type:str]
sops:
  age:
    - recipient: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
      enc: |
        -----BEGIN AGE ENCRYPTED FILE-----
        ...
        -----END AGE ENCRYPTED FILE-----
  lastmodified: "2026-02-14T10:30:00Z"
  mac: ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]
  version: 3.8.1
```

---

## Best Practices

### Key Management

1. **One key per cluster** - Each cluster has its own age keypair
2. **Backup keys securely** - Store private keys in secure vault (1Password, Vault)
3. **Rotate keys periodically** - Rotate age keys annually or after compromise
4. **Document key locations** - Maintain inventory of which keys encrypt which clusters

### Encryption Strategy

1. **Encrypt at rest** - All secrets encrypted before committing to Git
2. **Selective encryption** - Only encrypt sensitive fields when possible
3. **Full file encryption** - Encrypt entire Helm values files with secrets
4. **Never commit plaintext** - Use pre-commit hooks to prevent plaintext secrets

### File Organization

1. **Consistent .sops.yaml placement** - Place at repository root or cluster root
2. **Path-specific rules** - Use path_regex to match directory structure
3. **Document encryption rules** - Comment .sops.yaml with rule explanations

### Operational

1. **Test decryption** - Verify FluxCD can decrypt before committing
2. **Monitor decryption failures** - Alert on Kustomization decryption errors
3. **Audit encrypted files** - Regularly review what's encrypted
4. **Validate encryption** - Ensure no plaintext secrets in Git history

---

## Troubleshooting

### SOPS Cannot Find Age Key

**Error:** `failed to get the data key required to decrypt the SOPS file`

**Solution:**
```bash
# Set SOPS_AGE_KEY_FILE environment variable
export SOPS_AGE_KEY_FILE=${HOME}/.config/sops/age/${CLUSTER_NAME}_keys.txt

# Or use --age flag
sops -d --age $(cat ${HOME}/.config/sops/age/${CLUSTER_NAME}_keys.txt | grep "# public key:" | cut -d: -f2) secret.yaml
```

### FluxCD Decryption Fails

**Error:** `decryption failed: no age key found`

**Solution:**
```bash
# Verify sops-age secret exists
kubectl get secret sops-age -n flux-system

# Recreate if missing
kubectl create secret generic sops-age \
  --from-file=age.agekey=${HOME}/.config/sops/age/${CLUSTER_NAME}_keys.txt \
  -n flux-system
```

### Wrong Age Key Used

**Error:** `no age key found for recipient`

**Solution:**
```bash
# Check which age key encrypted the file
sops -s secret.yaml | grep age

# Update .sops.yaml with correct age key
# Then re-encrypt
sops updatekeys secret.yaml
```

### File Not Encrypted

**Error:** File committed with plaintext secrets

**Solution:**
```bash
# Encrypt the file
sops -e -i secret.yaml

# Amend commit
git add secret.yaml
git commit --amend --no-edit

# Force push (if already pushed)
git push --force-with-lease
```

### Cannot Edit Encrypted File

**Error:** `editor exited with non-zero status`

**Solution:**
```bash
# Set EDITOR environment variable
export EDITOR=vim

# Or specify editor inline
EDITOR=nano sops secret.yaml
```

---

## Security Considerations

### Key Storage

- **Private keys** - Never commit to Git; store in secure vault
- **Public keys** - Safe to commit in .sops.yaml
- **Kubernetes secrets** - Protect sops-age secret with RBAC

### Access Control

- **Age key access** - Limit who can access private keys
- **Git access** - Encrypted files still require Git access control
- **Kubernetes RBAC** - Restrict access to sops-age secret

### Encryption Strength

- **Age algorithm** - Uses ChaCha20-Poly1305 (strong encryption)
- **Key size** - 256-bit keys (industry standard)
- **No key escrow** - Only age key holder can decrypt

### Compliance

- **Encryption at rest** - Meets compliance requirements for secrets in Git
- **Audit trail** - Git history shows when secrets were updated
- **Key rotation** - Support for periodic key rotation

---

## Alternative: Sealed Secrets

openCenter also supports Bitnami Sealed Secrets as an alternative to SOPS.

### Comparison

| Feature | SOPS | Sealed Secrets |
|---------|------|----------------|
| Encryption | Age (asymmetric) | RSA (asymmetric) |
| Decryption | FluxCD | Controller in cluster |
| Key management | External (age keys) | Internal (cluster keys) |
| Offline decryption | Yes (with private key) | No (requires cluster) |
| Multi-cluster | One key per cluster | One key per cluster |
| Rotation | Manual (updatekeys) | Automatic (controller) |

### When to Use SOPS

- Need offline secret decryption
- Want Git-based key management
- Prefer FluxCD-native decryption
- Need to encrypt non-Kubernetes files

### When to Use Sealed Secrets

- Want automatic key rotation
- Prefer cluster-managed keys
- Don't need offline decryption
- Want simpler key management

---

## Evidence

**Source Files:**
- `customers/*/infrastructure/clusters/*/.sops.yaml` (configuration examples)
- `customers/*/applications/overlays/*/.sops.yaml` (overlay configurations)
- `docs/analysis/S4-FLUXCD-GITOPS.md` (SOPS workflow analysis)
- `docs/analysis/S7-SECURITY-GOVERNANCE.md` (secret management analysis)
- `llms.txt` lines 209-262 (SOPS workflow)
