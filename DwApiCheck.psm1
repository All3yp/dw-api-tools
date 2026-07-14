Set-StrictMode -Version Latest

function Get-DwDotEnvValue {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return $null
  }

  foreach ($line in Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue) {
    $trimmed = $line.Trim()
    if (-not $trimmed -or $trimmed.StartsWith('#')) {
      continue
    }

    if ($trimmed -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$' -and $Matches[1] -eq $Name) {
      $value = $Matches[2].Trim()
      if (
        ($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))
      ) {
        $value = $value.Substring(1, $value.Length - 2)
      }
      return $value
    }
  }

  return $null
}

function Get-DwUsageLevel {
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory = $true)]
    [double]$Percent
  )

  if ($Percent -ge 90) { return 'critico' }
  if ($Percent -ge 75) { return 'alto' }
  if ($Percent -ge 50) { return 'medio' }
  if ($Percent -gt 0) { return 'baixo' }
  return 'livre'
}

function Format-DwRelativeReset {
  [CmdletBinding()]
  [OutputType([string])]
  param(
    $ResetsAt,

    [DateTimeOffset]$Now = [DateTimeOffset]::Now
  )

  if (-not $ResetsAt) {
    return 'ja resetada'
  }

  try {
    $resetTime = [DateTimeOffset]::Parse([string]$ResetsAt)
  } catch {
    return [string]$ResetsAt
  }

  $delta = $resetTime - $Now
  if ($delta.TotalSeconds -le 0) {
    return 'ja resetada'
  }

  $parts = @()
  if ($delta.Days -gt 0) { $parts += "$($delta.Days)d" }
  if ($delta.Hours -gt 0) { $parts += "$($delta.Hours)h" }
  if ($delta.Minutes -gt 0 -or $parts.Count -eq 0) { $parts += "$($delta.Minutes)min" }

  $clock = $resetTime.ToLocalTime().ToString('HH:mm')
  return ('em {0} ({1})' -f ($parts -join ' '), $clock)
}

function Show-DwHelpText {
  [CmdletBinding()]
  param()

  $lines = @(
    'Usage:',
    '  .\dw_api_check.ps1 [--help] [--mode me|usage|models] [--api-key TOKEN]',
    '  .\dw_api_check.ps1 [-Help] [-Mode me|usage|models]',
    '',
    'Environment:',
    '  The script reads ANTHROPIC_API_KEY first, then DW_API_KEY.',
    '  In PowerShell, set it with:',
    '    $env:ANTHROPIC_API_KEY = "dw_live_..."',
    '  For a persistent user-level value, use:',
    '    setx ANTHROPIC_API_KEY "dw_live_..."',
    '  Optional fallback: create a .env with ANTHROPIC_API_KEY=dw_live_... in the',
    '  current folder or next to this script.',
    '',
    'Modes:',
    '  me      Calls /v1/me and returns the current account details.',
    '  usage   Calls /v1/usage and returns your own consumption.',
    '  models  Calls /v1/models and returns the available models.',
    '',
    'Examples:',
    '  $env:ANTHROPIC_API_KEY = "dw_live_..."',
    '  .\dw_api_check.ps1 --help',
    '  .\dw_api_check.ps1 --mode usage',
    '  .\dw_api_check.ps1 --mode models'
  )

  Write-Host ($lines -join [Environment]::NewLine)
}

function Show-DwUsageSummary {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    $Response
  )

  $labels = [ordered]@{
    '1h'  = 'Ultima 1 hora'
    '6h'  = 'Ultimas 6 horas'
    '24h' = 'Ultimas 24 horas'
  }

  Write-Host ''
  Write-Host 'Seu consumo'
  if ($Response.timezone) {
    Write-Host ("Fuso: {0}" -f $Response.timezone)
  } else {
    Write-Host 'Fuso: n/a'
  }
  Write-Host ('-' * 76)
  Write-Host ('{0,-18} {1,-22} {2,7}  {3,-8}  {4}' -f 'Janela', 'Uso', 'Pct', 'Nivel', 'Reset')
  Write-Host ('-' * 76)

  foreach ($windowName in $labels.Keys) {
    $window = $Response.windows.$windowName
    if (-not $window) { continue }

    $percent = [double]$window.used_percent
    $barWidth = 20
    $filled = [Math]::Max(0, [Math]::Min($barWidth, [int][Math]::Round($percent / 100 * $barWidth)))
    $bar = ('#' * $filled) + ('.' * ($barWidth - $filled))
    $level = Get-DwUsageLevel -Percent $percent
    $resetLabel = Format-DwRelativeReset -ResetsAt $window.resets_at

    Write-Host (
      '{0,-18} [{1}] {2,6:N1}%  {3,-8}  {4}' -f
      $labels[$windowName],
      $bar,
      $percent,
      $level,
      $resetLabel
    )
  }

  Write-Host ('-' * 76)
  Write-Host 'Legenda: livre=0% | baixo ate 49% | medio 50-74% | alto 75-89% | critico 90%+'
  Write-Host ''
}

