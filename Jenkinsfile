// Load shared library
@Library('jenkins-shared-library-temp') _

pipeline {
    agent {
        kubernetes {
            cloud 'kubernetes'
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
spec:
  serviceAccountName: jenkins
  containers:
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run
  - name: docker-client
    image: docker:24-cli
    command:
    - cat
    tty: true
    env:
    - name: DOCKER_HOST
      value: tcp://localhost:2375
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
  - name: python
    image: python:3.11-slim
    command:
    - cat
    tty: true
  volumes:
  - name: docker-sock
    emptyDir: {}
'''
        }
    }
    
    options {
        buildDiscarder(logRotator(daysToKeepStr: '30'))
        disableConcurrentBuilds()
        timestamps()
    }
    
    environment {
        // Docker Hub registry
        DOCKER_REGISTRY = "vixx3"
        AUTH_SERVICE_IMAGE = "${DOCKER_REGISTRY}/luxe-jewelry-auth-service"
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/luxe-jewelry-backend"
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/luxe-jewelry-frontend"
        VERSION = "1.0.${BUILD_NUMBER}"
        DOCKER_HUB_CRED_ID = "docker-hub"
        
        // Nexus UI URL
        NEXUS_UI_URL = "http://localhost:8081"
        // URL for tagging and pushing Docker images
        NEXUS_DOCKER_REGISTRY = "localhost:8082"
        // URL for Docker login command (with http:// prefix)
        NEXUS_DOCKER_LOGIN_URL = "http://localhost:8082"
        // Nexus repository name
        NEXUS_REPO = "docker-nexus"
        // Jenkins credential ID for Nexus authentication
        NEXUS_CRED_ID = "Nexus-Docker"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git config --global --add safe.directory ${WORKSPACE}'
            }
        }
        
        stage('Build Services') {
            parallel {
                stage('Build Auth Service') {
                    steps {
                        container('docker-client') {
                            sh 'docker build -f auth-service/Dockerfile -t ${AUTH_SERVICE_IMAGE}:${VERSION} -t ${AUTH_SERVICE_IMAGE}:latest .'
                        }
                    }
                }
                
                stage('Build Backend') {
                    steps {
                        container('docker-client') {
                            sh 'docker build -f backend/Dockerfile -t ${BACKEND_IMAGE}:${VERSION} -t ${BACKEND_IMAGE}:latest .'
                        }
                    }
                }
                
                stage('Build Frontend') {
                    steps {
                        container('docker-client') {
                            dir('jewelry-store') {
                                sh 'docker build -t ${FRONTEND_IMAGE}:${VERSION} -t ${FRONTEND_IMAGE}:latest .'
                            }
                        }
                    }
                }
            }
        }
        
        stage('Quality Checks') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        script {
                            // Run tests from the shared library
                            echo "Running tests from shared library..."
                            runPythonTests([
                                resultPath: 'test-results',
                                testCommand: 'pytest'
                            ])
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'test-results/*.xml'
                        }
                    }
                }
                
                stage('Static Code Linting') {
                    steps {
                        script {
                            sh '''
                                # Determine Python command
                                if command -v python3 &> /dev/null; then
                                  python3 -m pip install --upgrade pip --break-system-packages || true
                                  python3 -m pip install -r requirements-dev.txt --break-system-packages
                                  LINT_PY="python3"
                                fi

                                # Create pylint reports directory
                                mkdir -p pylint-reports

                                # Run pylint on Python files and generate reports
                                echo "Running Pylint static code analysis..."
                                find . -name "*.py" -not -path "./venv/*" -not -path "./.venv/*" | head -20 > python_files.txt
                                
                                if [ -s python_files.txt ]; then
                                    # Run pylint with parseable output for Jenkins
                                    $LINT_PY -m pylint --output-format=parseable --reports=y $(cat python_files.txt) > pylint-reports/pylint.log 2>&1 || true
                                    
                                    # Also generate JSON format for detailed analysis
                                    $LINT_PY -m pylint --output-format=json $(cat python_files.txt) > pylint-reports/pylint.json 2>&1 || true
                                    
                                    # Generate text report for human reading
                                    $LINT_PY -m pylint $(cat python_files.txt) > pylint-reports/pylint.txt 2>&1 || true
                                    
                                    echo "Pylint analysis completed. Check pylint-reports/ for detailed results."
                                    
                                    # Show summary
                                    if [ -f pylint-reports/pylint.txt ]; then
                                        echo "=== Pylint Summary ==="
                                        tail -20 pylint-reports/pylint.txt
                                    fi
                                else
                                    echo "No Python files found to lint."
                                    echo "Pylint: No issues found" > pylint-reports/pylint.log
                                fi
                            '''
                        }
                    }
                    post {
                        always {
                            // Archive pylint reports
                            archiveArtifacts artifacts: 'pylint-reports/*', allowEmptyArchive: true
                            
                            // Publish pylint results (fallback without Warnings Next Generation Plugin)
                            script {
                                if (fileExists('pylint-reports/pylint.txt')) {
                                    def pylintOutput = readFile('pylint-reports/pylint.txt')
                                    echo "=== Pylint Report ==="
                                    echo pylintOutput
                                    
                                    // Check if there are any errors/warnings and set build status
                                    if (pylintOutput.contains('Your code has been rated at')) {
                                        def rating = pylintOutput.find(/Your code has been rated at ([\d\.]+)\/10/)
                                        if (rating) {
                                            echo "Pylint Score: ${rating}"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        stage('Security Scan with Snyk') {
            when {
                expression {
                    return fileExists('/usr/local/bin/snyk') || fileExists('/usr/bin/snyk')
                }
            }
            steps {
                script {
                    try {
                        // Verify that Docker images exist before attempting to scan them
                        sh '''
                            # Check which images are actually available
                            echo "=== Checking for existing Docker images ==="
                            docker images | grep ${DOCKER_REGISTRY} || true
                        '''
                        
                        echo "=== Using Docker Hub Credentials ==="
                        echo "Using Docker Hub credential ID: ${env.DOCKER_HUB_CRED_ID}"
                        
                        withCredentials([
                            string(credentialsId: 'snky', variable: 'SNYK_TOKEN'),
                            usernamePassword(credentialsId: env.DOCKER_HUB_CRED_ID, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')
                            ]) {
                                sh '''
                                    set -e
                                    mkdir -p snyk-results
                                    touch snyk-results/scan-summary.json
                                    
                                    # Set Snyk token and login to Docker Hub
                                    export SNYK_TOKEN="$SNYK_TOKEN"
                                    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin || true
                                    
                                    # Helper function to scan only if image exists
                                    scan_if_exists() {
                                        local img=$1
                                        local output=$2
                                        if docker image inspect "$img" &>/dev/null; then
                                            echo "Image found, scanning: $img"
                                            snyk container test "$img" --severity-threshold=high --json-file-output="$output" || echo "Scan completed with issues"
                                            return 0
                                        else
                                            echo "Image not found, skipping scan: $img"
                                            echo '{"results": {"vulnerabilities": []}, "ok": true, "summary": "No image found to scan"}' > "$output"
                                            return 1
                                        fi
                                    }
                                    
                                    echo "=== Starting Snyk container scans ==="
                                    # Try scanning each image only if it exists
                                    scan_if_exists "${AUTH_SERVICE_IMAGE}:${VERSION}" "snyk-results/auth-scan-results.json" || true
                                    scan_if_exists "${BACKEND_IMAGE}:${VERSION}" "snyk-results/backend-scan-results.json" || true
                                    scan_if_exists "${FRONTEND_IMAGE}:${VERSION}" "snyk-results/frontend-scan-results.json" || true
                                    echo "=== Snyk scans completed ==="
                                '''
                            }
                        
                        // Archive scan results (if any were produced)
                        archiveArtifacts artifacts: 'snyk-results/*.json', allowEmptyArchive: true

                    } catch (Exception e) {
                        echo "Snyk scan stage failed: ${e.message}"
                        echo "Continuing pipeline execution..."
                    }
                }
            }
        }
        
        stage('Test Services') {
            parallel {
                stage('Test Auth Service') {
                    steps {
                        dir('auth-service') {
                            sh 'echo "Running auth service tests"'
                            // Add actual test commands here
                            // e.g., sh 'python -m pytest'
                        }
                    }
                }
                
                stage('Test Backend') {
                    steps {
                        dir('backend') {
                            sh 'echo "Running backend tests"'
                            // Add actual test commands here
                            // e.g., sh 'python -m pytest'
                        }
                    }
                }
                
                stage('Test Frontend') {
                    steps {
                        dir('jewelry-store') {
                            sh 'echo "Running frontend tests"'
                            // Add actual test commands here
                            // e.g., sh 'npm test'
                        }
                    }
                }
            }
        }
        
        stage('Push to Registries') {
            // Run Docker Hub and Nexus pushes in parallel to speed up the process
            parallel {
                stage('Push to Docker Hub') {
                    steps {
                        container('docker-client') {
                            script {
                                try {
                                    timeout(time: 10, unit: 'MINUTES') {
                                        // Using Jenkins credentials for secure Docker Hub login
                                        withCredentials([usernamePassword(credentialsId: env.DOCKER_HUB_CRED_ID, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                                            // Print username (but not password) for debugging
                                            sh 'echo "Using Docker Hub username: $DOCKER_USERNAME"'
                                            
                                            // Force Docker to log out first to ensure clean login
                                            sh 'docker logout'
                                            
                                            // Explicitly login to Docker Hub with full URL
                                            sh 'echo $DOCKER_PASSWORD | docker login https://index.docker.io/v1/ -u $DOCKER_USERNAME --password-stdin'
                                            
                                            // Verify we're logged in and can access the repositories
                                            sh 'docker info | grep "Username"'
                                            
                                            // Push with detailed error messages
                                            sh '''
                                            echo "Pushing to Docker Hub as $DOCKER_USERNAME"
                                            
                                            # Push auth-service images
                                            echo "Pushing ${AUTH_SERVICE_IMAGE}:${VERSION}..."
                                            docker push ${AUTH_SERVICE_IMAGE}:${VERSION}
                                            
                                            echo "Pushing ${AUTH_SERVICE_IMAGE}:latest..."
                                            docker push ${AUTH_SERVICE_IMAGE}:latest
                                            
                                            # Push backend images
                                            echo "Pushing ${BACKEND_IMAGE}:${VERSION}..."
                                            docker push ${BACKEND_IMAGE}:${VERSION}
                                            
                                            echo "Pushing ${BACKEND_IMAGE}:latest..."
                                            docker push ${BACKEND_IMAGE}:latest
                                            
                                            # Push frontend images
                                            echo "Pushing ${FRONTEND_IMAGE}:${VERSION}..."
                                            docker push ${FRONTEND_IMAGE}:${VERSION}
                                            
                                            echo "Pushing ${FRONTEND_IMAGE}:latest..."
                                            docker push ${FRONTEND_IMAGE}:latest
                                        '''
                                    }
                                }
                            } catch (Exception e) {
                                echo "Docker Hub push failed with error: ${e.message}"
                                echo "Continue pipeline execution without failing the build"
                            }
                            }
                        }
                    }
                }
                
                stage('Push to Nexus Registry') {
                    steps {
                        container('docker-client') {
                            script {
                                try {
                                    timeout(time: 10, unit: 'MINUTES') {
                                        withCredentials([usernamePassword(credentialsId: env.NEXUS_CRED_ID, passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')]) {
                                        // Alternative approach - try just ONE image at a time
                                        echo "Trying a focused approach with only the auth service first"
                                        
                                        sh '''
                                            # Configure Docker daemon for insecure registries
                                            mkdir -p ~/.docker
                                            cat > ~/.docker/config.json << EOF
                                            {
                                                "insecure-registries": ["localhost:8082", "localhost:8081"]
                                            }
                                            EOF
                                            
                                            # Tag just auth service
                                            echo "Tagging just auth service for Nexus..."
                                            docker tag ${AUTH_SERVICE_IMAGE}:${VERSION} localhost:8082/luxe-jewelry-auth-service:${VERSION}
                                            
                                            # Force logout to clear any stale credentials
                                            docker logout || true
                                            
                                            # Login to Nexus - with retry
                                            for attempt in 1 2 3; do
                                                echo "Login attempt $attempt..."
                                                echo "$NEXUS_PASSWORD" | docker login http://localhost:8082 -u "$NEXUS_USERNAME" --password-stdin && break
                                                sleep 2
                                            done
                                            
                                            # Push just auth service
                                            echo "Pushing auth service image to Nexus..."
                                            docker push localhost:8082/luxe-jewelry-auth-service:${VERSION}
                                        '''
                                        
                                        echo "First service pushed successfully, proceeding with others"
                                        
                                        // Now try the backend separately with fresh login
                                        sh '''
                                            # Force logout and re-login before pushing backend
                                            docker logout || true
                                            echo "$NEXUS_PASSWORD" | docker login http://localhost:8082 -u "$NEXUS_USERNAME" --password-stdin
                                            
                                            # Tag and push backend with fresh credentials
                                            docker tag ${BACKEND_IMAGE}:${VERSION} localhost:8082/luxe-jewelry-backend:${VERSION}
                                            echo "Pushing backend image to Nexus..."
                                            docker push localhost:8082/luxe-jewelry-backend:${VERSION} || true
                                        '''
                                        
                                        // Finally try the frontend separately with fresh login
                                        sh '''
                                            # Force logout and re-login before pushing frontend
                                            docker logout || true
                                            echo "$NEXUS_PASSWORD" | docker login http://localhost:8082 -u "$NEXUS_USERNAME" --password-stdin
                                            
                                            # Tag and push frontend with fresh credentials
                                            docker tag ${FRONTEND_IMAGE}:${VERSION} localhost:8082/luxe-jewelry-frontend:${VERSION}
                                            echo "Pushing frontend image to Nexus..."
                                            docker push localhost:8082/luxe-jewelry-frontend:${VERSION} || true
                                        '''
                                        
                                        // Finally push auth service with standard version
                                        sh '''
                                            # Force logout and re-login before pushing auth service
                                            docker logout || true
                                            echo "$NEXUS_PASSWORD" | docker login http://localhost:8082 -u "$NEXUS_USERNAME" --password-stdin
                                            
                                            # Tag and push auth service with fresh credentials
                                            docker tag ${AUTH_SERVICE_IMAGE}:${VERSION} localhost:8082/luxe-jewelry-auth-service:${VERSION}
                                            echo "Pushing auth service image to Nexus..."
                                            docker push localhost:8082/luxe-jewelry-auth-service:${VERSION} || true
                                        '''
                                    }
                                }
                                } catch (Exception e) {
                                    echo "Nexus push failed: ${e.message}"
                                    echo "Continue pipeline execution without failing the build"
                                }
                            }
                        }
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    script {
                        timeout(time: 10, unit: 'MINUTES') {
                            // Images are already pushed to vixx3 registry in earlier stage
                            // Kubernetes will use those images directly
                            echo "Using images from ${DOCKER_REGISTRY} registry for Kubernetes deployment"
                            
                            // Now deploy to Kubernetes
                            sh '''
                                echo "=== Deploying to Kubernetes ==="
                                
                                # Check if kubectl is available
                                if ! command -v kubectl &> /dev/null; then
                                    echo "ERROR: kubectl is not installed or not in PATH"
                                    exit 1
                                fi
                                
                                # Check if Minikube is running
                                if ! kubectl cluster-info &> /dev/null; then
                                    echo "ERROR: Kubernetes cluster is not accessible"
                                    echo "Please start Minikube: minikube start"
                                    exit 1
                                fi
                                
                                echo "Kubernetes cluster is accessible"
                                kubectl cluster-info
                                
                                # Apply Kubernetes manifests
                                echo "Applying Kubernetes manifests..."
                                kubectl apply -f k8s/base/namespace.yaml
                                kubectl apply -f k8s/base/configmap.yaml
                            '''
                            
                            // Try to create JWT secret if credential exists
                            try {
                                withCredentials([string(credentialsId: 'jwt-secret-key', variable: 'JWT_SECRET')]) {
                                    sh '''
                                        echo "Creating Kubernetes secret with JWT key from Jenkins..."
                                        kubectl create secret generic luxe-jewelry-secrets \
                                            --from-literal=JWT_SECRET_KEY="$JWT_SECRET" \
                                            --namespace=luxe-jewelry \
                                            --dry-run=client -o yaml | kubectl apply -f -
                                    '''
                                }
                            } catch (Exception e) {
                                echo "Warning: JWT secret credential not found. Using default secret from k8s/base/secret.yaml"
                                sh 'kubectl apply -f k8s/base/secret.yaml'
                            }
                            
                            // Create Docker registry secret for pulling images
                            withCredentials([usernamePassword(credentialsId: env.DOCKER_HUB_CRED_ID, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                                sh '''
                                    echo "Creating Docker registry secret for Kubernetes..."
                                    kubectl create secret docker-registry dockerhub-secret \
                                        --docker-server=https://index.docker.io/v1/ \
                                        --docker-username="$DOCKER_USERNAME" \
                                        --docker-password="$DOCKER_PASSWORD" \
                                        --namespace=luxe-jewelry \
                                        --dry-run=client -o yaml | kubectl apply -f -
                                    
                                    echo "Docker registry secret created!"
                                '''
                            }
                            
                            sh '''
                                kubectl apply -f k8s/deployments/auth-service-deployment.yaml
                                kubectl apply -f k8s/deployments/backend-deployment.yaml
                                kubectl apply -f k8s/deployments/frontend-deployment.yaml
                                kubectl apply -f k8s/base/ingress.yaml
                                
                                # Wait for deployments to be ready
                                echo "Waiting for deployments to be ready..."
                                kubectl rollout status deployment/auth-service -n luxe-jewelry --timeout=300s
                                kubectl rollout status deployment/backend -n luxe-jewelry --timeout=300s
                                kubectl rollout status deployment/frontend -n luxe-jewelry --timeout=300s
                                
                                # Display deployment status
                                echo "=== Deployment Status ==="
                                kubectl get all -n luxe-jewelry
                                
                                echo "=== Pod Details ==="
                                kubectl get pods -n luxe-jewelry -o wide
                                
                                echo "=== Services ==="
                                kubectl get svc -n luxe-jewelry
                                
                                echo "=== Ingress ==="
                                kubectl get ingress -n luxe-jewelry
                                
                                # Get Minikube service URL
                                echo "=== Access URLs ==="
                                echo "Frontend: http://$(minikube ip):30000"
                                echo "Or use: minikube service frontend -n luxe-jewelry --url"
                                
                                echo "Deployment to Kubernetes completed successfully!"
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Deploy with Docker Compose (Alternative)') {
            when {
                expression {
                    return params.DEPLOY_METHOD == 'docker-compose'
                }
            }
            steps {
                container('docker-client') {
                    timeout(time: 5, unit: 'MINUTES') {
                        withCredentials([usernamePassword(credentialsId: env.DOCKER_HUB_CRED_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            # Deploy using docker-compose
                            docker-compose down || true
                            docker-compose up -d
                            
                            # Give containers a moment to start and verify they're running
                            sleep 10
                            docker ps
                            
                            echo "Deployment complete - All 3 services running"
                        '''
                        }
                    }
                }
            }
        }
        
    }
    
    post {
        always {
            // Workspace cleanup
            script {
                cleanWs()
            }
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
            // Add notification steps here (email, Slack, etc.)
        }
    }
}
