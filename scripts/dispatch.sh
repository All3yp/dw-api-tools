#!/usr/bin/env sh
# Detecta Windows vs Unix e despacha install / dw / test / uninstall.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)

cmd=${1:-}
if [ -n "$cmd" ]; then
  shift
fi

is_windows() {
  # Native Windows Make sets OS=Windows_NT; Git Bash / MSYS report MINGW*/MSYS*.
  case "${OS-}" in
    Windows_NT) return 0 ;;
  esac
  case "$(uname -s 2>/dev/null || printf unknown)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
  esac
  return 1
}

run_powershell() {
  file=$1
  shift
  if command -v pwsh >/dev/null 2>&1; then
    exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$file" "$@"
  fi
  if command -v powershell.exe >/dev/null 2>&1; then
    exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$file" "$@"
  fi
  if command -v powershell >/dev/null 2>&1; then
    exec powershell -NoProfile -ExecutionPolicy Bypass -File "$file" "$@"
  fi
  printf '%s\n' "ERRO: PowerShell nao encontrado (pwsh/powershell)." >&2
  exit 1
}

usage() {
  cat <<'EOF'
Uso: dispatch.sh <install|uninstall|dw|test|help> [args...]

  install     Instala o comando 'dw' no ambiente atual
  uninstall   Remove o comando instalado
  dw          Roda a ferramenta (ex.: dw --mode usage)
  test        Roda testes (Windows / pwsh)
  help        Mostra esta ajuda
EOF
}

case "$cmd" in
  ''|help|-h|--help)
    usage
    exit 0
    ;;
  install)
    if is_windows; then
      run_powershell "$root/scripts/install.ps1" "$@"
    else
      export INSTALL_DIR="${INSTALL_DIR:-$HOME/bin}"
      export COMMAND_NAME="${COMMAND_NAME:-dw}"
      export UNINSTALL="${UNINSTALL:-0}"
      export ADD_TO_PATH="${ADD_TO_PATH:-ask}"
      exec sh "$root/scripts/install.sh" "$@"
    fi
    ;;
  uninstall)
    if is_windows; then
      run_powershell "$root/scripts/install.ps1" -Uninstall "$@"
    else
      export UNINSTALL=1
      export COMMAND_NAME="${COMMAND_NAME:-dw}"
      exec sh "$root/scripts/install.sh" "$@"
    fi
    ;;
  dw|run)
    if is_windows; then
      run_powershell "$root/src/dw_api_check.ps1" "$@"
    else
      exec sh "$root/src/dw_api_check.sh" "$@"
    fi
    ;;
  test)
    if is_windows; then
      run_powershell "$root/scripts/Invoke-Tests.ps1" "$@"
    elif command -v pwsh >/dev/null 2>&1; then
      exec pwsh -NoProfile -File "$root/scripts/Invoke-Tests.ps1" "$@"
    else
      printf '%s\n' "ERRO: testes Pester precisam de PowerShell (pwsh)." >&2
      exit 1
    fi
    ;;
  *)
    printf '%s\n' "ERRO: comando desconhecido: $cmd" >&2
    usage >&2
    exit 1
    ;;
esac
