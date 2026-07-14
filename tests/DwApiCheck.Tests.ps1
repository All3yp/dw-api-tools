# Requires: Pester 5+
BeforeAll {
  $modulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'DwApiCheck.psm1'
  Import-Module $modulePath -Force
}

Describe 'Get-DwUsageLevel' {
  It 'returns livre for 0' {
    Get-DwUsageLevel -Percent 0 | Should -Be 'livre'
  }

  It 'returns baixo for small positive usage' {
    Get-DwUsageLevel -Percent 12.5 | Should -Be 'baixo'
  }

  It 'returns medio for 50-74' {
    Get-DwUsageLevel -Percent 50 | Should -Be 'medio'
    Get-DwUsageLevel -Percent 74.9 | Should -Be 'medio'
  }

  It 'returns alto for 75-89' {
    Get-DwUsageLevel -Percent 75 | Should -Be 'alto'
    Get-DwUsageLevel -Percent 89.9 | Should -Be 'alto'
  }

  It 'returns critico for 90+' {
    Get-DwUsageLevel -Percent 90 | Should -Be 'critico'
    Get-DwUsageLevel -Percent 100 | Should -Be 'critico'
  }
}

Describe 'Format-DwRelativeReset' {
  It 'returns ja resetada when ResetsAt is null' {
    Format-DwRelativeReset -ResetsAt $null | Should -Be 'ja resetada'
  }

  It 'returns ja resetada when reset is in the past' {
    $now = [DateTimeOffset]::Parse('2026-07-14T18:00:00-03:00')
    $past = '2026-07-14T17:00:00-03:00'
    Format-DwRelativeReset -ResetsAt $past -Now $now | Should -Be 'ja resetada'
  }

  It 'formats relative future reset with clock' {
    $now = [DateTimeOffset]::Parse('2026-07-14T18:00:00-03:00')
    $future = '2026-07-14T19:30:00-03:00'
    $text = Format-DwRelativeReset -ResetsAt $future -Now $now
    $text | Should -Match '^em 1h 30min \('
  }
}

Describe 'Get-DwDotEnvValue' {
  BeforeAll {
    $tempDir = Join-Path $TestDrive 'dotenv'
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $script:envFile = Join-Path $tempDir '.env'
    @(
      '# comment',
      'OTHER=1',
      'ANTHROPIC_API_KEY="dw_live_test_key"',
      "DW_API_KEY='ignored_here'"
    ) | Set-Content -Path $script:envFile -Encoding utf8
  }

  It 'reads quoted ANTHROPIC_API_KEY' {
    Get-DwDotEnvValue -Path $script:envFile -Name 'ANTHROPIC_API_KEY' | Should -Be 'dw_live_test_key'
  }

  It 'returns null for missing file' {
    Get-DwDotEnvValue -Path (Join-Path $TestDrive 'missing.env') -Name 'ANTHROPIC_API_KEY' | Should -BeNullOrEmpty
  }

  It 'returns null for missing key' {
    Get-DwDotEnvValue -Path $script:envFile -Name 'DOES_NOT_EXIST' | Should -BeNullOrEmpty
  }
}

Describe 'ConvertFrom-DwCliArgument' {
  It 'parses --mode usage' {
    $parsed = ConvertFrom-DwCliArgument -RemainingArguments @('--mode', 'usage')
    $parsed.Mode | Should -Be 'usage'
    $parsed.ShowHelp | Should -BeFalse
  }

  It 'parses --api-key without binding into Mode' {
    $parsed = ConvertFrom-DwCliArgument -RemainingArguments @('--mode', 'models', '--api-key', 'dw_live_abc')
    $parsed.Mode | Should -Be 'models'
    $parsed.Key | Should -Be 'dw_live_abc'
  }

  It 'handles --help' {
    $parsed = ConvertFrom-DwCliArgument -RemainingArguments @('--help')
    $parsed.ShowHelp | Should -BeTrue
  }

  It 'throws on unknown argument' {
    { ConvertFrom-DwCliArgument -RemainingArguments @('--nope') } | Should -Throw '*Unknown argument*'
  }
}

Describe 'Resolve-DwCredential' {
  It 'prefers explicit Current value' {
    Resolve-DwCredential -Current 'dw_live_explicit' | Should -Be 'dw_live_explicit'
  }

  It 'reads DW_API_KEY when Current empty and no dotenv' {
    $old = $env:DW_API_KEY
    $oldAnthropic = $env:ANTHROPIC_API_KEY
    try {
      $env:ANTHROPIC_API_KEY = $null
      $env:DW_API_KEY = 'dw_live_from_dw'
      # Use a script root without .env
      $emptyRoot = Join-Path $TestDrive 'empty-root'
      New-Item -ItemType Directory -Path $emptyRoot -Force | Out-Null
      Push-Location $emptyRoot
      try {
        Resolve-DwCredential -Current $null -ScriptRoot $emptyRoot | Should -Be 'dw_live_from_dw'
      } finally {
        Pop-Location
      }
    } finally {
      $env:DW_API_KEY = $old
      $env:ANTHROPIC_API_KEY = $oldAnthropic
    }
  }
}
