# Using ngrok with Jenkins for GitHub Webhooks

This guide explains how to use ngrok to expose your locally running Jenkins server to the internet, allowing GitHub webhooks to trigger your pipeline.

## What is ngrok?

Ngrok is a tool that creates secure tunnels from public URLs to locally running services. It's perfect for exposing your local Jenkins server to GitHub for webhook integration.

## Setup Instructions

### 1. Install ngrok

1. Download ngrok from [https://ngrok.com/download](https://ngrok.com/download)
2. Extract the downloaded file
3. If you want to use your ngrok account (recommended), sign up at [https://dashboard.ngrok.com/signup](https://dashboard.ngrok.com/signup)
4. Connect your account with the auth token:
   ```bash
   ngrok authtoken YOUR_AUTH_TOKEN
   ```

### 2. Start ngrok tunnel to Jenkins

Assuming Jenkins is running on port 8080 (default):

```bash
ngrok http 8080
```

You'll see output similar to:

```
Session Status                online
Account                       your-email@example.com
Version                       2.3.40
Region                        United States (us)
Web Interface                 http://127.0.0.1:4040
Forwarding                    http://a1b2c3d4.ngrok.io -> http://localhost:8080
Forwarding                    https://a1b2c3d4.ngrok.io -> http://localhost:8080
```

The important part is the forwarding URL (e.g., `https://a1b2c3d4.ngrok.io`). This is your public Jenkins URL.

### 3. Configure Jenkins

1. In Jenkins, go to **Manage Jenkins > Configure System**
2. Find the **Jenkins URL** field
3. Update it to your ngrok URL (e.g., `https://a1b2c3d4.ngrok.io`)
4. Save the configuration

### 4. Set up GitHub webhook

1. Go to your GitHub repository > **Settings > Webhooks > Add webhook**
2. Set the Payload URL to your ngrok URL + `/github-webhook/`
   Example: `https://a1b2c3d4.ngrok.io/github-webhook/`
3. Set Content type to `application/json`
4. Select events: Choose "Just the push event" (or customize as needed)
5. Click **Add webhook**

### 5. Test the webhook

1. Make a small commit and push it to your repository
2. In GitHub, go to repository **Settings > Webhooks**, click on your webhook
3. Scroll down to "Recent Deliveries" to see if the webhook was delivered successfully
4. In Jenkins, check if your pipeline job was triggered

## Important Notes

1. **ngrok URL changes**: The free version of ngrok generates a new URL each time you restart it. For persistent URLs, consider upgrading to a paid plan.
2. **Keep ngrok running**: The tunnel only works while ngrok is running.
3. **Firewall/security**: No need to change firewall settings as ngrok creates an outbound connection.
4. **Jenkins CSRF protection**: You may need to disable CSRF protection or add exceptions if you encounter issues.

## Troubleshooting

1. **Webhook isn't triggering**:
   - Check that your ngrok session is active
   - Verify the correct webhook URL in GitHub
   - Look for errors in GitHub webhook delivery history
   - Ensure Jenkins is configured for GitHub webhook trigger

2. **Connection refused**:
   - Verify Jenkins is running and accessible at localhost:8080
   - Check if ngrok shows active connections when webhook is triggered

3. **Authentication issues**:
   - If your Jenkins requires authentication, you may need to configure an API token

## Advanced: Running ngrok as a service

For a more persistent setup, consider running ngrok as a service using tools like PM2 (Node.js), systemd (Linux), or creating a Windows service.

Example systemd service file:
```ini
[Unit]
Description=ngrok
After=network.target

[Service]
ExecStart=/path/to/ngrok http 8080
Restart=always
User=jenkins

[Install]
WantedBy=multi-user.target
```

Save this and enable the service to have ngrok start automatically with your system.
