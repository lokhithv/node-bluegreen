param([string]$IMAGE)

# App name and ports
$AppName = "bluegreenapp"
$BluePort = 4000
$GreenPort = 5000

# Track current active deployment
$ActiveFile = "E:\bluegreen-scripts\active_color.txt"

# NGINX upstream config path
$NginxConf = "C:\nginx-1.28.0\nginx-1.28.0\conf\app_upstream.conf"

function Get-ActiveColor {
    if (Test-Path $ActiveFile) { Get-Content $ActiveFile } else { "none" }
}

function Start-Container($Color, $Port) {
    $Name = "$AppName-$Color"
    Write-Host "→ Starting container: $Name on port $Port"
    docker rm -f $Name -ErrorAction SilentlyContinue
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
    Write-Host "→ Pointing NGINX to $Color ($Port)"
    Set-Content $NginxConf "upstream app_upstream { server 127.0.0.1:$Port; }"

    # Reload nginx (do NOT kill it)
    & "C:\nginx-1.28.0\nginx-1.28.0\nginx.exe" -s reload

    # Save active color
    $Color | Set-Content $ActiveFile
}

# Determine which color to deploy to
$Current = Get-ActiveColor
if ($Current -eq "blue") { $Target="green"; $Port=$GreenPort }
elseif ($Current -eq "green") { $Target="blue"; $Port=$BluePort }
else { $Target="blue"; $Port=$BluePort }

Write-Host "`n==============================="
Write-Host "  BLUE-GREEN DEPLOYMENT START   "
Write-Host "===============================`n"
Write-Host "Current Active: $Current"
Write-Host "Deploying to:   $Target on $Port"
Write-Host ""

docker pull $IMAGE

Start-Container $Target $Port

if (-not (Health-Check $Port)) {
    Write-Host "❌ Health check failed! Rolling back..."
    docker rm -f "$AppName-$Target" -ErrorAction SilentlyContinue
    exit 1
}

Update-Nginx $Port $Target

if ($Current -ne "none") {
    Write-Host "→ Stopping old $Current container..."
    docker rm -f "$AppName-$Current" -ErrorAction SilentlyContinue
}

Write-Host "`n✅ Deployment complete. Active environment is now: $Target"
