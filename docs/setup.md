# Configuración inicial

## Requisitos

- Docker Desktop instalado y corriendo
- Make
- Cuenta de Anthropic (para OAuth) o API key

## Instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/tu-usuario/claubox
cd claubox

# 2. Crear fichero de variables
cp .env.example .env

# 3. Editar .env según tus necesidades
#    Ver sección "Variables" más abajo

# 4. Construir la imagen
make build
```

## Variables de entorno (`.env`)

**Autenticación y servicios:**

| Variable | Requerida | Descripción |
|---|---|---|
| `ANTHROPIC_API_KEY` | No | API key. Si se omite, Claude usará OAuth |
| `AWS_PROFILE` | No | Perfil de AWS a usar. Default: `default` |
| `BRAVE_API_KEY` | No | Para el MCP de búsqueda web |
| `GITHUB_TOKEN` | No | Para el MCP de GitHub |

**Modelos por comando (configurables sin tocar el Makefile):**

| Variable | Default | Comando |
|---|---|---|
| `ROLE_CHAT` | `claude-haiku-4-5-20251001` | `make chat` |
| `ROLE_RUN` | `claude-sonnet-5` | `make run` |
| `ROLE_ORCH` | `claude-opus-4-8` | `make orch` |

**Modelos de sub-agentes (usados internamente por el orquestador):**

Track de desarrollo:

| Variable | Default | Rol |
|---|---|---|
| `ROLE_SCOUT` | `claude-haiku-4-5-20251001` | Explora código existente |
| `ROLE_ARCHITECT` | `claude-sonnet-5` | Diseña la solución |
| `ROLE_IMPLEMENTER` | `claude-sonnet-5` | Escribe código |
| `ROLE_TESTER` | `claude-sonnet-5` | Crea suites de test |
| `ROLE_REVIEWER` | `claude-sonnet-5` | Ejecuta tests y valida |
| `ROLE_FIXER` | `claude-sonnet-5` | Corrige lo rechazado por el reviewer |

Tracks adicionales:

| Variable | Default | Rol |
|---|---|---|
| `ROLE_DOCUMENTER` | `claude-sonnet-5` | Documentación técnica |
| `ROLE_ANALYST` | `claude-sonnet-5` | Análisis de datos |
| `ROLE_REPORTER` | `claude-haiku-4-5-20251001` | Documentos para personas |
| `ROLE_INFRA` | `claude-sonnet-5` | Infraestructura (K8s, AWS, Docker) |

## Primer arranque - Login OAuth

Si no tienes `ANTHROPIC_API_KEY`, al arrancar Claude mostrará una URL. Ábrela en tu navegador, haz login con tu cuenta de Anthropic y las credenciales se guardarán en `data/home/.claude/` para todas las sesiones futuras.

## Configuración global - ficheros managed y del usuario

Los ficheros de `~/.claude/` tienen comportamientos distintos en cada arranque:

| Fichero | Comportamiento | Editable |
|---|---|---|
| `CLAUDE.md` | **Siempre** se sobreescribe desde `config/` | No - los cambios se pierden al reiniciar |
| `agent.md` | **Siempre** se sobreescribe desde `config/` | No - los cambios se pierden al reiniciar |
| `settings.json` | Solo se crea si no existe | Si - edita `data/home/.claude/settings.json` |
| `user-additions.md` | Montado desde `data/user/` via Docker | Si - edita `data/user/user-additions.md` |

### Añadir preferencias globales

Para que algo aplique "siempre, en cualquier proyecto", edita `data/user/user-additions.md` o pídele al asistente que lo añada ahí. Este fichero se monta directamente en el contenedor, persiste entre reinicios y se importa automáticamente en cada sesión.

Ejemplos de qué poner en `user-additions.md`:
- Convenciones de código preferidas
- Herramientas o librerías por defecto
- Comportamientos específicos de tu flujo de trabajo

### Propagar cambios al sistema

- **`CLAUDE.md` / `agent.md`**: edita en `assistant/config/` y los cambios se aplican en el **próximo arranque** del contenedor sin necesidad de `make build`.
- **`settings.json`**: edita directamente en `data/home/.claude/settings.json` para la instalación actual, y en `assistant/config/settings.json` para que nuevas instalaciones la tengan.

Lo que **nunca** se toca automáticamente: `.claude.json` (credenciales OAuth). La carpeta `.claude/projects/` contiene las sesiones y los symlinks a `memory/` de cada proyecto - no tocar directamente.

## Montar proyectos del Mac

Para trabajar en proyectos que ya tienes en el Mac, añade un volumen en `docker-compose.yml`:

```yaml
volumes:
  - ~/mis-proyectos:/work/proyectos
```

Luego: `make run PROJECT=proyectos/mi-app`
