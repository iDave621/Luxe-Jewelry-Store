# Step-by-Step Guide: Connecting GitHub to Local Jenkins using ngrok

This guide provides practical steps to run ngrok and connect your GitHub repository to your local Jenkins server using webhooks.

## Prerequisites
- Jenkins installed and running locally (typically on port 8080)
- Admin access to your GitHub repository
- ngrok installed on your computer

## Step 1: Run Jenkins Locally

1. Start your Jenkins server if it's not already running
   - On Windows: Start the Jenkins Windows service or run from command line
   - Access Jenkins at http://localhost:8080

## Step 2: Run ngrok on Your Computer

1. Open a command prompt or terminal window
2. Navigate to the folder where you extracted ngrok
3. Run the following command:
   ```
   ngrok http 8080
   ```
4. Keep this terminal window open as long as you need the tunnel active
5. Note the forwarding URL displayed (e.g., `https://a1b2c3d4.ngrok.io`)

## Step 3: Update Jenkins Configuration

1. In your browser, go to your Jenkins dashboard
2. Navigate to **Manage Jenkins** > **Configure System**
3. Find the **Jenkins URL** setting
4. Change it to your ngrok URL (e.g., `https://a1b2c3d4.ngrok.io`)
5. Click **Save**

## Step 4: Create Your Jenkins Pipeline

1. From the Jenkins dashboard, click **New Item**
2. Enter "Luxe-Jewelry-Store-Pipeline" as the name
3. Select **Pipeline** and click **OK**
4. Under **General**, check "GitHub project" and enter your repo URL:
   - `https://github.com/ronbhadad22/Luxe-Jewelry-Store.git`
5. Under **Build Triggers**, check "GitHub hook trigger for GITScm polling"
6. Under **Pipeline**:
   - Choose "Pipeline script from SCM"
   - Select "Git" as SCM
   - Repository URL: `https://github.com/ronbhadad22/Luxe-Jewelry-Store.git`
   - Credentials: Add your GitHub credentials if it's a private repo
   - Branch Specifier: `*/main` (or your default branch)
   - Script Path: `Jenkinsfile`
7. Click **Save**

## Step 5: Configure GitHub Webhook

1. Go to your GitHub repository:
   - `https://github.com/ronbhadad22/Luxe-Jewelry-Store`
2. Click **Settings** tab (you need admin access)
3. Click **Webhooks** in the left sidebar
4. Click **Add webhook** button
5. Configure the webhook:
   - Payload URL: `https://a1b2c3d4.ngrok.io/github-webhook/` (use your actual ngrok URL)
   - Content type: Select `application/json`
   - Secret: Leave blank (or set up a secret if desired)
   - Which events?: Choose "Just the push event"
   - Active: Check this box
6. Click **Add webhook**

## Step 6: Test the Integration

1. Make a small change to your repository
2. Commit and push to GitHub
3. Go to your Jenkins dashboard
4. Check if your pipeline job starts automatically
5. Review the build logs to see the progress

## Important Notes

- The free version of ngrok will generate a new URL each time you restart it
- Keep the terminal running ngrok open as long as you need the webhook connection
- If ngrok restarts or your URL changes, you must update both:
  - Jenkins URL in system configuration
  - Webhook URL in GitHub repository settings

## Troubleshooting

- If webhooks aren't triggering:
  1. Check GitHub webhook delivery history for errors
  2. Verify your ngrok tunnel is active
  3. Ensure the webhook URL ends with `/github-webhook/`
  4. Check Jenkins logs for incoming webhook requests
