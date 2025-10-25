# 💎 Luxe Jewelry Store

A microservices-based jewelry e-commerce application with CI/CD pipeline integration using Jenkins.

## 🏗️ Project Structure

The application consists of three main services:

1. **Auth Service** - FastAPI authentication microservice (Port 8001)
2. **Backend** - FastAPI products and orders API (Port 8000) 
3. **Frontend** - React SPA frontend (Port 3000)

See [docs/PROJECT-STRUCTURE.md](./docs/PROJECT-STRUCTURE.md) for detailed architecture.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Git
- Minikube and kubectl for Kubernetes deployment
- Helm 3.x for chart deployment
- Nexus Docker Registry running on `host.minikube.internal:8082`

### Option 1: Deploy with Helm (Recommended)
```bash
# Start Minikube
minikube start --driver=docker

# Deploy with Helm
helm install luxe-jewelry ./luxe-jewelry-chart \
  --namespace luxe-jewelry-helm \
  --create-namespace

# Access application
minikube tunnel
# Then visit: http://luxe-jewelry-helm.local
```

### Option 2: Run with Docker Compose
```bash
git clone https://github.com/iDave621/Luxe-Jewelry-Store.git
cd Luxe-Jewelry-Store
docker-compose up --build
```

See [docs/HELM_INTEGRATION_GUIDE.md](./docs/HELM_INTEGRATION_GUIDE.md) for detailed Helm deployment guide.

### Access the Application

**Docker Compose:**
- Frontend: http://localhost:3000 (Nginx running on port 80 inside container)
- Backend API: http://localhost:8000
- Auth Service: http://localhost:8001
- API Docs: http://localhost:8000/docs

**Kubernetes (Minikube):**
- Frontend: http://\<minikube-ip\>:30000
- Use: `minikube service frontend -n luxe-jewelry` to open in browser

## ⚙️ CI/CD Pipeline

The project uses a Jenkins pipeline defined in [Jenkinsfile](./Jenkinsfile) with the following stages:

1. **Checkout** - Retrieves source code from Git repository
2. **Build Services** - Builds Docker images for auth-service, backend, and frontend
3. **Quality Checks** - Runs unit tests and static code analysis
4. **Security Scan** - Uses Snyk to scan Docker images for vulnerabilities
5. **Test Services** - Runs application-specific tests for each service
6. **Push to Nexus** - Pushes images to private Nexus Docker registry (`host.minikube.internal:8082`)
7. **Deploy with Helm** - Deploys all services to Kubernetes using Helm charts
8. **Verification** - Validates deployment health and accessibility

### Required Jenkins Credentials

- `dockerhub` - Docker Hub credentials (for base images)
- `nexus-credentials` - Nexus Docker registry credentials
- `snky` - Snyk API token for security scanning
- `jwt-secret-key` - JWT secret for secure authentication

### Required Infrastructure

- **Jenkins** running in Docker Desktop
- **Nexus Repository** on `host.minikube.internal:8082`
- **Minikube** with Ingress enabled
- **Kubernetes Cloud** configured in Jenkins

## 🔧 Environment Variables

### Auth Service
- `JWT_SECRET_KEY` - For JWT token signing

### Backend
- `AUTH_SERVICE_URL` - Auth service URL

## 🐳 Docker Commands

| Command | Description |
|---------|-------------|
| `docker-compose up --build` | Build and start all services |
| `docker-compose down` | Stop and remove containers |
| `docker-compose logs -f` | View logs |
| `docker-compose ps` | Check container status |

## 🛠 Development Setup

### 1. Auth Service
```bash
cd auth-service
python -m venv venv
# Windows: .\venv\Scripts\activate
# Mac/Linux: source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8001
```

### 2. Backend Service
```bash
cd ../backend
python -m venv venv
# Windows: .\venv\Scripts\activate
# Mac/Linux: source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### 3. Frontend
```bash
cd ../jewelry-store
npm install
npm start
```

## 🚀 Deployment Options

### 1. Helm Deployment (Recommended)

```bash
# Install
helm install luxe-jewelry ./luxe-jewelry-chart \
  --namespace luxe-jewelry-helm \
  --create-namespace

# Upgrade
helm upgrade luxe-jewelry ./luxe-jewelry-chart

# Uninstall
helm uninstall luxe-jewelry -n luxe-jewelry-helm
```

See [luxe-jewelry-chart/README.md](./luxe-jewelry-chart/README.md) for full Helm documentation.

### 2. Kubernetes Deployment (Raw Manifests)

```powershell
# Deploy using raw Kubernetes manifests
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/base/
```

### 3. Docker Compose Deployment

```bash
docker-compose up --build -d
```

## 📁 Project Structure

```
Luxe-Jewelry-Store/
├── 📁 auth-service/          # Authentication microservice
├── 📁 backend/               # Products & orders API
├── 📁 jewelry-store/         # React frontend
├── 📁 luxe-jewelry-chart/    # Helm chart for K8s deployment
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   └── README.md
├── 📁 k8s/                   # Raw Kubernetes manifests
│   ├── deployments/
│   ├── base/
│   └── scripts/
├── 📁 docs/                  # Documentation
│   ├── HELM_INTEGRATION_GUIDE.md
│   ├── HELM_QUICK_REFERENCE.md
│   ├── JENKINS-KUBERNETES-SETUP.md
│   └── PROJECT-STRUCTURE.md
├── 📁 scripts/               # Utility scripts
│   ├── start-ingress-tunnel.ps1
│   └── find-nexus-volume.ps1
├── 📄 Jenkinsfile            # CI/CD pipeline
├── 📄 docker-compose.yml     # Docker Compose config
└── 📄 README.md              # This file
```
