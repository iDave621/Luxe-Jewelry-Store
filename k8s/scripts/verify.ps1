# Verification Script for Luxe Jewelry Store Kubernetes Deployment

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Deployment Verification" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

function Write-Check {
    param([string]$Message, [bool]$Success)
    if ($Success) {
        Write-Host "[✓] $Message" -ForegroundColor Green
    } else {
        Write-Host "[✗] $Message" -ForegroundColor Red
    }
}

# Check 1: Namespace
Write-Host ">>> Checking Namespace" -ForegroundColor Cyan
$namespace = kubectl get namespace luxe-jewelry 2>$null
if ($namespace) {
    Write-Check "Namespace 'luxe-jewelry' exists" $true
} else {
    Write-Check "Namespace 'luxe-jewelry' exists" $false
}

# Check 2: Pods
Write-Host ""
Write-Host ">>> Checking Pods" -ForegroundColor Cyan
$pods = kubectl get pods -n luxe-jewelry -o json | ConvertFrom-Json
$totalPods = $pods.items.Count
$runningPods = ($pods.items | Where-Object { $_.status.phase -eq "Running" }).Count

Write-Host "Total Pods: $totalPods"
Write-Host "Running Pods: $runningPods"

foreach ($pod in $pods.items) {
    $name = $pod.metadata.name
    $status = $pod.status.phase
    $ready = ($pod.status.containerStatuses | Where-Object { $_.ready -eq $true }).Count
    $total = $pod.status.containerStatuses.Count
    
    $podStatus = $name + ' (' + $ready + '/' + $total + ' ready)'
    if ($status -eq "Running" -and $ready -eq $total) {
        Write-Check $podStatus $true
    } else {
        Write-Check ($podStatus + ' - Status: ' + $status) $false
    }
}

# Check 3: Services
Write-Host ""
Write-Host ">>> Checking Services" -ForegroundColor Cyan
$services = kubectl get svc -n luxe-jewelry -o json | ConvertFrom-Json
foreach ($svc in $services.items) {
    $name = $svc.metadata.name
    $svcType = $svc.spec.type
    $port = $svc.spec.ports[0].port
    Write-Check ($name + ' (' + $svcType + ' Port ' + $port + ')') $true
}

# Check 4: Deployments
Write-Host ""
Write-Host ">>> Checking Deployments" -ForegroundColor Cyan
$deployments = @("auth-service", "backend", "frontend")
foreach ($dep in $deployments) {
    $deployment = kubectl get deployment $dep -n luxe-jewelry -o json 2>$null | ConvertFrom-Json
    if ($deployment) {
        $ready = $deployment.status.readyReplicas
        $desired = $deployment.status.replicas
        
        $depStatus = $dep + ' (' + $ready + '/' + $desired + ' replicas ready)'
        if ($ready -eq $desired) {
            Write-Check $depStatus $true
        } else {
            Write-Check $depStatus $false
        }
    } else {
        Write-Check "$dep exists" $false
    }
}

# Check 5: HPA
Write-Host ""
Write-Host ">>> Checking Horizontal Pod Autoscalers" -ForegroundColor Cyan
$hpaList = kubectl get hpa -n luxe-jewelry --no-headers 2>$null
if ($hpaList) {
    $hpaCount = ($hpaList | Measure-Object).Count
    Write-Check ('HPA configured (' + $hpaCount + ' autoscalers)') $true
    kubectl get hpa -n luxe-jewelry
} else {
    Write-Check "HPA configured" $false
    Write-Host "  HPA is not deployed. Run deploy.ps1 to enable auto-scaling." -ForegroundColor Yellow
}

# Check 6: Metrics Server
Write-Host ""
Write-Host ">>> Checking Metrics Server" -ForegroundColor Cyan
$metricsServer = kubectl get deployment metrics-server -n kube-system 2>$null
if ($metricsServer) {
    Write-Check "Metrics server is enabled" $true
    
    # Check if metrics are available
    Start-Sleep -Seconds 2
    $metrics = kubectl top pods -n luxe-jewelry 2>$null
    if ($metrics) {
        Write-Check "Pod metrics available" $true
        Write-Host ""
        kubectl top pods -n luxe-jewelry
    } else {
        Write-Check "Pod metrics available (may need 1-2 minutes)" $false
    }
} else {
    Write-Check "Metrics server is enabled" $false
    Write-Host "  Run: minikube addons enable metrics-server" -ForegroundColor Yellow
}

# Check 7: Ingress
Write-Host ""
Write-Host ">>> Checking Ingress" -ForegroundColor Cyan
$ingress = kubectl get ingress -n luxe-jewelry 2>$null
if ($ingress) {
    Write-Check "Ingress configured" $true
} else {
    Write-Check "Ingress configured" $false
}

# Check 8: ConfigMap and Secret
Write-Host ""
Write-Host ">>> Checking Configuration" -ForegroundColor Cyan
$configmap = kubectl get configmap luxe-jewelry-config -n luxe-jewelry 2>$null
$secret = kubectl get secret luxe-jewelry-secrets -n luxe-jewelry 2>$null

Write-Check "ConfigMap exists" ($null -ne $configmap)
Write-Check "Secret exists" ($null -ne $secret)

# Summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Access Information" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$minikubeIp = minikube ip 2>$null
if ($minikubeIp) {
    Write-Host ""
    Write-Host "Frontend URL: " -NoNewline
    Write-Host "http://${minikubeIp}:30000" -ForegroundColor Green
    Write-Host ""
    Write-Host "Quick Access Command:" -ForegroundColor Yellow
    Write-Host "  minikube service frontend -n luxe-jewelry" -ForegroundColor White
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Useful Commands" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "View all resources:    kubectl get all,hpa -n luxe-jewelry"
Write-Host "View logs (backend):   kubectl logs -n luxe-jewelry -l app=backend -f"
Write-Host 'View pod details:      kubectl describe pod -n luxe-jewelry POD-NAME'
Write-Host "Check HPA:             kubectl get hpa -n luxe-jewelry"
Write-Host 'Resource usage:        kubectl top pods -n luxe-jewelry'
Write-Host ""
