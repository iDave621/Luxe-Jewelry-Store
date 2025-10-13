# Private Container Registry Setup for Kubernetes

This guide explains how to configure Kubernetes to pull images from a private Docker Hub registry.

## Overview

The Luxe Jewelry Store uses **private Docker Hub images** for all services:
- `idave621/luxe-jewelry-auth-service:latest`
- `idave621/luxe-jewelry-backend:latest`
- `idave621/luxe-jewelry-frontend:latest`

To pull these images, Kubernetes requires authentication credentials stored as a Secret.

---

## Quick Setup

**Prerequisites:** Have your Docker Hub access token ready (same one used in Jenkins)

### Option 1: Automated (Recommended)

Run the deployment script, which will prompt you to create the secret if it doesn't exist:

```powershell
.\deploy.ps1
```

When prompted:
1. Choose `y` to create the Docker registry secret
2. Enter your existing Docker Hub access token (from Jenkins `dockerhub` credential)

### Option 2: Manual

Create the secret manually before deployment:

```powershell
.\create-docker-secret.ps1
```

Enter your existing Docker Hub access token when prompted.

Then run deployment:

```powershell
.\deploy.ps1
```

---

## How It Works

### 1. Docker Registry Secret

A Kubernetes secret of type `kubernetes.io/dockerconfigjson` stores your Docker Hub credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: dockerhub-secret
  namespace: luxe-jewelry
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-docker-config>
```

### 2. ImagePullSecrets in Deployments

Each deployment references the secret to authenticate when pulling images:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  template:
    spec:
      imagePullSecrets:
      - name: dockerhub-secret
      containers:
      - name: backend
        image: idave621/luxe-jewelry-backend:latest
```

---

## Manual Secret Creation

If you prefer to create the secret manually using kubectl:

```powershell
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=iDave621 \
  --docker-password=<your-password-or-token> \
  --docker-email=<your-email> \
  -n luxe-jewelry
```

**Important:** Use your existing Docker Hub **Access Token** (the same one used in Jenkins with credential ID `dockerhub`).

### Using Your Existing Docker Hub Access Token

**You already have a Docker Hub access token configured!**

- **Username:** `iDave621`
- **Token:** Use the same token from your Jenkins `dockerhub` credential

When running `create-docker-secret.ps1`, simply paste your existing Docker Hub access token when prompted.

### If You Need a New Token

1. Log in to [Docker Hub](https://hub.docker.com/)
2. Go to **Account Settings** → **Security**
3. Click **New Access Token**
4. Name it (e.g., "kubernetes-pull")
5. Set permissions to **Read, Write, Delete** (or **Read-only** if you only need pull access)
6. Copy the generated token
7. Use this token when creating the Kubernetes secret

---

## Verifying the Secret

Check if the secret exists:

```powershell
kubectl get secret dockerhub-secret -n luxe-jewelry
```

View secret details (without exposing credentials):

```powershell
kubectl describe secret dockerhub-secret -n luxe-jewelry
```

---

## Updated Deployment Files

All deployment files have been updated with:

1. **Image paths** pointing to `idave621/*` registry
2. **imagePullSecrets** configured to use `dockerhub-secret`
3. **imagePullPolicy** set to `Always` to ensure latest images

### Files Updated:
- `auth-service-deployment.yaml`
- `backend-deployment.yaml`
- `frontend-deployment.yaml`

---

## Troubleshooting

### Error: ImagePullBackOff

If you see this error:

```
Failed to pull image "idave621/luxe-jewelry-backend:latest": 
rpc error: code = Unknown desc = Error response from daemon: 
pull access denied for idave621/luxe-jewelry-backend
```

**Solutions:**

1. **Check if secret exists:**
   ```powershell
   kubectl get secret dockerhub-secret -n luxe-jewelry
   ```

2. **Recreate the secret:**
   ```powershell
   kubectl delete secret dockerhub-secret -n luxe-jewelry
   .\create-docker-secret.ps1
   ```

3. **Verify credentials:**
   - Ensure username is correct: `iDave621`
   - Ensure password/token is valid
   - Test login manually:
     ```powershell
     docker login
     ```

4. **Check deployment configuration:**
   ```powershell
   kubectl describe pod <pod-name> -n luxe-jewelry
   ```

5. **Restart deployment:**
   ```powershell
   kubectl rollout restart deployment/backend -n luxe-jewelry
   ```

### Error: Secret "dockerhub-secret" not found

The secret doesn't exist in the namespace. Run:

```powershell
.\create-docker-secret.ps1
```

---

## CI/CD Integration

For Jenkins or automated deployments, create the secret using environment variables:

```groovy
withCredentials([usernamePassword(
    credentialsId: 'dockerhub',
    usernameVariable: 'DOCKER_USER',
    passwordVariable: 'DOCKER_PASS'
)]) {
    sh """
        kubectl create secret docker-registry dockerhub-secret \
            --docker-server=https://index.docker.io/v1/ \
            --docker-username=${DOCKER_USER} \
            --docker-password=${DOCKER_PASS} \
            -n luxe-jewelry \
            --dry-run=client -o yaml | kubectl apply -f -
    """
}
```

---

## Security Best Practices

1. **Use Access Tokens**: Never use your Docker Hub password directly
2. **Read-Only Tokens**: Create tokens with minimal permissions (read-only)
3. **Rotate Regularly**: Update tokens periodically
4. **Namespace Isolation**: Keep secrets in specific namespaces
5. **RBAC**: Restrict who can view secrets

---

## Reference

- [Kubernetes: Pull Image from Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)
- [Docker Hub Access Tokens](https://docs.docker.com/docker-hub/access-tokens/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

---

## Summary

✅ **Created Files:**
- `create-docker-secret.ps1` - Helper script to create the secret
- `docker-registry-secret.yaml` - Template (reference only)
- `PRIVATE-REGISTRY-SETUP.md` - This guide

✅ **Updated Files:**
- `auth-service-deployment.yaml` - Added imagePullSecrets
- `backend-deployment.yaml` - Added imagePullSecrets
- `frontend-deployment.yaml` - Added imagePullSecrets
- `deploy.ps1` - Added secret validation step

✅ **Registry Details:**
- **Registry:** Docker Hub (index.docker.io)
- **Username:** iDave621
- **Images:** idave621/luxe-jewelry-*

**You're all set!** Run `.\deploy.ps1` to deploy with private registry support. 🚀
