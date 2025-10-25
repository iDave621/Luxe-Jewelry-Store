# 🎯 Helm Integration Guide - Luxe Jewelry Store

## Why We Integrated Helm?

### ❌ Before Helm (Problems):
- **10+ separate YAML files** to manage
- **Update image tag?** → Edit 3 deployment files manually
- **Different environments?** → Maintain duplicate file sets
- **Rollback?** → Manual kubectl commands and file tracking
- **Share deployment?** → Send entire k8s/ folder

### ✅ After Helm (Solutions):
- **1 chart** packages everything
- **Update image tag?** → Change 1 value or use `--set`
- **Different environments?** → Same chart, different values files
- **Rollback?** → `helm rollback` command
- **Share deployment?** → Send 1 `.tgz` file

---

## 📊 Before vs After Comparison

### Updating Image Version

#### Before (Plain Kubernetes):
```bash
# Edit frontend-deployment.yaml
vim k8s/deployments/frontend-deployment.yaml
# Change: image: davidh9527/luxe-jewelry-frontend:v1.0.0

# Edit backend-deployment.yaml
vim k8s/deployments/backend-deployment.yaml
# Change: image: davidh9527/luxe-jewelry-backend:v1.0.0

# Edit auth-service-deployment.yaml
vim k8s/deployments/auth-service-deployment.yaml
# Change: image: davidh9527/luxe-jewelry-auth:v1.0.0

# Apply each file
kubectl apply -f k8s/deployments/frontend-deployment.yaml
kubectl apply -f k8s/deployments/backend-deployment.yaml
kubectl apply -f k8s/deployments/auth-service-deployment.yaml
```

#### After (With Helm):
```bash
# Single command!
helm upgrade luxe-jewelry ./luxe-jewelry-chart \
  --set frontend.image.tag=v1.0.0 \
  --set backend.image.tag=v1.0.0 \
  --set authService.image.tag=v1.0.0
```

---

## 🚀 Quick Start - Deploy with Helm

### 1. Verify Helm Chart
```bash
# Validate the chart
helm lint luxe-jewelry-chart

# Preview what will be deployed
helm template luxe-jewelry ./luxe-jewelry-chart
```

### 2. Deploy the Application
```bash
# Install the chart
helm install luxe-jewelry ./luxe-jewelry-chart \
  --set dockerRegistry.password=YOUR_DOCKER_PASSWORD

# Check installation status
helm status luxe-jewelry

# View deployed resources
kubectl get all -n luxe-jewelry
```

### 3. Access the Application
```bash
# Start Ingress tunnel (Windows/Minikube)
minikube service ingress-nginx-controller -n ingress-nginx

# Access at: http://luxe-jewelry.local:XXXXX
```

---

## 📝 Common Operations

### Update Application Version
```bash
helm upgrade luxe-jewelry ./luxe-jewelry-chart \
  --set frontend.image.tag=v2.0.0 \
  --set backend.image.tag=v2.0.0
```

### Scale Services
```bash
helm upgrade luxe-jewelry ./luxe-jewelry-chart \
  --set frontend.replicaCount=5 \
  --set backend.replicaCount=3
```

### Rollback to Previous Version
```bash
# View release history
helm history luxe-jewelry

# Rollback to previous version
helm rollback luxe-jewelry

# Rollback to specific revision
helm rollback luxe-jewelry 2
```

### Uninstall Application
```bash
helm uninstall luxe-jewelry -n luxe-jewelry
```

---

## 🔧 Jenkins Integration

### Option 1: Update Existing Jenkinsfile

Add this stage to your Jenkinsfile:

