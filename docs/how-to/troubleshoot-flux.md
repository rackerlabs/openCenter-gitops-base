---
doc_type: how-to
title: "Troubleshoot FluxCD Reconciliation"
audience: "platform engineers"
---

# Troubleshoot FluxCD Reconciliation

**Purpose:** For platform engineers, shows how to debug FluxCD reconciliation issues, covering status checks, log analysis, common errors, and remediation steps.

## Prerequisites

- FluxCD installed in cluster
- flux CLI installed (`flux version`)
- kubectl access to cluster
- Basic understanding of FluxCD resources

## Quick Diagnostics

### Check overall Flux health

```bash
# Check all Flux components
flux check

# Check Flux controllers
kubectl get pods -n flux-system

# Check Flux version
flux version
```

Expected output:
```
✔ All checks passed
```

### Check resource status

```bash
# Check all Flux resources
flux get all

# Check specific resource types
flux get sources git
flux get sources helm
flux get helmreleases
flux get kustomizations
```

## Common Issues and Solutions

### Issue 1: GitRepository Authentication Failure

**Symptom:**

```bash
flux get sources git
NAME                    READY   MESSAGE
opencenter-base         False   authentication required
```

**Diagnosis:**

```bash
kubectl describe gitrepository opencenter-base -n flux-system
```

Look for:
```
Message: unable to clone: authentication required
```

**Solution:**

Verify SSH key secret exists:

```bash
kubectl get secret opencenter-base -n flux-system
```

If missing, recreate:

```bash
flux create secret git opencenter-base \
  --url=ssh://git@github.com/rackerlabs/openCenter-gitops-base.git \
  --ssh-key-algorithm=ed25519 \
  --namespace=flux-system
```

Add public key to GitHub repository as deploy key.

Verify SSH key format:

```bash
kubectl get secret opencenter-base -n flux-system -o jsonpath='{.data.identity}' | base64 -d | head -1
```

Should start with `-----BEGIN OPENSSH PRIVATE KEY-----`.

Force reconciliation:

```bash
flux reconcile source git opencenter-base
```

### Issue 2: HelmRelease Stuck in "Installing"

**Symptom:**

```bash
flux get helmreleases -n cert-manager
NAME            READY   MESSAGE
cert-manager    False   install retries exhausted
```

**Diagnosis:**

```bash
kubectl describe helmrelease cert-manager -n cert-manager
```

Check events:

```bash
kubectl get events -n cert-manager --sort-by='.lastTimestamp'
```

View Helm controller logs:

```bash
flux logs --kind=HelmRelease --name=cert-manager --namespace=cert-manager
```

**Common Causes:**

1. **Helm repository not accessible**

```bash
flux get sources helm
kubectl describe helmrepository cert-manager -n flux-system
```

2. **Chart version not found**

Check HelmRelease chart version:

```bash
kubectl get helmrelease cert-manager -n cert-manager -o jsonpath='{.spec.chart.spec.version}'
```

Check available versions:

```bash
helm search repo cert-manager --versions
```

3. **Values validation failed**

Check values secrets:

```bash
kubectl get secret cert-manager-values-base -n cert-manager
```

Decode and validate:

```bash
kubectl get secret cert-manager-values-base -n cert-manager -o jsonpath='{.data.values\.yaml}' | base64 -d | yq eval
```

**Solution:**

Suspend and resume HelmRelease:

```bash
flux suspend helmrelease cert-manager -n cert-manager
flux resume helmrelease cert-manager -n cert-manager
```

Or delete and let Flux recreate:

```bash
kubectl delete helmrelease cert-manager -n cert-manager
flux reconcile kustomization cert-manager
```

### Issue 3: Kustomization Drift Detected

**Symptom:**

```bash
flux get kustomizations
NAME            READY   MESSAGE
cert-manager    True    Applied revision: main@sha1:abc123, drift detected
```

**Diagnosis:**

```bash
kubectl describe kustomization cert-manager -n flux-system
```

Check drift detection mode:

