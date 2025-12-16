param(
  [Parameter(Mandatory = $false)]
  [string]$DeviceId = "windows"
)

$ErrorActionPreference = "Stop"

function Get-SafeName([string]$name) {
  return ($name -replace "[^a-zA-Z0-9_-]", "_")
}

$safeDevice = Get-SafeName $DeviceId
$pidFile = Join-Path $PSScriptRoot "..\\.flutter_run_$safeDevice.pid"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if (Test-Path $pidFile) {
  try {
    $pidText = (Get-Content $pidFile -Raw).Trim()
    if ($pidText) {
      $pid = [int]$pidText
      $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
      if ($proc) {
        Stop-Process -Id $pid -Force
      }
    }
  } catch {
    # ignore
  }

  try { Remove-Item $pidFile -Force } catch { }
}

Push-Location $projectRoot
try {
  $args = @(
    "run",
    "-d", $DeviceId,
    "--pid-file", $pidFile
  )

  $p = Start-Process -FilePath "flutter" -ArgumentList $args -NoNewWindow -PassThru
  # На Windows flutter сам создаст pid-file чуть позже; на всякий случай пишем PID процесса flutter tool сразу.
  Set-Content -Path $pidFile -Value $p.Id -Encoding ASCII
  Write-Host ("Started flutter run (device={0}) with PID {1}" -f $DeviceId, $p.Id)
} finally {
  Pop-Location
}


