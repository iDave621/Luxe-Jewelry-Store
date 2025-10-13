# Start Port-Forward Tunnels for Luxe Jewelry Store
# This script starts all 3 required port-forwards in separate background jobs

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Starting Port-Forward Tunnels" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if already running
$existingJobs = Get-Job | Where-Object { $_.Name -like "luxe-*" }
if ($existingJobs) {
    Write-Host "Existing tunnels found. Stopping them first..." -ForegroundColor Yellow
    $existingJobs | Stop-Job
    $existingJobs | Remove-Job
}

Write-Host "Starting tunnels..." -ForegroundColor Cyan

# Start Frontend tunnel
Write-Host "  [1/3] Frontend (localhost:3000)..." -NoNewline
Start-Job -Name "luxe-frontend" -ScriptBlock {
    kubectl port-forward -n luxe-jewelry svc/frontend 3000:80
} | Out-Null
Start-Sleep -Seconds 1
Write-Host " OK" -ForegroundColor Green

# Start Backend tunnel
Write-Host "  [2/3] Backend (localhost:8000)..." -NoNewline
Start-Job -Name "luxe-backend" -ScriptBlock {
    kubectl port-forward -n luxe-jewelry svc/backend 8000:8000
} | Out-Null
Start-Sleep -Seconds 1
Write-Host " OK" -ForegroundColor Green

# Start Auth tunnel
Write-Host "  [3/3] Auth Service (localhost:8001)..." -NoNewline
Start-Job -Name "luxe-auth" -ScriptBlock {
    kubectl port-forward -n luxe-jewelry svc/auth-service 8001:8001
} | Out-Null
Start-Sleep -Seconds 1
Write-Host " OK" -ForegroundColor Green

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Tunnels Running Successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access your application at:" -ForegroundColor Cyan
Write-Host "  http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "To stop tunnels, run:" -ForegroundColor Yellow
Write-Host "  .\stop-tunnels.ps1" -ForegroundColor White
Write-Host ""
Write-Host "To check tunnel status:" -ForegroundColor Yellow
Write-Host "  Get-Job | Where-Object { `$_.Name -like 'luxe-*' }" -ForegroundColor White
Write-Host ""
Write-Host "Tunnels will keep running in the background." -ForegroundColor Cyan
Write-Host "DO NOT close this PowerShell window!" -ForegroundColor Red
Write-Host ""
