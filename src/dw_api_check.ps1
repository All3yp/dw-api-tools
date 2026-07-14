[CmdletBinding(PositionalBinding = $false)]
param(
  [ValidateSet('me', 'usage', 'models', 'help')]
  [string]$Mode = 'me',

  [Alias('h')]
  [switch]$Help,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$RemainingArguments
)

# Repo: ./src/DwApiCheck.psm1 | Instalado: ./DwApiCheck.psm1 (ao lado deste script em ~/bin)
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'DwApiCheck.psm1'
if (-not (Test-Path -LiteralPath $modulePath)) {
  throw "Module not found: $modulePath"
}

Import-Module -Name $modulePath -Force

# .env na raiz do repo (pai de src/) ou na pasta instalada (~/bin)
$scriptRootForEnv = $PSScriptRoot
if ((Split-Path -Leaf $PSScriptRoot) -eq 'src') {
  $scriptRootForEnv = Split-Path -Parent $PSScriptRoot
}

Invoke-DwApiCheck `
  -Mode $Mode `
  -Help:$Help `
  -RemainingArguments $RemainingArguments `
  -ScriptRoot $scriptRootForEnv
