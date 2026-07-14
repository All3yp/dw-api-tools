@echo off
REM Entrypoint Windows (cmd / PowerShell). Mesma ideia do ./dw no Unix.
setlocal
where pwsh >nul 2>&1
if %ERRORLEVEL%==0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\dw_api_check.ps1" %*
  exit /b %ERRORLEVEL%
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\dw_api_check.ps1" %*
exit /b %ERRORLEVEL%
