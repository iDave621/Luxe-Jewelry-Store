# Create Docker Registry Secret for Private Registry Access
# This script creates a Kubernetes secret to pull images from Docker Hub private registry

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Create Docker Registry Secret" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Docker Hub credentials
$DOCKER_REGISTRY_SERVER = "https://index.docker.io/v1/"
$DOCKER_USERNAME = "iDave621"

Write-Host "Docker Hub Username: $DOCKER_USERNAME" -ForegroundColor Green
Write-Host ""
Write-Host "Please enter your Docker Hub Access Token:" -ForegroundColor Yellow
Write-Host "(Use the same token from your Jenkins 'dockerhub' credential)" -ForegroundColor Cyan
Write-Host ""
$DOCKER_PASSWORD = Read-Host -AsSecureString

# Convert secure string to plain text for kubectl
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($DOCKER_PASSWORD)
$DOCKER_PASSWORD_PLAIN = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host ""
Write-Host "Creating Kubernetes secret..." -ForegroundColor Cyan

# Create namespace if it doesn't exist
kubectl create namespace luxe-jewelry --dry-run=client -o yaml | kubectl apply -f -

# Delete existing secret if it exists
kubectl delete secret dockerhub-secret -n luxe-jewelry 2>$null

# Create the docker registry secret
kubectl create secret docker-registry dockerhub-secret `
    --docker-server=$DOCKER_REGISTRY_SERVER `
    --docker-username=$DOCKER_USERNAME `
    --docker-password=$DOCKER_PASSWORD_PLAIN `
    --docker-email="your-email@example.com" `
    -n luxe-jewelry

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[OK] Docker registry secret created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Secret details:" -ForegroundColor Cyan
    kubectl get secret dockerhub-secret -n luxe-jewelry
    Write-Host ""
    Write-Host "You can now deploy applications that pull from private registry." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[ERROR] Failed to create secret!" -ForegroundColor Red
    exit 1
}

# Clear password from memory
$DOCKER_PASSWORD_PLAIN = $null
[System.GC]::Collect()

Write-Host ""
