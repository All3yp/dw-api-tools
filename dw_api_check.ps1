[CmdletBinding(PositionalBinding = $false)]
param(
  [ValidateSet('me', 'usage', 'models')]
  [string]$Mode = 'me',

  [Alias('h')]
  [switch]$Help,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$RemainingArguments
)

# #region agent log
try {
  $agentLog = Join-Path -Path $PSScriptRoot -ChildPath 'debug-2b0a52.log'
  $paramNames = @((Get-Command -Name $PSCommandPath).Parameters.Keys | Sort-Object)
  $payload = @{
    sessionId    = '2b0a52'
    runId        = 'post-fix'
    hypothesisId = 'B'
    location     = 'dw_api_check.ps1:param-check'
    message      = 'wrapper parameters after ApiKey removal'
    data         = @{
      paramNames = $paramNames
      hasApiKey  = ($paramNames -contains 'ApiKey')
      hasKey     = ($paramNames -contains 'Key')
      mode       = $Mode
      help       = [bool]$Help
    }
    timestamp    = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  }
  Add-Content -LiteralPath $agentLog -Value (($payload | ConvertTo-Json -Compress -Depth 5)) -Encoding utf8
} catch {
  Write-Verbose "agent-log-skip: $($_.Exception.Message)"
}
# #endregion

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'DwApiCheck.psm1'
if (-not (Test-Path -LiteralPath $modulePath)) {
  throw "Module not found: $modulePath"
}

Import-Module -Name $modulePath -Force

Invoke-DwApiCheck `
  -Mode $Mode `
  -Help:$Help `
  -RemainingArguments $RemainingArguments `
  -ScriptRoot $PSScriptRoot
