# Luxe Jewelry Store - Ingress Tunnel Script
# Run this once and keep it running in the background

Write-Host "Starting Minikube Ingress Tunnel..." -ForegroundColor Cyan
Write-Host "Keep this window open for the URL to work!" -ForegroundColor Yellow
Write-Host ""

# Update hosts file to use 127.0.0.1
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$content = Get-Content $hostsPath
$filtered = $content | Where-Object {$_ -notmatch "luxe-jewelry.local"}
$filtered += "`n127.0.0.1`tluxe-jewelry.local"
$filtered | Set-Content $hostsPath -Force

Write-Host "✅ Hosts file updated" -ForegroundColor Green

# Start the tunnel
Write-Host ""
Write-Host "🌐 Access your app at: http://luxe-jewelry.local:XXXX" -ForegroundColor Green
Write-Host "   (The port number will appear below)" -ForegroundColor Gray
Write-Host ""

minikube service ingress-nginx-controller -n ingress-nginx
