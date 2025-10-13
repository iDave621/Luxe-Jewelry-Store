# PowerShell Deployment script for Luxe Jewelry Store - Complete Kubernetes Deployment Script
# This script handles everything: prerequisites, deployment, health checks, and verification

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Luxe Jewelry Store - Kubernetes Deployment" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

function Write-Info {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host ">>> $Message" -ForegroundColor Cyan
}

# ============================================
# STEP 1: Check Prerequisites
# ============================================
Write-Step "Step 1: Checking Prerequisites"

# Check kubectl
try {
    $null = kubectl version --client 2>$null
    Write-Info "kubectl is installed"
} catch {
    Write-ErrorMessage "kubectl is not installed"
    Write-Host "Install: choco install kubernetes-cli"
    exit 1
}

# Check Minikube
try {
    $null = minikube version 2>$null
    Write-Info "Minikube is installed"
} catch {
    Write-ErrorMessage "Minikube is not installed"
    Write-Host "Install: choco install minikube"
    exit 1
}

# ============================================
# STEP 2: Start/Verify Kubernetes Cluster
# ============================================
Write-Step "Step 2: Verifying Kubernetes Cluster"

try {
    $null = kubectl cluster-info 2>$null
    Write-Info "Kubernetes cluster is running"
} catch {
    Write-Warning "Kubernetes cluster is not running"
    Write-Host "Starting Minikube..."
    minikube start --driver=docker
    Start-Sleep -Seconds 5
    Write-Info "Minikube started successfully"
}

# ============================================
# STEP 3: Enable Metrics Server (for HPA)
# ============================================
Write-Step "Step 3: Enabling Metrics Server"

$metricsEnabled = minikube addons list | Select-String "metrics-server.*enabled"
if ($metricsEnabled) {
    Write-Info "Metrics server is already enabled"
} else {
    Write-Host "Enabling metrics server..."
    minikube addons enable metrics-server
    Write-Info "Metrics server enabled"
}

# ============================================
# STEP 4: Deploy Application
# ============================================
Write-Step "Step 4: Deploying Application"

Write-Host "Creating namespace..."
kubectl apply -f ..\base\namespace.yaml | Out-Null
Write-Info "Namespace created"

Write-Host "Checking Docker registry secret..."
$dockerSecret = kubectl get secret dockerhub-secret -n luxe-jewelry 2>$null
if ($null -eq $dockerSecret) {
    Write-Host ""
    Write-Warning "Docker registry secret not found!"
    Write-Host "This secret is required to pull images from private Docker Hub registry." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Run the following command to create it:" -ForegroundColor Cyan
    Write-Host "  .\create-docker-secret.ps1" -ForegroundColor White
    Write-Host ""
    $createNow = Read-Host "Create the secret now? (y/n)"
    if ($createNow -eq 'y' -or $createNow -eq 'Y') {
        & "$PSScriptRoot\create-docker-secret.ps1"
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMessage "Failed to create Docker secret. Exiting..."
            exit 1
        }
    } else {
        Write-ErrorMessage "Docker secret is required. Please create it and re-run deployment."
        exit 1
    }
} else {
    Write-Info "Docker registry secret found"
}

Write-Host "Applying configuration..."
kubectl apply -f ..\base\configmap.yaml | Out-Null
kubectl apply -f ..\base\secret.yaml | Out-Null
Write-Info "Configuration applied"

Write-Host "Deploying Auth Service (includes HPA)..."
kubectl apply -f ..\deployments\auth-service-deployment.yaml | Out-Null
Write-Info "Auth Service deployed"

Write-Host "Deploying Backend (includes HPA)..."
kubectl apply -f ..\deployments\backend-deployment.yaml | Out-Null
Write-Info "Backend deployed"

Write-Host "Deploying Frontend (includes HPA)..."
kubectl apply -f ..\deployments\frontend-deployment.yaml | Out-Null
Write-Info "Frontend deployed"

Write-Host "Creating Ingress..."
kubectl apply -f ..\base\ingress.yaml | Out-Null
Write-Info "Ingress created"

# ============================================
# STEP 5: Wait for Deployments to be Ready
# ============================================
Write-Step "Step 5: Waiting for Deployments to be Ready"

Write-Host "Waiting for Auth Service..." -NoNewline
try {
    kubectl rollout status deployment/auth-service -n luxe-jewelry --timeout=180s 2>&1 | Out-Null
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-ErrorMessage "Auth Service failed to start"
}

Write-Host "Waiting for Backend..." -NoNewline
try {
    kubectl rollout status deployment/backend -n luxe-jewelry --timeout=180s 2>&1 | Out-Null
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-ErrorMessage "Backend failed to start"
}

Write-Host "Waiting for Frontend..." -NoNewline
try {
    kubectl rollout status deployment/frontend -n luxe-jewelry --timeout=180s 2>&1 | Out-Null
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-ErrorMessage "Frontend failed to start"
}

