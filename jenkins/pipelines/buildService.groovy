// Build Service Pipeline
// Handles building Docker images for a specific service

def call(Map params) {
    def config = params.config
    def serviceName = params.serviceName
    def version = params.version
    
    stage("Build ${serviceName}") {
        when {
            expression { params.shouldBuild }
        }
        steps {
            script {
                container('docker-client') {
                    echo "Building ${serviceName} version ${version}..."
                    
                    def imageName = config.getImageName(serviceName)
                    def dockerfile = config.SERVICE_DOCKERFILES[serviceName]
                    
                    sh """
                        docker build -f ${dockerfile} \
                            -t ${imageName}:${version} \
                            -t ${imageName}:latest \
                            .
                    """
                    
                    echo "✅ Successfully built ${serviceName}"
                }
            }
        }
    }
}

def buildImage(script, config, serviceName, version) {
    script.container('docker-client') {
        script.echo "🔨 Building ${serviceName} version ${version}..."
        
        def imageName = config.getImageName(serviceName)
        def dockerfile = config.SERVICE_DOCKERFILES[serviceName]
        
        script.sh """
            docker build -f ${dockerfile} \
                -t ${imageName}:${version} \
                -t ${imageName}:latest \
                .
        """
        
        script.echo "✅ Successfully built ${serviceName}"
    }
}

return this
