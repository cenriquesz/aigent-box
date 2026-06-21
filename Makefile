COMPOSE = docker compose --project-directory . -f assistant/docker-compose.yml
PROJECT ?=

# Carga variables del .env si existe
-include .env
export

.DEFAULT_GOAL := help

help:
	@echo ""
	@echo "  claubox - Claude Code en Docker"
	@echo ""
	@echo "  Uso:"
	@echo "    make build                   Construir la imagen"
	@echo "    make rebuild                 Reconstruir desde cero (sin caché)"
	@echo "    make chat                    Haiku  - preguntas rápidas (/work/chat)"
	@echo "    make run   [PROJECT=nombre]  Sonnet - planifica y orquesta sub-agentes"
	@echo "    make orch  [PROJECT=nombre]  Opus   - orquestación compleja, máximo paralelismo"
	@echo "    make shell                   bash   - mantenimiento del contenedor"
	@echo "    make update                  Sincronizar con el repo original (upstream)"
	@echo ""

build:
	$(COMPOSE) build

rebuild:
	$(COMPOSE) build --no-cache

chat:
	$(COMPOSE) run --rm -e CLAUDE_MODEL=$(ROLE_CHAT) -e PROJECT=chat claude

run:
	@if [ -z "$(PROJECT)" ]; then \
	  read -p "Proyecto: " p; \
	  $(COMPOSE) run --rm -e CLAUDE_MODEL=$(ROLE_RUN) -e PROJECT=$$p claude; \
	else \
	  $(COMPOSE) run --rm -e CLAUDE_MODEL=$(ROLE_RUN) -e PROJECT=$(PROJECT) claude; \
	fi

orch:
	@if [ -z "$(PROJECT)" ]; then \
	  read -p "Proyecto: " p; \
	  $(COMPOSE) run --rm -e CLAUDE_MODEL=$(ROLE_ORCH) -e PROJECT=$$p claude; \
	else \
	  $(COMPOSE) run --rm -e CLAUDE_MODEL=$(ROLE_ORCH) -e PROJECT=$(PROJECT) claude; \
	fi

shell:
	$(COMPOSE) run --rm claude bash

update:
	@if ! git remote get-url upstream > /dev/null 2>&1; then \
	  git remote add upstream https://github.com/cenriquesz/aigent-box.git; \
	  echo "  -> Remote 'upstream' configurado"; \
	fi
	@if [ "$$(git branch --show-current)" != "main" ]; then \
	  echo "  ✗ Cambia a la rama main antes de hacer update"; exit 1; \
	fi
	git fetch upstream
	git merge upstream/main

.PHONY: help build rebuild chat run orch shell update
