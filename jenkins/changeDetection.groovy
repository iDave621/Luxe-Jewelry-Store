// Change Detection Utilities
// Detects which services have changed since last build

class ChangeDetection {
    
    def script
    
    ChangeDetection(script) {
        this.script = script
    }
    
    /**
     * Detect which services have changed
     * @return Map with service names as keys and boolean values
     */
    Map<String, Boolean> detectChanges() {
        def changes = [
            'auth-service': false,
            'backend': false,
            'frontend': false,
            'helm': false,
            'all': false
        ]
        
        try {
            // Get changed files since last successful build
            def changedFiles = script.sh(
                script: '''
                    if [ -z "$(git rev-parse --verify HEAD~1 2>/dev/null)" ]; then
                        # First build or no previous commit
                        echo "ALL_CHANGED"
                    else
                        git diff --name-only HEAD~1 HEAD || echo "ALL_CHANGED"
                    fi
                ''',
                returnStdout: true
            ).trim()
            
            script.echo "Changed files:\n${changedFiles}"
            
            // If it's the first build or git command failed, build everything
            if (changedFiles.contains('ALL_CHANGED') || changedFiles.isEmpty()) {
                script.echo "Building all services (first build or no changes detected)"
                changes.each { k, v -> changes[k] = true }
                return changes
            }
            
            def fileList = changedFiles.split('\n')
            
            // Check each service
            changes['auth-service'] = fileList.any { it.startsWith('auth-service/') }
            changes['backend'] = fileList.any { it.startsWith('backend/') }
            changes['frontend'] = fileList.any { it.startsWith('jewelry-store/') }
            changes['helm'] = fileList.any { 
                it.startsWith('luxe-jewelry-chart/') || 
                it == 'Jenkinsfile' || 
                it.startsWith('jenkins/')
            }
            
            // Check if Jenkinsfile or config changed (rebuild all if so)
            if (fileList.any { it == 'Jenkinsfile' || it.startsWith('jenkins/config') }) {
                script.echo "Jenkinsfile or config changed - rebuilding all services"
                changes.each { k, v -> changes[k] = true }
            }
            
            // If any service changed, mark all as true for this implementation
            // (you can make this smarter later to only build changed services)
            if (changes['auth-service'] || changes['backend'] || changes['frontend']) {
                changes['all'] = true
            }
            
        } catch (Exception e) {
            script.echo "Error detecting changes: ${e.message}"
            script.echo "Building all services as fallback"
            changes.each { k, v -> changes[k] = true }
        }
        
        return changes
    }
    
    /**
     * Check if a specific service has changed
     */
    boolean hasServiceChanged(String serviceName, Map changes) {
        return changes[serviceName] ?: false
    }
    
    /**
     * Get list of changed services
     */
    List<String> getChangedServices(Map changes) {
        return changes.findAll { k, v -> 
            v && k != 'all' && k != 'helm' 
        }.collect { k, v -> k }
    }
    
    /**
     * Print change summary
     */
    void printChangeSummary(Map changes) {
        script.echo "=== Change Detection Summary ==="
        changes.each { service, changed ->
            def status = changed ? "✅ CHANGED" : "⏭️  SKIPPED"
            script.echo "${service.padRight(15)}: ${status}"
        }
        script.echo "================================"
    }
}

return ChangeDetection
