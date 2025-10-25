# Script to find the Nexus volume with Docker images

Write-Host "🔍 Searching for Nexus volumes with data..." -ForegroundColor Cyan
Write-Host ""

# Get all volumes
$volumes = docker volume ls -q

Write-Host "Found $($volumes.Count) volumes. Checking each one..." -ForegroundColor Yellow
Write-Host ""

foreach ($vol in $volumes) {
    Write-Host "Checking volume: $vol" -ForegroundColor Gray
    
    # Try to check if volume has nexus data
    $result = docker run --rm -v "${vol}:/data" alpine sh -c "ls -la /data 2>/dev/null | head -20"
    
    if ($result -match "blobs" -or $result -match "db" -or $result -match "nexus" -or $result -match "sonatype-work") {
        Write-Host "✅ FOUND NEXUS DATA in volume: $vol" -ForegroundColor Green
        Write-Host "Contents:" -ForegroundColor Yellow
        Write-Host $result
        Write-Host ""
        Write-Host "=" * 60
        Write-Host ""
    }
}

Write-Host ""
Write-Host "✅ Search complete!" -ForegroundColor Green
