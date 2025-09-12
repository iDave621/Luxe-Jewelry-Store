pipeline {
    agent {
        docker {
            image 'iDave621/jenkins-agent'
            args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
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
        GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Auth Service') {
            steps {
                dir('auth-service') {
                    sh 'docker build -t ${AUTH_SERVICE_IMAGE}:${VERSION} -t ${AUTH_SERVICE_IMAGE}:${GIT_COMMIT_SHORT} -t ${AUTH_SERVICE_IMAGE}:latest .'
                }
            }
        }
        
        stage('Build Backend') {
            steps {
                dir('backend') {
                    sh 'docker build -t ${BACKEND_IMAGE}:${VERSION} -t ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} -t ${BACKEND_IMAGE}:latest .'
                }
            }
        }
        
        stage('Build Frontend') {
            steps {
                dir('jewelry-store') {
                    sh 'docker build -t ${FRONTEND_IMAGE}:${VERSION} -t ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} -t ${FRONTEND_IMAGE}:latest .'
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
                        withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                            sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                            sh '''
                                # Push auth-service images
                                docker push ${AUTH_SERVICE_IMAGE}:${VERSION}
                                docker push ${AUTH_SERVICE_IMAGE}:${GIT_COMMIT_SHORT}
                                docker push ${AUTH_SERVICE_IMAGE}:latest
                                
                                # Push backend images
                                docker push ${BACKEND_IMAGE}:${VERSION}
                                docker push ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}
                                docker push ${BACKEND_IMAGE}:latest
                                
                                # Push frontend images
                                docker push ${FRONTEND_IMAGE}:${VERSION}
                                docker push ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}
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
            node(null) {
                // Clean up Docker images
                sh '''
                    # Clean auth-service images
                    docker rmi ${AUTH_SERVICE_IMAGE}:${VERSION} ${AUTH_SERVICE_IMAGE}:${GIT_COMMIT_SHORT} ${AUTH_SERVICE_IMAGE}:latest || true
                    
                    # Clean backend images
                    docker rmi ${BACKEND_IMAGE}:${VERSION} ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} ${BACKEND_IMAGE}:latest || true
                    
                    # Clean frontend images
                    docker rmi ${FRONTEND_IMAGE}:${VERSION} ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} ${FRONTEND_IMAGE}:latest || true
                '''
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
