# DW API Tools — um unico jeito de instalar e rodar (detecta o SO).
#
#   make install
#   make usage
#   make dw MODE=usage
#   make test
#   make uninstall

ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

ifeq ($(OS),Windows_NT)
  # Make nativo no Windows (cmd): nao depende de sh/Git Bash.
  PS := powershell -NoProfile -ExecutionPolicy Bypass -File
  DW_ENTRY := $(ROOT)/src/dw_api_check.ps1
  INSTALL_ENTRY := $(ROOT)/scripts/install.ps1
  TEST_ENTRY := $(ROOT)/scripts/Invoke-Tests.ps1
else
  DISPATCH := sh "$(ROOT)/scripts/dispatch.sh"
endif

.PHONY: help install uninstall dw run me usage models test

help:
	@echo DW API Tools
	@echo.
	@echo Instalacao:
	@echo   make install              Instala o comando dw (detecta Windows/Unix)
	@echo   make uninstall            Remove o comando instalado
	@echo.
	@echo Modos da API (atalhos):
	@echo   make me                   Conta (/v1/me)
	@echo   make usage                Consumo 1h/6h/24h (/v1/usage)
	@echo   make models               Modelos (/v1/models)
	@echo   make dw MODE=usage        Mesmo efeito via MODE=
	@echo.
	@echo Outros:
	@echo   make test                 Testes Pester
	@echo   make help                 Esta mensagem
	@echo.
	@echo Sem Make (pasta do projeto):
	@echo   .\dw.cmd --mode usage     Windows
	@echo   ./dw --mode usage         Linux/macOS / Git Bash
	@echo.
	@echo Depois de instalado (qualquer pasta):
	@echo   dw --help
	@echo   dw --mode me
	@echo   dw --mode usage
	@echo   dw --mode models

ifeq ($(OS),Windows_NT)

install:
	$(PS) "$(INSTALL_ENTRY)"

uninstall:
	$(PS) "$(INSTALL_ENTRY)" -Uninstall

# Use MODE=... (evita quebra de ARGS="--mode x" no Make do Windows).
dw run:
ifdef MODE
	$(PS) "$(DW_ENTRY)" --mode $(MODE) $(ARGS)
else
	$(PS) "$(DW_ENTRY)" $(ARGS)
endif

me:
	$(PS) "$(DW_ENTRY)" --mode me

usage:
	$(PS) "$(DW_ENTRY)" --mode usage

models:
	$(PS) "$(DW_ENTRY)" --mode models

test:
	$(PS) "$(TEST_ENTRY)"

else

install:
	@$(DISPATCH) install

uninstall:
	@$(DISPATCH) uninstall

dw run:
ifdef MODE
	@$(DISPATCH) dw --mode $(MODE) $(ARGS)
else
	@$(DISPATCH) dw $(ARGS)
endif

me:
	@$(DISPATCH) dw --mode me

usage:
	@$(DISPATCH) dw --mode usage

models:
	@$(DISPATCH) dw --mode models

test:
	@$(DISPATCH) test

endif
