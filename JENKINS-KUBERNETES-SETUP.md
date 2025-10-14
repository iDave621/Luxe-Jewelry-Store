# Jenkins Kubernetes Cloud Setup Guide

## ✅ Step 1: Kubernetes Resources Created

The following resources have been created in your Kubernetes cluster:

- ✅ **Namespace:** `jenkins`
- ✅ **Service Account:** `jenkins` (in jenkins namespace)
- ✅ **ClusterRole:** Permissions for Jenkins to create pods
- ✅ **ClusterRoleBinding:** Links service account to cluster role
- ✅ **RoleBinding:** Allows Jenkins to deploy to `luxe-jewelry` namespace
- ✅ **Token Secret:** Long-lived token for Jenkins authentication

## 📋 Step 2: Install Kubernetes Plugin in Jenkins

1. Go to Jenkins: `http://localhost:8080`
2. Navigate to: **Manage Jenkins** → **Plugins** → **Available plugins**
3. Search for: **Kubernetes**
4. Install: **Kubernetes plugin**
5. Restart Jenkins after installation

## 🔧 Step 3: Configure Kubernetes Cloud in Jenkins

### A. Navigate to Cloud Configuration

1. Go to: **Manage Jenkins** → **Clouds**
2. Click: **New cloud**
3. Name it: `kubernetes`
4. Type: **Kubernetes**

### B. Kubernetes Configuration

Enter these values:

| Field | Value |
|-------|-------|
| **Kubernetes URL** | `https://127.0.0.1:52961` |
| **Kubernetes Namespace** | `jenkins` |
| **Credentials** | Create new "Secret text" credential (see below) |
| **Jenkins URL** | `http://host.docker.internal:8080` |
| **Jenkins tunnel** | `host.docker.internal:50000` |

### C. Create Kubernetes Credential

1. Click **Add** next to Credentials
2. Kind: **Secret text**
3. Scope: **Global**
4. Secret: Paste the token below
5. ID: `kubernetes-token`
6. Description: `Jenkins Kubernetes Service Account Token`

**Token to use:**
```
eyJhbGciOiJSUzI1NiIsImtpZCI6IlBoZDB0SVIxMTAtOFZfd3FUaVVQOVJZdXBiVjBwRkJTbF8zMUdlcHBPaEEifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJqZW5raW5zIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImplbmtpbnMtdG9rZW4iLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiamVua2lucyIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjVmZDM1ZDZhLTg1NTYtNGZiNC1hNDQ0LTFhMjM4ODY3NTUyMiIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpqZW5raW5zOmplbmtpbnMifQ.hiqH8pBYCvwzgvkFmOk5hLJo9V6S9iUV-mG2m7uxKTBkJLLQF2-is-iKd5AMeRuZbxsD9CFEytp1GK3ko43O0by523MXbHrTjoFUfD1XZWHAxk7k9g-D8Lfe4FceSjCE_n9kkIj8NdfTHOOclUA72RO6VFODF3KzdESAHLGFCbR7HZdYRKYsz3uyFg9i-gZOyQZCHTGnAFcFIAvjbbU-VDQOt2alAAslOGm6rRmxf5M-PVew2Joy3m5sJXAV4_-kN5hZltRyaBdRbJPG26Az7B5j2UGTPWvoKlb-etg6kRJf-yFm1fDZpQ3QtaL3wE6JDXdsCj_elWX3RjCxh77uCg
```

### D. Test Connection

1. Click **Test Connection**
2. You should see: ✅ **Connection test successful**

### E. Pod Templates (Optional)

You can configure a default pod template here, but we'll define it in the Jenkinsfile instead for flexibility.

## 🚀 Step 4: Update Jenkinsfile

The Jenkinsfile will be updated to use:
```groovy
agent {
  kubernetes {
    yaml '''
      apiVersion: v1
      kind: Pod
      spec:
        containers:
        - name: docker
          image: docker:latest
          command:
          - cat
          tty: true
          volumeMounts:
          - name: docker-sock
            mountPath: /var/run/docker.sock
        - name: kubectl
          image: bitnami/kubectl:latest
          command:
          - cat
          tty: true
        volumes:
        - name: docker-sock
          hostPath:
            path: /var/run/docker.sock
    '''
  }
}
```

## 📝 Important Notes

### Network Configuration

Since Jenkins is running in Docker and needs to connect to Minikube:
- Use `host.docker.internal` to reference the host machine
- Ensure Minikube API is accessible from Docker containers

### Verification Commands

```bash
# Check Jenkins namespace
kubectl get all -n jenkins

# Check service account
kubectl get serviceaccount jenkins -n jenkins

# Check if Jenkins can create pods
kubectl auth can-i create pods --as=system:serviceaccount:jenkins:jenkins -n jenkins
```

## 🎯 What Happens Next

1. When a pipeline runs, Jenkins will:
   - Create a pod in the `jenkins` namespace
   - Run the build stages in that pod
   - Delete the pod when done
   
2. Dynamic scaling:
   - Pods are created on-demand
   - Multiple builds = multiple pods
   - Automatic cleanup

## 🔍 Troubleshooting

### If connection fails:

```bash
# Check Minikube IP
minikube ip

# Check if API server is accessible
curl -k https://127.0.0.1:52961

# Verify service account token
kubectl describe secret jenkins-token -n jenkins
```

### If pods don't start:

```bash
# Check pod events
kubectl get events -n jenkins --sort-by='.lastTimestamp'

# Check pod logs
kubectl logs -n jenkins <pod-name>
```

---

**Made with ❤️ for Luxe Jewelry Store**
