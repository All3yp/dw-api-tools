# 🚀 DW API Tools

Ferramentas simples para consultar a API da **DevWServices** direto pelo terminal.

Com elas, você consegue verificar rapidamente se sua chave está funcionando, consultar seu consumo e listar os modelos disponíveis.

---

## ✅ O que você consegue fazer

- 👤 Ver dados da sua conta
- 📊 Consultar seu uso/consumo da API
- 🤖 Listar modelos disponíveis
- 🔑 Testar se sua chave da API está correta

---

## 🧭 Para quem é este guia?

Este guia foi escrito para pessoas que **não têm experiência com terminal**.

A ideia é: copiar, colar e testar.

---

## ⚡ Comece por aqui

### 1. Instale o comando

No Windows, na pasta do projeto:

```powershell
.\install.ps1
```

Isso coloca `dw_api_check` em `%USERPROFILE%\bin`, no PATH do usuário e no profile do PowerShell — assim você roda de qualquer pasta.

Passo a passo completo: 👉 [INSTALL.md](INSTALL.md)

---

### 2. Configure sua chave da API

A ferramenta precisa de uma chave chamada `ANTHROPIC_API_KEY`.

No **Windows PowerShell**:

```powershell
$env:ANTHROPIC_API_KEY = "dw_live_..."
```

No **Linux/macOS**:

```sh
export ANTHROPIC_API_KEY="dw_live_..."
```

> 🔐 Troque `dw_live_...` pela sua chave real.

---

### 3. Teste se instalou certo

Depois da instalação, feche o terminal, abra de novo e rode:

```sh
dw_api_check --help
```

Se aparecer uma tela de ajuda, deu certo. 🎉

---

## 🧪 Comandos principais

### 👤 Ver minha conta

```sh
dw_api_check --mode me
```

Use este comando para confirmar que sua chave está funcionando.

---

### 📊 Ver meu consumo

```sh
dw_api_check --mode usage
```

Consulta o endpoint `/v1/usage` e mostra o consumo da **sua** chave de forma parseada (sem JSON cru).

O que aparece na tela:

| Coluna | Significado |
|---|---|
| `Janela` | Período: última 1h, 6h ou 24h |
| `Uso` | Barra visual do percentual consumido |
| `%` | Percentual usado na janela |
| `Nivel` | Classificação do uso (`livre` → `critico`) |
| `Reset` | Tempo relativo até liberar de novo (`em 1h 19min (19:30)` ou `ja resetada`) |

Exemplo de saída:

```text
Seu consumo
Fuso: America/Sao_Paulo
----------------------------------------------------------------------------
Janela             Uso                          %  Nivel     Reset
----------------------------------------------------------------------------
Ultima 1 hora      [....................]    0.0%  livre     ja resetada
Ultimas 6 horas    [###########.........]   55.2%  medio     em 1h 19min (19:30)
Ultimas 24 horas   [##############......]   72.0%  medio     em 7h 15min (01:28)
----------------------------------------------------------------------------
Legenda: livre=0% | baixo<50% | medio 50-74% | alto 75-89% | critico>=90%
```

Equivalente manual (JSON puro da API, se quiser testar sem o script):

```sh
# Linux/macOS
curl -H "Authorization: Bearer dw_live_..." \
  https://ai.devwservices.shop/v1/usage
```

```powershell
# Windows PowerShell
Invoke-WebRequest -Uri "https://ai.devwservices.shop/v1/usage" `
  -Headers @{ Authorization = "Bearer dw_live_..." }
```

---

### 🤖 Ver modelos disponíveis

```sh
dw_api_check --mode models
```

Use este comando para listar os modelos que a API disponibiliza.

---

## 🪟 Comandos no Windows PowerShell

No PowerShell, os comandos também funcionam assim:

```powershell
dw_api_check --help
dw_api_check --mode me
dw_api_check --mode usage
dw_api_check --mode models
```

Se você estiver usando o script PowerShell diretamente, também pode usar:

```powershell
.\dw_api_check.ps1 --help
```

---

## 🐧 Comandos no Linux/macOS

```sh
dw_api_check --help
dw_api_check --mode me
dw_api_check --mode usage
dw_api_check --mode models
```

Se você ainda não instalou globalmente, pode rodar direto da pasta do projeto:

```sh
./dw_api_check.sh --help
./dw_api_check.sh --mode me
./dw_api_check.sh --mode usage
./dw_api_check.sh --mode models
```

---

## 🔑 Como a chave da API é lida

A ferramenta procura sua chave nesta ordem:

1. `ANTHROPIC_API_KEY`
2. `DW_API_KEY`
3. arquivo `.env` na pasta atual
4. arquivo `.env` na mesma pasta do script

Exemplo de arquivo `.env`:

```env
ANTHROPIC_API_KEY=dw_live_...
```

---

## 🧩 Modos disponíveis

| Modo | Endpoint | O que faz |
|---|---|---|
| `me` | `/v1/me` | Mostra dados da conta |
| `usage` | `/v1/usage` | Mostra o próprio consumo (`1h` / `6h` / `24h`) |
| `models` | `/v1/models` | Lista os modelos disponíveis |

---

## ✅ Como saber se funcionou?

Funcionou se:

- `dw_api_check --help` mostra a ajuda da ferramenta
- `dw_api_check --mode me` retorna dados da sua conta
- `dw_api_check --mode usage` mostra o consumo parseado (janelas, `%`, nível e tempo de reset)
- `dw_api_check --mode models` retorna a lista de modelos

---

## 🆘 Problemas comuns

### ❌ `dw_api_check: command not found`

O terminal ainda não encontrou o comando.

Tente isto:

1. Feche o terminal
2. Abra novamente
3. Rode:

```sh
dw_api_check --help
```

Se continuar, veja se a pasta `~/bin` está no seu `PATH`.

---

### ❌ `Missing API key`

A chave da API não foi encontrada.

Configure a chave novamente:

```sh
export ANTHROPIC_API_KEY="dw_live_..."
```

Ou crie um arquivo `.env` com:

```env
ANTHROPIC_API_KEY=dw_live_...
```

---

### ❌ `401 Unauthorized` ou `403 Forbidden`

A chave foi encontrada, mas a API recusou o acesso.

Verifique se:

- a chave está correta
- a chave não expirou
- você copiou a chave inteira
- não há espaços antes ou depois da chave

---

### ❌ Erro de conexão

Pode ser internet, firewall, DNS ou indisponibilidade temporária da API.

Tente novamente depois ou verifique sua conexão.

---

## 🧼 Desinstalar

No Linux/macOS:

```sh
UNINSTALL=1 ./install.sh
```

No Windows PowerShell:

```powershell
.\install.ps1 -Uninstall
```

---

## 🧪 Testes unitários

Os helpers ficam em `DwApiCheck.psm1` e os testes em `tests/` (Pester 5+).

```powershell
.\Invoke-Tests.ps1
```

---

## 💡 Dica rápida

Para testar tudo em sequência:

```sh
dw_api_check --help
dw_api_check --mode me
dw_api_check --mode usage
dw_api_check --mode models
```

Se os comandos responderem sem erro, sua instalação está pronta. ✅
