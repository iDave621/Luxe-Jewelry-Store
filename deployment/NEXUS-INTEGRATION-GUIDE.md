# Nexus Docker Registry Integration Guide

This guide explains how to configure Jenkins to push Docker images to Nexus Repository Manager using both HTTP and HTTPS protocols.

## Current Setup

The Jenkinsfile is configured to support both HTTP and HTTPS for pushing Docker images to Nexus:

```groovy
// Nexus Docker registry information
// Use Nexus API port with HTTPS for general Nexus operations
NEXUS_API = "192.168.1.117:8443"
// Use Docker-specific port for Docker registry operations with HTTPS
// This MUST be configured in Nexus Docker repository settings (HTTPS section)
NEXUS_DOCKER_REGISTRY = "192.168.1.117:8082"
// Use HTTPS for Docker registry operations as Docker insists on HTTPS
NEXUS_USE_HTTPS = true
```

## Configuring Nexus Repository

### For HTTP (Basic Setup)

1. Log into the Nexus Repository Manager UI
2. Go to Settings > Repositories
3. Click on "docker-hosted" repository (or create one if it doesn't exist)
4. Under HTTP section:
   - Check "Enable HTTP"
   - Set port to 8082 (or your preferred port)
5. Save the configuration

### For HTTPS (Advanced Setup)

To use HTTPS with Nexus:

1. Generate SSL certificates for your Nexus server
2. Configure Nexus to use HTTPS (requires modifying Jetty configuration)
3. Configure Docker clients to trust your certificates
4. Update the Jenkins pipeline to use HTTPS URLs

## Docker Client Configuration

### For HTTP

Docker requires explicit configuration to use insecure HTTP registries:

```json
{
  "insecure-registries": ["192.168.1.117:8082"]
}
```

This is automatically set up in the Jenkins pipeline.

### For HTTPS

If using HTTPS with self-signed certificates, Docker needs to trust your certificate:

1. Copy your certificate to `/etc/docker/certs.d/192.168.1.117:8082/ca.crt`
2. Restart Docker

## Troubleshooting

### Common Issues

1. **"http: server gave HTTP response to HTTPS client"**
   - Docker is trying to use HTTPS despite configuration
   - Ensure the insecure registry setting is correct
   - Or properly set up HTTPS with certificates

2. **Authentication failures**
   - Verify credentials in Jenkins are correct
   - Check that the Docker Bearer Token Realm is enabled in Nexus

3. **Connectivity issues**
   - Test Nexus connectivity with curl:
     ```bash
     # For HTTP
     curl -u admin:password http://192.168.1.117:8082/v2/_catalog
     
     # For HTTPS (with self-signed certs)
     curl -k -u admin:password https://192.168.1.117:8082/v2/_catalog
     ```

## Nexus Repository Verification

You can verify the Docker repository in Nexus is properly configured by:

1. Checking the repository listing:
   ```bash
   curl -u username:password http://192.168.1.117:8081/service/rest/v1/repositories | grep docker-hosted
   ```

2. Checking Docker catalog:
   ```bash
   curl -u username:password http://192.168.1.117:8082/v2/_catalog
   ```
