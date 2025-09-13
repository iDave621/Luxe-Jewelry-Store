"""
Shared CORS configuration for all services
"""
from fastapi.middleware.cors import CORSMiddleware

# CORS configuration
CORS_SETTINGS = {
    "allow_origins": ["http://localhost:3000"],  # React dev server
    "allow_credentials": True,
    "allow_methods": ["*"],
    "allow_headers": ["*"],
}

def add_cors_middleware(app):
    """Add CORS middleware to FastAPI app with shared configuration"""
    app.add_middleware(CORSMiddleware, **CORS_SETTINGS)
