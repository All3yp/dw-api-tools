param(
  [string]$InstallDir = (Join-Path $HOME 'bin'),
  [string]$CommandName = 'dw_api_check',
  [switch]$Uninstall,
  [switch]$SkipPathUpdate
)

$scriptRoot = $PSScriptRoot
$sourceScript = Join-Path $scriptRoot 'dw_api_check.ps1'
$targetScript = Join-Path $InstallDir "$CommandName.ps1"
$targetCmd = Join-Path $InstallDir "$CommandName.cmd"

function Ensure-PathEntry {
  param([string]$PathToAdd)

  $current = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ([string]::IsNullOrWhiteSpace($current)) {
    $current = ''
  }

  $segments = $current -split ';' | Where-Object { $_ -and $_.Trim() }
  if ($segments -notcontains $PathToAdd) {
    $updated = (($segments + $PathToAdd) -join ';').Trim(';')
    [Environment]::SetEnvironmentVariable('Path', $updated, 'User')
  }
}

if ($Uninstall) {
  if (Test-Path $targetCmd) { Remove-Item $targetCmd -Force }
  if (Test-Path $targetScript) { Remove-Item $targetScript -Force }
  Write-Host "Removed $CommandName from $InstallDir"
  return
}

if (-not (Test-Path $sourceScript)) {
  throw "Source script not found: $sourceScript"
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item -Force $sourceScript $targetScript

@"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"%~dp0$CommandName.ps1`" %*
"@ | Set-Content -Path $targetCmd -Encoding Ascii

if (-not $SkipPathUpdate) {
  Ensure-PathEntry -PathToAdd $InstallDir
  $env:Path = "$InstallDir;$env:Path"
}

Write-Host "Installed $CommandName to $InstallDir"
Write-Host "Open a new terminal, then run: $CommandName --help"
Write-Host "Set the API key in PowerShell with: `$env:ANTHROPIC_API_KEY = 'dw_live_...'"
Write-Host "For a persistent user value: [Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY', 'dw_live_...', 'User')"
