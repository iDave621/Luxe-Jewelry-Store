// Security Scanning Pipeline
// Handles Snyk security scanning for Docker images

def scanImage(script, config, serviceName, version) {
    script.echo "🔍 Security scanning ${serviceName}..."
    
    def imageName = config.getImageName(serviceName)
    
    // Use credentials from config
    script.withCredentials([
        script.string(credentialsId: config.SNYK_TOKEN, variable: 'SNYK_TOKEN')
    ]) {
        try {
            script.sh """
                docker run --rm \
                    -e SNYK_TOKEN=\${SNYK_TOKEN} \
                    -v /var/run/docker.sock:/var/run/docker.sock \
                    snyk/snyk:docker \
                    snyk test --docker ${imageName}:${version} \
                    --severity-threshold=high \
                    --json > snyk-report-${serviceName}.json || true
            """
            
            script.echo "✅ Security scan completed for ${serviceName}"
        } catch (Exception e) {
            script.echo "⚠️  Security scan failed for ${serviceName}: ${e.message}"
            script.echo "Continuing with build..."
        }
    }
}

def scanAllServices(script, config, services, version) {
    services.each { serviceName ->
        scanImage(script, config, serviceName, version)
    }
}

return this
