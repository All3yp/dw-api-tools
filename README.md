# 🚀 DW API Tools

Ferramentas simples para consultar a API da **DevWServices** direto pelo terminal.

Com elas, voce consegue verificar rapidamente se sua chave esta funcionando,
consultar seu consumo e listar os modelos disponiveis.

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

Um jeito so — o projeto detecta se voce esta no Windows ou no Linux/macOS.

### 1. Instale o comando

Na pasta do projeto (com [Make](https://www.gnu.org/software/make/) instalado):

```sh
make install
```

Isso coloca o comando `dw` no PATH. Passo a passo completo: 👉 [INSTALL.md](INSTALL.md)

Sem Make:

| Sistema | Instalar | Rodar sem instalar |
| --- | --- | --- |
| Windows | `powershell -File .\scripts\install.ps1` | `.\dw.cmd --help` |
| Linux/macOS | `sh ./scripts/install.sh` | `./dw --help` |

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

> 🔐 Troque `dw_live_...` pela sua chave real. Voce tambem pode copiar `.env.example` para `.env`.

---

### 3. Teste se instalou certo

Feche o terminal, abra de novo e rode:

```sh
dw --help
```

Ou, ainda na pasta do projeto:

```sh
make help
make usage
```

Se aparecer a ajuda, deu certo. 🎉

---

## 🎛️ Modos de uso

Ha tres formas equivalentes de chamar a ferramenta.

### A) Comando instalado (qualquer pasta)

Depois de `make install`:

```sh
dw --help
dw --mode me
dw --mode usage
dw --mode models
```

### B) Make (pasta do repositorio)

| Comando | O que faz |
| --- | --- |
| `make install` | Instala `dw` (detecta Windows/Unix) |
| `make uninstall` | Remove `dw` |
| `make me` | Conta (`/v1/me`) |
| `make usage` | Consumo (`/v1/usage`) |
| `make models` | Modelos (`/v1/models`) |
| `make dw MODE=usage` | Mesmo que `make usage` |
| `make test` | Testes Pester |
| `make help` | Ajuda do Makefile |

### C) Sem instalar (pasta do projeto)

| Sistema | Exemplo |
| --- | --- |
| Windows | `.\dw.cmd --mode usage` |
| Linux/macOS / Git Bash | `./dw --mode usage` |

---

## 🧩 Modos da API

| Modo | Endpoint | O que faz |
| --- | --- | --- |
| `me` | `/v1/me` | Mostra dados da conta |
| `usage` | `/v1/usage` | Mostra o proprio consumo (`1h` / `6h` / `24h`) |
| `models` | `/v1/models` | Lista os modelos disponiveis |
| `help` | — | Mostra a ajuda (igual a `--help`) |

### 📊 Detalhe do modo `usage`

```sh
dw --mode usage
# ou
make usage
```

Consulta `/v1/usage` e mostra o consumo parseado (sem JSON cru):

| Coluna | Significado |
| --- | --- |
| Janela | Periodo: `1h`, `6h` ou `24h` |
| Uso | Quantidade usada / limite |
| % | Percentual do limite |
| Nivel | `livre`, `baixo`, `medio`, `alto`, `critico` |
| Reset | Tempo relativo ate o reset (com horario) |

---

## 🔑 Como a chave da API é lida

Ordem de busca:

1. `ANTHROPIC_API_KEY`
2. `DW_API_KEY`
3. arquivo `.env` na pasta atual
4. arquivo `.env` na raiz do projeto (ou na pasta do comando instalado)

Exemplo:

```env
ANTHROPIC_API_KEY=dw_live_...
```

---

## 📁 Estrutura do projeto

```text
dw-api-tools/
  Makefile               # make install / make usage / make dw
  dw / dw.cmd            # rodar sem instalar (detecta o SO)
  README.md / INSTALL.md
  .env.example
  src/                   # implementacao (PowerShell + shell)
  scripts/               # install, testes, dispatch
  tests/
  config/
```

Nao precisa escolher entre `.ps1` e `.sh`: use `make` ou `dw` / `dw.cmd`.

---

## ✅ Como saber se funcionou?

- `dw --help` (ou `make help`) mostra a ajuda
- `dw --mode me` retorna dados da conta
- `dw --mode usage` mostra consumo parseado
- `dw --mode models` lista os modelos

---

## 🆘 Problemas comuns

### ❌ `dw: command not found`

1. Feche e abra o terminal
2. Rode `dw --help`
3. Confirme `~/bin` (ou `%USERPROFILE%\bin`) no PATH
4. Rode `make install` de novo

### ❌ `Missing API key`

```sh
export ANTHROPIC_API_KEY="dw_live_..."
```

Ou crie um `.env` com `ANTHROPIC_API_KEY=dw_live_...`.

### ❌ `401 Unauthorized` / `403 Forbidden`

Chave encontrada, mas recusada. Confira se esta completa, ativa e sem espacos.

### ❌ Erro de conexão

Internet, firewall, DNS ou API temporariamente indisponivel.

---

## 🧼 Desinstalar

```sh
make uninstall
```

---

## 🧪 Testes unitários

```sh
make test
```

Helpers em `src/DwApiCheck.psm1`, testes em `tests/` (Pester 5+).

---

## 💡 Dica rápida

```sh
make install
dw --help
dw --mode me
dw --mode usage
dw --mode models
```

Se responderem sem erro, sua instalacao esta pronta. ✅
