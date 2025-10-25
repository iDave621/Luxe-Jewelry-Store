# ⚡ Helm Quick Reference - Luxe Jewelry Store

## 🚀 Common Commands

### Deploy
```bash
helm install luxe-jewelry ./luxe-jewelry-chart
```

### Upgrade (after changing values.yaml)
```bash
helm upgrade luxe-jewelry ./luxe-jewelry-chart
```

### Upgrade with command-line values
```bash
helm upgrade luxe-jewelry ./luxe-jewelry-chart \
  --set frontend.image.tag=v2.0.0 \
  --set frontend.replicaCount=5
```

### Check Status
```bash
helm status luxe-jewelry
helm list
kubectl get all -n luxe-jewelry
```

### Rollback
```bash
helm history luxe-jewelry
helm rollback luxe-jewelry        # Previous version
helm rollback luxe-jewelry 3      # Specific version
```

### Uninstall
```bash
helm uninstall luxe-jewelry -n luxe-jewelry
```

---

## 🔧 Testing & Debugging

### Validate Chart
```bash
helm lint luxe-jewelry-chart
```

### Dry Run (see what will be deployed)
```bash
helm install luxe-jewelry ./luxe-jewelry-chart --dry-run --debug
```

### Template Preview
```bash
helm template luxe-jewelry ./luxe-jewelry-chart
```

### Get Current Values
```bash
helm get values luxe-jewelry
```

### Get All Manifests
```bash
helm get manifest luxe-jewelry
```

---

## 📝 Your Current Values

```yaml
# Image Registry
imageRegistry: host.minikube.internal:8082

# Replicas
frontend: 2
backend: 2
authService: 2

# HPA Max
frontend: 8
backend: 10
authService: 5

# Resources
frontend:   requests(64Mi/50m)  limits(256Mi/200m)
backend:    requests(128Mi/100m) limits(512Mi/500m)
authService: requests(128Mi/100m) limits(512Mi/500m)
```

---

## 🎯 Quick Scenarios

### Update Image Tag (for new build)
```bash
helm upgrade luxe-jewelry ./luxe-jewelry-chart \
  --set frontend.image.tag=v2.1.0 \
  --set backend.image.tag=v2.1.0 \
  --set authService.image.tag=v2.1.0
```

### Scale Up for High Traffic
```bash
helm upgrade luxe-jewelry ./luxe-jewelry-chart \
  --set frontend.hpa.maxReplicas=15 \
  --set backend.hpa.maxReplicas=20
```

### Temporarily Disable a Service
```bash
helm upgrade luxe-jewelry ./luxe-jewelry-chart \
  --set authService.enabled=false
```

### Change Resource Limits
```bash
helm upgrade luxe-jewelry ./luxe-jewelry-chart \
  --set backend.resources.limits.memory=1Gi \
  --set backend.resources.limits.cpu=1000m
```

---

## 🔄 Jenkins Integration Snippet

```groovy
stage('Deploy with Helm') {
    steps {
        script {
            sh """
                helm upgrade --install luxe-jewelry ./luxe-jewelry-chart \
                    --set frontend.image.tag=\${BUILD_NUMBER} \
                    --set backend.image.tag=\${BUILD_NUMBER} \
                    --set authService.image.tag=\${BUILD_NUMBER} \
                    --wait --timeout 10m
            """
        }
    }
}
```

---

## 📦 Package & Share

```bash
# Package
helm package luxe-jewelry-chart

# Install from package
helm install luxe-jewelry luxe-jewelry-chart-1.0.0.tgz

# Share the .tgz file with your team!
```

---

## 🆘 Troubleshooting

### Chart won't install
```bash
# Check if namespace exists
kubectl get namespace luxe-jewelry

# Delete if needed
kubectl delete namespace luxe-jewelry

# Install fresh
helm install luxe-jewelry ./luxe-jewelry-chart
```

### Values not applying
```bash
# Check current values
helm get values luxe-jewelry

# Force upgrade
helm upgrade luxe-jewelry ./luxe-jewelry-chart --force
```

### Pods not starting
```bash
# Check deployment
kubectl get pods -n luxe-jewelry
kubectl describe pod <pod-name> -n luxe-jewelry
kubectl logs <pod-name> -n luxe-jewelry

# Check Helm status
helm status luxe-jewelry
```

---

## 💡 Pro Tips

1. **Always use `--dry-run` first** when testing changes
2. **Check `helm history`** before rollback
3. **Use separate values files** for dev/staging/prod
4. **Version your chart** by updating `Chart.yaml`
5. **Document custom values** in comments

---

## 📚 Full Documentation

- **HELM_CONVERSION_SUMMARY.md** - What was converted
- **HELM_INTEGRATION_GUIDE.md** - Why use Helm
- **luxe-jewelry-chart/README.md** - Complete chart documentation
