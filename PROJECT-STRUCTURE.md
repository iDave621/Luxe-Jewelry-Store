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

### Detailed Stage Description

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
   - Pushes to Docker Hub (`vixx3/luxe-jewelry-*`)
   - Secure credential handling

5. **🚀 Deploy Application**
   - Uses `deployment/docker-compose.prod.yml`
   - Health checks and rollback on failure
   - Only runs on `main` branch

### Visual Pipeline Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                JENKINS PIPELINE EXECUTION                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│ STAGE 1 │ ──► │  🧪 UNIT TESTS      │ ──► │ • Python pytest      │
└─────────┘     └─────────────────────┘     │ • Shared library    │
                                            └─────────────────────┘
    │
    ▼
┌─────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│ STAGE 2 │ ──► │  📊 CODE QUALITY   │ ──► │ • Pylint linting    │
└─────────┘     └─────────────────────┘     │ • Quality reports   │
                                            └─────────────────────┘
    │
    ▼
┌─────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│ STAGE 3 │ ──► │  🏗️ BUILD DOCKER   │ ──► │ • Three services    │
└─────────┘     └─────────────────────┘     │ • Version tags     │
                                            └─────────────────────┘
    │
    ▼
┌─────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│ STAGE 4 │ ──► │  📤 PUSH REGISTRY  │ ──► │ • Docker Hub       │
└─────────┘     └─────────────────────┘     │ • Secure handling   │
                                            └─────────────────────┘
    │
    ▼
┌─────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│ STAGE 5 │ ──► │  🚀 DEPLOY APP     │ ──► │ • docker-compose   │
└─────────┘     └─────────────────────┘     │ • Health checks    │
                                            └─────────────────────┘
```

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

## 🏗️ Deployment Environments

```
┌─────────────────────────────────────────────────────────────────┐
│                      DEPLOYMENT ENVIRONMENTS                      │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────┐     ┌─────────────────────────────────┐
│ DEVELOPMENT ENVIRONMENT    │     │ PRODUCTION ENVIRONMENT          │
├──────────────────────────┤     ├─────────────────────────────────┤
│ • docker-compose.yml       │     │ • docker-compose.prod.yml       │
│   Local development setup   │     │   Production configuration      │
│                            │     │                                │
│ • Jenkins agent for CI/CD   │     │ • Nginx reverse proxy           │
│   Pipeline testing on       │     │   Load balancing and routing     │
│   developer's machines      │     │                                │
│                            │     │ • Health checks                  │
│ • Direct from source builds │     │   Service monitoring            │
│   Fast iterative testing    │     │                                │
│                            │     │ • Environment variables         │
│                            │     │   Production-specific config     │
└──────────────────────────┘     └─────────────────────────────────┘
```

## 🚀 CI/CD Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                       DEVELOPMENT WORKFLOW                        │
└─────────────────────────────────────────────────────────────────┘

👨‍💻 Developer          ➔  🗶️ Git Push            ➔  🏪️ Jenkins Pipeline     ➔  🚀 Deployment
                                                     │
      Development               🔁 CI/CD             └──────────────────────→  🔍 Testing/QA
      
┌──────────────────────────┐     ┌─────────────────────────────────┐
│ QUICK START: DEVELOPMENT │     │ QUICK START: DEPLOYMENT         │
├──────────────────────────┤     ├─────────────────────────────────┤
│ $ git clone [repo]        │     │ # Manual deployment:            │
│ $ cd Luxe-Jewelry-Store   │     │ $ docker-compose up -d          │
│ $ docker-compose up -d     │     │                                │
│                            │     │ # OR use Jenkins pipeline:      │
│ # Open in browser:         │     │ # Push to repo, and pipeline    │
│ http://localhost:3000      │     │ # handles deployment            │
└──────────────────────────┘     └─────────────────────────────────┘
```

## 🔐 Security & Configuration

```
┌─────────────────────────────────────────────────────────────────┐
│                  SECURITY CONFIGURATION                           │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────┐     ┌─────────────────────────────────┐
│ JENKINS CREDENTIALS         │     │ ENVIRONMENT VARIABLES            │
├──────────────────────────┤     ├─────────────────────────────────┤
│ • docker-hub                │     │ • JWT_SECRET_KEY                 │
│   Docker Hub access for       │     │   Auth service token signing      │
│   pushing to vixx3 org        │     │                                  │
│                              │     │ • AUTH_SERVICE_URL               │
│ • snky                      │     │   Backend to auth communication   │
│   Snyk API token for          │     │                                  │
│   security scanning           │     │ • REACT_APP_API_BASE_URL         │
│                              │     │   Frontend to backend connection  │
│ • jwt-secret-key             │     │                                  │
│   JWT secret for deployment   │     │ • REACT_APP_AUTH_BASE_URL        │
│                              │     │   Frontend to auth connection     │
│ • Nexus-Docker              │     │                                  │
│   Optional Nexus integration  │     │ • VERSION                        │
│                              │     │   Docker image versioning         │
└──────────────────────────┘     └─────────────────────────────────┘
```


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
