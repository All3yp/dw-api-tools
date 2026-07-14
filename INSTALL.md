# Guia de Instalacao — DW API Tools

Este guia mostra como instalar o comando `dw` para usar em qualquer
pasta do computador.

> Passo a passo para usuarios leigos: copiar, colar e testar.

---

## O que vem neste pacote?

Na raiz (o que voce usa):

- `Makefile` — `make install`, `make usage`, `make dw MODE=...`
- `dw` / `dw.cmd` — rodar sem instalar (detecta o sistema)

Interno: `src/` (codigo), `scripts/` (instalador e testes).

---

## Antes de comecar: tenha sua chave da API

Voce precisa de uma chave parecida com:

```text
dw_live_...
```

A ferramenta usa principalmente:

```text
ANTHROPIC_API_KEY
```

---

## Caminho rapido (recomendado)

Na pasta do projeto, com Make instalado:

```sh
make install
```

O Make detecta Windows ou Linux/macOS e chama o instalador certo.
Depois feche e abra o terminal e teste:

```sh
dw --help
dw --mode me
```

Sem Make:

| Sistema | Comando |
| --- | --- |
| Windows PowerShell | `powershell -File .\scripts\install.ps1` |
| Linux/macOS | `sh ./scripts/install.sh` |

---

## Modos de uso (resumo)

| Forma | Exemplos |
| --- | --- |
| Instalado | `dw --mode me`, `dw --mode usage`, `dw --help` |
| Make | `make me`, `make usage`, `make models`, `make dw MODE=usage` |
| Sem instalar (Windows) | `.\dw.cmd --mode usage` |
| Sem instalar (Unix) | `./dw --mode usage` |

Modos da API: `me`, `usage`, `models`, `help`.

---

## Instalacao no Windows (detalhes)

### 1. Abra o PowerShell

Procure por **PowerShell** no menu iniciar.

### 2. Entre na pasta do projeto

```powershell
cd C:\Users\SeuUsuario\Downloads\dw-api-tools
```

### 3. Instale

```powershell
make install
```

Ou direto:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
powershell -File .\scripts\install.ps1
```

O instalador:

1. Copia `dw.ps1` e `DwApiCheck.psm1` para `%USERPROFILE%\bin`
2. Adiciona essa pasta ao PATH do usuario
3. Tenta registrar o comando no profile do PowerShell

### 4. Feche e abra o PowerShell

### 5. Teste

```powershell
dw --help
dw --mode me
make help
```

### 6. Configure a chave

Nesta janela:

```powershell
$env:ANTHROPIC_API_KEY = "dw_live_..."
```

Permanente:

```powershell
[Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY', 'dw_live_...', 'User')
```

### Desinstalar

```powershell
make uninstall
```

---

## Instalacao no Linux/macOS (detalhes)

### 1. Abra o Terminal

### 2. Entre na pasta do projeto

```sh
cd ~/Downloads/dw-api-tools
```

### 3. Instale

```sh
make install
```

Ou:

```sh
chmod +x ./dw ./scripts/dispatch.sh ./scripts/install.sh
sh ./scripts/install.sh
```

O comando fica em `~/bin/dw`.

### 4. Feche e abra o terminal; teste

```sh
dw --help
dw --mode me
make help
```

### 5. Configure a chave

```sh
export ANTHROPIC_API_KEY="dw_live_..."
```

Para salvar, coloque a linha no `~/.bashrc` ou `~/.zshrc`.

### Desinstalar

```sh
make uninstall
```

---

## Rodar sem instalar

Ainda na pasta do projeto:

```sh
make me
make usage
make models
make dw MODE=help
make help
```

Ou:

| Sistema | Comando |
| --- | --- |
| Windows | `.\dw.cmd --mode usage` |
| Linux/macOS / Git Bash | `./dw --mode usage` |

---

## Alternativa: arquivo `.env`

Crie `.env` na raiz do projeto (ou copie de `.env.example`):

```env
ANTHROPIC_API_KEY=dw_live_...
```

Depois:

```sh
dw --mode me
```

---

## Testes recomendados

```sh
dw --help
dw --mode me
dw --mode usage
dw --mode models
```

Unitarios (Pester):

```sh
make test
```

---

## Problemas comuns

### O comando `dw` nao foi encontrado

1. Fechar e abrir o terminal
2. Rodar `dw --help`
3. Confirmar que `~/bin` (ou `%USERPROFILE%\bin`) esta no PATH
4. Rodar `make install` de novo

### A chave da API nao foi encontrada

```sh
export ANTHROPIC_API_KEY="dw_live_..."
```

Ou use um arquivo `.env`.

### A API retornou `Unauthorized` ou `Forbidden`

Confira se a chave esta completa, ativa e sem espacos extras.

### O Windows bloqueou o script

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
```

---

## Resumo rapido

```sh
make install
# configure ANTHROPIC_API_KEY
dw --mode me
dw --mode usage
make models
```
