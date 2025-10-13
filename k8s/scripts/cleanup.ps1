# PowerShell Cleanup script for Luxe Jewelry Store Kubernetes deployment

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Luxe Jewelry Store - Kubernetes Cleanup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Stop port-forward tunnels first
Write-Host "Stopping port-forward tunnels..." -ForegroundColor Cyan
& "$PSScriptRoot\stop-tunnels.ps1"
Write-Host ""

# Check if kubectl is installed
try {
    $null = kubectl version --client 2>$null
} catch {
    Write-ErrorMessage "kubectl is not installed."
    exit 1
}

# Check if namespace exists
try {
    $namespace = kubectl get namespace luxe-jewelry 2>$null
    if ($null -eq $namespace) {
        Write-Warning "Namespace 'luxe-jewelry' does not exist. Nothing to clean up."
        exit 0
    }
} catch {
    Write-Warning "Namespace 'luxe-jewelry' does not exist. Nothing to clean up."
    exit 0
}

# Confirm deletion
Write-Host ""
Write-Warning "This will delete all resources in the 'luxe-jewelry' namespace."
$confirm = Read-Host "Are you sure you want to continue? (yes/no)"

if ($confirm -ne 'yes') {
    Write-Info "Cleanup cancelled."
    exit 0
}

# Display current resources
Write-Info "Current resources in luxe-jewelry namespace:"
kubectl get all -n luxe-jewelry

Write-Host ""
Write-Info "Deleting namespace and all resources..."

# Delete namespace (this will delete all resources in it)
kubectl delete namespace luxe-jewelry

Write-Info "Cleanup completed successfully!"
Write-Host ""
Write-Info "All resources in the 'luxe-jewelry' namespace have been deleted."
