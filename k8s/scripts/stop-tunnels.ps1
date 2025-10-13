# Stop Port-Forward Tunnels for Luxe Jewelry Store

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Stopping Port-Forward Tunnels" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Get all luxe tunnel jobs
$tunnelJobs = Get-Job | Where-Object { $_.Name -like "luxe-*" }

if ($tunnelJobs) {
    Write-Host "Found " -NoNewline
    Write-Host $tunnelJobs.Count -NoNewline -ForegroundColor Yellow
    Write-Host " tunnel(s) running"
    Write-Host ""
    
    foreach ($job in $tunnelJobs) {
        Write-Host "  Stopping: " -NoNewline
        Write-Host $job.Name -NoNewline -ForegroundColor Cyan
        Stop-Job -Job $job
        Remove-Job -Job $job
        Write-Host " OK" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "All tunnels stopped successfully!" -ForegroundColor Green
} else {
    Write-Host "No tunnels are currently running." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "To start tunnels again, run:" -ForegroundColor Cyan
Write-Host "  .\start-tunnels.ps1" -ForegroundColor White
Write-Host ""
