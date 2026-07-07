FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV LANG=C.UTF-8

# --------------------------------------------------------------
# 1. SISTEMA BASE
# --------------------------------------------------------------
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    curl wget git build-essential ca-certificates \
    unzip zip jq vim nano \
    gnupg lsb-release \
    ssh iputils-ping net-tools dnsutils \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------
# 2. RUNTIMES - Python · Java · Node.js
# --------------------------------------------------------------

# Chromium nativo (sin snap) - para scripts propios
RUN apt-get update && apt-get install -y chromium \
    && rm -rf /var/lib/apt/lists/*

# Python 3
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv python3-dev \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3 /usr/bin/python

RUN pip3 install --break-system-packages \
    python-docx python-pptx \
    pandas numpy matplotlib seaborn \
    boto3 requests httpx \
    pillow \
    jupyter ipykernel \
    black ruff \
    markitdown[all] \
    graphifyy

# Java 21 LTS via Eclipse Temurin (soporta amd64 y arm64)
RUN curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | \
    gpg --dearmor -o /usr/share/keyrings/adoptium.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" \
    | tee /etc/apt/sources.list.d/adoptium.list && \
    apt-get update && apt-get install -y temurin-21-jdk \
    && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH=amd64
ENV JAVA_HOME=/usr/lib/jvm/temurin-21-jdk-${TARGETARCH}

# Maven
RUN apt-get update && apt-get install -y maven \
    && rm -rf /var/lib/apt/lists/*

# Node.js 22 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------
# 3. HERRAMIENTAS CLOUD Y DEVOPS
# --------------------------------------------------------------

# AWS CLI v2 (multi-arch)
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip; \
    else \
        curl -s "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o awscliv2.zip; \
    fi && \
    unzip -q awscliv2.zip && ./aws/install && rm -rf awscliv2.zip aws/

# Docker CLI (solo cliente, daemon en el host)
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bookworm stable" \
    | tee /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# kubectl
RUN ARCH=$(dpkg --print-architecture) && \
    curl -sLO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Helm
RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# --------------------------------------------------------------
# 4. CLAUDE CODE + MCP SERVERS
# --------------------------------------------------------------

# Claude Code CLI + herramientas de desarrollo
RUN npm install -g @anthropic-ai/claude-code@2.1.162 repomix

# MCP Servers npm - pre-instalados para no descargar en runtime
RUN npm install -g \
    @modelcontextprotocol/server-filesystem

# GitHub MCP oficial - binario Go, multi-arch
RUN ARCH=$(dpkg --print-architecture) && \
    [ "$ARCH" = "amd64" ] && GOARCH="x86_64" || GOARCH="$ARCH" && \
    GH_MCP_VER=$(curl -s https://api.github.com/repos/github/github-mcp-server/releases/latest | jq -r '.tag_name') && \
    curl -sL "https://github.com/github/github-mcp-server/releases/download/${GH_MCP_VER}/github-mcp-server_Linux_${GOARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin github-mcp-server

# Playwright stealth MCP - navegación web sin detección anti-bot
# Browsers en /opt para que el usuario assistant los encuentre sin descargar nada
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers
RUN npm install -g @prakhar1/playwright-stealth-mcp && \
    mkdir -p /opt/playwright-browsers && \
    npx playwright install chromium && \
    npx playwright install-deps chromium && \
    chmod -R 755 /opt/playwright-browsers

# --------------------------------------------------------------
# 5. CONFIGURACIÓN INICIAL Y SKILLS
# --------------------------------------------------------------

# Skills de comunidad - instaladas en build, sin necesitar red al arrancar
# Se hace antes del COPY: capa de caché independiente, no se invalida al editar config
RUN git clone --depth 1 https://github.com/blader/humanizer.git /config/skills/humanizer
RUN git clone --depth 1 https://github.com/SpillwaveSolutions/document-specialist-skill.git /config/skills/document-specialist-skill

# Graphify skill - extraída del paquete pip ya instalado
RUN mkdir -p /config/skills/graphify && \
    python3 -c "import graphify, shutil, os; shutil.copy(os.path.join(os.path.dirname(graphify.__file__), 'skill.md'), '/config/skills/graphify/SKILL.md')"

# Mermaid skill - diagramas de arquitectura, secuencia, clases, ER, etc.
RUN mkdir -p /config/skills/mermaid-skill && \
    curl -fsSL https://raw.githubusercontent.com/Agents365-ai/mermaid-skill/main/skills/mermaid-skill/SKILL.md \
    > /config/skills/mermaid-skill/SKILL.md

# Configuración base - se copia al volumen solo si no existe (primera vez)
COPY config/ /config/

COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Tools propias - todos los ficheros de tools/ van a /usr/local/bin con permisos de ejecución
COPY --chmod=755 tools/ /usr/local/bin/

# --------------------------------------------------------------
# 6. USUARIO
# --------------------------------------------------------------

# Usuario no-root - Claude Code rechaza --dangerously-skip-permissions como root (uid 0)
RUN useradd -m -u 1000 -s /bin/bash assistant && \
    echo "assistant ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /work && chown assistant:assistant /work

USER assistant
WORKDIR /work

ENTRYPOINT ["/entrypoint.sh"]
