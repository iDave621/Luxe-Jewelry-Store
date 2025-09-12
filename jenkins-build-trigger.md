# Jenkins Build Trigger

This file was created to trigger a Jenkins build via SCM polling.

## Build Information
- Date: 2025-09-12
- Purpose: Testing pipeline execution with SCM polling
- Build Features:
  - Docker image building
  - Unit testing
  - Deployment

## Pipeline Stages
The Jenkinsfile defines the following stages:
1. Checkout code
2. Build services (auth-service, backend, frontend)
3. Run tests
4. Push images to Docker Hub
5. Deploy to development environment

## SCM Polling Configuration
- The Jenkins Multibranch Pipeline is configured to poll the repository periodically
- When new commits are detected, the pipeline is triggered automatically
- No webhooks or external services are needed for this configuration
