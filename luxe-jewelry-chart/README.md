# 💎 Luxe Jewelry Store - Helm Chart

This Helm chart deploys the Luxe Jewelry Store application on Kubernetes.

## 📋 Overview

The Luxe Jewelry Store is a full-stack e-commerce application consisting of:
- **Frontend**: React-based web interface (Port 80)
- **Backend**: Python FastAPI service (Port 8000)
- **Auth Service**: Authentication microservice (Port 8001)

## ✅ Prerequisites

- Kubernetes cluster (Minikube, EKS, GKE, AKS, etc.)
- Helm 3.x installed
- kubectl configured to access your cluster
- Nexus Docker registry running on `host.minikube.internal:8082`
- Docker registry credentials configured in Jenkins

## 📁 Chart Structure

```
luxe-jewelry-chart/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
├── templates/              # Kubernetes manifests templates
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── docker-registry-secret.yaml
│   ├── frontend-deployment.yaml
│   ├── backend-deployment.yaml
│   ├── auth-service-deployment.yaml
│   ├── ingress.yaml
│   └── NOTES.txt
└── README.md
```

## 🚀 Quick Start

```bash
# Install in default namespace
helm install luxe-jewelry ./luxe-jewelry-chart

# Install in custom namespace (recommended)
helm install luxe-jewelry ./luxe-jewelry-chart \
  --namespace luxe-jewelry-helm \
  --create-namespace
```

## 📦 Installation

### 1. Install with default values

```bash
helm install luxe-jewelry ./luxe-jewelry-chart
```

### 2. Install with custom Docker credentials

```bash
helm install luxe-jewelry ./luxe-jewelry-chart \
  --set dockerRegistry.password=YOUR_DOCKER_PASSWORD
```

### 3. Install with custom values file

```bash
# Create a custom values file
cp luxe-jewelry-chart/values.yaml my-values.yaml

# Edit my-values.yaml with your settings
# Then install:
helm install luxe-jewelry ./luxe-jewelry-chart -f my-values.yaml
```

### 4. Install in a specific namespace

```bash
helm install luxe-jewelry ./luxe-jewelry-chart -n luxe-jewelry --create-namespace
```

## ⚙️ Configuration

### Key Configuration Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Kubernetes namespace | `luxe-jewelry` |
| `global.imageRegistry` | Docker registry URL | `host.minikube.internal:8082` |
| `frontend.replicaCount` | Number of frontend pods | `2` |
| `frontend.image.tag` | Frontend image tag | `latest` |
| `backend.replicaCount` | Number of backend pods | `2` |
| `backend.image.tag` | Backend image tag | `latest` |
| `authService.replicaCount` | Number of auth service pods | `2` |
| `authService.image.tag` | Auth service image tag | `latest` |
| `ingress.enabled` | Enable Ingress | `true` |
| `ingress.host` | Ingress hostname | `luxe-jewelry.local` |

### Example: Scaling Replicas

```bash
helm upgrade luxe-jewelry ./luxe-jewelry-chart \
  --set frontend.replicaCount=3 \
  --set backend.replicaCount=4
```

### Example: Changing Image Tags

```bash
helm upgrade luxe-jewelry ./luxe-jewelry-chart \
  --set frontend.image.tag=v1.2.0 \
  --set backend.image.tag=v1.2.0 \
  --set authService.image.tag=v1.2.0
```

### Example: Disabling a Service

```bash
helm upgrade luxe-jewelry ./luxe-jewelry-chart \
  --set authService.enabled=false
```

## 🌐 Accessing the Application

### For Minikube (Windows):

1. Start the Ingress tunnel:
   ```powershell
   minikube service ingress-nginx-controller -n ingress-nginx
   ```

2. Access the application:
   ```
   http://luxe-jewelry.local:XXXXX
   ```
   (Port number shown in tunnel output)

### For Cloud Providers:

The Ingress will be automatically exposed. Check the Ingress IP:
```bash
kubectl get ingress -n luxe-jewelry
```

## 🔧 Management Commands

### Check deployment status:
```bash
helm status luxe-jewelry -n luxe-jewelry
```

### Get current values:
```bash
helm get values luxe-jewelry -n luxe-jewelry
```

### Upgrade the deployment:
```bash
helm upgrade luxe-jewelry ./luxe-jewelry-chart
```

### Rollback to previous version:
```bash
helm rollback luxe-jewelry -n luxe-jewelry
```

### Uninstall:
```bash
helm uninstall luxe-jewelry -n luxe-jewelry
```

## 🧪 Testing

### Dry-run installation:
```bash
helm install luxe-jewelry ./luxe-jewelry-chart --dry-run --debug
```

### Template rendering:
```bash
helm template luxe-jewelry ./luxe-jewelry-chart
```

### Lint the chart:
```bash
helm lint ./luxe-jewelry-chart
```

## 📦 Packaging & Distribution

### Package the chart:
```bash
helm package luxe-jewelry-chart
```

This creates: `luxe-jewelry-chart-1.0.0.tgz`

### Install from package:
```bash
helm install luxe-jewelry luxe-jewelry-chart-1.0.0.tgz
```

## 🔍 Troubleshooting

### Check pod status:
```bash
kubectl get pods -n luxe-jewelry
```

### View pod logs:
```bash
kubectl logs -n luxe-jewelry deployment/frontend
kubectl logs -n luxe-jewelry deployment/backend
kubectl logs -n luxe-jewelry deployment/auth-service
```

### Describe resources:
```bash
kubectl describe deployment frontend -n luxe-jewelry
kubectl describe ingress luxe-jewelry-ingress -n luxe-jewelry
```

## 🔄 CI/CD Integration

### Jenkins Pipeline Example:
```groovy
stage('Deploy with Helm') {
    steps {
        script {
            sh '''
                helm upgrade --install luxe-jewelry ./luxe-jewelry-chart \
                    --set frontend.image.tag=${BUILD_NUMBER} \
                    --set backend.image.tag=${BUILD_NUMBER} \
                    --set authService.image.tag=${BUILD_NUMBER} \
                    --wait --timeout 5m
            '''
        }
    }
}
```

## 📚 Additional Documentation

See the `/docs` folder for:
- `HELM_INTEGRATION_GUIDE.md` - Detailed Helm setup guide
- `HELM_QUICK_REFERENCE.md` - Quick command reference
- `JENKINS-KUBERNETES-SETUP.md` - Jenkins integration guide

## 📝 License

MIT License
