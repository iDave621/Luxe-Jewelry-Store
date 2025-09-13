# Luxe Jewelry Store - Project Structure

## 📁 Directory Organization

```
Luxe-Jewelry-Store/
├── 🔧 jenkins/                    # Jenkins CI/CD Configuration
│   ├── agent/                     # Jenkins Build Agent
│   │   ├── Dockerfile            # Agent with Python, Docker, AWS CLI, Snyk
│   │   ├── requirements-dev.txt  # Python dev dependencies (pylint, pytest)
│   │   └── README.md             # Agent configuration guide
│   └── master/                    # Jenkins Master/Controller
│       ├── Dockerfile            # Master with Blue Ocean & Docker
│       └── README.md             # Master configuration guide
│
├── 🚀 deployment/                 # Production Deployment
│   ├── docker-compose.prod.yml   # Production services with health checks
│   ├── nginx.conf                # Reverse proxy configuration
│   └── README.md                 # Deployment guide
│
├── 🔐 auth-service/               # Authentication Microservice
│   ├── Dockerfile                # FastAPI auth service container
│   ├── main.py                   # JWT authentication, user management
│   ├── requirements.txt          # Python dependencies
│   └── README.md                 # Auth service documentation
│
├── 🛍️ backend/                    # Main API Backend
│   ├── Dockerfile                # FastAPI backend container
│   ├── main.py                   # Products, cart, orders API
│   ├── requirements.txt          # Python dependencies
│   └── README.md                 # Backend API documentation
│
├── 💎 jewelry-store/              # React Frontend
│   ├── public/                   # Static assets
│   ├── src/                      # React components and pages
│   ├── Dockerfile                # React app container
│   ├── package.json              # Node.js dependencies
│   └── README.md                 # Frontend documentation
│
├── 🔄 shared/                     # Shared Components
│   ├── __init__.py               # Python package init
│   └── cors_config.py            # Shared CORS middleware
│
├── 📋 Jenkinsfile                 # CI/CD Pipeline Definition
├── 🐳 docker-compose.yml          # Development environment
├── 📏 .pylintrc                   # Python code quality rules
└── 📚 *.md                       # Documentation files
```

## 🔄 CI/CD Pipeline Stages

1. **🧪 Unit Tests** (Parallel)
   - Runs pytest on auth-service and backend
   - Uses `jenkins/agent/requirements-dev.txt`

2. **📊 Static Code Linting** (Parallel)
   - Pylint analysis with `.pylintrc` configuration
   - Generates quality reports and scores

3. **🏗️ Build Docker Images**
   - Builds auth-service, backend, and frontend images
   - Tags with version and latest

4. **📤 Push to Registry**
   - Pushes to Docker Hub (`iDave621/luxe-jewelry-*`)
   - Secure credential handling

5. **🚀 Deploy Application**
   - Uses `deployment/docker-compose.prod.yml`
   - Health checks and rollback on failure
   - Only runs on `main` branch

## 🛠️ Development vs Production

### Development (`docker-compose.yml`)
- Jenkins agent for CI/CD
- Local development environment
- Agent connects to Jenkins master

### Production (`deployment/docker-compose.prod.yml`)
- All application services
- Nginx reverse proxy
- Health checks and monitoring
- Environment-specific configuration

## 🔐 Security & Configuration

### Jenkins Credentials Required:
- `dockerhub` - Docker Hub username/password for `iDave621`
- `jwt-secret-key` - JWT secret for production deployment

### Environment Variables:
- `JWT_SECRET_KEY` - JWT token signing
- `AUTH_SERVICE_URL` - Service communication
- `VERSION` - Docker image versioning

## 🚀 Quick Start

### Development:
```bash
docker-compose up -d
```

### Production Deployment:
```bash
docker-compose -f deployment/docker-compose.prod.yml up -d
```

### CI/CD Pipeline:
- Push to any branch → Unit tests + Linting
- Push to `main` branch → Full pipeline with deployment

## 📊 Code Quality

- **Pylint** integration with custom `.pylintrc`
- **Shared modules** to reduce code duplication
- **Exception handling** with proper error chains
- **Import organization** following PEP 8 standards

## 🌐 Service Architecture

- **Frontend** (Port 3000) → React SPA
- **Backend** (Port 8000) → Product/Cart API
- **Auth Service** (Port 8001) → JWT Authentication
- **Nginx** (Port 80/443) → Reverse Proxy & Load Balancer

Routes:
- `/` → Frontend
- `/api/` → Backend
- `/auth/` → Auth Service
