// Helm Deployment Pipeline
// Handles Helm chart installation and upgrades

def deployWithHelm(script, config, version) {
    script.echo "🚀 Deploying with Helm..."
    
    script.container('kubectl') {
        try {
            // Check if release exists
            def releaseExists = script.sh(
                script: """
                    helm list -n ${config.HELM_NAMESPACE} | grep ${config.HELM_RELEASE_NAME} || true
                """,
                returnStdout: true
            ).trim()
            
            if (releaseExists) {
                script.echo "Upgrading existing Helm release..."
                script.sh """
                    helm upgrade ${config.HELM_RELEASE_NAME} ${config.HELM_CHART_PATH} \
                        --namespace ${config.HELM_NAMESPACE} \
                        --set frontend.image.tag=${version} \
                        --set backend.image.tag=${version} \
                        --set authService.image.tag=${version} \
                        --wait --timeout 10m
                """
            } else {
                script.echo "Installing new Helm release..."
                script.sh """
                    helm install ${config.HELM_RELEASE_NAME} ${config.HELM_CHART_PATH} \
                        --namespace ${config.HELM_NAMESPACE} \
                        --create-namespace \
                        --set frontend.image.tag=${version} \
                        --set backend.image.tag=${version} \
                        --set authService.image.tag=${version} \
                        --wait --timeout 10m
                """
            }
            
            script.echo "✅ Helm deployment successful!"
            
            // Show deployment status
            script.sh """
                echo "=== Deployment Status ==="
                helm status ${config.HELM_RELEASE_NAME} -n ${config.HELM_NAMESPACE}
                
                echo ""
                echo "=== Pods Status ==="
                kubectl get pods -n ${config.HELM_NAMESPACE}
                
                echo ""
                echo "=== Services ==="
                kubectl get svc -n ${config.HELM_NAMESPACE}
                
                echo ""
                echo "=== Ingress ==="
                kubectl get ingress -n ${config.HELM_NAMESPACE}
            """
            
        } catch (Exception e) {
            script.error "❌ Helm deployment failed: ${e.message}"
        }
    }
}

def rollback(script, config) {
    script.echo "⏮️  Rolling back Helm release..."
    
    script.container('kubectl') {
        script.sh """
            helm rollback ${config.HELM_RELEASE_NAME} -n ${config.HELM_NAMESPACE}
        """
    }
}

def uninstall(script, config) {
    script.echo "🗑️  Uninstalling Helm release..."
    
    script.container('kubectl') {
        script.sh """
            helm uninstall ${config.HELM_RELEASE_NAME} -n ${config.HELM_NAMESPACE}
        """
    }
}

return this
