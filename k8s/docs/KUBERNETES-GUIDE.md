# Complete Kubernetes Deployment Guide
## Luxe Jewelry Store

---

## Table of Contents
1. [Quick Start](#quick-start)
2. [Prerequisites](#prerequisites)
3. [Private Registry Setup](#private-registry-setup)
4. [Installation](#installation)
5. [Deployment](#deployment)
6. [Resource Management & Auto-Scaling](#resource-management--auto-scaling)
7. [Accessing the Application](#accessing-the-application)
8. [Monitoring & Troubleshooting](#monitoring--troubleshooting)
9. [Management Commands](#management-commands)
10. [Jenkins Integration](#jenkins-integration)
11. [Assignment Completion](#assignment-completion)

---

## Quick Start

### TL;DR - Deploy in 3 Commands

```powershell
# 1. Start Minikube (first time only)
minikube start --driver=docker

# 2. Deploy everything (includes health checks & verification)
cd Luxe-Jewelry-Store\k8s
.\deploy.ps1

# 3. Start port-forward tunnels (Windows Docker Driver)
.\start-tunnels.ps1

# Then access: http://localhost:3000

# Stop tunnels
.\stop-tunnels.ps1

# Cleanup deployment
.\cleanup.ps1
```

---

## Prerequisites

### Required Software

| Tool | Purpose | Installation |
|------|---------|--------------|
| **Minikube** | Local Kubernetes cluster | `choco install minikube` |
| **kubectl** | Kubernetes CLI | `choco install kubernetes-cli` |
| **Docker** | Container runtime | `choco install docker-desktop` |

### Verify Installation

```powershell
minikube version
kubectl version --client
docker --version
```

### Install Chocolatey (if needed)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

---

## Private Registry Setup

The application uses **private Docker Hub images** that require authentication.

### Container Images

All services pull from private registry:
- `idave621/luxe-jewelry-auth-service:latest`
- `idave621/luxe-jewelry-backend:latest`
- `idave621/luxe-jewelry-frontend:latest`

### Setup Docker Registry Secret

The deployment script will automatically prompt you to create the Docker registry secret if it doesn't exist.

**Important:** Use your existing Docker Hub access token (same one from Jenkins `dockerhub` credential)

**Option 1: Let deploy.ps1 handle it (Recommended)**
```powershell
.\deploy.ps1
# Choose 'y' when prompted
# Enter your Docker Hub access token (same as Jenkins)
```

**Option 2: Create manually before deployment**
```powershell
.\create-docker-secret.ps1
# Enter your Docker Hub access token when prompted
```

### What Gets Created

A Kubernetes secret named `dockerhub-secret` containing Docker Hub credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: dockerhub-secret
  namespace: luxe-jewelry
type: kubernetes.io/dockerconfigjson
```

All deployments reference this secret via `imagePullSecrets`:

```yaml
spec:
  template:
    spec:
      imagePullSecrets:
      - name: dockerhub-secret
```

### Troubleshooting

If you see `ImagePullBackOff` errors:

```powershell
# Check if secret exists
kubectl get secret dockerhub-secret -n luxe-jewelry

# Recreate the secret
kubectl delete secret dockerhub-secret -n luxe-jewelry
.\create-docker-secret.ps1

# Restart deployments
kubectl rollout restart deployment -n luxe-jewelry --all
```

**📖 For detailed information, see:** [PRIVATE-REGISTRY-SETUP.md](PRIVATE-REGISTRY-SETUP.md)

---

## Installation

### Windows Installation

```powershell
# Install all tools at once
choco install minikube kubernetes-cli docker-desktop -y

# Verify installations
minikube version
kubectl version --client
docker --version
```

### Start Minikube

```powershell
# Start with Docker driver
minikube start --driver=docker

# Verify cluster is running
kubectl cluster-info
minikube status

# Enable metrics server (required for auto-scaling)
minikube addons enable metrics-server

# Enable ingress (optional, for advanced routing)
minikube addons enable ingress
```

---

## Deployment

### Method 1: Automated Deployment (Recommended)

```powershell
cd Luxe-Jewelry-Store\k8s

# Fix PowerShell execution policy (first time only)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Deploy everything
.\deploy.ps1
```

**What the script does:**
1. ✅ Checks kubectl and Minikube
2. ✅ Creates namespace
3. ✅ Deploys ConfigMap and Secret
4. ✅ Deploys all services (auth, backend, frontend)
5. ✅ Sets up auto-scaling (HPA)
6. ✅ Creates ingress rules
7. ✅ Waits for pods to be ready
8. ✅ Shows access URLs

### Method 2: All-in-One YAML

```powershell
# Deploy everything with one command
kubectl apply -f deploy-all.yaml

# Wait for deployments
kubectl rollout status deployment/auth-service -n luxe-jewelry
kubectl rollout status deployment/backend -n luxe-jewelry
kubectl rollout status deployment/frontend -n luxe-jewelry

# Check status
kubectl get all,hpa -n luxe-jewelry
```

### Method 3: Step-by-Step Manual Deployment

```powershell
# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Create configuration
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

# 3. Deploy services (includes HPA)
kubectl apply -f auth-service-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml

# 4. Create ingress
kubectl apply -f ingress.yaml

# 5. Verify deployment
kubectl get all,hpa -n luxe-jewelry
```

---

## Resource Management & Auto-Scaling

### Resource Limits (Already Configured)

Each service has CPU and memory limits to prevent resource overconsumption:

| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|-------------|-----------|----------------|--------------|
| **Auth Service** | 100m | 500m | 128Mi | 512Mi |
| **Backend** | 100m | 500m | 128Mi | 512Mi |
| **Frontend** | 50m | 200m | 64Mi | 256Mi |

**What this means:**
- **Requests**: Guaranteed minimum resources
- **Limits**: Maximum resources the pod can use
- Prevents any pod from consuming too many resources

### Horizontal Pod Autoscaler (HPA)

HPA automatically scales pods based on CPU/Memory usage:

| Service | Min Replicas | Max Replicas | Scale Up When | Scale Down When |
|---------|--------------|--------------|---------------|-----------------|
| **Auth Service** | 2 | 5 | CPU > 70% or Memory > 80% | CPU < 70% and Memory < 80% |
| **Backend** | 2 | 10 | CPU > 70% or Memory > 80% | CPU < 70% and Memory < 80% |
| **Frontend** | 2 | 8 | CPU > 70% or Memory > 80% | CPU < 70% and Memory < 80% |

### Check HPA Status

```powershell
# View HPA status
kubectl get hpa -n luxe-jewelry

# Detailed HPA information
kubectl describe hpa backend-hpa -n luxe-jewelry

# Watch HPA in real-time
kubectl get hpa -n luxe-jewelry --watch

# Check resource usage
kubectl top pods -n luxe-jewelry
kubectl top nodes
```

### Test Auto-Scaling

```powershell
# Generate load on backend
kubectl run -it --rm load-generator --image=busybox --restart=Never -n luxe-jewelry -- /bin/sh

# Inside the pod, run:
while true; do wget -q -O- http://backend:8000/; done

# In another terminal, watch scaling
kubectl get pods -n luxe-jewelry --watch
kubectl get hpa -n luxe-jewelry --watch
```

**Expected behavior:**
1. CPU/Memory usage increases
2. HPA detects high utilization
3. New pods are created
4. Load is distributed
5. CPU/Memory per pod decreases
6. When load stops, HPA gradually scales down

---

## Accessing the Application

### Method 1: NodePort (Recommended for Minikube)

```powershell
# Get Minikube IP
$minikubeIp = minikube ip
Write-Host "Frontend: http://${minikubeIp}:30000"

# Or use Minikube service command (opens browser)
minikube service frontend -n luxe-jewelry

# Get URL without opening browser
minikube service frontend -n luxe-jewelry --url
```

### Method 2: Port Forwarding

```powershell
# Forward frontend
kubectl port-forward -n luxe-jewelry svc/frontend 3000:80

# Forward backend
kubectl port-forward -n luxe-jewelry svc/backend 8000:8000

# Forward auth service
kubectl port-forward -n luxe-jewelry svc/auth-service 8001:8001

# Access at:
# Frontend: http://localhost:3000
# Backend: http://localhost:8000
# Auth: http://localhost:8001
```

### Method 3: Ingress (Advanced)

```powershell
# 1. Enable ingress addon
minikube addons enable ingress

# 2. Get Minikube IP
minikube ip

# 3. Add to hosts file (C:\Windows\System32\drivers\etc\hosts)
<minikube-ip> luxe-jewelry.local

# 4. Access at: http://luxe-jewelry.local
```

---

## Monitoring & Troubleshooting

### View Status

```powershell
# All resources
kubectl get all,hpa -n luxe-jewelry

# Pods only
kubectl get pods -n luxe-jewelry

# Detailed pod info
kubectl get pods -n luxe-jewelry -o wide

# Services
kubectl get svc -n luxe-jewelry

# HPA status
kubectl get hpa -n luxe-jewelry
```

### View Logs

```powershell
# View logs for a specific pod
kubectl logs -n luxe-jewelry <pod-name>

# Follow logs in real-time
kubectl logs -n luxe-jewelry <pod-name> -f

# View logs for all pods of a service
kubectl logs -n luxe-jewelry -l app=backend

# View previous container logs (if crashed)
kubectl logs -n luxe-jewelry <pod-name> --previous

# View logs from all containers in a pod
kubectl logs -n luxe-jewelry <pod-name> --all-containers
```

### Describe Resources

```powershell
# Describe pod (shows events and status)
kubectl describe pod -n luxe-jewelry <pod-name>

# Describe deployment
kubectl describe deployment -n luxe-jewelry backend

# Describe service
kubectl describe svc -n luxe-jewelry frontend

# Describe HPA
kubectl describe hpa -n luxe-jewelry backend-hpa
```

### Execute Commands in Pods

```powershell
# Get a shell in a pod
kubectl exec -it -n luxe-jewelry <pod-name> -- /bin/bash

# Run a single command
kubectl exec -n luxe-jewelry <pod-name> -- env
kubectl exec -n luxe-jewelry <pod-name> -- ls -la
```

### Common Issues & Solutions

#### Issue 1: Pods Not Starting

```powershell
# Check pod status
kubectl get pods -n luxe-jewelry

# Check pod events
kubectl describe pod -n luxe-jewelry <pod-name>

# Check logs
kubectl logs -n luxe-jewelry <pod-name>
```

**Common causes:**
- Image pull errors → Check image name and Docker Hub access
- Resource constraints → Check node resources with `kubectl top nodes`
- Configuration errors → Check ConfigMap and Secret

#### Issue 2: HPA Shows "unknown" Metrics

```powershell
# Check if metrics server is running
kubectl get deployment metrics-server -n kube-system

# Restart metrics server
kubectl rollout restart deployment metrics-server -n kube-system

# Wait 1-2 minutes for metrics to populate
kubectl top pods -n luxe-jewelry
```

#### Issue 3: Service Not Accessible

```powershell
# Check service endpoints
kubectl get endpoints -n luxe-jewelry

# Check if pods are running
kubectl get pods -n luxe-jewelry

# Test connectivity from another pod
kubectl run -it --rm debug --image=busybox --restart=Never -n luxe-jewelry -- wget -O- http://frontend
```

#### Issue 4: ImagePullBackOff Error

```powershell
# Check pod events
kubectl describe pod -n luxe-jewelry <pod-name>

# Verify image exists
docker pull vixx3/luxe-jewelry-frontend:latest

# Check image name in deployment
kubectl get deployment -n luxe-jewelry frontend -o yaml | grep image:
```

---

## Management Commands

### Scaling

```powershell
# Manual scaling
kubectl scale deployment/frontend -n luxe-jewelry --replicas=5

# Verify scaling
kubectl get pods -n luxe-jewelry

# Check HPA (will override manual scaling if active)
kubectl get hpa -n luxe-jewelry
```

### Updates & Rollbacks

```powershell
# Update image version
kubectl set image deployment/frontend -n luxe-jewelry frontend=vixx3/luxe-jewelry-frontend:v2.0

# Check rollout status
kubectl rollout status deployment/frontend -n luxe-jewelry

# View rollout history
kubectl rollout history deployment/frontend -n luxe-jewelry

# Rollback to previous version
kubectl rollout undo deployment/frontend -n luxe-jewelry

# Rollback to specific revision
kubectl rollout undo deployment/frontend -n luxe-jewelry --to-revision=2
```

### Configuration Updates

```powershell
# Update ConfigMap
kubectl edit configmap luxe-jewelry-config -n luxe-jewelry

# Or apply updated file
kubectl apply -f configmap.yaml

# Restart deployments to pick up changes
kubectl rollout restart deployment/auth-service -n luxe-jewelry
kubectl rollout restart deployment/backend -n luxe-jewelry
kubectl rollout restart deployment/frontend -n luxe-jewelry
```

### Update Secrets

```powershell
# Update JWT secret
kubectl create secret generic luxe-jewelry-secrets \
  --from-literal=JWT_SECRET_KEY='new-secret-key' \
  --namespace=luxe-jewelry \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart deployments
kubectl rollout restart deployment/auth-service -n luxe-jewelry
```

### Cleanup

```powershell
# Option 1: Use cleanup script
.\cleanup.ps1

# Option 2: Delete namespace (deletes everything)
kubectl delete namespace luxe-jewelry

# Option 3: Delete using YAML
kubectl delete -f deploy-all.yaml

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

---

## Jenkins Integration

### Kubernetes Deployment in Jenkins Pipeline

The Jenkinsfile includes a "Deploy to Kubernetes" stage that:

1. ✅ Checks if kubectl is available
2. ✅ Verifies Kubernetes cluster is accessible
3. ✅ Creates namespace and applies ConfigMap
4. ✅ Creates Secret with JWT key from Jenkins credentials
5. ✅ Deploys all services (with HPA)
6. ✅ Waits for deployments to be ready
7. ✅ Displays deployment status

### Prerequisites for Jenkins

1. **Jenkins agent** must have `kubectl` installed
2. **Jenkins agent** must have access to Kubernetes cluster
3. **Kubeconfig** must be configured on Jenkins agent
4. **JWT secret credential** must exist in Jenkins with ID: `jwt-secret-key`

### JWT Secret Configuration

**For Manual Deployment:**
- Update JWT secret in `secret.yaml` before deploying

**For Jenkins Deployment:**
- JWT secret is automatically injected from Jenkins credentials
- Credential ID: `jwt-secret-key`
- The pipeline creates the Kubernetes secret dynamically

---

## Assignment Completion

### ✅ Requirements Met

#### 1. Convert Application to Kubernetes ✓
- ✅ Created Kubernetes deployments for all 3 services
- ✅ Deployed on Minikube cluster
- ✅ Used dedicated namespace: `luxe-jewelry`
- ✅ All services running with 2 replicas each

#### 2. Resource Restrictions ✓
- ✅ Configured CPU and memory **requests** (guaranteed resources)
- ✅ Configured CPU and memory **limits** (maximum resources)
- ✅ Prevents resource overconsumption
- ✅ Ensures fair resource distribution

#### 3. Horizontal Pod Autoscaler (HPA) ✓
- ✅ Created HPA for all 3 services
- ✅ Auto-scaling based on CPU and memory utilization
- ✅ Appropriate min/max replica counts
- ✅ Scale-up and scale-down behaviors configured

### Architecture Overview

```
Namespace: luxe-jewelry
├── ConfigMap: luxe-jewelry-config (non-sensitive config)
├── Secret: luxe-jewelry-secrets (JWT secret)
│
├── Auth Service
│   ├── Deployment (2-5 replicas with HPA)
│   ├── Service (ClusterIP:8001)
│   └── HPA (70% CPU / 80% Memory)
│
├── Backend
│   ├── Deployment (2-10 replicas with HPA)
│   ├── Service (ClusterIP:8000)
│   └── HPA (70% CPU / 80% Memory)
│
├── Frontend
│   ├── Deployment (2-8 replicas with HPA)
│   ├── Service (NodePort:30000)
│   └── HPA (70% CPU / 80% Memory)
│
└── Ingress (traffic routing)
```

### File Structure

```
k8s/
├── Core Resources
│   ├── namespace.yaml                 # Namespace isolation
│   ├── configmap.yaml                 # Non-sensitive config
│   ├── secret.yaml                    # Sensitive data
│   ├── auth-service-deployment.yaml   # Auth (Deployment + Service + HPA)
│   ├── backend-deployment.yaml        # Backend (Deployment + Service + HPA)
│   ├── frontend-deployment.yaml       # Frontend (Deployment + Service + HPA)
│   └── ingress.yaml                   # Traffic routing
│
├── Convenience
│   └── deploy-all.yaml                # All-in-one deployment
│
├── Scripts
│   ├── deploy.ps1                     # Windows deployment
│   ├── deploy.sh                      # Linux/Mac deployment
│   └── cleanup.ps1                    # Cleanup script
│
└── Documentation
    └── KUBERNETES-GUIDE.md            # This file
```

---

## Best Practices

1. **Resource Limits** ✓ - Set appropriate CPU and memory limits
2. **Health Checks** ✓ - Liveness and readiness probes configured
3. **Auto-Scaling** ✓ - HPA for automatic scaling
4. **Secrets Management** ✓ - Kubernetes Secrets for sensitive data
5. **Namespace Isolation** ✓ - Dedicated namespace for the application
6. **High Availability** ✓ - Multiple replicas for each service
7. **Configuration Management** ✓ - ConfigMaps for non-sensitive config

---

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---

## Summary

Your Luxe Jewelry Store application is now:
- ✅ **Deployed on Kubernetes** with proper namespace isolation
- ✅ **Resource-managed** with CPU/memory limits
- ✅ **Auto-scaling** with Horizontal Pod Autoscaler
- ✅ **Highly available** with multiple replicas
- ✅ **Production-ready** with health checks and monitoring
- ✅ **CI/CD integrated** with Jenkins pipeline

**🎉 Assignment Complete! 🎉**
