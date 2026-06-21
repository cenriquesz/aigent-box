---
name: readbin
version: 1.1.0
description: |
  Convierte ficheros binarios (docx, pdf, pptx, xlsx) a markdown limpio para
  usarlos como contexto. Usa markitdown + mdimg para extraer el texto y separar
  las imágenes base64 embebidas como ficheros reales. Usar SIEMPRE antes de
  procesar cualquier fichero binario.
license: MIT
compatibility: claude-code
allowed-tools:
  - Bash
  - Read
---

# readbin - Leer ficheros binarios como contexto LLM

## Cuándo usar esta skill

Siempre que el usuario mencione o proporcione un fichero con extensión:
`.docx` `.pdf` `.pptx` `.xlsx` `.xls` `.odt` `.odp` `.ods`

No intentes leer estos ficheros directamente. Ejecuta este pipeline primero.

## Pipeline

```bash
markitdown --keep-data-uris <fichero> | mdimg <fichero_sin_extension>_images > <fichero_sin_extension>.md
```

Ejemplo para `informe.docx`:
```bash
markitdown --keep-data-uris informe.docx | mdimg informe_images > informe.md
```

`--keep-data-uris` es obligatorio: sin él, markitdown trunca las imágenes a `base64...` (placeholder sin datos reales) y las imágenes se pierden.

## Pasos

1. **Ejecuta el pipeline** con Bash. `mdimg` reporta en stderr cuántas imágenes extrajo.

2. **Lee el markdown limpio** con Read:
   ```
   Read informe.md
   ```

3. **Imágenes** - si `mdimg` extrajo imágenes Y son relevantes para la tarea
   (diagramas, tablas como imagen, capturas, esquemas):
   - Lista `informe_images/` con Bash para ver qué hay
   - Lee con Read las imágenes relevantes - Claude las procesa visualmente

4. **Limpieza opcional** - si el .md y las imágenes ya no son necesarios al
   terminar la tarea, bórralos con Bash para no dejar residuos.

## Por qué este pipeline

- `markitdown` sin flags trunca las imágenes a `base64...` - un placeholder vacío,
  las imágenes se pierden completamente
- `--keep-data-uris` hace que markitdown incluya el base64 real en el markdown,
  pero eso son cadenas ASCII enormes (cientos de miles de chars por imagen) que
  Claude lee como texto plano sin poder verlas
- `mdimg` extrae ese base64, guarda cada imagen como fichero real y deja una
  referencia normal `![alt](ruta.png)` en el md
- El resultado: texto limpio + imágenes como entradas visuales reales para Claude

## Ejemplo completo

```
usuario: analiza el contrato contrato_proveedor.pdf

-> Bash: markitdown --keep-data-uris contrato_proveedor.pdf | mdimg contrato_proveedor_images > contrato_proveedor.md
  stderr: [mdimg] contrato_proveedor_images/img_001_3a2f.png
  stderr: [mdimg] contrato_proveedor_images/img_002_b1c9.png

-> Read: contrato_proveedor.md   (texto completo del contrato)

-> si hay tablas de precios o firmas escaneadas relevantes:
  Bash: ls contrato_proveedor_images/
  Read: contrato_proveedor_images/img_001_3a2f.png   (Claude la ve visualmente)

-> ahora responde al usuario con el análisis
```
