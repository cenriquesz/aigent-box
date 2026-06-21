# claubox

Claude Code corriendo en Docker como asistente personal persistente. Memoria, sesiones y configuración sobreviven reinicios del contenedor gracias a volúmenes mapeados al host.

---

## Inicio rápido

```bash
cp .env.example .env   # configurar variables (ver docs/setup.md)
make build             # construir la imagen
make chat              # arrancar
```

---

## Uso con fork

claubox está diseñado para ser forkeado: cada usuario mantiene su propia configuración y proyectos en su fork, y puede traerse mejoras del repo original sin perder nada.

**Primera vez:**

1. Haz fork del repo en GitHub
2. Clona tu fork y configura:
   ```bash
   git clone https://github.com/tu-usuario/claubox.git
   cd claubox
   cp .env.example .env   # añade tu API key o deja vacío para OAuth
   make build
   make run PROJECT=mi-proyecto
   ```

**Tus ficheros (commitable en tu fork, nunca tocados por upstream):**

| Ruta | Contenido |
|---|---|
| `data/user/user-additions.md` | Tus preferencias globales del asistente |
| `data/work/` | Tus proyectos de trabajo |

Commitea y pushea a tu fork libremente. Upstream nunca toca esas rutas, así que no habrá conflictos.

**Cuando el repo original tenga actualizaciones:**

```bash
make update   # añade upstream si no existe y hace git merge
```

---

## Comandos

```bash
make chat              # Haiku  - chat cotidiano, siempre en /work/chat
make run               # Sonnet - uso general y planificación
make orch              # Opus   - orquestación compleja, máximo paralelismo
make shell             # bash   - mantenimiento del contenedor
make update            # sincronizar con el repo original (upstream)

make run PROJECT=nombre   # arranca en /work/nombre con su propia memoria
make orch PROJECT=nombre
```

---

## Conceptos clave

### Proyectos

Cada subdirectorio de `/work` es un proyecto independiente. Al arrancar en uno nuevo, el asistente scaffoldea automáticamente su arnés y entrevista al usuario para rellenar el `agent.md`:

```
data/work/mi-app/
├── CLAUDE.md    <- carga el contexto del proyecto vía @ import (no editar)
├── agent.md     <- qué construir, stack, convenciones, criterios de validación
├── memory.md    <- contexto acumulado entre sesiones
├── tasks.md     <- estado de tareas
└── progress/    <- resultados de sub-agentes
```

Ver [docs/projects.md](docs/projects.md) para detalle del sistema de proyectos y multi-agente.

### Configuración global

Los ficheros de configuración en `~/.claude/` tienen dos categorías:

| Fichero | Tipo | Comportamiento |
|---|---|---|
| `CLAUDE.md` | managed | Se sobreescribe en cada arranque - no editar |
| `agent.md` | managed | Se sobreescribe en cada arranque - no editar |
| `settings.json` | semi-managed | Solo se crea si no existe - editable |
| `user-additions.md` | tuyo | Vive en `data/user/` - commitable en tu fork |

**Para añadir preferencias globales** ("hazlo siempre", "en cualquier proyecto"): pídele al asistente que lo añada o edita directamente `data/user/user-additions.md`. El asistente sabe que debe escribir ahí y nunca en los ficheros managed.

Ver [docs/setup.md](docs/setup.md) para variables, modelos y login OAuth.

### Multi-agente

`make run` y `make orch` orquestan sub-agentes internos por rol (scout, architect, implementer, tester, reviewer, fixer). El asistente elige el modelo adecuado según complejidad. Ver [docs/projects.md](docs/projects.md).

---

## Estructura del repo

```
claubox/
├── .env.example              # Plantilla de variables
├── Makefile                  # Comandos de uso diario
├── docs/                     # Documentación detallada
│   ├── setup.md              # Variables, modelos, OAuth, volúmenes
│   ├── projects.md           # Proyectos, memoria y multi-agente
│   └── tools.md              # Herramientas, MCPs y skills
├── data/
│   ├── home/                 # GITIGNORED - home del asistente (/home/assistant)
│   ├── user/                 # TUYO - tus preferencias globales (commitable en tu fork)
│   │   └── user-additions.md
│   └── work/                 # TUYO - tus proyectos (/work) (commitable en tu fork)
└── assistant/
    ├── Dockerfile
    ├── docker-compose.yml
    ├── scripts/entrypoint.sh
    ├── tools/                # Utilidades en /usr/local/bin
    └── config/               # Configuración base de la imagen
        ├── settings.json
        ├── CLAUDE.md         # managed - se instala y actualiza en cada arranque
        ├── agent.md          # managed - se instala y actualiza en cada arranque
        ├── commands/         # Slash commands (/estado)
        ├── skills/           # Skills (/humanizer, /graphify, /readbin, /mermaid-skill...)
        └── templates/        # Plantillas para nuevos proyectos
            ├── CLAUDE.md     # carga agent.md del proyecto vía @ import
            ├── agent.md      # plantilla de configuración del proyecto
            ├── memory.md
            └── tasks.md
```

---

## Documentación

- [Configuración inicial](docs/setup.md) - variables, modelos, OAuth, montar proyectos del Mac
- [Proyectos y memoria](docs/projects.md) - arnés, memoria entre sesiones, multi-agente
- [Herramientas y MCPs](docs/tools.md) - Python, Java, AWS CLI, markitdown, skills
