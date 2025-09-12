pipeline {
    agent any
    
    environment {
        DOCKER_HUB_CREDS = credentials('docker-hub-credentials')
        DOCKER_REGISTRY = "iDave621"
        AUTH_SERVICE_IMAGE = "${DOCKER_REGISTRY}/luxe-jewelry-auth-service"
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/luxe-jewelry-backend"
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/luxe-jewelry-frontend"
        VERSION = "1.0.${BUILD_NUMBER}"
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
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                    sh 'docker push ${AUTH_SERVICE_IMAGE}:${VERSION}'
                    sh 'docker push ${AUTH_SERVICE_IMAGE}:latest'
                    sh 'docker push ${BACKEND_IMAGE}:${VERSION}'
                    sh 'docker push ${BACKEND_IMAGE}:latest'
                    sh 'docker push ${FRONTEND_IMAGE}:${VERSION}'
                    sh 'docker push ${FRONTEND_IMAGE}:latest'
                }
            }
        }
        
        stage('Deploy to Development') {
            steps {
                sh 'echo "Deploying to development environment"'
                // Here you would typically update your Docker Compose file 
                // or Kubernetes manifests with the new image tags
                sh '''
                    echo "Using Docker Compose for deployment..."
                    docker-compose down || true
                    docker-compose up -d
                '''
            }
        }
    }
    
    post {
        always {
            node {
                sh 'docker logout'
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
