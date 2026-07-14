Set-StrictMode -Version Latest

<#
.SYNOPSIS
  Reads a variable value from a .env file.

.DESCRIPTION
  Parses KEY=VALUE lines and returns the value for the requested name.
  Supports optional single/double quotes around the value.
  Blank lines and comments starting with # are ignored.

.PARAMETER Path
  Full path to the .env file.

.PARAMETER Name
  Environment variable name to look up.

.EXAMPLE
  Get-DwDotEnvValue -Path '.\.env' -Name 'ANTHROPIC_API_KEY'
#>
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

<#
.SYNOPSIS
  Maps a usage percentage to a human-readable level.

.DESCRIPTION
  Returns one of: livre, baixo, medio, alto, critico.

.PARAMETER Percent
  Used percentage from 0 to 100.

.EXAMPLE
  Get-DwUsageLevel -Percent 82.5
#>
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

<#
.SYNOPSIS
  Formats a usage reset timestamp as relative text.

.DESCRIPTION
  Returns "ja resetada" when empty/past, otherwise a Portuguese relative string
  such as "em 1h 30min (19:30)".

.PARAMETER ResetsAt
  ISO timestamp or null.

.PARAMETER Now
  Optional reference time (defaults to current time). Useful for tests.

.EXAMPLE
  Format-DwRelativeReset -ResetsAt '2026-07-14T19:30:00-03:00'
#>
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

<#
.SYNOPSIS
  Prints beginner-friendly CLI help text.

.DESCRIPTION
  Writes Portuguese help for dw commands to the host.

.EXAMPLE
  Show-DwHelpText
#>
function Show-DwHelpText {
  [CmdletBinding()]
  param()

  $lines = @(
    'DW API Tools - ajuda rapida',
    '',
    'O que e isso?',
    '  Consulta sua conta DevWServices, consumo e modelos no terminal.',
    '',
    'Antes de comecar (obrigatorio)',
    '  Voce precisa da chave (comeca com dw_live_...).',
    '',
    '  PowerShell (so nesta janela):',
    '    $env:ANTHROPIC_API_KEY = "dw_live_..."',
    '',
    '  Linux/macOS (so neste terminal):',
    '    export ANTHROPIC_API_KEY="dw_live_..."',
    '',
    '  Ou arquivo .env na raiz do projeto:',
    '    ANTHROPIC_API_KEY=dw_live_...',
    '',
    'Modos (API)',
    '  me       Conta (/v1/me)',
    '  usage    Consumo 1h/6h/24h (/v1/usage)',
    '  models   Modelos disponiveis (/v1/models)',
    '  help     Esta ajuda',
    '',
    'Como rodar (depois de make install)',
    '  dw --mode me',
    '  dw --mode usage',
    '  dw --mode models',
    '  dw --help',
    '',
    'Como rodar (na pasta do projeto, com Make)',
    '  make install              Instala o comando dw',
    '  make uninstall            Remove o comando',
    '  make me | usage | models  Atalhos de modo',
    '  make dw MODE=usage        Modo via MODE=',
    '  make test                 Testes Pester',
    '  make help                 Ajuda do Makefile',
    '',
    'Como rodar (sem instalar)',
    '  Windows:  .\dw.cmd --mode usage',
    '  Unix:     ./dw --mode usage',
    '',
    'Problemas comuns',
    '  - Missing API key: configure a chave ou o .env',
    '  - 401 Unauthorized: chave errada ou inativa',
    '  - command not found: feche o terminal ou rode make install',
    '',
    'Guia completo: README.md e INSTALL.md'
  )

  Write-Host ($lines -join [Environment]::NewLine)
}

<#
.SYNOPSIS
  Prints a parsed usage summary table.

.DESCRIPTION
  Shows 1h/6h/24h windows with bars, levels and relative reset times.

.PARAMETER Response
  Object returned by GET /v1/usage.

.EXAMPLE
  Show-DwUsageSummary -Response $usageResponse
#>
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

<#
.SYNOPSIS
  Prints a compact list of available models.

.DESCRIPTION
  Renders model id, context window and owner from GET /v1/models.

.PARAMETER Response
  Object returned by GET /v1/models.

.EXAMPLE
  Show-DwModelsSummary -Response $modelsResponse
#>
function Show-DwModelsSummary {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    $Response
  )

  $models = @()
  if ($Response.data) {
    $models = @($Response.data)
  }

  Write-Host ''
  Write-Host ("Modelos disponiveis ({0})" -f $models.Count)
  Write-Host ('-' * 76)
  Write-Host ('{0,-40} {1,12}  {2}' -f 'ID', 'Contexto', 'Owner')
  Write-Host ('-' * 76)

  foreach ($model in $models) {
    $id = [string]$model.id
    $ctx = if ($null -ne $model.context_window) { $model.context_window } else { 'n/a' }
    $owner = if ($model.owned_by) { [string]$model.owned_by } else { 'n/a' }
    Write-Host ('{0,-40} {1,12}  {2}' -f $id, $ctx, $owner)
  }

  Write-Host ('-' * 76)
  Write-Host ''
}

<#
.SYNOPSIS
  Prints a parsed account summary.

.DESCRIPTION
  Shows telegram id, plan, status, validity and expired flag from GET /v1/me.

.PARAMETER Response
  Object returned by GET /v1/me.

