#!/usr/bin/env sh

set -eu

INSTALL_DIR=${INSTALL_DIR:-"$HOME/bin"}
COMMAND_NAME=${COMMAND_NAME:-dw}
UNINSTALL=${UNINSTALL:-0}
ADD_TO_PATH=${ADD_TO_PATH:-ask}

supports_color() {
  [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || printf 0)" -ge 8 ]
}

if supports_color; then
  green=$(printf '\033[32m')
  red=$(printf '\033[31m')
  yellow=$(printf '\033[33m')
  blue=$(printf '\033[34m')
  bold=$(printf '\033[1m')
  reset=$(printf '\033[0m')
else
  green=''
  red=''
  yellow=''
  blue=''
  bold=''
  reset=''
fi

info() { printf '%s\n' "${blue}INFO: $*${reset}"; }
success() { printf '%s\n' "${green}OK: $*${reset}"; }
warn() { printf '%s\n' "${yellow}AVISO: $*${reset}"; }
fail() { printf '%s\n' "${red}ERRO: $*${reset}" >&2; }

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
source_impl="$repo_root/src/dw_api_check.sh"
target_script="$INSTALL_DIR/$COMMAND_NAME.sh"
target_shim="$INSTALL_DIR/$COMMAND_NAME"

get_profile_file() {
  shell_name=$(basename "${SHELL:-sh}")
  case "$shell_name" in
    zsh) printf '%s\n' "$HOME/.zshrc" ;;
    bash) printf '%s\n' "$HOME/.bashrc" ;;
    fish) printf '%s\n' "$HOME/.config/fish/config.fish" ;;
    *) printf '%s\n' "$HOME/.profile" ;;
  esac
}

path_contains_install_dir() {
  case ":$PATH:" in
    *":$INSTALL_DIR:"*) return 0 ;;
    *) return 1 ;;
  esac
}

add_install_dir_to_path() {
  profile_file=$(get_profile_file)
  profile_dir=$(dirname "$profile_file")
  mkdir -p "$profile_dir"

  if [ "$(basename "${SHELL:-sh}")" = "fish" ]; then
    line="fish_add_path $INSTALL_DIR"
  else
    line="export PATH=\"$INSTALL_DIR:\$PATH\""
  fi

  if [ -f "$profile_file" ] && grep -F "$INSTALL_DIR" "$profile_file" >/dev/null 2>&1; then
    success "$INSTALL_DIR já aparece em $profile_file"
    return 0
  fi

  {
    printf '\n# DW API Tools\n'
    printf '%s\n' "$line"
  } >> "$profile_file"

  success "Adicionado ao PATH em: $profile_file"
  warn "Feche e abra o terminal para aplicar a alteração."
}

printf '%s\n' "${bold}🚀 Instalador DW API Tools${reset}"
printf '%s\n' ""

if [ "$UNINSTALL" = "1" ]; then
  rm -f "$target_script" "$target_shim"
  success "Removido: $COMMAND_NAME de $INSTALL_DIR"
  warn "Se você adicionou $INSTALL_DIR ao PATH manualmente, remova do seu arquivo de perfil se desejar."
  exit 0
fi

if [ ! -f "$source_impl" ]; then
  fail "Script principal nao encontrado: $source_impl"
  exit 1
fi

mkdir -p "$INSTALL_DIR"
# Install a self-contained copy: shim + implementation side by side.
cp "$source_impl" "$target_script"
chmod +x "$target_script"
success "Script copiado para: $target_script"

cat > "$target_shim" <<EOF
#!/usr/bin/env sh
exec "$target_script" "\$@"
EOF
chmod +x "$target_shim"
success "Comando criado em: $target_shim"

if path_contains_install_dir; then
  success "$INSTALL_DIR já está no PATH."
else
  warn "$INSTALL_DIR ainda não está no PATH."

  case "$ADD_TO_PATH" in
    yes|1|true)
      add_install_dir_to_path
      ;;
    no|0|false)
      warn "Adição automática ao PATH ignorada."
      ;;
    *)
      if [ -t 0 ]; then
        printf 'Deseja adicionar %s ao PATH automaticamente? [S/n] ' "$INSTALL_DIR"
        read answer
        case "$answer" in
          n|N|no|NO|Não|não)
            warn "Tudo bem. Você pode adicionar manualmente depois."
            ;;
          *)
            add_install_dir_to_path
            ;;
        esac
      else
        warn "Modo não interativo: não alterei seu PATH automaticamente."
        info "Para adicionar manualmente, inclua isto no seu perfil de shell:"
        printf '%s\n' "export PATH=\"$INSTALL_DIR:\$PATH\""
      fi
      ;;
  esac
fi

printf '%s\n' ""
success "Instalação concluída."
info "Abra um novo terminal e teste com: $COMMAND_NAME --help"
info "Depois configure sua chave: export ANTHROPIC_API_KEY=\"dw_live_...\""
