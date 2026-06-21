# Trabajar con proyectos

## Concepto

Cada subdirectorio de `/work` es un proyecto independiente con su propio arnés: contexto, memoria, tareas y carpeta de progreso para sub-agentes. Claude arranca posicionado en ese directorio y acumula conocimiento entre sesiones.

```
data/work/
├── api-backend/       # make run/orch PROJECT=api-backend
├── analisis-ventas/   # make run/orch PROJECT=analisis-ventas
└── chat/              # make chat (siempre este, con Haiku)
```

## Arrancar en un proyecto

```bash
make chat                    # Haiku - preguntas rápidas (/work/chat)
make run   PROJECT=mi-app    # Sonnet - planifica y orquesta sub-agentes
make orch  PROJECT=mi-app    # Opus   - orquestación compleja, máximo paralelismo
```

**Proyectos nuevos:** si `agent.md` está vacío (contiene la plantilla), el asistente entrevista al usuario directamente al arrancar, genera el `agent.md` y procede con la planificación y orquestación. No hace falta ningún paso previo.

**¿`run` o `orch`?** El asistente lo evalúa al planificar: Sonnet para tareas secuenciales (<8 tareas, un track), Opus para múltiples tracks paralelos o proyectos grandes. Si arrancaste con `make run` pero el proyecto necesita Opus, el asistente te lo indicará.

## Arnés del proyecto

Al crear un proyecto nuevo, el entrypoint scaffoldea automáticamente su arnés:

```
data/work/mi-app/
├── CLAUDE.md    <- carga agent.md vía @ import (generado automáticamente - no editar)
├── agent.md     <- qué construir, stack, convenciones, criterios de validación
├── memory/      <- memoria entre sesiones, versionada en git (ver más abajo)
├── tasks.md     <- estado de tareas (pendiente / en progreso / completado)
└── progress/    <- resultados de sub-agentes (scout, architect, implementer, reviewer...)
```

### CLAUDE.md - punto de entrada del proyecto

Generado automáticamente al crear el proyecto. Contiene únicamente `@agent.md`, que hace que Claude Code cargue el contexto del proyecto de forma garantizada al arrancar la sesión - sin depender de instrucciones de texto.

Puedes editarlo si necesitas añadir imports adicionales, pero si eliminas `@agent.md` el asistente arrancará sin contexto del proyecto.

### agent.md - el arnés

Es el fichero más importante. Define el proyecto de forma que cualquier agente pueda entenderlo sin leer el código entero:

- Qué se construye y para qué
- Stack tecnológico
- Convenciones del proyecto
- Criterios de validación (¿cuándo está "hecho"?)
- Qué no tocar

El asistente lo genera mediante entrevista al arrancar en un proyecto nuevo. Si el proyecto ya tiene código, lo analiza antes de preguntar.

### memory/ - memoria entre sesiones

Carpeta versionada en git que acumula lo que no es obvio leyendo el código: decisiones de arquitectura, restricciones, contexto de negocio. Formato de cada entrada: **qué** -> **por qué** -> **cómo aplicar**.

El harness carga el índice (`memory/MEMORY.md`) automáticamente en cada sesión. El contenido se escribe durante la sesión sin intervención manual.

Al estar en git, la memoria se sincroniza entre máquinas con un simple `git pull`.

### tasks.md - estado de tareas

El orquestador lo lee al arrancar y lo actualiza durante la sesión:

```markdown
## Pendiente
- [ ] Implementar endpoints CRUD de usuarios

## En progreso
- [ ] Diseño del esquema de base de datos

## Completado
- [x] Scaffold inicial del proyecto
```

### progress/ - trazabilidad de sub-agentes

Cada sub-agente escribe su resultado aquí antes de terminar. El siguiente agente lee solo lo que necesita, sin releer el codebase entero:

```
progress/
├── 01-scout-auth.md       <- "El módulo auth usa JWT, está en src/auth/..."
├── 02-architect-users.md  <- "Esquema propuesto: tabla users con campos..."
├── 03-impl-crud.md        <- "Implementados GET/POST/PUT/DELETE en users/router.py"
├── 04-tester-crud.md      <- "Suite de tests en tests/test_users.py, 12 casos"
└── 05-reviewer-crud.md    <- "Tests pasan. Falta validación de email."
```

## Sistema multi-agente

Al usar `make run` o `make orch`, el orquestador gestiona internamente sub-agentes por rol:

### Track de desarrollo

| Rol | Modelo | Qué hace |
|---|---|---|
| scout | Haiku | Explora código existente; usa graphify en proyectos grandes |
| architect | Sonnet | Diseña la solución; análisis de impacto con graphify |
| implementer | Sonnet | Escribe código; puede correr en paralelo si las tareas son independientes |
| tester | Sonnet | Crea suites de test (unit, integration, e2e) |
| reviewer | Sonnet | Ejecuta tests, valida contra requisitos, aprueba o rechaza con motivo |
| fixer | Sonnet | Corrige exactamente lo que rechazó el reviewer |

### Tracks adicionales

| Rol | Modelo | Qué hace |
|---|---|---|
| documenter | Sonnet | Docs técnicas con graphify + repomix |
| analyst | Sonnet | Análisis de datos con pandas/matplotlib |
| reporter | Haiku | Genera documentos para personas; aplica /humanizer |
| infra | Sonnet | Kubernetes, Helm, Docker, AWS |

El ciclo reviewer->fixer se repite máximo 3 veces por tarea. Si persiste el fallo, el orquestador para y reporta al usuario.

Los modelos son configurables en `.env` (ver `docs/setup.md`).

## Eliminar un proyecto

Los datos de sesiones y memoria interna viven en `data/home/.claude/projects/`. La ruta se codifica reemplazando `/` por `-`:

```bash
# /work/mi-app -> -work-mi-app
rm -rf data/home/.claude/projects/-work-mi-app
```

Los ficheros del proyecto en `data/work/mi-app` (agent.md, memory/, código...) no se tocan - son independientes.

## Proyectos del Mac montados como volumen

Los proyectos que ya existen en tu Mac se montan directamente en `/work`:

```yaml
# docker-compose.yml
volumes:
  - ~/code:/work/code
```

```bash
make run PROJECT=code/mi-startup
```

El `agent.md` que se genere viajará con tu repo en git.
