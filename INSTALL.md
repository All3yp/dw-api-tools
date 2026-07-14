# 🛠️ Guia de Instalação — DW API Tools

Este guia mostra como instalar o comando `dw_api_check` para usar em qualquer pasta do computador.

> Este passo a passo foi feito para usuários leigos. Basta copiar e colar os comandos.

---

## 📦 O que vem neste pacote?

- 🪟 `dw_api_check.ps1` — script para Windows PowerShell
- 🐧 `dw_api_check.sh` — script para Linux/macOS
- 🪟 `install.ps1` — instalador para Windows
- 🐧 `install.sh` — instalador para Linux/macOS

---

## 🔑 Antes de começar: tenha sua chave da API

Você precisa de uma chave parecida com:

```text
dw_live_...
```

A ferramenta usa principalmente a variável:

```text
ANTHROPIC_API_KEY
```

---

# 🪟 Instalação no Windows

## 1. Abra o PowerShell

Procure por **PowerShell** no menu iniciar.

---

## 2. Entre na pasta do projeto

Exemplo:

```powershell
cd C:\Users\SeuUsuario\Downloads\dw-api-tools
```

> Ajuste o caminho conforme a pasta onde você baixou os arquivos.

---

## 3. Rode o instalador

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install.ps1
```

O instalador faz 3 coisas:

1. Copia `dw_api_check.ps1` e `DwApiCheck.psm1` para `%USERPROFILE%\bin`
2. Adiciona essa pasta ao **PATH do usuário** (cmd, PowerShell, Windows Terminal)
3. Registra o comando no **profile do PowerShell**, para funcionar mesmo sem depender do PATH

Depois disso, você pode rodar `dw_api_check` de **qualquer pasta**, sem entrar de novo no repositório.

---

## 4. Feche e abra o PowerShell novamente

Isso ajuda o Windows a carregar o PATH e o profile novos.

---

## 5. Teste a instalação

```powershell
dw_api_check --help
```

Se aparecer a ajuda do programa, deu certo. 🎉

---

## 6. Configure sua chave da API

Para configurar apenas no terminal atual:

```powershell
$env:ANTHROPIC_API_KEY = "dw_live_..."
```

Para salvar de forma permanente no seu usuário:

```powershell
[Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY', 'dw_live_...', 'User')
```

Depois de salvar de forma permanente, feche e abra o PowerShell novamente.

---

## 7. Faça um teste real

```powershell
dw_api_check --mode me
```

Se retornar dados da sua conta, está tudo funcionando. ✅

---

## 🧼 Desinstalar no Windows

```powershell
.\install.ps1 -Uninstall
```

---

# 🐧 Instalação no Linux/macOS

## 1. Abra o Terminal

Use o aplicativo **Terminal**.

---

## 2. Entre na pasta do projeto

Exemplo:

```sh
cd ~/Downloads/dw-api-tools
```

---

## 3. Dê permissão de execução

```sh
chmod +x ./install.sh ./dw_api_check.sh
```

---

## 4. Rode o instalador

```sh
./install.sh
```

O instalador vai copiar o script para:

```text
~/bin
```

E criar o comando:

```text
dw_api_check
```

---

## 5. Feche e abra o terminal novamente

Depois teste:

```sh
dw_api_check --help
```

Se aparecer a ajuda do programa, deu certo. 🎉

---

## 6. Configure sua chave da API

```sh
export ANTHROPIC_API_KEY="dw_live_..."
```

Para salvar permanentemente, adicione essa linha ao arquivo de configuração do seu shell, como `~/.bashrc`, `~/.zshrc` ou equivalente.

---

## 7. Faça um teste real

```sh
dw_api_check --mode me
```

Se retornar dados da sua conta, está tudo funcionando. ✅

---

## 🧼 Desinstalar no Linux/macOS

```sh
UNINSTALL=1 ./install.sh
```

---

# 📄 Alternativa: usar arquivo `.env`

Se você não quiser configurar variável no terminal, crie um arquivo chamado `.env` na mesma pasta do script.

Conteúdo do arquivo:

```env
ANTHROPIC_API_KEY=dw_live_...
```

Depois rode:

```sh
dw_api_check --mode me
```

---

# 🧪 Testes recomendados

Rode estes comandos:

```sh
dw_api_check --help
dw_api_check --mode me
dw_api_check --mode usage
dw_api_check --mode models
```

---

# 🆘 Problemas comuns

## ❌ O comando `dw_api_check` não foi encontrado

Tente:

1. Fechar o terminal
2. Abrir novamente
3. Rodar:

```sh
dw_api_check --help
```

No Linux/macOS, veja também se `~/bin` está no seu `PATH`.

---

## ❌ A chave da API não foi encontrada

Configure a chave:

```sh
export ANTHROPIC_API_KEY="dw_live_..."
```

Ou use um arquivo `.env`.

---

## ❌ A API retornou `Unauthorized` ou `Forbidden`

A chave existe, mas foi recusada.

Confira se:

- você copiou a chave inteira
- a chave está ativa
- não há espaços extras
- você está usando a chave correta

---

## ❌ O Windows bloqueou o script

Execute no PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
```

Depois rode o instalador novamente.

---

# ✅ Resumo rápido

Linux/macOS:

```sh
chmod +x ./install.sh ./dw_api_check.sh
./install.sh
export ANTHROPIC_API_KEY="dw_live_..."
dw_api_check --mode me
```

Windows PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install.ps1
$env:ANTHROPIC_API_KEY = "dw_live_..."
dw_api_check --mode me
```
