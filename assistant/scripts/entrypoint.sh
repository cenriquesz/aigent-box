#!/bin/bash
set -e

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "  -> Sin API key: se iniciará login con cuenta Anthropic"
fi

# ── Inicializar configuración (solo la primera vez) ──────────
# Para actualizar en instalaciones existentes: editar también data/home/.claude/ directamente.
mkdir -p $HOME/.claude/commands $HOME/.claude/skills

if [ ! -f $HOME/.claude/settings.json ]; then
    cp /config/settings.json $HOME/.claude/settings.json
fi
# CLAUDE.md y agent.md son managed: siempre se actualizan desde config
cp /config/CLAUDE.md $HOME/.claude/CLAUDE.md
cp /config/agent.md $HOME/.claude/agent.md
# user-additions.md se monta directamente desde data/user/ via docker-compose

# Commands: añade los nuevos, no sobreescribe los existentes
for cmd in /config/commands/*; do
    name=$(basename "$cmd")
    [ ! -f "$HOME/.claude/commands/$name" ] && cp "$cmd" "$HOME/.claude/commands/$name"
done

# Skills: añade las nuevas, no sobreescribe las existentes
for skill_dir in /config/skills/*/; do
    name=$(basename "$skill_dir")
    [ ! -d "$HOME/.claude/skills/$name" ] && cp -r "$skill_dir" "$HOME/.claude/skills/$name"
done

# ── Auto-clone de app/ si existe .app-repo y la carpeta no existe aun ────────
for project_dir in /work/*/; do
    [ -d "$project_dir" ] || continue
    app_repo_file="${project_dir%/}/.app-repo"
    app_dir="${project_dir%/}/app"
    if [ -f "$app_repo_file" ] && [ ! -d "$app_dir" ]; then
        repo_url=$(cat "$app_repo_file")
        echo "  -> Clonando app: $(basename $project_dir) <- $repo_url"
        git clone "$repo_url" "$app_dir" 2>/dev/null || echo "  !! Error clonando $repo_url"
    fi
done

# ── Memoria persistente: symlinks .claude/projects -> /work/<proyecto>/memory/ ──
# Permite sincronizar memoria entre maquinas via git (memory/ vive en el repo del proyecto)
for project_dir in /work/*/; do
    [ -d "$project_dir" ] || continue
    project_name=$(basename "$project_dir")
    project_memory="${project_dir%/}/memory"
    harness_memory="$HOME/.claude/projects/-work-${project_name}/memory"

    # Ya es symlink correcto, nada que hacer
    if [ -L "$harness_memory" ] && [ "$(readlink "$harness_memory")" = "$project_memory" ]; then
        continue
    fi

    # Crear carpeta memory en el proyecto si no existe
    mkdir -p "$project_memory"

    # Migrar ficheros del harness al proyecto (el proyecto tiene prioridad si hay conflicto)
    migrated=false
    if [ -d "$harness_memory" ] && [ ! -L "$harness_memory" ]; then
        for f in "$harness_memory"/*; do
            [ -f "$f" ] || continue
            fname=$(basename "$f")
            [ ! -f "$project_memory/$fname" ] && cp "$f" "$project_memory/$fname"
        done
        rm -rf "$harness_memory"
        migrated=true
    fi

    mkdir -p "$(dirname "$harness_memory")"
    ln -sf "$project_memory" "$harness_memory"

    if [ "$migrated" = true ]; then
        echo "  -> Memoria migrada: $project_name"
    else
        echo "  -> Memoria enlazada: $project_name"
    fi
done

# ── Bienvenida ───────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════╗"
echo "║        Claude Code Assistant         ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "  Modelo : ${CLAUDE_MODEL:-claude-sonnet-4-6}"
echo "  Work   : /work"
echo "  Docker : $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')"
echo "  AWS    : ${AWS_PROFILE:-default}"
echo ""

# ── Arranque ─────────────────────────────────────────────────
if [ $# -gt 0 ]; then
    exec "$@"
fi

if [ -n "$PROJECT" ]; then
    PROJECT_DIR="/work/$PROJECT"
    IS_NEW=false
    if [ ! -d "$PROJECT_DIR" ]; then
        mkdir -p "$PROJECT_DIR"
        IS_NEW=true
    fi
    cd "$PROJECT_DIR"

    # Scaffolding del arnés en proyectos nuevos
    if [ "$IS_NEW" = true ]; then
        mkdir -p progress memory
        for tpl in CLAUDE.md agent.md tasks.md; do
            [ ! -f "$tpl" ] && [ -f "/config/templates/$tpl" ] && cp "/config/templates/$tpl" "$tpl"
        done
        echo "  -> Proyecto creado: $PROJECT_DIR"
        echo "  -> Arnés inicializado (agent.md, tasks.md, memory/, progress/)"
        echo "  -> agent.md listo para rellenar - el asistente te entrevistará al arrancar"
    else
        if [ ! -f "CLAUDE.md" ] && [ -f "/config/templates/CLAUDE.md" ]; then
            cp "/config/templates/CLAUDE.md" "CLAUDE.md"
            echo "  -> CLAUDE.md añadido al proyecto existente"
        fi
    fi

    echo "  Proyecto: $PROJECT"
else
    PROJECT_DIR="/work"
    echo "  Proyecto: /work (global)"
fi

# Pre-confiar en el directorio del proyecto para evitar el diálogo de confianza
CLAUDE_JSON="$HOME/.claude.json"
if [ ! -f "$CLAUDE_JSON" ]; then
    echo '{}' > "$CLAUDE_JSON"
fi
jq --arg p "$PROJECT_DIR" '.projects[$p].hasTrustDialogAccepted = true' "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" \
    && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"

echo ""

# Arrancar con prompt inicial si agent.md del proyecto está sin rellenar
INITIAL_PROMPT=""
if [ -n "$PROJECT" ] && [ -f "$PROJECT_DIR/agent.md" ] && grep -q '\[Nombre del proyecto\]' "$PROJECT_DIR/agent.md"; then
    INITIAL_PROMPT="Empecemos con el nuevo proyecto."
fi

if [ -n "$INITIAL_PROMPT" ]; then
    exec claude --dangerously-skip-permissions --model "${CLAUDE_MODEL:-claude-sonnet-4-6}" "$INITIAL_PROMPT"
else
    exec claude --dangerously-skip-permissions --model "${CLAUDE_MODEL:-claude-sonnet-4-6}"
fi
