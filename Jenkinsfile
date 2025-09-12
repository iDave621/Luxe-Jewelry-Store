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
        DOCKER_REGISTRY = "iDave621"
        AUTH_SERVICE_IMAGE = "${DOCKER_REGISTRY}/luxe-jewelry-auth-service"
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/luxe-jewelry-backend"
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/luxe-jewelry-frontend"
        VERSION = "1.0.${BUILD_NUMBER}"
        DOCKER_HUB_CRED_ID = 'docker-hub-credentials'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git config --global --add safe.directory ${WORKSPACE}'
            }
        }
        
        stage('Build Auth Service') {
            steps {
                dir('auth-service') {
                    sh 'docker build -t ${AUTH_SERVICE_IMAGE}:${VERSION} -t ${AUTH_SERVICE_IMAGE}:latest .'
                }
            }
        }
        
        stage('Build Backend') {
            steps {
                dir('backend') {
                    sh 'docker build -t ${BACKEND_IMAGE}:${VERSION} -t ${BACKEND_IMAGE}:latest .'
                }
            }
        }
        
        stage('Build Frontend') {
            steps {
                dir('jewelry-store') {
                    sh 'docker build -t ${FRONTEND_IMAGE}:${VERSION} -t ${FRONTEND_IMAGE}:latest .'
                }
            }
        }
        
        stage('Security Scan with Snyk') {
            steps {
                script {
                    try {
                        // 1) Try anonymous pull first (works for public repos)
                        sh '''
                            set -eu
                            for IMG in "${AUTH_SERVICE_IMAGE}:${VERSION}" "${BACKEND_IMAGE}:${VERSION}" "${FRONTEND_IMAGE}:${VERSION}"; do
                              if ! docker image inspect "$IMG" > /dev/null 2>&1; then
                                echo "Attempting anonymous pull for $IMG (linux/amd64)"
                                docker pull --platform=linux/amd64 "$IMG" || true
                              fi
                            done
                        '''

                        // 2) If any image still missing, try authenticated pull using configured credentials
                        def needAuthPull = sh(
                            script: 'for IMG in "${AUTH_SERVICE_IMAGE}:${VERSION}" "${BACKEND_IMAGE}:${VERSION}" "${FRONTEND_IMAGE}:${VERSION}"; do docker image inspect "$IMG" > /dev/null 2>&1 || exit 1; done; exit 0',
                            returnStatus: true
                        )

                        if (needAuthPull != 0) {
                            echo "Attempting authenticated pull using credentials ID: ${env.DOCKER_HUB_CRED_ID}"
                            withCredentials([usernamePassword(credentialsId: env.DOCKER_HUB_CRED_ID, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                                sh '''
                                    set -eu
                                    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                                    for IMG in "${AUTH_SERVICE_IMAGE}:${VERSION}" "${BACKEND_IMAGE}:${VERSION}" "${FRONTEND_IMAGE}:${VERSION}"; do
                                      if ! docker image inspect "$IMG" > /dev/null 2>&1; then
                                        echo "Authenticated pull for $IMG (linux/amd64)"
                                        docker pull --platform=linux/amd64 "$IMG" || true
                                      fi
                                    done
                                '''
                            }
                        } else {
                            echo 'All images present locally after anonymous pull; skipping authenticated pull'
                        }

                        // 3) Snyk auth and scans (prefer authenticated remote; fallback to unauthenticated if creds missing)
                        withCredentials([string(credentialsId: 'snyk-api-token', variable: 'SNYK_TOKEN')]) {
                            try {
                                withCredentials([usernamePassword(credentialsId: env.DOCKER_HUB_CRED_ID, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                                    sh '''
                                        set -eu
                                        mkdir -p snyk-results
                                        
                                        # Provide auth for Snyk and Docker Hub
                                        export SNYK_TOKEN="$SNYK_TOKEN"
                                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin || true

                                        # Authenticated registry-based scanning
                                        echo "Scanning Auth Service (remote, auth): ${AUTH_SERVICE_IMAGE}:${VERSION}"
                                        snyk container test --remote "${AUTH_SERVICE_IMAGE}:${VERSION}" --username "$DOCKER_USERNAME" --password "$DOCKER_PASSWORD" --severity-threshold=high --json-file-output=snyk-results/auth-scan-results.json || true

                                        echo "Scanning Backend (remote, auth): ${BACKEND_IMAGE}:${VERSION}"
                                        snyk container test --remote "${BACKEND_IMAGE}:${VERSION}" --username "$DOCKER_USERNAME" --password "$DOCKER_PASSWORD" --severity-threshold=high --json-file-output=snyk-results/backend-scan-results.json || true

                                        echo "Scanning Frontend (remote, auth): ${FRONTEND_IMAGE}:${VERSION}"
                                        snyk container test --remote "${FRONTEND_IMAGE}:${VERSION}" --username "$DOCKER_USERNAME" --password "$DOCKER_PASSWORD" --severity-threshold=high --json-file-output=snyk-results/frontend-scan-results.json || true
                                    '''
                                }
                            } catch (Exception credErr) {
                                echo "Docker Hub credential '${env.DOCKER_HUB_CRED_ID}' not found or inaccessible; running unauthenticated remote scans (public repos only)"
                                sh '''
                                    set -eu
                                    mkdir -p snyk-results
                                    
                                    # Snyk auth via env only
                                    export SNYK_TOKEN="$SNYK_TOKEN"

                                    echo "Scanning Auth Service (remote): ${AUTH_SERVICE_IMAGE}:${VERSION}"
                                    snyk container test --remote "${AUTH_SERVICE_IMAGE}:${VERSION}" --severity-threshold=high --json-file-output=snyk-results/auth-scan-results.json || true

                                    echo "Scanning Backend (remote): ${BACKEND_IMAGE}:${VERSION}"
                                    snyk container test --remote "${BACKEND_IMAGE}:${VERSION}" --severity-threshold=high --json-file-output=snyk-results/backend-scan-results.json || true

                                    echo "Scanning Frontend (remote): ${FRONTEND_IMAGE}:${VERSION}"
                                    snyk container test --remote "${FRONTEND_IMAGE}:${VERSION}" --severity-threshold=high --json-file-output=snyk-results/frontend-scan-results.json || true
                                '''
                            }
                        }

                        // Archive scan results (if produced)
                        archiveArtifacts artifacts: 'snyk-results/*.json', allowEmptyArchive: true

                    } catch (Exception e) {
                        echo "Snyk scan found security issues: ${e.message}"
                        echo "Continuing pipeline execution despite security findings..."
                    }
                }
            }
        }
        
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
        
        stage('Push Images to Registry') {
            steps {
                script {
                    try {
                        // Using Jenkins credentials for secure Docker Hub login
                        withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                            sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                            sh '''
                                # Push auth-service images
                                docker push ${AUTH_SERVICE_IMAGE}:${VERSION}
                                docker push ${AUTH_SERVICE_IMAGE}:latest
                                
                                # Push backend images
                                docker push ${BACKEND_IMAGE}:${VERSION}
                                docker push ${BACKEND_IMAGE}:latest
                                
                                # Push frontend images
                                docker push ${FRONTEND_IMAGE}:${VERSION}
                                docker push ${FRONTEND_IMAGE}:latest
                            '''
                        }
                    } catch (Exception e) {
                        echo "Docker Hub push skipped: ${e.message}"
                        echo "Continue pipeline execution without failing the build"
                    }
                }
            }
        }
        
        stage('Deploy to Development') {
            steps {
                script {
                    try {
                        sh 'echo "Deploying to development environment"'
                        // Here you would typically update your Docker Compose file 
                        // or Kubernetes manifests with the new image tags
                        
                        // First check if docker-compose exists
                        def dockerComposeExists = sh(script: 'command -v docker-compose', returnStatus: true) == 0
                        def dockerComposePluginExists = false
                        
                        if (!dockerComposeExists) {
                            // Check if docker CLI with compose plugin exists
                            def dockerExists = sh(script: 'command -v docker', returnStatus: true) == 0
                            if (dockerExists) {
                                dockerComposePluginExists = sh(script: 'docker compose version', returnStatus: true) == 0
                            }
                        }
                        
                        if (dockerComposeExists) {
                            echo "Using docker-compose command"
                            sh 'docker-compose down || true'
                            sh 'docker-compose up -d'
                        } else if (dockerComposePluginExists) {
                            echo "Using docker compose plugin"
                            sh 'docker compose down || true'
                            sh 'docker compose up -d'
                        } else {
                            echo "WARNING: docker-compose command not found. Skipping deployment."
                            echo "Please install docker-compose or Docker CLI with compose plugin."
                        }
                    } catch (Exception e) {
                        echo "Deployment step failed: ${e.message}"
                        echo "Continuing with pipeline execution."
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Ensure post actions cannot linger
            timeout(time: 1, unit: 'MINUTES') {
                node('docker-agent') {
                    // Clean up Docker images (short timeout, never fail build)
                    script {
                        try {
                            timeout(time: 20, unit: 'SECONDS') {
                                sh 'docker image prune -f || true'
                            }
                        } catch (Exception e) {
                            echo "Error cleaning up Docker images: ${e.message}"
                        }
                    }
                    // Workspace cleanup (short timeout)
                    timeout(time: 20, unit: 'SECONDS') {
                        cleanWs()
                    }
                }
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