```bash
kubectl get kustomization cert-manager -n flux-system -o jsonpath='{.spec.driftDetection.mode}'
```

**Cause:**

Resources were modified outside of Git (manual kubectl apply or Helm upgrade).

**Solution:**

View drifted resources:

```bash
flux diff kustomization cert-manager
```

Force reconciliation to restore Git state:

```bash
flux reconcile kustomization cert-manager --with-source
```

Prevent drift by enabling remediation:

```yaml
spec:
  driftDetection:
    mode: enabled
  prune: true
  force: true  # Force apply even if resources exist
```

### Issue 4: SOPS Decryption Failed

**Symptom:**

```bash
flux get kustomizations
NAME            READY   MESSAGE
my-service      False   decryption failed
```

**Diagnosis:**

```bash
kubectl describe kustomization my-service -n flux-system
```

Look for:
```
Message: failed to decrypt secret: no age key found
```

**Solution:**

Check age key secret exists:

```bash
kubectl get secret sops-age -n flux-system
```

If missing, create:

```bash
kubectl create secret generic sops-age \
  --from-file=age.agekey=${HOME}/.config/sops/age/k8s-sandbox_keys.txt \
  -n flux-system
```

Verify Kustomization references secret:

```bash
kubectl get kustomization my-service -n flux-system -o jsonpath='{.spec.decryption}'
```

Should show:
```json
{"provider":"sops","secretRef":{"name":"sops-age"}}
```

Force reconciliation:

```bash
flux reconcile kustomization my-service
```

### Issue 5: Dependency Wait Timeout

**Symptom:**

```bash
flux get kustomizations
NAME                READY   MESSAGE
cert-manager-certs  False   dependency 'cert-manager' is not ready
```

**Diagnosis:**

```bash
kubectl describe kustomization cert-manager-certs -n flux-system
```

Check dependency status:

```bash
flux get kustomizations | grep cert-manager
```

**Solution:**

Check dependency is healthy:

```bash
kubectl get kustomization cert-manager -n flux-system
```

If dependency is stuck, troubleshoot it first.

If dependency is ready but not detected, force reconciliation:

```bash
flux reconcile kustomization cert-manager
flux reconcile kustomization cert-manager-certs
```

Increase timeout if needed:

```yaml
spec:
  dependsOn:
    - name: cert-manager
  timeout: 10m  # Increase from default 5m
```

### Issue 6: Image Pull Errors

**Symptom:**

HelmRelease shows ready, but pods fail to start:

```bash
kubectl get pods -n cert-manager
NAME                           READY   STATUS             RESTARTS   AGE
cert-manager-5d7f9c8b6-abc12   0/1     ImagePullBackOff   0          2m
```

**Diagnosis:**

```bash
kubectl describe pod cert-manager-5d7f9c8b6-abc12 -n cert-manager
```

Look for:
```
Failed to pull image "registry.example.com/cert-manager:v1.18.2": rpc error: code = Unknown desc = failed to pull and unpack image
```

**Solution:**

Check image exists:

```bash
# For public images
docker pull registry.example.com/cert-manager:v1.18.2

# For private registries
kubectl get secret -n cert-manager | grep regcred
```

Create image pull secret if needed:

```bash
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass \
  -n cert-manager
```

Update HelmRelease values:

```yaml
imagePullSecrets:
  - name: regcred
```

### Issue 7: Resource Quota Exceeded

**Symptom:**

```bash
flux logs --kind=HelmRelease --name=my-service
Error: admission webhook denied the request: exceeded quota
```

**Diagnosis:**

```bash
kubectl describe resourcequota -n my-service
```

**Solution:**

Increase quota:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: my-service-quota
  namespace: my-service
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
```

Or reduce resource requests in Helm values.

### Issue 8: Webhook Timeout

**Symptom:**

```bash
flux logs --kind=Kustomization --name=my-service
Error: context deadline exceeded
```

**Diagnosis:**

Check admission webhooks:

```bash
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations
```

**Solution:**

Check webhook service is running:

```bash
kubectl get pods -n kyverno
kubectl get pods -n cert-manager
```

If webhook is down, suspend Kustomization temporarily:

```bash
flux suspend kustomization my-service
# Fix webhook
flux resume kustomization my-service
```

Increase timeout:

```yaml
spec:
  timeout: 10m
