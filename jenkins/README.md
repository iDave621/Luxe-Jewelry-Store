# 🔧 Modular Jenkins Pipeline

Centralized configuration and reusable pipeline modules.

## 📁 Structure

```
jenkins/
├── config.groovy              # All credentials & settings
├── changeDetection.groovy     # Smart build detection
└── pipelines/
    ├── buildService.groovy    # Build images
    ├── securityScan.groovy    # Security scanning
    ├── pushToRegistry.groovy  # Push to registries
    └── helmDeploy.groovy      # Kubernetes deployment
```

## 🎯 Key Features

- **Centralized Config** - All credentials in `config.groovy`
- **Smart Builds** - Only builds what changed (saves 60%+ time)
- **Parallel Execution** - Builds, scans, pushes run simultaneously
- **Modular** - Easy to maintain and extend

## 📚 Quick Reference

### `config.groovy` - All Settings
```groovy
DOCKER_HUB_CREDENTIALS = "docker-hub"
NEXUS_CREDENTIALS = "Nexus-Docker"
SNYK_TOKEN = "snky"
JWT_SECRET = "jwt-secret-key"
```
Change credential ID once, works everywhere.

### `changeDetection.groovy` - Smart Builds
Detects what changed using `git diff`, only builds those services.

### `pipelines/buildService.groovy` - Build Images
```groovy
buildService.buildImage(this, config, 'frontend', version)
```

### `pipelines/securityScan.groovy` - Scan Images
```groovy
securityScan.scanImage(this, config, 'backend', version)
```

### `pipelines/pushToRegistry.groovy` - Push to Registries
```groovy
pushToRegistry.pushToDockerHub(this, config, 'frontend', version)
pushToRegistry.pushToNexus(this, config, 'frontend', version)
```

### `pipelines/helmDeploy.groovy` - Deploy to K8s
```groovy
helmDeploy.deployWithHelm(this, config, version)
```

## 🚀 Quick Start

1. **Update Credentials** - Edit `config.groovy` with your credential IDs
2. **Use in Jenkins** - Point to `Jenkinsfile.new` to test
3. **Pipeline Auto-Detects** - Builds only what changed, runs in parallel

That's it!

---

**For detailed explanations, see `MIGRATION_GUIDE.md` and `PERFORMANCE.md`**
