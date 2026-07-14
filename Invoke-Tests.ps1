[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$pesterModule = Get-Module -ListAvailable -Name Pester |
  Where-Object { $_.Version -ge [version]'5.0.0' } |
  Sort-Object Version -Descending |
  Select-Object -First 1

if (-not $pesterModule) {
  Write-Host 'Installing Pester 5+ (CurrentUser)...'
  Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck -MinimumVersion 5.0.0 -AllowClobber
  $pesterModule = Get-Module -ListAvailable -Name Pester |
    Where-Object { $_.Version -ge [version]'5.0.0' } |
    Sort-Object Version -Descending |
    Select-Object -First 1
}

Import-Module -Name $pesterModule.Path -Force

$config = New-PesterConfiguration
$config.Run.Path = Join-Path $PSScriptRoot 'tests'
$config.Run.Exit = $true
$config.Output.Verbosity = 'Detailed'

Invoke-Pester -Configuration $config
