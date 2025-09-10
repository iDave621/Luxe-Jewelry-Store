# Jenkins Pipeline Setup for Luxe Jewelry Store

This document provides instructions for setting up a Jenkins pipeline for the Luxe Jewelry Store application.

## Required Jenkins Plugins

Ensure these plugins are installed in your Jenkins instance:

1. **Docker Pipeline** - For Docker integration in your pipeline
2. **Pipeline** - For defining pipelines as code
3. **Git** - For SCM integration
4. **Credentials** - For secure credential management
5. **Blue Ocean** - For improved pipeline visualization (optional)

## Setup Instructions

### 1. Create Docker Hub Credentials in Jenkins

1. Navigate to **Dashboard > Manage Jenkins > Credentials > System > Global credentials > Add Credentials**
2. Select **Username with password** as the kind
3. Enter your Docker Hub username and password
4. Set the ID as `docker-hub-credentials`
5. Add a description like "Docker Hub Access"
6. Click **OK** to save

### 2. Create a New Pipeline Job

1. From the Jenkins dashboard, click **New Item**
2. Enter `Luxe-Jewelry-Store-Pipeline` as the item name
3. Select **Pipeline** as the job type
4. Click **OK**

### 3. Configure the Pipeline

In the configuration page:

1. Under the **General** section:
   - Add a description: "CI/CD pipeline for the Luxe Jewelry Store application"
   - Check "GitHub project" and enter your repository URL

2. Under the **Build Triggers** section:
   - Check "GitHub hook trigger for GITScm polling" to enable automatic builds on code changes
   
3. Under the **Pipeline** section:
   - Select "Pipeline script from SCM" as the Definition
   - Choose "Git" as the SCM
   - Enter your repository URL in the "Repository URL" field
   - Specify credentials if your repository is private
   - Set "Branches to build" to `*/main` or your main branch
   - Set "Script Path" to `Jenkinsfile`

4. Click **Save** to create the pipeline

### 4. Test the Pipeline

1. Go to your new pipeline job
2. Click **Build Now** to manually trigger the first build
3. Monitor the build progress in the **Stage View** or using Blue Ocean

### 5. Setting Up Webhooks (Optional)

To trigger builds automatically when code is pushed:

1. Go to your GitHub repository
2. Click **Settings > Webhooks > Add webhook**
3. Set Payload URL to `http://<jenkins-url>/github-webhook/`
4. Choose "application/json" as the content type
5. Select "Just the push event" for simplicity
6. Click **Add webhook** to save

## Troubleshooting

- **Docker Issues**: Ensure the Jenkins user has Docker permissions
- **Credential Errors**: Verify your Docker Hub credentials are correctly configured
- **SCM Issues**: Check Jenkins has proper access to your Git repository

## Next Steps

- Configure notification settings (email, Slack, etc.)
- Set up branch-specific deployment rules
- Implement more sophisticated testing
- Add security scanning stages

For more information, refer to the [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/).