.EXAMPLE
  Show-DwMeSummary -Response $meResponse
#>
function Show-DwMeSummary {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    $Response
  )

  $telegramId = if ($Response.user -and $Response.user.telegram_id) { $Response.user.telegram_id } else { 'n/a' }
  $plan = if ($Response.api_key -and $Response.api_key.plan) { $Response.api_key.plan } else { 'n/a' }
  $status = if ($Response.api_key -and $Response.api_key.status) { $Response.api_key.status } else { 'n/a' }
  $endDate = if ($Response.api_key -and $Response.api_key.end_date) { $Response.api_key.end_date } else { 'n/a' }
  $expired = if ($Response.api_key -and $null -ne $Response.api_key.is_expired) {
    if ($Response.api_key.is_expired) { 'sim' } else { 'nao' }
  } else {
    'n/a'
  }

  Write-Host ''
  Write-Host 'Sua conta'
  Write-Host ('-' * 48)
  Write-Host ("Telegram ID : {0}" -f $telegramId)
  Write-Host ("Plano       : {0}" -f $plan)
  Write-Host ("Status      : {0}" -f $status)
  Write-Host ("Validade    : {0}" -f $endDate)
  Write-Host ("Expirada    : {0}" -f $expired)
  Write-Host ('-' * 48)
  Write-Host ''
}

<#
.SYNOPSIS
  Resolves the API credential from multiple sources.

.DESCRIPTION
  Preference order: explicit Current value, dotenv file in the current
  directory, dotenv next to ScriptRoot, then DW_API_KEY environment variable.

.PARAMETER Current
  Explicit key already provided by the caller.

.PARAMETER ScriptRoot
  Directory used to look for a secondary dotenv file.

.OUTPUTS
  System.String
  The resolved API key, or nothing when no credential is found.

.EXAMPLE
  Resolve-DwCredential -ScriptRoot C:\path\to\repo
#>
function Resolve-DwCredential {
  [CmdletBinding()]
  [OutputType([string])]
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

<#
.SYNOPSIS
  Parses GNU-style CLI flags for dw.

.DESCRIPTION
  Supports --help, --mode, --api-key (with or without =value).

.PARAMETER RemainingArguments
  Raw remaining argv tokens.

.PARAMETER Mode
  Initial mode before flag overrides.

.PARAMETER Key
  Initial API key before flag overrides.

.PARAMETER Help
  Initial Help switch value.

.EXAMPLE
  ConvertFrom-DwCliArgument -RemainingArguments @('--mode', 'usage')
#>
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

<#
.SYNOPSIS
  Runs a dw query (me, usage, models, or help).

.DESCRIPTION
  Parses CLI arguments, resolves credentials, calls the DevWServices API
  and prints a beginner-friendly summary.

.PARAMETER Mode
  One of: me, usage, models, help.

.PARAMETER Key
  Optional API key. Falls back to env/.env.

.PARAMETER Help
  Shows help when set.

.PARAMETER RemainingArguments
  Extra GNU-style args such as --mode usage.

.PARAMETER ScriptRoot
  Script directory used for .env lookup.

.PARAMETER ApiBaseUrl
  API base URL.

.EXAMPLE
  Invoke-DwApiCheck -Mode usage -ScriptRoot $PSScriptRoot
#>
function Invoke-DwApiCheck {
  [CmdletBinding()]
  param(
    [ValidateSet('me', 'usage', 'models', 'help')]
    [string]$Mode = 'me',

    [string]$Key = $env:ANTHROPIC_API_KEY,

    [switch]$Help,

    [string[]]$RemainingArguments,

    [string]$ScriptRoot = $PSScriptRoot,

    [string]$ApiBaseUrl = 'https://ai.devwservices.shop'
  )

  $parsed = ConvertFrom-DwCliArgument -RemainingArguments $RemainingArguments -Mode $Mode -Key $Key -Help:$Help

  if ($parsed.ShowHelp -or $parsed.Mode -eq 'help') {
    Show-DwHelpText
    return
  }

  if ($parsed.Mode -notin @('me', 'usage', 'models')) {
    throw ("Invalid mode: {0}. Use me, usage, models, or help." -f $parsed.Mode)
  }

  $resolvedKey = Resolve-DwCredential -Current $parsed.Key -ScriptRoot $ScriptRoot

  if (-not $resolvedKey) {
    throw 'Missing API key. Set $env:ANTHROPIC_API_KEY, use a .env file, or pass --api-key.'
  }

  if (
    $resolvedKey -in @('--mode', '-Mode', '-mode', 'me', 'usage', 'models', 'help') -or
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

  Write-Host ("Consultando {0} ..." -f $uri)

  try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -TimeoutSec 20
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

  switch ($parsed.Mode) {
    'usage' {
      Show-DwUsageSummary -Response $response
      return
    }
    'models' {
      Show-DwModelsSummary -Response $response
      return
    }
    default {
      Show-DwMeSummary -Response $response
      return
    }
  }
}

Export-ModuleMember -Function @(
  'Get-DwDotEnvValue',
  'Get-DwUsageLevel',
  'Format-DwRelativeReset',
  'Show-DwHelpText',
  'Show-DwUsageSummary',
  'Show-DwModelsSummary',
  'Show-DwMeSummary',
  'Resolve-DwCredential',
  'ConvertFrom-DwCliArgument',
  'Invoke-DwApiCheck'
)
