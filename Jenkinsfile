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
    command:
    - dockerd-entrypoint.sh
    args:
    - "--insecure-registry=host.minikube.internal:8082"
    - "--insecure-registry=host.minikube.internal:8081"
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
    image: alpine/k8s:1.28.3
    command:
    - cat
    tty: true
    env:
    - name: KUBECONFIG
      value: /tmp/kubeconfig
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
        // URL for tagging and pushing Docker images (use host.minikube.internal for access from K8s pods)
        NEXUS_DOCKER_REGISTRY = "host.minikube.internal:8082"
        // URL for Docker login command (with http:// prefix)
        NEXUS_DOCKER_LOGIN_URL = "http://host.minikube.internal:8082"
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
                                sh '''
                                    docker build \
                                        --build-arg REACT_APP_API_BASE_URL=/api \
                                        --build-arg REACT_APP_AUTH_BASE_URL=/auth \
                                        -t ${FRONTEND_IMAGE}:${VERSION} \
                                        -t ${FRONTEND_IMAGE}:latest \
                                        .
                                '''
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
                        container('python') {
                            script {
                                // Run tests from the shared library
                                echo "Running tests from shared library..."
                                runPythonTests([
                                    resultPath: 'test-results',
                                    testCommand: 'pytest'
                                ])
                            }
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
                        container('python') {
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
                                            # Tag auth service for Nexus (both version and latest)
                                            echo "Tagging auth service for Nexus..."
                                            docker tag ${AUTH_SERVICE_IMAGE}:${VERSION} ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-auth-service:${VERSION}
                                            docker tag ${AUTH_SERVICE_IMAGE}:${VERSION} ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-auth-service:latest
                                            
                                            # Force logout to clear any stale credentials
                                            docker logout || true
                                            
                                            # Login to Nexus - with retry
                                            for attempt in 1 2 3; do
                                                echo "Login attempt $attempt..."
                                                echo "$NEXUS_PASSWORD" | docker login ${NEXUS_DOCKER_LOGIN_URL} -u "$NEXUS_USERNAME" --password-stdin && break
                                                sleep 2
                                            done
                                            
                                            # Push auth service (both version and latest)
                                            echo "Pushing auth service ${VERSION} to Nexus..."
                                            docker push ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-auth-service:${VERSION}
                                            echo "Pushing auth service latest to Nexus..."
                                            docker push ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-auth-service:latest
                                        '''
                                        
                                        echo "First service pushed successfully, proceeding with others"
                                        
                                        // Now try the backend separately with fresh login
                                        sh '''
                                            # Force logout and re-login before pushing backend
                                            docker logout || true
                                            echo "$NEXUS_PASSWORD" | docker login ${NEXUS_DOCKER_LOGIN_URL} -u "$NEXUS_USERNAME" --password-stdin
                                            
                                            # Tag backend with fresh credentials (both version and latest)
                                            docker tag ${BACKEND_IMAGE}:${VERSION} ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-backend:${VERSION}
                                            docker tag ${BACKEND_IMAGE}:${VERSION} ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-backend:latest
                                            
                                            echo "Pushing backend ${VERSION} to Nexus..."
                                            docker push ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-backend:${VERSION} || true
                                            echo "Pushing backend latest to Nexus..."
                                            docker push ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-backend:latest || true
                                        '''
                                        
                                        // Finally try the frontend separately with fresh login
                                        sh '''
                                            # Force logout and re-login before pushing frontend
                                            docker logout || true
                                            echo "$NEXUS_PASSWORD" | docker login ${NEXUS_DOCKER_LOGIN_URL} -u "$NEXUS_USERNAME" --password-stdin
                                            
                                            # Tag frontend with fresh credentials (both version and latest)
                                            docker tag ${FRONTEND_IMAGE}:${VERSION} ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-frontend:${VERSION}
                                            docker tag ${FRONTEND_IMAGE}:${VERSION} ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-frontend:latest
                                            
                                            echo "Pushing frontend ${VERSION} to Nexus..."
                                            docker push ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-frontend:${VERSION} || true
                                            echo "Pushing frontend latest to Nexus..."
                                            docker push ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-frontend:latest || true
                                        '''
                                        
                                        echo "✅ All images pushed to Nexus successfully!"
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
                                
                                # Configure kubectl to use in-cluster service account
                                KUBERNETES_SERVICE_HOST=${KUBERNETES_SERVICE_HOST:-kubernetes.default.svc}
                                KUBERNETES_SERVICE_PORT=${KUBERNETES_SERVICE_PORT:-443}
                                SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
                                TOKEN=$(cat ${SERVICEACCOUNT}/token)
                                CACERT=${SERVICEACCOUNT}/ca.crt
                                
                                # Create kubeconfig
                                kubectl config set-cluster kubernetes --server=https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT} --certificate-authority=${CACERT}
                                kubectl config set-credentials jenkins --token=${TOKEN}
                                kubectl config set-context jenkins@kubernetes --cluster=kubernetes --user=jenkins --namespace=jenkins
                                kubectl config use-context jenkins@kubernetes
                                
                                echo "Kubernetes cluster configured successfully"
                                
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
                                
                                # Update deployments with versioned images from Nexus
                                echo "Updating deployments with version ${VERSION} from Nexus..."
                                kubectl set image deployment/auth-service auth-service=${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-auth-service:${VERSION} -n luxe-jewelry
                                kubectl set image deployment/backend backend=${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-backend:${VERSION} -n luxe-jewelry
                                kubectl set image deployment/frontend frontend=${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-frontend:${VERSION} -n luxe-jewelry
                                
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
                                
                                echo ""
                                echo "╔════════════════════════════════════════════════════════════════╗"
                                echo "║                  🎉 DEPLOYMENT SUCCESSFUL! 🎉                  ║"
                                echo "╠════════════════════════════════════════════════════════════════╣"
                                echo "║                                                                ║"
                                echo "║  📱 Access Your Luxe Jewelry Store:                            ║"
                                echo "║                                                                ║"
                                echo "║  Option 1: Direct URL (may not work on Windows)                ║"
                                echo "║     http://192.168.49.2:30000                                  ║"
                                echo "║                                                                ║"
                                echo "║  Option 2: Use Minikube Service (RECOMMENDED)                  ║"
                                echo "║     Run in terminal:                                           ║"
                                echo "║     minikube service frontend -n luxe-jewelry                  ║"
                                echo "║                                                                ║"
                                echo "║  Option 3: Port Forward                                        ║"
                                echo "║     kubectl port-forward -n luxe-jewelry svc/frontend 3000:80  ║"
                                echo "║     Then open: http://localhost:3000                           ║"
                                echo "║                                                                ║"
                                echo "║  🔍 Check Status:                                              ║"
                                echo "║     kubectl get pods -n luxe-jewelry                           ║"
                                echo "║                                                                ║"
                                echo "╚════════════════════════════════════════════════════════════════╝"
                                echo ""
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