```

## Debugging Commands

### View Flux controller logs

```bash
# All controllers
flux logs

# Specific controller
flux logs --kind=Kustomization --name=my-service

# Follow logs
flux logs --follow

# Last 100 lines
flux logs --tail=100
```

### Force reconciliation

```bash
# Reconcile source
flux reconcile source git opencenter-base

# Reconcile Kustomization
flux reconcile kustomization my-service

# Reconcile with source update
flux reconcile kustomization my-service --with-source

# Reconcile HelmRelease
flux reconcile helmrelease my-service -n my-service
```

### Suspend and resume

```bash
# Suspend (stop reconciliation)
flux suspend kustomization my-service

# Resume
flux resume kustomization my-service
```

### Export and inspect resources

```bash
# Export GitRepository
flux export source git opencenter-base

# Export HelmRelease
flux export helmrelease cert-manager -n cert-manager

# Export Kustomization
flux export kustomization my-service
```

### Trace reconciliation

```bash
# Trace Kustomization
flux trace kustomization my-service

# Shows:
# - Source
# - Dependencies
# - Applied resources
# - Health checks
```

## Verification Checklist

After resolving issues:

```bash
# 1. All sources are ready
flux get sources git
flux get sources helm

# 2. All Kustomizations are ready
flux get kustomizations

# 3. All HelmReleases are ready
flux get helmreleases --all-namespaces

# 4. No suspended resources
flux get all | grep -i suspended

# 5. Check recent events
kubectl get events -n flux-system --sort-by='.lastTimestamp' | tail -20
```

## Prevention Best Practices

1. **Pin versions** - Use specific tags/versions, not `latest`
2. **Test in non-production** - Validate changes before production
3. **Use health checks** - Configure readiness/liveness probes
4. **Set resource limits** - Prevent resource exhaustion
5. **Monitor Flux** - Set up alerts for reconciliation failures
6. **Backup age keys** - Store SOPS keys securely
7. **Document dependencies** - Clear dependency chains
8. **Use drift detection** - Catch manual changes
9. **Implement retries** - Configure remediation policies
10. **Regular upgrades** - Keep Flux up to date

## Emergency Procedures

### Complete Flux failure

If all Flux controllers are down:

```bash
# Check controller pods
kubectl get pods -n flux-system

# Restart controllers
kubectl rollout restart deployment -n flux-system

# If that fails, reinstall Flux
flux uninstall --silent
flux bootstrap git \
  --url=ssh://git@github.com/${GIT_REPO}.git \
  --branch=main \
  --path=applications/overlays/${CLUSTER_NAME}
```

### Rollback to previous version

```bash
# Find previous commit
git log --oneline

# Revert to previous commit
git revert HEAD
git push origin main

# Force reconciliation
flux reconcile source git opencenter-base
flux reconcile kustomization my-service
```

### Manual intervention required

If Flux cannot recover:

```bash
# Suspend Flux
flux suspend kustomization my-service

# Apply manually
kubectl apply -f applications/overlays/k8s-sandbox/services/my-service/

# Resume Flux
flux resume kustomization my-service
```

## Next Steps

- Set up Flux monitoring (see [setup-observability.md](setup-observability.md))
- Configure Flux notifications (Slack, PagerDuty)
- Implement automated testing for Flux resources
- Create runbooks for common Flux issues

## Evidence

**Sources:**
- `llms.txt` lines 19-262 - Flux bootstrap and patterns
- `docs/service-standards-and-lifecycle.md` lines 82-174 - GitOps architecture
- S4-FLUXCD-GITOPS.md - FluxCD configuration and patterns
- S1-APP-RUNTIME-APIS.md - HelmRelease patterns