```groovy
stage('Deploy with Helm') {
    steps {
        container('kubectl') {
            script {
                sh '''
                    # Install/Upgrade with Helm
                    helm upgrade --install luxe-jewelry ./luxe-jewelry-chart \
                        --set frontend.image.tag=latest \
                        --set backend.image.tag=latest \
                        --set authService.image.tag=latest \
                        --set dockerRegistry.password=${DOCKER_PASSWORD} \
                        --wait --timeout 5m
                    
                    # Display status
                    helm status luxe-jewelry
                    kubectl get all -n luxe-jewelry
                '''
            }
        }
    }
}
```

### Option 2: Complete Helm-Based Pipeline

Replace the "Deploy to Kubernetes" stage with:

```groovy
stage('Deploy with Helm') {
    steps {
        container('kubectl') {
            script {
                echo "Deploying with Helm..."
                
                sh """
                    helm upgrade --install luxe-jewelry ./luxe-jewelry-chart \
                        --set frontend.image.tag=${BUILD_NUMBER} \
                        --set backend.image.tag=${BUILD_NUMBER} \
                        --set authService.image.tag=${BUILD_NUMBER} \
                        --set dockerRegistry.password=\${DOCKER_PASSWORD} \
                        --namespace luxe-jewelry \
                        --create-namespace \
                        --wait \
                        --timeout 10m
                """
                
                echo "Deployment successful!"
                sh "helm status luxe-jewelry -n luxe-jewelry"
            }
        }
    }
}
```

---

## 🌍 Environment-Specific Deployments

### Create Environment Values Files

**values-dev.yaml**:
```yaml
frontend:
  replicaCount: 1
backend:
  replicaCount: 1
authService:
  replicaCount: 1
ingress:
  host: luxe-jewelry-dev.local
```

**values-prod.yaml**:
```yaml
frontend:
  replicaCount: 3
backend:
  replicaCount: 3
authService:
  replicaCount: 2
ingress:
  host: luxe-jewelry.com
```

### Deploy to Different Environments

```bash
# Deploy to Dev
helm install luxe-jewelry-dev ./luxe-jewelry-chart -f values-dev.yaml

# Deploy to Prod
helm install luxe-jewelry-prod ./luxe-jewelry-chart -f values-prod.yaml
```

---

## 📦 Package & Distribute

### Package the Chart
```bash
helm package luxe-jewelry-chart
# Creates: luxe-jewelry-chart-1.0.0.tgz
```

### Install from Package
```bash
helm install luxe-jewelry luxe-jewelry-chart-1.0.0.tgz
```

### Share with Team
```bash
# Upload to chart repository or share the .tgz file
# Others can install with:
helm install luxe-jewelry luxe-jewelry-chart-1.0.0.tgz
```

---

## 🎓 Key Benefits Summary

| Benefit | Plain K8s | With Helm |
|---------|-----------|-----------|
| **Files to manage** | 10+ YAML files | 1 chart |
| **Update image tag** | Edit 3 files | 1 command |
| **Environment management** | Duplicate files | Different values files |
| **Rollback** | Manual process | `helm rollback` |
| **Version tracking** | Git only | Helm releases + Git |
| **Package & share** | Folder of files | Single .tgz file |
| **Templating** | Manual find/replace | Built-in variables |
| **Dependency management** | Manual | Helm dependencies |

---

## 🔍 Troubleshooting

### Chart Validation Issues
```bash
# Lint the chart
helm lint luxe-jewelry-chart

# Dry-run to see what would be deployed
helm install luxe-jewelry ./luxe-jewelry-chart --dry-run --debug
```

### Deployment Issues
```bash
# Check release status
helm status luxe-jewelry

# View release history
helm history luxe-jewelry

# Get deployed values
helm get values luxe-jewelry

# Get all manifests
helm get manifest luxe-jewelry
```

---

## ✅ Next Steps

1. **Test the Helm deployment** locally
2. **Integrate with Jenkins** pipeline
3. **Create environment-specific values** files
4. **Package and version** your chart
5. **Set up automated testing** with Helm

---

## 📚 Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Chart Development Guide](https://helm.sh/docs/chart_template_guide/)
