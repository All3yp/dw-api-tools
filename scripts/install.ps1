[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [string]$InstallDir = (Join-Path $HOME 'bin'),
  [string]$CommandName = 'dw',
  [switch]$Uninstall,
  [switch]$SkipPathUpdate,
  [switch]$SkipProfileUpdate
)

$ErrorActionPreference = 'Stop'

# scripts/ resides one level below the repo root.
$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceScript = Join-Path $repoRoot 'src\dw_api_check.ps1'
$sourceModule = Join-Path $repoRoot 'src\DwApiCheck.psm1'
$targetScript = Join-Path $InstallDir "$CommandName.ps1"
$targetModule = Join-Path $InstallDir 'DwApiCheck.psm1'
$targetCmd = Join-Path $InstallDir "$CommandName.cmd"
$profileMarkerBegin = '#region dw-api-tools'
$profileMarkerEnd = '#endregion dw-api-tools'

function Get-PowerShellLauncher {
  if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    return 'pwsh.exe'
  }
  return 'powershell.exe'
}

function Add-UserPathEntry {
  param([string]$PathToAdd)

  $current = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ([string]::IsNullOrWhiteSpace($current)) {
    $current = ''
  }

  $segments = @(
    $current -split ';' |
      ForEach-Object { $_.Trim() } |
      Where-Object { $_ }
  )

  $alreadyPresent = $segments | Where-Object {
    $_.Equals($PathToAdd, [System.StringComparison]::OrdinalIgnoreCase)
  }

  if (-not $alreadyPresent) {
    $updated = (($segments + $PathToAdd) -join ';').Trim(';')
    [Environment]::SetEnvironmentVariable('Path', $updated, 'User')
  }

  $sessionSegments = @(
    $env:Path -split ';' |
      ForEach-Object { $_.Trim() } |
      Where-Object { $_ }
  )
  $inSession = $sessionSegments | Where-Object {
    $_.Equals($PathToAdd, [System.StringComparison]::OrdinalIgnoreCase)
  }
  if (-not $inSession) {
    $env:Path = "$PathToAdd;$env:Path"
  }
}

function Get-ProfilePath {
  $targets = @()

  if ($PROFILE.CurrentUserAllHosts) {
    $targets += $PROFILE.CurrentUserAllHosts
  }
  if ($PROFILE.CurrentUserCurrentHost -and ($PROFILE.CurrentUserCurrentHost -ne $PROFILE.CurrentUserAllHosts)) {
    $targets += $PROFILE.CurrentUserCurrentHost
  }

  $extra = @(
    (Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $HOME 'Documents\PowerShell\profile.ps1'),
    (Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $HOME 'Documents\WindowsPowerShell\profile.ps1')
  )

  foreach ($path in $extra) {
    if ($targets -notcontains $path) {
      $targets += $path
    }
  }

  return $targets | Select-Object -Unique
}

function Clear-ProfileCommand {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param([string[]]$ProfilePath)

  foreach ($path in $ProfilePath) {
    if (-not (Test-Path -LiteralPath $path)) { continue }

    $content = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($content)) { continue }
    if ($content -notlike "*$profileMarkerBegin*") { continue }

    if (-not $PSCmdlet.ShouldProcess($path, 'Remove dw-api-tools profile block')) {
      continue
    }

    $pattern = '(?s)\r?\n?' + [regex]::Escape($profileMarkerBegin) + '.*?' + [regex]::Escape($profileMarkerEnd) + '\r?\n?'
    $updated = [regex]::Replace($content, $pattern, '')
    Set-Content -LiteralPath $path -Value $updated -Encoding utf8
  }
}

