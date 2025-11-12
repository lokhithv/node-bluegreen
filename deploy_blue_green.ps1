param([string]$IMAGE)

# App name and ports
$AppName = "bluegreenapp"
$BluePort = 4000
$GreenPort = 5000

# Track current active deployment
$ActiveFile = "E:\node-bluegreen\active_color.txt"

# NGINX paths
$NginxConf = "C:\nginx-1.28.0\nginx-1.28.0\conf\app_upstream.conf"
$NginxExe = "C:\nginx-1.28.0\nginx-1.28.0\nginx.exe"

function Get-ActiveColor {
    if (Test-Path $ActiveFile) { Get-Content $ActiveFile } else { "none" }
}

function Start-Container($Color, $Port) {
    $Name = "$AppName-$Color"
    Write-Host "→ Starting container: $Name on port $Port"
    docker stop $Name *> $null
    docker rm -f $Name *> $null
    docker run -d --name $Name -p ${Port}:3000 -e ENV_COLOR=$Color $IMAGE | Out-Null
}

function Health-Check($Port) {
    Write-Host "→ Running health check on port $Port..."
    for ($i = 0; $i -lt 20; $i++) {
        try {
            $r = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/health" -UseBasicParsing -TimeoutSec 2
            if ($r.StatusCode -eq 200) { return $true }
        } catch { Start-Sleep -Seconds 1 }
    }
    return $false
}

function Update-Nginx($Port, $Color) {
    Write-Host "→ Updating NGINX to route traffic to $Color ($Port)..."

@"
upstream app_upstream {
    server 127.0.0.1:$Port;
}

server {
    listen 80;
    location / {
        proxy_pass http://app_upstream;
    }
}
"@ | Set-Content $NginxConf

    taskkill /IM nginx.exe /F *> $null
    Start-Process $NginxExe
    $Color | Set-Content $ActiveFile
}

# Main Deployment Logic
$Current = Get-ActiveColor
if ($Current -eq "blue") { $Target="green"; $Port=$GreenPort }
elseif ($Current -eq "green") { $Target="blue"; $Port=$BluePort }
else { $Target="blue"; $Port=$BluePort }

Write-Host "`n==============================="
Write-Host "  BLUE-GREEN DEPLOYMENT START   "
Write-Host "===============================`n"
Write-Host "Current Active: $Current"
Write-Host "Deploying to:   $Target on port $Port"
Write-Host ""

docker pull $IMAGE

Start-Container $Target $Port

if (-not (Health-Check $Port)) {
    Write-Host "❌ Health check FAILED! Rolling back..."
    docker rm -f "$AppName-$Target" *> $null
    exit 1
}

Update-Nginx $Port $Target

if ($Current -ne "none") {
    Write-Host "→ Stopping old container: $AppName-$Current"
    docker rm -f "$AppName-$Current" *> $null
}

Write-Host "`n✅ Deployment COMPLETE. Now ACTIVE: $Target"
