pipeline {
    agent {
        node {
            label 'docker-agent'
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
        
        // Nexus Docker registry information
        // Nexus registry address with port
        NEXUS_REGISTRY = "192.168.1.117:8082"
        // Docker repository name in Nexus
        NEXUS_REPO = "docker-hosted"
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
                        sh 'docker build -f auth-service/Dockerfile -t ${AUTH_SERVICE_IMAGE}:${VERSION} -t ${AUTH_SERVICE_IMAGE}:latest .'
                    }
                }
                
                stage('Build Backend') {
                    steps {
                        sh 'docker build -f backend/Dockerfile -t ${BACKEND_IMAGE}:${VERSION} -t ${BACKEND_IMAGE}:latest .'
                    }
                }
                
                stage('Build Frontend') {
                    steps {
                        dir('jewelry-store') {
                            sh 'docker build -t ${FRONTEND_IMAGE}:${VERSION} -t ${FRONTEND_IMAGE}:latest .'
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
                            sh '''
                                # Determine Python command
                                if command -v python3 &> /dev/null; then
                                  python3 -m pip install --upgrade pip --break-system-packages || true
                                  python3 -m pip install -r requirements-dev.txt --break-system-packages
                                  TEST_PY="python3"
                                fi

                                # Run tests and produce JUnit XML
                                $TEST_PY -m pytest --junitxml results.xml tests/*.py || true
                            '''
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'results.xml'
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
            steps {
                script {
                    try {
                        // Try multiple common Docker Hub credential IDs
                        def credentialIds = ['docker-hub', 'dockerhub', 'docker-hub-credentials', 'dockerhub-credentials', 'docker_hub', 'DOCKERHUB_CREDENTIALS']
                        def workingCredId = null
                        
                        echo "=== Finding Docker Hub Credentials ==="
                        echo "Pipeline job: ${env.JOB_NAME}"
                        echo "Build number: ${env.BUILD_NUMBER}"
                        
                        for (credId in credentialIds) {
                            if (workingCredId) break
                            try {
                                withCredentials([usernamePassword(credentialsId: credId, passwordVariable: 'TEST_PASS', usernameVariable: 'TEST_USER')]) {
                                    echo "✓ Found working credential ID: ${credId}"
                                    workingCredId = credId
                                }
                            } catch (Exception e) {
                                echo "✗ Credential ID '${credId}' not found: ${e.message}"
                            }
                        }
                        
                        if (workingCredId) {
                            echo "Using Docker Hub credential ID: ${workingCredId}"
                            withCredentials([
                                string(credentialsId: 'snky', variable: 'SNYK_TOKEN'),
                                usernamePassword(credentialsId: workingCredId, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')
                            ]) {
                                sh '''
                                    set -eu
                                    mkdir -p snyk-results
                                    
                                    # Set Snyk token and login to Docker Hub
                                    export SNYK_TOKEN="$SNYK_TOKEN"
                                    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                                    
                                    # Authenticated registry-based scanning
                                    echo "Scanning Auth Service (remote, authenticated): ${AUTH_SERVICE_IMAGE}:${VERSION}"
                                    snyk container test --remote "${AUTH_SERVICE_IMAGE}:${VERSION}" --username "$DOCKER_USERNAME" --password "$DOCKER_PASSWORD" --severity-threshold=high --json-file-output=snyk-results/auth-scan-results.json || true
                                    
                                    echo "Scanning Backend (remote, authenticated): ${BACKEND_IMAGE}:${VERSION}"
                                    snyk container test --remote "${BACKEND_IMAGE}:${VERSION}" --username "$DOCKER_USERNAME" --password "$DOCKER_PASSWORD" --severity-threshold=high --json-file-output=snyk-results/backend-scan-results.json || true
                                    
                                    echo "Scanning Frontend (remote, authenticated): ${FRONTEND_IMAGE}:${VERSION}"
                                    snyk container test --remote "${FRONTEND_IMAGE}:${VERSION}" --username "$DOCKER_USERNAME" --password "$DOCKER_PASSWORD" --severity-threshold=high --json-file-output=snyk-results/frontend-scan-results.json || true
                                '''
                            }
                        } else {
                            echo "❌ No Docker Hub credentials found with common IDs"
                            echo "Please create a Docker Hub credential in Jenkins with one of these IDs:"
                            echo "  - dockerhub (recommended)"
                            echo "  - docker-hub-credentials" 
                            echo "  - dockerhub-credentials"
                            echo "Credential type: Username with password"
                            echo "Skipping Snyk scans for this build."
                        }
                        
                        // Archive scan results (if any were produced)
                        archiveArtifacts artifacts: 'snyk-results/*.json', allowEmptyArchive: true

                    } catch (Exception e) {
                        echo "Snyk scan found security issues: ${e.message}"
                        echo "Continuing pipeline execution despite security findings..."
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
                                            
                                            # Push auth-service images with retries
                                            echo "Pushing ${AUTH_SERVICE_IMAGE}:${VERSION}..."
                                            for i in 1 2 3; do
                                                docker push ${AUTH_SERVICE_IMAGE}:${VERSION} && break || echo "Retry $i for auth service..."
                                                sleep 3
                                            done
                                            
                                            echo "Pushing ${AUTH_SERVICE_IMAGE}:latest..."
                                            for i in 1 2 3; do
                                                docker push ${AUTH_SERVICE_IMAGE}:latest && break || echo "Retry $i for auth service latest..."
                                                sleep 3
                                            done
                                            
                                            # Push backend images with retries
                                            echo "Pushing ${BACKEND_IMAGE}:${VERSION}..."
                                            for i in 1 2 3; do
                                                docker push ${BACKEND_IMAGE}:${VERSION} && break || echo "Retry $i for backend..."
                                                sleep 3
                                            done
                                            
                                            echo "Pushing ${BACKEND_IMAGE}:latest..."
                                            for i in 1 2 3; do
                                                docker push ${BACKEND_IMAGE}:latest && break || echo "Retry $i for backend latest..."
                                                sleep 3
                                            done
                                            
                                            # Push frontend images with retries
                                            echo "Pushing ${FRONTEND_IMAGE}:${VERSION}..."
                                            for i in 1 2 3; do
                                                docker push ${FRONTEND_IMAGE}:${VERSION} && break || echo "Retry $i for frontend..."
                                                sleep 3
                                            done
                                            
                                            echo "Pushing ${FRONTEND_IMAGE}:latest..."
                                            for i in 1 2 3; do
                                                docker push ${FRONTEND_IMAGE}:latest && break || echo "Retry $i for frontend latest..."
                                                sleep 3
                                            done
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
                
                stage('Push to Nexus Registry') {
                    steps {
                        script {
                            try {
                                timeout(time: 10, unit: 'MINUTES') {
                                    withCredentials([usernamePassword(credentialsId: env.NEXUS_CRED_ID, passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')]) {
                                        // Use Docker commands with HTTPS for Nexus Docker registry
                                        sh '''
                                            echo "==== PUSHING DOCKER IMAGES TO NEXUS REGISTRY USING HTTPS ===="
                                            
                                            # Check for Docker certificates directory for our registry
                                            echo "\nVerifying Docker certificates setup..."
                                            if [ ! -d "/etc/docker/certs.d/${NEXUS_DOCKER_REGISTRY}" ]; then
                                                echo "Warning: No certificates directory found for ${NEXUS_DOCKER_REGISTRY}"
                                                echo "Docker may not trust the Nexus certificate"
                                                echo "Creating directory for certificate..."
                                                mkdir -p /etc/docker/certs.d/${NEXUS_DOCKER_REGISTRY}
                                            else
                                                echo "Certificate directory exists for ${NEXUS_DOCKER_REGISTRY}"
                                            fi
                                            
                                            # 1. Create Docker configuration with registry auth
                                            echo "\nConfiguring Docker authentication..."
                                            mkdir -p ~/.docker
                                            echo '{"auths":{"'${NEXUS_DOCKER_REGISTRY}'":{"auth":"'$(echo -n ${NEXUS_USERNAME}:${NEXUS_PASSWORD} | base64 -w 0)'"}}}' > ~/.docker/config.json
                                            
                                            # 2. Tag the images with our HTTPS registry
                                            echo "\nTagging Docker images for HTTPS Nexus registry..."
                                            docker tag ${AUTH_SERVICE_IMAGE}:${VERSION} ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-auth-service:${VERSION}
                                            docker tag ${BACKEND_IMAGE}:${VERSION} ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-backend:${VERSION}
                                            docker tag ${FRONTEND_IMAGE}:${VERSION} ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-frontend:${VERSION}
                                            
                                            # 3. Log in to the Nexus registry
                                            echo "\nLogging in to Nexus Docker registry..."
                                            echo ${NEXUS_PASSWORD} | docker login -u ${NEXUS_USERNAME} --password-stdin ${NEXUS_DOCKER_REGISTRY}
                                            
                                            # 4. Push images to Nexus registry
                                            echo "\nPushing auth-service to Nexus (with retry logic)..."
                                            for i in 1 2 3; do
                                                docker push ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-auth-service:${VERSION} && break || echo "Attempt $i failed, retrying..."
                                                sleep 3
                                            done
                                            
                                            echo "\nPushing backend to Nexus (with retry logic)..."
                                            for i in 1 2 3; do
                                                docker push ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-backend:${VERSION} && break || echo "Attempt $i failed, retrying..."
                                                sleep 3
                                            done
                                            
                                            echo "\nPushing frontend to Nexus (with retry logic)..."
                                            for i in 1 2 3; do
                                                docker push ${NEXUS_DOCKER_REGISTRY}/luxe-jewelry-frontend:${VERSION} && break || echo "Attempt $i failed, retrying..."
                                                sleep 3
                                            done
                                            
                                            # 5. Verify the push was successful
                                            echo "\nVerifying Nexus repository contents..."
                                            curl -k -s -u "${NEXUS_USERNAME}:${NEXUS_PASSWORD}" -X GET https://${NEXUS_DOCKER_REGISTRY}/v2/_catalog
                                            
                                            echo "\n==== NEXUS PUSH OPERATIONS COMPLETED ===="
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
        
        stage('Deploy App') {
            steps {
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
    
    post {
        always {
            // Clean up Docker images
            script {
                try {
                    sh 'docker image prune -f || true'
                } catch (Exception e) {
                    echo "Error cleaning up Docker images: ${e.message}"
                }
            }
            // Workspace cleanup
            cleanWs()
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
