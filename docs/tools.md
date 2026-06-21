# Herramientas y MCPs

## Herramientas instaladas en el contenedor

| Herramienta | Versión | Uso |
|---|---|---|
| Python | 3.x | Análisis, scripting, generación de documentos |
| Java | 21 LTS | Proyectos Spring Boot, Maven, Gradle |
| Maven | última estable | Build y gestión de dependencias Java |
| Node.js | 22 LTS | Frontend, scripts JS, MCPs |
| AWS CLI | v2 (multi-arch) | Gestión de recursos AWS |
| Docker CLI | última estable | Gestión de contenedores del host |
| kubectl + Helm | últimas estables | Kubernetes |
| Chromium | nativo Debian | Automatización web (Playwright) |
| pandoc | última estable | Conversión universal de documentos (MD, DOCX, PDF, HTML, EPUB...) |
| markitdown | última | Conversión de DOCX/PDF/PPTX a Markdown |
| mdimg | - | Extrae imágenes base64 de un markdown y las guarda como ficheros reales |
| repomix | última | Empaqueta un repo completo en un fichero para LLMs |
| graphify | última | Convierte un proyecto en grafo de conocimiento consultable |

### Librerías Python incluidas

`pandas`, `numpy`, `matplotlib`, `seaborn`, `boto3`, `requests`, `httpx`, `pillow`, `python-docx`, `python-pptx`, `jupyter`, `black`, `ruff`, `markitdown`

## MCPs preconfigurados

Los MCPs son plugins que Claude usa como herramientas nativas durante la sesión.

| MCP | Función | Requiere |
|---|---|---|
| `filesystem` | Acceso avanzado a ficheros en `/work` | - |
| `brave-search` | Búsqueda en internet | `BRAVE_API_KEY` en `.env` |
| `github` | Gestión de repositorios | `GITHUB_TOKEN` en `.env` |
| `playwright` | Navegación web con stealth anti-detección | - |

## markitdown + mdimg - Conversión de ficheros binarios

Para procesar cualquier fichero binario usa `/readbin` - invoca automáticamente el pipeline completo:

```bash
markitdown --keep-data-uris fichero.docx | mdimg fichero_images > fichero.md
```

- `markitdown` extrae el texto del binario conservando las imágenes en base64
- `mdimg` extrae ese base64 y guarda cada imagen como fichero real

No hace falta invocarlo manualmente - el `CLAUDE.md` global instruye al asistente para usar `/readbin` siempre que detecte un fichero binario.

## Skills (slash commands)

Las skills son automatizaciones invocadas con `/nombre` dentro de una sesión.

| Skill | Descripción |
|---|---|
| `/document-specialist` | Documentación profesional: SRS, PRD, API docs, arquitectura (MD/DOCX/PDF) |
| `/estado` | Resumen del estado actual del proyecto y entorno |
| `/humanizer` | Reescribe texto para eliminar patrones típicos de IA |
| `/mermaid-skill` | Genera diagramas y los exporta a PNG/SVG/PDF |
| `/readbin` | Convierte binarios (DOCX/PDF/PPTX/XLSX) a Markdown limpio con imágenes extraídas |

### /humanizer - Textos que suenan humanos

