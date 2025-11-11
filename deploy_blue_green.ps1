param([string]$Image)

$AppName = "my-node-app"
$BluePort = 4000
$GreenPort = 5000
$ActiveFile = "E:\bluegreen-scripts\active_color.txt"
$NginxConf = "C:\nginx\conf\app_upstream.conf"

function Get-ActiveColor {
  if (Test-Path $ActiveFile) { Get-Content $ActiveFile } else { "none" }
}

function Start-Container($Color, $Port) {
  $Name = "$AppName-$Color"
  docker rm -f $Name -ErrorAction SilentlyContinue
  docker run -d --name $Name -p ${Port}:3000 $Image | Out-Null
}

function Health-Check($Port) {
  for ($i = 0; $i -lt 20; $i++) {
    try {
      $r = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/health" -UseBasicParsing -TimeoutSec 2
      if ($r.StatusCode -eq 200) { return $true }
    } catch { Start-Sleep -Seconds 1 }
  }
  return $false
}

function Update-Nginx($Port) {
  (Get-Content $NginxConf) -replace 'server 127\.0\.0\.1:\d+;', "server 127.0.0.1:$Port;" | Set-Content $NginxConf
  taskkill /IM nginx.exe /F
  Start-Process "C:\nginx\nginx.exe"
  if ($Port -eq $BluePort) { "blue" | Set-Content $ActiveFile } else { "green" | Set-Content $ActiveFile }
}

$Current = Get-ActiveColor
if ($Current -eq "blue") { $Target="green"; $Port=$GreenPort }
elseif ($Current -eq "green") { $Target="blue"; $Port=$BluePort }
else { $Target="blue"; $Port=$BluePort }

Write-Host "Deploying $Target on port $Port..."
docker pull $Image
Start-Container $Target $Port

if (-not (Health-Check $Port)) {
  Write-Host "❌ Health check failed!"
  exit 1
}

Update-Nginx $Port

if ($Current -ne "none") {
  docker rm -f "$AppName-$Current" -ErrorAction SilentlyContinue
}

Write-Host "✅ Deployment complete. Active: $Target"
