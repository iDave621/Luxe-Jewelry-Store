// Push to Registry Pipeline
// Handles pushing Docker images to Docker Hub and Nexus

def pushToDockerHub(script, config, serviceName, version) {
    script.echo "📤 Pushing ${serviceName} to Docker Hub..."
    
    def imageName = config.getImageName(serviceName)
    def fullImageName = config.getDockerHubImage(serviceName)
    
    script.withCredentials([
        script.usernamePassword(
            credentialsId: config.DOCKER_HUB_CREDENTIALS,
            passwordVariable: 'DOCKER_PASSWORD',
            usernameVariable: 'DOCKER_USERNAME'
        )
    ]) {
        script.sh """
            echo "Logging into Docker Hub..."
            echo \$DOCKER_PASSWORD | docker login -u \$DOCKER_USERNAME --password-stdin
            
            echo "Tagging image..."
            docker tag ${imageName}:${version} ${fullImageName}:${version}
            docker tag ${imageName}:latest ${fullImageName}:latest
            
            echo "Pushing to Docker Hub..."
            docker push ${fullImageName}:${version}
            docker push ${fullImageName}:latest
            
            echo "✅ Successfully pushed ${serviceName} to Docker Hub"
        """
    }
}

def pushToNexus(script, config, serviceName, version) {
    script.echo "📤 Pushing ${serviceName} to Nexus..."
    
    def imageName = config.getImageName(serviceName)
    def nexusImageName = config.getNexusImage(serviceName)
    
    script.withCredentials([
        script.usernamePassword(
            credentialsId: config.NEXUS_CREDENTIALS,
            passwordVariable: 'NEXUS_PASSWORD',
            usernameVariable: 'NEXUS_USERNAME'
        )
    ]) {
        script.sh """
            echo "Logging into Nexus registry..."
            echo \$NEXUS_PASSWORD | docker login ${config.NEXUS_LOGIN_URL} -u \$NEXUS_USERNAME --password-stdin
            
            echo "Tagging image for Nexus..."
            docker tag ${imageName}:${version} ${nexusImageName}:${version}
            docker tag ${imageName}:latest ${nexusImageName}:latest
            
            echo "Pushing to Nexus..."
            docker push ${nexusImageName}:${version}
            docker push ${nexusImageName}:latest
            
            echo "✅ Successfully pushed ${serviceName} to Nexus"
        """
    }
}

def pushAllToDockerHub(script, config, services, version) {
    services.each { serviceName ->
        pushToDockerHub(script, config, serviceName, version)
    }
}

def pushAllToNexus(script, config, services, version) {
    services.each { serviceName ->
        pushToNexus(script, config, serviceName, version)
    }
}

return this