Skill de la comunidad ([blader/humanizer](https://github.com/blader/humanizer)) instalada automáticamente con el build. Detecta y elimina 29 patrones propios de texto generado por IA: lenguaje corporativo, em-dashes excesivos, construcciones pasivas, conclusiones genéricas, etc.

**Uso manual:**
```
/humanizer

[pega aquí el texto a mejorar]
```

**Automático en documentos:** el `CLAUDE.md` global instruye al asistente para que lo aplique siempre antes de entregar documentos destinados a personas (informes, correos, presentaciones).

Si proporcionas ejemplos de tu propia escritura antes de invocarlo, adapta el resultado a tu voz y estilo.

### /mermaid-skill - Diagramas técnicos

Skill instalada automáticamente con el build. Genera diagramas en texto (Mermaid) y los renderiza a imagen usando la **API de Kroki** (`kroki.io`) vía curl. Soporta 11+ tipos:

| Tipo | Uso |
|---|---|
| Flowchart | Procesos y flujos de decisión |
| Sequence | Llamadas entre servicios, flujos OAuth |
| Class | Modelos OOP, herencia |
| ER | Esquemas de base de datos |
| C4 Context | Arquitectura de sistemas |
| State | Máquinas de estado |
| Gantt | Timelines de proyecto |
| Mind Map | Desglose de temas |

**Uso:**
```
/mermaid-skill

Genera un diagrama de secuencia del flujo de autenticación JWT
```

**Salida:** fichero `.mmd` (texto, versionable en git) + imagen PNG/SVG/PDF en `/work`.

El renderizado usa la **API de Kroki** (`kroki.io`) vía curl - sin browser, sin Puppeteer, sin dependencias locales. Requiere conexión a internet.

Se activa automáticamente cuando Claude detecta que una explicación involucra 3+ componentes, flujos de API, jerarquías de clases o esquemas de base de datos.

### /readbin - Leer ficheros binarios

Skill instalada automáticamente con el build. Convierte cualquier fichero binario a Markdown limpio listo para ser procesado como contexto por Claude. Combina `markitdown` y `mdimg` para extraer tanto el texto como las imágenes embebidas.

**Uso:** Claude lo invoca automáticamente al detectar ficheros `.docx`, `.pdf`, `.pptx`, `.xlsx`.

**Pipeline interno:**
```bash
markitdown --keep-data-uris fichero.docx | mdimg fichero_images > fichero.md
```

**Por qué este pipeline:**
- `markitdown` sin flags trunca las imágenes a un placeholder vacío - se pierden
- `--keep-data-uris` conserva el base64 real, pero son cadenas enormes ilegibles para Claude
- `mdimg` extrae ese base64, guarda cada imagen como fichero real y deja una referencia `![alt](ruta.png)` - Claude las lee visualmente

**Resultado:** texto limpio en `.md` + imágenes como ficheros `.png`/`.jpg` que Claude puede ver.

### /graphify - Grafo de conocimiento del proyecto

Skill instalada automáticamente con el build. Transforma cualquier carpeta de código, docs, PDFs o vídeos en un **grafo de conocimiento consultable** - Claude navega el grafo en lugar de leer ficheros uno a uno, ahorrando hasta 71x tokens en proyectos grandes.

**Primera vez en un proyecto:**
```
/graphify
```
Analiza el directorio actual, construye el grafo y genera:
- `graphify-out/GRAPH_REPORT.md` - resumen de nodos clave y comunidades
- `graphify-out/graph.html` - visualización interactiva
- `graphify-out/graph.json` - datos crudos (compatible GraphRAG)

**Consultas sin leer ficheros:**
```
/graphify query "¿cómo fluye la autenticación?"
/graphify path "UserService" "TokenRepository"
/graphify explain "PaymentController"
```

**Añadir instrucciones al proyecto:**
```bash
graphify claude install   # añade sección graphify al CLAUDE.md del proyecto
```

**Mantener el grafo actualizado:**
```bash
graphify hook install     # hook git post-commit: reconstruye el grafo tras cada commit
/graphify --watch         # modo continuo: reconstruye al guardar ficheros
/graphify --update        # actualización incremental (solo ficheros cambiados)
```

**Cuándo usarlo:** proyectos con más de ~20 ficheros donde necesitas entender la arquitectura, rastrear dependencias o hacer preguntas de alto nivel sobre el código.

### Añadir más skills

- **Global** (todas las sesiones): añadir fichero en `data/home/.claude/skills/` o `data/home/.claude/commands/`
- **Por proyecto**: añadir `.md` en `/work/mi-proyecto/.claude/commands/`

Para incluir una skill en el build (disponible para todos sin pasos manuales), clonar el repo en el Dockerfile y añadirla a `/config/skills/`.
