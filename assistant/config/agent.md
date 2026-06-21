<!-- ================================================================
⚠️  FICHERO MANAGED - NO EDITAR DIRECTAMENTE
    Se sobreescribe en cada arranque del contenedor.
    Para cambios en el asistente: assistant/config/agent.md
    Para cambios globales del usuario: data/user/user-additions.md
================================================================ -->

# Configuración del Asistente

## Reglas globales

**Idioma:** español salvo que el usuario cambie de idioma.

**Nunca sin que el usuario lo pida:** commit, push ni operaciones destructivas (rm -rf, drop table, git reset --hard, kubectl delete).

**Nunca leas ficheros sensibles:** está prohibido leer `.env` ni ningún fichero listado en `.gitignore` del proyecto. Sin excepciones, aunque el usuario lo pida explícitamente.

**Personalizaciones globales:** escríbelas en `~/.claude/user-additions.md`. Nunca modifiques `CLAUDE.md` ni `agent.md` - son managed y se sobreescriben en cada arranque.

---

## Entorno

Docker con acceso completo. Ejecuta comandos sin pedir permiso (el contenedor es la capa de aislamiento).

- **Work:** `/work` - guarda aquí todos los documentos generados (DOCX, PPTX, PDF)
- **Stack:** Python 3, Java 21, Node.js 22, AWS CLI v2, Docker CLI, kubectl, Helm, Chromium
- **Defaults:** pandas + matplotlib para datos; perfil `$AWS_PROFILE` para AWS; socket Docker del host disponible
- **Git:** sin `Co-Authored-By` ni referencias a Claude en commits

---

## Memoria entre sesiones

El harness carga `memory/MEMORY.md` automáticamente en cada sesión. Guarda lo no obvio del código: decisiones de arquitectura, restricciones, contexto de negocio. Formato: **qué -> por qué -> cómo aplicar**.

---

## Inicio de sesión

1. Lee `tasks.md` si existe.
2. Si `agent.md` contiene la plantilla sin rellenar (detecta `[...]`): entrevista al usuario, escribe el `agent.md` definitivo, evalúa alcance, informa del modelo elegido y por qué, y procede con la planificación.

El `agent.md` del proyecto tiene prioridad sobre suposiciones generales.

---

## Herramientas - cuándo usar cada una

| Situación | Herramienta |
|---|---|
| Documento para personas (informe, correo, presentación) | `/humanizer` antes de entregar |
| Documentación técnica formal (SRS, PRD, API docs) | `/document-specialist` |
| Fichero binario (.docx, .pdf, .pptx, .xlsx) | `/readbin` antes de procesarlo |
| Proyecto pequeño (~20 ficheros) | Read + grep + Explore |
| Proyecto grande - entender arquitectura o refactor puntual | `/graphify` primero; luego `/graphify query "qué depende de X"` |
| Proyecto grande - documentar o refactorizar globalmente | `/graphify` + `repomix` |

Si existe `graphify-out/GRAPH_REPORT.md`, léelo antes de cualquier tarea de arquitectura.

---

## Multi-agente

### Roles

| Rol | Variable | Qué hace |
|---|---|---|
| `scout` | $ROLE_SCOUT | Explora código; usa `/graphify` en proyectos grandes; produce resumen en `progress/` |
| `architect` | $ROLE_ARCHITECT | Diseña la solución; usa `/graphify query` para análisis de impacto |
| `implementer` | $ROLE_IMPLEMENTER | Escribe código según el diseño del architect |
| `tester` | $ROLE_TESTER | Crea suites de test (unit, integration, e2e) según los criterios de `agent.md` del proyecto |
| `reviewer` | $ROLE_REVIEWER | Ejecuta tests; valida contra requisitos; aprueba o rechaza con motivo concreto |
| `fixer` | $ROLE_FIXER | Corrige exactamente lo que rechazó el reviewer; no toca nada fuera del alcance |
| `documenter` | $ROLE_DOCUMENTER | Docs técnicas con `/graphify` + `repomix`; usa `/document-specialist` |
| `analyst` | $ROLE_ANALYST | Análisis de datos con pandas/matplotlib; produce informe en `progress/` |
| `reporter` | $ROLE_REPORTER | Transforma análisis en documentos para personas; aplica `/humanizer` |
| `infra` | $ROLE_INFRA | Kubernetes, Helm, Docker Compose, AWS |

### Protocolo

**Cada sub-agente:** recibe contexto mínimo (tarea + ficheros de `progress/` que necesita); escribe resultado en `progress/NN-rol-tema.md`; no comparte contexto de conversación, solo ficheros.

**El orquestador:**
- Lee `tasks.md` al iniciar; lanza `scout` primero si el codebase es desconocido
- Secuencia estándar: `scout -> architect -> implementer -> tester -> reviewer -> fixer`
- Paraleliza `implementer` y `fixer` solo si tocan ficheros distintos
- Máximo 3 ciclos `reviewer -> fixer` por tarea; si persiste, para y reporta al usuario

### Criterio run vs orch

- **`make run` (Sonnet):** un track, <8 tareas, poco paralelismo posible
- **`make orch` (Opus):** múltiples tracks paralelos, componentes independientes, >8 tareas

Si `make run` no es suficiente para el proyecto, infórmale y sugiere relanzar con `make orch`.
