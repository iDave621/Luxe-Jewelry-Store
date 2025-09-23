# 💎 Luxe Jewelry Store

A microservices-based jewelry e-commerce application with CI/CD pipeline integration using Jenkins.

## 🏗️ Project Structure

The application consists of three main services:

1. **Auth Service** - FastAPI authentication microservice (Port 8001)
2. **Backend** - FastAPI products and orders API (Port 8000) 
3. **Frontend** - React SPA frontend (Port 3000)

See [PROJECT-STRUCTURE.md](./PROJECT-STRUCTURE.md) for detailed architecture.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Git

### Run with Docker (Recommended)
```bash
git clone https://github.com/iDave621/Luxe-Jewelry-Store.git
cd Luxe-Jewelry-Store
docker-compose up --build
```

### Access the Application
- Frontend: http://localhost:3000 (Nginx running on port 80 inside container)
- Backend API: http://localhost:8000
- Auth Service: http://localhost:8001
- API Docs: http://localhost:8000/docs

## ⚙️ CI/CD Pipeline

The project uses a Jenkins pipeline defined in [Jenkinsfile](./Jenkinsfile) with the following stages:

1. **Checkout** - Retrieves source code from Git repository
2. **Build Services** - Builds Docker images for auth-service, backend, and frontend
3. **Quality Checks** - Runs unit tests and static code analysis
4. **Security Scan** - Uses Snyk to scan Docker images for vulnerabilities
5. **Test Services** - Runs application-specific tests for each service
6. **Push to Registries** - Pushes images to Docker Hub registry (`vixx3/luxe-jewelry-*`)
7. **Deploy App** - Deploys all services using docker-compose

### Required Jenkins Credentials

- `docker-hub` - Docker Hub credentials for pushing images to `vixx3` organization
- `snky` - Snyk API token for security scanning
- `jwt-secret-key` - JWT secret for secure authentication in the deployment

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

## 🚀 Manual Deployment

To deploy manually to Docker Hub:

```bash
docker-compose build
docker login
docker tag luxe-jewelry-store_auth-service vixx3/luxe-jewelry-auth-service:latest
docker tag luxe-jewelry-store_backend vixx3/luxe-jewelry-backend:latest
docker tag luxe-jewelry-store_frontend vixx3/luxe-jewelry-frontend:latest

docker push vixx3/luxe-jewelry-auth-service:latest
docker push vixx3/luxe-jewelry-backend:latest
docker push vixx3/luxe-jewelry-frontend:latest
```
