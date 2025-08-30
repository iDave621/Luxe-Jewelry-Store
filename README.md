# 💎 Luxe Jewelry Store

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Git

### Run with Docker (Recommended)
```bash
git clone https://github.com/ronbhadad22/Luxe-Jewelry-Store.git
cd Luxe-Jewelry-Store
docker-compose up --build
```

### Access the Application
- Frontend: http://localhost:3000 (Nginx running on port 80 inside container)
- Backend API: http://localhost:8000
- Auth Service: http://localhost:8001
- API Docs: http://localhost:8000/docs

## 🛠 Manual Setup (Development)

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

## 🐳 Docker Commands

| Command | Description |
|---------|-------------|
| `docker-compose up --build` | Build and start all services |
| `docker-compose down` | Stop and remove containers |
| `docker-compose logs -f` | View logs |
| `docker-compose ps` | Check container status |

## 🔧 Environment Variables

### Auth Service
- `JWT_SECRET_KEY` - For JWT token signing
- `DATABASE_URL` - Database connection string

### Backend
- `AUTH_SERVICE_URL` - Auth service URL
- `DATABASE_URL` - Database connection string

## 🚀 Deployment

1. Build and push to Docker Hub:
```bash
docker-compose build
docker login
docker tag luxe-jewelry-store_auth-service <your-username>/luxe-jewelry-store-auth:latest
docker tag luxe-jewelry-store_backend <your-username>/luxe-jewelry-store-backend:latest
docker tag luxe-jewelry-store_frontend <your-username>/luxe-jewelry-store-frontend:latest

docker push <your-username>/luxe-jewelry-store-auth:latest
docker push <your-username>/luxe-jewelry-store-backend:latest
docker push <your-username>/luxe-jewelry-store-frontend:latest
```

2. Deploy using Kubernetes (see `k8s/` directory)

## 📝 License

MIT