function Update-ProfileCommand {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param(
    [string]$ScriptPath,
    [string]$Name,
    [string[]]$ProfilePath
  )

  $block = @"
$profileMarkerBegin
function global:$Name {
  param(
    [Parameter(ValueFromRemainingArguments = `$true)]
    [string[]]`$DwApiCheckArgs
  )
  & '$ScriptPath' @DwApiCheckArgs
}
$profileMarkerEnd
"@

  foreach ($path in $ProfilePath) {
    if (-not $PSCmdlet.ShouldProcess($path, 'Update dw-api-tools profile command')) {
      continue
    }

    $profileDir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $profileDir)) {
      New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
    }

    if (-not (Test-Path -LiteralPath $path)) {
      try {
        New-Item -ItemType File -Force -Path $path | Out-Null
        Set-Content -LiteralPath $path -Value ($block.Trim() + "`r`n") -Encoding utf8
      } catch {
        Write-Warning "Nao foi possivel criar o profile: $path ($($_.Exception.Message))"
      }
      continue
    }

    $content = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { $content = '' }

    if ($content -like "*$profileMarkerBegin*") {
      $pattern = '(?s)' + [regex]::Escape($profileMarkerBegin) + '.*?' + [regex]::Escape($profileMarkerEnd)
      $content = [regex]::Replace($content, $pattern, $block.Trim())
    } else {
      if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) {
        $content += "`r`n"
      }
      $content += "`r`n" + $block.Trim() + "`r`n"
    }

    try {
      Set-Content -LiteralPath $path -Value $content -Encoding utf8
    } catch {
      Write-Warning "Nao foi possivel atualizar o profile: $path ($($_.Exception.Message))"
    }
  }
}

function Register-SessionCommand {
  param(
    [string]$ScriptPath,
    [string]$Name
  )

  $escapedPath = $ScriptPath.Replace("'", "''")
  $definition = @"
param(
  [Parameter(ValueFromRemainingArguments = `$true)]
  [string[]]`$DwApiCheckArgs
)
& '$escapedPath' @DwApiCheckArgs
"@
  Set-Item -Path "Function:global:$Name" -Value ([scriptblock]::Create($definition))
}

$profilePaths = @(Get-ProfilePath)

if ($Uninstall) {
  if ($PSCmdlet.ShouldProcess($InstallDir, "Uninstall $CommandName")) {
    if (Test-Path -LiteralPath $targetCmd) { Remove-Item -LiteralPath $targetCmd -Force }
    if (Test-Path -LiteralPath $targetScript) { Remove-Item -LiteralPath $targetScript -Force }
    if (Test-Path -LiteralPath $targetModule) { Remove-Item -LiteralPath $targetModule -Force }
    Clear-ProfileCommand -ProfilePath $profilePaths
    Write-Host "Removed $CommandName from $InstallDir and PowerShell profiles."
  }
  return
}

if (-not (Test-Path -LiteralPath $sourceScript)) {
  throw "Source script not found: $sourceScript"
}
if (-not (Test-Path -LiteralPath $sourceModule)) {
  throw "Source module not found: $sourceModule"
}

if (-not $PSCmdlet.ShouldProcess($InstallDir, "Install $CommandName")) {
  return
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item -Force -LiteralPath $sourceScript -Destination $targetScript
Copy-Item -Force -LiteralPath $sourceModule -Destination $targetModule

# Remove o nome antigo, se existir (migracao dw_api_check -> dw).
if ($CommandName -eq 'dw') {
  foreach ($legacy in @(
      (Join-Path $InstallDir 'dw_api_check.ps1'),
      (Join-Path $InstallDir 'dw_api_check.cmd')
    )) {
    if (Test-Path -LiteralPath $legacy) {
      Remove-Item -LiteralPath $legacy -Force
    }
  }
}

$launcher = Get-PowerShellLauncher
@"
@echo off
$launcher -NoProfile -ExecutionPolicy Bypass -File "%~dp0$CommandName.ps1" %*
"@ | Set-Content -LiteralPath $targetCmd -Encoding Ascii

if (-not $SkipPathUpdate) {
  Add-UserPathEntry -PathToAdd $InstallDir
}

if (-not $SkipProfileUpdate) {
  Update-ProfileCommand -ScriptPath $targetScript -Name $CommandName -ProfilePath $profilePaths
}

Register-SessionCommand -ScriptPath $targetScript -Name $CommandName

Write-Host ""
Write-Host "Installed $CommandName"
Write-Host "  Binary/script : $targetScript"
Write-Host "  Module        : $targetModule"
Write-Host "  CMD wrapper   : $targetCmd"
Write-Host "  PATH (User)   : $InstallDir"
if (-not $SkipProfileUpdate) {
  Write-Host "  PS profile    : updated ($($profilePaths.Count) file(s))"
}
Write-Host ""
Write-Host "You can run from any folder:"
Write-Host "  $CommandName --help"
Write-Host "  $CommandName --mode usage"
Write-Host ""
Write-Host "If a terminal was already open, close it and open a new one (or reopen the tab)."
Write-Host "Set API key: `$env:ANTHROPIC_API_KEY = 'dw_live_...'"
Write-Host "Persistent:  [Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY', 'dw_live_...', 'User')"