function Resolve-DwCredential {
  [CmdletBinding()]
  param(
    [string]$Current,
    [string]$ScriptRoot = $PSScriptRoot
  )

  if ($Current) { return $Current }

  $fromPwd = Get-DwDotEnvValue -Path (Join-Path -Path $PWD -ChildPath '.env') -Name 'ANTHROPIC_API_KEY'
  if ($fromPwd) { return $fromPwd }

  $fromScript = Get-DwDotEnvValue -Path (Join-Path -Path $ScriptRoot -ChildPath '.env') -Name 'ANTHROPIC_API_KEY'
  if ($fromScript) { return $fromScript }

  if ($env:DW_API_KEY) { return $env:DW_API_KEY }

  return $null
}

function ConvertFrom-DwCliArgument {
  [CmdletBinding()]
  param(
    [string[]]$RemainingArguments,
    [string]$Mode = 'me',
    [string]$Key,
    [switch]$Help
  )

  $result = [pscustomobject]@{
    Mode     = $Mode
    Key      = $Key
    Help     = [bool]$Help
    ShowHelp = $false
  }

  $argv = @()
  if ($null -ne $RemainingArguments) {
    $argv = @($RemainingArguments)
  }

  $i = 0
  while ($i -lt $argv.Count) {
    switch -Regex ($argv[$i]) {
      '^(--help|-h|/\?)$' {
        $result.ShowHelp = $true
        return $result
      }
      '^--mode$' {
        if ($i + 1 -ge $argv.Count) { throw 'Missing value for --mode.' }
        $result.Mode = $argv[$i + 1]
        $i += 2
        continue
      }
      '^--mode=(.+)$' {
        $result.Mode = $Matches[1]
        $i += 1
        continue
      }
      '^--api-key$' {
        if ($i + 1 -ge $argv.Count) { throw 'Missing value for --api-key.' }
        $result.Key = $argv[$i + 1]
        $i += 2
        continue
      }
      '^--api-key=(.+)$' {
        $result.Key = $Matches[1]
        $i += 1
        continue
      }
      default {
        throw ("Unknown argument: {0}. Use --help for examples." -f $argv[$i])
      }
    }
  }

  if ($result.Help) {
    $result.ShowHelp = $true
  }

  return $result
}

function Invoke-DwApiCheck {
  [CmdletBinding()]
  param(
    [ValidateSet('me', 'usage', 'models')]
    [string]$Mode = 'me',

    [string]$Key = $env:ANTHROPIC_API_KEY,

    [switch]$Help,

    [string[]]$RemainingArguments,

    [string]$ScriptRoot = $PSScriptRoot,

    [string]$ApiBaseUrl = 'https://ai.devwservices.shop'
  )

  $parsed = ConvertFrom-DwCliArgument -RemainingArguments $RemainingArguments -Mode $Mode -Key $Key -Help:$Help

  if ($parsed.ShowHelp) {
    Show-DwHelpText
    return
  }

  if ($parsed.Mode -notin @('me', 'usage', 'models')) {
    throw ("Invalid mode: {0}. Use me, usage, or models." -f $parsed.Mode)
  }

  $resolvedKey = Resolve-DwCredential -Current $parsed.Key -ScriptRoot $ScriptRoot

  if (-not $resolvedKey) {
    throw 'Missing API key. Set $env:ANTHROPIC_API_KEY, use a .env file, or pass --api-key.'
  }

  if (
    $resolvedKey -in @('--mode', '-Mode', '-mode', 'me', 'usage', 'models') -or
    $resolvedKey.StartsWith('-')
  ) {
    throw (
      'API key looks invalid ("{0}"). Pass --mode/--api-key as named flags, or set ANTHROPIC_API_KEY / .env.' -f $resolvedKey
    )
  }

  $headers = @{
    Authorization = "Bearer $resolvedKey"
  }

  $uri = switch ($parsed.Mode) {
    'usage' { "$ApiBaseUrl/v1/usage" }
    'models' { "$ApiBaseUrl/v1/models" }
    default { "$ApiBaseUrl/v1/me" }
  }

  try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers
  } catch {
    $status = $null
    if ($_.Exception.Response) {
      $status = [int]$_.Exception.Response.StatusCode
    }

    if ($status -eq 401) {
      throw (
        '401 Unauthorized calling {0}. Check ANTHROPIC_API_KEY / .env (key length now: {1}).' -f
        $uri,
        $resolvedKey.Length
      )
    }

    throw ("Failed to call {0}. {1}" -f $uri, $_.Exception.Message)
  }

  if ($parsed.Mode -eq 'usage') {
    Show-DwUsageSummary -Response $response
    return
  }

  $response | ConvertTo-Json -Depth 20
}

Export-ModuleMember -Function @(
  'Get-DwDotEnvValue',
  'Get-DwUsageLevel',
  'Format-DwRelativeReset',
  'Show-DwHelpText',
  'Show-DwUsageSummary',
  'Resolve-DwCredential',
  'ConvertFrom-DwCliArgument',
  'Invoke-DwApiCheck'
)
