// Jenkins Configuration - Centralized credentials and settings
// This file contains all configuration needed for the Jenkins pipeline

class JenkinsConfig {
    
    // ===== CREDENTIAL IDs =====
    static final String DOCKER_HUB_CREDENTIALS = "docker-hub"
    static final String NEXUS_CREDENTIALS = "Nexus-Docker"
    static final String SNYK_TOKEN = "snky"
    static final String JWT_SECRET = "jwt-secret-key"
    
    // ===== DOCKER REGISTRIES =====
    static final String DOCKER_HUB_REGISTRY = "vixx3"
    static final String NEXUS_REGISTRY = "host.minikube.internal:8082"
    static final String NEXUS_LOGIN_URL = "http://host.minikube.internal:8082"
    static final String NEXUS_UI_URL = "http://localhost:8081"
    static final String NEXUS_REPO_NAME = "docker-nexus"
    
    // ===== IMAGE NAMES =====
    static final String AUTH_SERVICE_IMAGE = "luxe-jewelry-auth-service"
    static final String BACKEND_IMAGE = "luxe-jewelry-backend"
    static final String FRONTEND_IMAGE = "luxe-jewelry-frontend"
    
    // ===== KUBERNETES SETTINGS =====
    static final String K8S_NAMESPACE = "luxe-jewelry"
    static final String K8S_CLOUD = "kubernetes"
    static final String SERVICE_ACCOUNT = "jenkins"
    
    // ===== HELM SETTINGS =====
    static final String HELM_RELEASE_NAME = "luxe-jewelry"
    static final String HELM_CHART_PATH = "./luxe-jewelry-chart"
    static final String HELM_NAMESPACE = "luxe-jewelry-helm"
    
    // ===== BUILD SETTINGS =====
    static final String PYTHON_VERSION = "3.11-slim"
    static final String DOCKER_VERSION = "24"
    static final String KUBECTL_VERSION = "1.28.3"
    static final int BUILD_TIMEOUT_MINUTES = 30
    static final int SECURITY_SCAN_TIMEOUT_MINUTES = 10
    
    // ===== SERVICE PATHS =====
    static final Map<String, String> SERVICE_PATHS = [
        'auth-service': 'auth-service/',
        'backend': 'backend/',
        'frontend': 'jewelry-store/'
    ]
    
    static final Map<String, String> SERVICE_DOCKERFILES = [
        'auth-service': 'auth-service/Dockerfile',
        'backend': 'backend/Dockerfile',
        'frontend': 'jewelry-store/Dockerfile'
    ]
    
    // Helper method to get full Docker Hub image name
    static String getDockerHubImage(String service) {
        return "${DOCKER_HUB_REGISTRY}/${getImageName(service)}"
    }
    
    // Helper method to get full Nexus image name
    static String getNexusImage(String service) {
        return "${NEXUS_REGISTRY}/${getImageName(service)}"
    }
    
    // Helper method to get image name by service
    static String getImageName(String service) {
        switch(service) {
            case 'auth-service':
                return AUTH_SERVICE_IMAGE
            case 'backend':
                return BACKEND_IMAGE
            case 'frontend':
                return FRONTEND_IMAGE
            default:
                throw new Exception("Unknown service: ${service}")
        }
    }
}

return this