# ============================================
# STEP 6: Verify All Components
# ============================================
Write-Step "Step 6: Verifying All Components"

# Check pods
$pods = kubectl get pods -n luxe-jewelry -o json | ConvertFrom-Json
$totalPods = $pods.items.Count
$runningPods = ($pods.items | Where-Object { $_.status.phase -eq "Running" }).Count

Write-Host "Pods: $runningPods/$totalPods running" -ForegroundColor $(if ($runningPods -eq $totalPods) { "Green" } else { "Yellow" })

# Check each deployment
$deployments = @("auth-service", "backend", "frontend")
foreach ($dep in $deployments) {
    $deployment = kubectl get deployment $dep -n luxe-jewelry -o json | ConvertFrom-Json
    $ready = $deployment.status.readyReplicas
    $desired = $deployment.status.replicas
    
    if ($ready -eq $desired) {
        Write-Info "$dep`: $ready/$desired replicas ready"
    } else {
        Write-Warning "$dep`: $ready/$desired replicas ready"
    }
}

# Check HPA
Write-Host ""
Write-Host "Checking Horizontal Pod Autoscalers..."
Start-Sleep -Seconds 3
$hpaList = kubectl get hpa -n luxe-jewelry --no-headers 2>$null
if ($hpaList) {
    Write-Info "HPA configured for all services"
} else {
    Write-Warning "HPA metrics not available yet (wait 1-2 minutes)"
}

# Check services
$services = kubectl get svc -n luxe-jewelry -o json | ConvertFrom-Json
Write-Info "Services: $($services.items.Count) services created"

# ============================================
# STEP 7: Health Checks
# ============================================
Write-Step "Step 7: Running Health Checks"

# Check if all pods are healthy
$unhealthyPods = kubectl get pods -n luxe-jewelry --no-headers | Select-String -Pattern "0/1|Error|CrashLoop|ImagePull"
if ($unhealthyPods) {
    Write-Warning "Some pods are not healthy:"
    $unhealthyPods | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
} else {
    Write-Info "All pods are healthy"
}

# ============================================
# STEP 8: Display Status & Access Info
# ============================================
Write-Step "Step 8: Deployment Summary"

Write-Host ""
Write-Host "=== Deployment Status ===" -ForegroundColor Cyan
kubectl get pods,svc,hpa -n luxe-jewelry

Write-Host ""
Write-Host "=== Access Information ===" -ForegroundColor Cyan
Write-Host "Windows Docker Driver requires port-forwarding" -ForegroundColor Yellow
Write-Host ""
Write-Host "Open 3 separate PowerShell terminals and run:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Terminal 1 (Frontend):" -ForegroundColor White
Write-Host "  kubectl port-forward -n luxe-jewelry svc/frontend 3000:80" -ForegroundColor Green
Write-Host ""
Write-Host "Terminal 2 (Backend):" -ForegroundColor White
Write-Host "  kubectl port-forward -n luxe-jewelry svc/backend 8000:8000" -ForegroundColor Green
Write-Host ""
Write-Host "Terminal 3 (Auth):" -ForegroundColor White
Write-Host "  kubectl port-forward -n luxe-jewelry svc/auth-service 8001:8001" -ForegroundColor Green
Write-Host ""
Write-Host "Then access: " -NoNewline
Write-Host "http://localhost:3000" -ForegroundColor Green

Write-Host ""
Write-Host "=== Useful Commands ===" -ForegroundColor Cyan
Write-Host "View logs:        kubectl logs -n luxe-jewelry -l app=backend -f"
Write-Host "Check HPA:        kubectl get hpa -n luxe-jewelry"
Write-Host "Check pods:       kubectl get pods -n luxe-jewelry"
Write-Host "Cleanup:          .\cleanup.ps1"

# ============================================
# STEP 9: Final Verification
# ============================================
Write-Host ""
$allHealthy = $true

# Final pod check
$podStatus = kubectl get pods -n luxe-jewelry -o json | ConvertFrom-Json
foreach ($pod in $podStatus.items) {
    $phase = $pod.status.phase
    $ready = ($pod.status.containerStatuses | Where-Object { $_.ready -eq $true }).Count
    $total = $pod.status.containerStatuses.Count
    
    if ($phase -ne "Running" -or $ready -ne $total) {
        $allHealthy = $false
    }
}

Write-Host ""
Write-Host ""
if ($allHealthy) {
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "  All services are running and healthy" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
} else {
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host "  DEPLOYMENT COMPLETED WITH WARNINGS" -ForegroundColor Yellow
    Write-Host "  Some pods may still be starting up" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Starting Port-Forward Tunnels" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
& "$PSScriptRoot\start-tunnels.ps1"
