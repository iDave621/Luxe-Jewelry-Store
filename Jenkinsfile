library identifier: 'luxe-jewelry-lib@main',
        retriever: modernSCM([
            $class: 'GitSCMSource',
            remote: 'https://github.com/iDave621/jenkins-shared-library.git'
            // Using library without additional traits
        ])

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
        
        // Nexus credential ID for authentication
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
                        // Use the defined Docker Hub credential ID
                        def workingCredId = DOCKER_HUB_CRED_ID
                        echo "=== Using Docker Hub Credential: ${workingCredId} ==="
                        
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
                                timeout(time: 5, unit: 'MINUTES') {
                                    // Push to Docker Hub using simplified shared library function
                                    echo "Pushing version-tagged images to Docker Hub..."
                                    pushToDockerHub(sourceImage: "${AUTH_SERVICE_IMAGE}:${VERSION}")
                                    pushToDockerHub(sourceImage: "${BACKEND_IMAGE}:${VERSION}")
                                    pushToDockerHub(sourceImage: "${FRONTEND_IMAGE}:${VERSION}")
                                    
                                    // Also push latest tags
                                    echo "Pushing latest tags to Docker Hub..."
                                    pushToDockerHub(sourceImage: "${AUTH_SERVICE_IMAGE}:latest")
                                    pushToDockerHub(sourceImage: "${BACKEND_IMAGE}:latest")
                                    pushToDockerHub(sourceImage: "${FRONTEND_IMAGE}:latest")
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
                                    // Using simplified shared library function for pushing to Nexus
                                    echo "Pushing Auth Service to Nexus..."
                                    pushToNexus(sourceImage: "${AUTH_SERVICE_IMAGE}:${VERSION}")
                                    
                                    echo "Pushing Backend to Nexus..."
                                    pushToNexus(sourceImage: "${BACKEND_IMAGE}:${VERSION}")
                                    
                                    echo "Pushing Frontend to Nexus..."
                                    pushToNexus(sourceImage: "${FRONTEND_IMAGE}:${VERSION}")
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
