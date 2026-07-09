#!/usr/bin/env sh

set -eu

API_BASE_URL=${API_BASE_URL:-https://ai.devwservices.shop}
CONNECT_TIMEOUT=${CONNECT_TIMEOUT:-10}
MAX_TIME=${MAX_TIME:-30}

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

info() { printf '%s\n' "${blue}INFO: $*${reset}" >&2; }
success() { printf '%s\n' "${green}OK: $*${reset}" >&2; }
warn() { printf '%s\n' "${yellow}AVISO: $*${reset}" >&2; }
fail() { printf '%s\n' "${red}ERRO: $*${reset}" >&2; }

show_usage() {
  cat <<EOF
${bold}🚀 DW API Tools${reset}

Uso:
  dw_api_check [--help] [--mode me|usage|models] [--api-key <token>]
  ./dw_api_check.sh [--help] [--mode me|usage|models] [--api-key <token>]

Chave da API:
  O script procura a chave nesta ordem:
    1. ANTHROPIC_API_KEY
    2. DW_API_KEY
    3. arquivo .env na pasta atual
    4. arquivo .env ao lado deste script

Exemplo Linux/macOS:
  export ANTHROPIC_API_KEY="dw_live_..."

Exemplo PowerShell:
  \$env:ANTHROPIC_API_KEY = "dw_live_..."

Modos:
  me      👤 consulta /v1/me e mostra dados da conta
  usage   📊 consulta /v1/usage e mostra consumo
  models  🤖 consulta /v1/models e lista modelos

Exemplos:
  dw_api_check --help
  dw_api_check --mode me
  dw_api_check --mode usage
  dw_api_check --mode models
EOF
}

get_dotenv_value() {
  file_path=$1
  name=$2

  [ -f "$file_path" ] || return 0

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|'#'*) continue ;;
    esac

    case "$line" in
      "$name"=*)
        value=${line#*=}
        value=$(printf '%s' "$value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        case "$value" in
          \"*) value=$(printf '%s' "$value" | sed 's/^"//; s/"$//') ;;
          "'"*) value=$(printf '%s' "$value" | sed "s/^'//; s/'$//") ;;
        esac
        printf '%s\n' "$value"
        return 0
        ;;
    esac
  done < "$file_path"
}

pretty_json_if_possible() {
  if command -v jq >/dev/null 2>&1; then
    jq .
  else
    cat
    warn "Dica: instale o 'jq' para ver o JSON formatado de forma mais bonita."
  fi
}

api_key=${ANTHROPIC_API_KEY:-}
mode=me

while [ "$#" -gt 0 ]; do
  case "$1" in
    --help|-h|/? )
      show_usage
      exit 0
      ;;
    --mode)
      [ "$#" -ge 2 ] || { fail "Faltou informar o valor de --mode."; exit 2; }
      mode=$2
      shift 2
      ;;
    --mode=*)
      mode=${1#*=}
      shift 1
      ;;
    --api-key)
      [ "$#" -ge 2 ] || { fail "Faltou informar o valor de --api-key."; exit 2; }
      api_key=$2
      shift 2
      ;;
    --api-key=*)
      api_key=${1#*=}
      shift 1
      ;;
    *)
      fail "Argumento desconhecido: $1"
      info "Use --help para ver exemplos."
      exit 2
      ;;
  esac
done

case "$mode" in
  me|usage|models) ;;
  *)
    fail "Modo inválido: $mode"
    info "Use um destes modos: me, usage ou models."
    exit 2
    ;;
esac

if ! command -v curl >/dev/null 2>&1; then
  fail "O comando 'curl' não está instalado."
  info "Instale o curl e tente novamente."
  exit 1
fi

if [ -z "$api_key" ] && [ -n "${DW_API_KEY:-}" ]; then
  api_key=$DW_API_KEY
fi

if [ -z "$api_key" ]; then
  api_key=$(get_dotenv_value "$PWD/.env" ANTHROPIC_API_KEY || true)
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ -z "$api_key" ]; then
  api_key=$(get_dotenv_value "$script_dir/.env" ANTHROPIC_API_KEY || true)
fi

if [ -z "$api_key" ]; then
  fail "Chave da API não encontrada."
  info "Configure ANTHROPIC_API_KEY, use um arquivo .env ou passe --api-key."
  info "Exemplo: export ANTHROPIC_API_KEY=\"dw_live_...\""
  exit 1
fi

case "$mode" in
  me) endpoint="$API_BASE_URL/v1/me" ;;
  usage) endpoint="$API_BASE_URL/v1/usage" ;;
  models) endpoint="$API_BASE_URL/v1/models" ;;
esac

info "Modo selecionado: $mode"
info "Consultando API..."

tmp_body=$(mktemp 2>/dev/null || printf '/tmp/dw_api_check_body_%s' "$$")
trap 'rm -f "$tmp_body"' EXIT HUP INT TERM

http_status=$(curl \
  --silent \
  --show-error \
  --location \
  --connect-timeout "$CONNECT_TIMEOUT" \
  --max-time "$MAX_TIME" \
  --header "Authorization: Bearer $api_key" \
  --output "$tmp_body" \
  --write-out '%{http_code}' \
  "$endpoint") || {
    fail "Não foi possível conectar à API."
    info "Verifique sua internet, firewall ou tente novamente depois."
    exit 1
  }

case "$http_status" in
  2*)
    success "Resposta recebida com sucesso."
    pretty_json_if_possible < "$tmp_body"
    ;;
  401)
    fail "401 Unauthorized: a chave da API foi recusada."
    info "Confira se a chave está correta e ativa."
    cat "$tmp_body" >&2
    exit 1
    ;;
  403)
    fail "403 Forbidden: sua chave não tem permissão para este recurso."
    cat "$tmp_body" >&2
    exit 1
    ;;
  404)
    fail "404 Not Found: endpoint não encontrado."
    info "Endpoint usado: $endpoint"
    cat "$tmp_body" >&2
    exit 1
    ;;
  5*)
    fail "$http_status: a API retornou erro interno."
    info "Tente novamente mais tarde."
    cat "$tmp_body" >&2
    exit 1
    ;;
  *)
    fail "A API retornou HTTP $http_status."
    cat "$tmp_body" >&2
    exit 1
    ;;
esac
