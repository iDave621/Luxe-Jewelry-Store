# Kubernetes Configuration

This directory contains all Kubernetes manifests and scripts for deploying the Luxe Jewelry Store application.

## 📁 Directory Structure

```
k8s/
├── base/                   # Core Kubernetes resources
│   ├── namespace.yaml      # Namespace definition
│   ├── configmap.yaml      # Configuration data
│   ├── secret.yaml         # Secret template
│   ├── ingress.yaml        # Ingress routing rules
│   └── docker-registry-secret.yaml  # Docker registry secret template
│
├── deployments/            # Application deployments
│   ├── auth-service-deployment.yaml
│   ├── backend-deployment.yaml
│   └── frontend-deployment.yaml
│
├── scripts/                # Deployment and management scripts
│   ├── deploy.ps1          # Main deployment script
│   ├── cleanup.ps1         # Cleanup script
│   ├── verify.ps1          # Verification script
│   ├── create-docker-secret.ps1  # Create Docker registry secret
│   ├── start-tunnels.ps1   # Start port-forward tunnels
│   └── stop-tunnels.ps1    # Stop port-forward tunnels
│
└── docs/                   # Documentation
    ├── KUBERNETES-GUIDE.md
    ├── PRIVATE-REGISTRY-SETUP.md
    └── PRIVATE-REGISTRY-CHANGES.md
```

## 🚀 Quick Start

### Deploy Application

```powershell
cd k8s/scripts
.\deploy.ps1
```

### Start Port-Forward Tunnels

```powershell
cd k8s/scripts
.\start-tunnels.ps1
```

### Access Application

- **Frontend:** http://localhost:3000
- **Backend:** http://localhost:8000
- **Auth Service:** http://localhost:8001

### Cleanup

```powershell
cd k8s/scripts
.\cleanup.ps1
```

## 📝 Usage Notes

### From Root of k8s Directory

If you're in the root `k8s/` directory, run scripts with:

```powershell
.\scripts\deploy.ps1
.\scripts\cleanup.ps1
.\scripts\verify.ps1
```

### From scripts Directory

If you're in the `k8s/scripts/` directory, run directly:

```powershell
.\deploy.ps1
.\cleanup.ps1
.\verify.ps1
```

## 🔐 Docker Registry Secret

The application pulls images from a private Docker registry (`idave621/*`).

### Create Secret Manually

```powershell
cd k8s/scripts
.\create-docker-secret.ps1
```

### Via Jenkins (Automatic)

The Jenkins pipeline automatically creates the `dockerhub-secret` during deployment.

## 📖 Documentation

For detailed information, see:

- **[KUBERNETES-GUIDE.md](docs/KUBERNETES-GUIDE.md)** - Complete deployment guide
- **[PRIVATE-REGISTRY-SETUP.md](docs/PRIVATE-REGISTRY-SETUP.md)** - Private registry configuration
- **[PRIVATE-REGISTRY-CHANGES.md](docs/PRIVATE-REGISTRY-CHANGES.md)** - Change log

## 🏗️ Architecture

### Services

| Service | Port | Description |
|---------|------|-------------|
| **auth-service** | 8001 | Authentication and authorization |
| **backend** | 8000 | Main API backend |
| **frontend** | 3000 | React frontend application |

### Deployments

All deployments include:
- ✅ Horizontal Pod Autoscaler (HPA)
- ✅ Resource limits and requests
- ✅ Health checks (liveness and readiness probes)
- ✅ Private registry image pull secrets

## 🔧 Jenkins Integration

The Jenkins pipeline automatically:

1. Builds Docker images
2. Pushes to Docker Hub (vixx3/*)
3. Tags and pushes for Kubernetes (idave621/*)
4. Creates Kubernetes secrets
5. Deploys all services
6. Waits for deployments to be ready

## 🛠️ Troubleshooting

### Check Pod Status

```powershell
kubectl get pods -n luxe-jewelry
```

### View Pod Logs

```powershell
kubectl logs <pod-name> -n luxe-jewelry
```

### Describe Pod (for events)

```powershell
kubectl describe pod <pod-name> -n luxe-jewelry
```

### Verify Secret

```powershell
kubectl get secret dockerhub-secret -n luxe-jewelry
```

### Common Issues

**ImagePullBackOff:**
- Ensure `dockerhub-secret` exists
- Verify Docker Hub credentials are correct
- Run: `.\create-docker-secret.ps1`

**CrashLoopBackOff:**
- Check pod logs: `kubectl logs <pod-name> -n luxe-jewelry`
- Verify environment variables in configmap
- Check JWT secret exists

## 📦 Container Images

- **Auth Service:** `idave621/luxe-jewelry-auth-service:latest`
- **Backend:** `idave621/luxe-jewelry-backend:latest`
- **Frontend:** `idave621/luxe-jewelry-frontend:latest`

Registry: Docker Hub (https://hub.docker.com/)

---

**Made with ❤️ for Luxe Jewelry Store**
