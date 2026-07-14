param(
  [string]$ApiKey = $env:ANTHROPIC_API_KEY,
  [ValidateSet('me', 'usage', 'models')]
  [string]$Mode = 'me',
  [switch]$Help
)

function Get-DotEnvValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  if (-not (Test-Path $Path)) {
    return $null
  }

  foreach ($line in Get-Content -Path $Path -ErrorAction SilentlyContinue) {
    $trimmed = $line.Trim()
    if (-not $trimmed -or $trimmed.StartsWith('#')) {
      continue
    }

    if ($trimmed -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$' -and $Matches[1] -eq $Name) {
      $value = $Matches[2].Trim()
      if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
      }
      return $value
    }
  }

  return $null
}

function Show-Usage {
  @'
Usage:
  .\dw_api_check.ps1 [--help] [-Mode me|usage|models] [-ApiKey <token>]

Environment:
  The script reads ANTHROPIC_API_KEY first, then DW_API_KEY.
  In PowerShell, set it with:
    $env:ANTHROPIC_API_KEY = "dw_live_..."
  For a persistent user-level value, use:
    setx ANTHROPIC_API_KEY "dw_live_..."
  Optional fallback: create a .env with ANTHROPIC_API_KEY=dw_live_... in the
  current folder or next to this script.

Modes:
  me      Calls /v1/me and returns the current account details.
  usage   Calls /v1/usage and returns your own consumption.
  models  Calls /v1/models and returns the available models.

Examples:
  $env:ANTHROPIC_API_KEY = "dw_live_..."
  .\dw_api_check.ps1 --help
  .\dw_api_check.ps1 -Mode usage
  .\dw_api_check.ps1 -Mode models
'@ | Write-Host
}

if (
  $Help -or
  ($args -contains '--help') -or
  ($args -contains '-h') -or
  ($ApiKey -in @('--help', '-h', '/?')) -or
  ($Mode -in @('--help', '-h', '/?'))
) {
  Show-Usage
  return
}

if (-not $ApiKey) {
  $ApiKey = Get-DotEnvValue -Path (Join-Path $PWD '.env') -Name 'ANTHROPIC_API_KEY'
}

if (-not $ApiKey) {
  $scriptEnvPath = Join-Path $PSScriptRoot '.env'
  $ApiKey = Get-DotEnvValue -Path $scriptEnvPath -Name 'ANTHROPIC_API_KEY'
}

if (-not $ApiKey) {
  $ApiKey = $env:DW_API_KEY
}

if (-not $ApiKey) {
  throw "Missing API key. Set `$env:ANTHROPIC_API_KEY in the current PowerShell session, use setx for a persistent user value, or pass -ApiKey."
}

$headers = @{
  Authorization = "Bearer $ApiKey"
}

$uri = switch ($Mode) {
  'usage' { 'https://ai.devwservices.shop/v1/usage' }
  'models' { 'https://ai.devwservices.shop/v1/models' }
  default { 'https://ai.devwservices.shop/v1/me' }
}

function Show-UsageSummary {
  param([Parameter(Mandatory = $true)]$Response)

  Write-Host ""
  Write-Host "Consumo (timezone: $($Response.timezone))"
  Write-Host ("-" * 48)

  foreach ($windowName in @('1h', '6h', '24h')) {
    $window = $Response.windows.$windowName
    if (-not $window) { continue }

    $percent = [double]$window.used_percent
    $barWidth = 20
    $filled = [Math]::Max(0, [Math]::Min($barWidth, [int][Math]::Round($percent / 100 * $barWidth)))
    $bar = ("#" * $filled) + ("-" * ($barWidth - $filled))
    Write-Host ("{0,3}  [{1}] {2,5:N1}%  reseta em {3}" -f $windowName, $bar, $percent, $window.resets_at)
  }

  Write-Host ""
}

try {
  $response = Invoke-RestMethod -Uri $uri -Headers $headers
} catch {
  throw "Failed to call $uri. $($_.Exception.Message)"
}

if ($Mode -eq 'usage') {
  Show-UsageSummary -Response $response
}

$response | ConvertTo-Json -Depth 20
