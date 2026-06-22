# memory-review

Audita las memorias del proyecto activo, propone consolidaciones y ejecuta los cambios aprobados.

## Pasos

1. Deriva la ruta de memoria del proyecto activo a partir del working directory actual.
   - Formato: `~/.claude/projects/<ruta-con-guiones>/memory/`
   - Ejemplo: `/work/p-claubox` -> `~/.claude/projects/-work-p-claubox/memory/`
   - Si no existe esa carpeta, informa al usuario y para.

2. Lee `MEMORY.md` y luego cada fichero `.md` referenciado en él.

3. Por cada memoria, valida:
   - **Tipo `project`**: comprueba que los ficheros, ramas, URLs y estados descritos siguen siendo correctos leyendo los ficheros reales del proyecto. Marca como obsoleta si el estado ha cambiado.
   - **Tipo `feedback`**: comprueba que la regla no contradice instrucciones actuales en `CLAUDE.md`, `agent.md` o `user-additions.md`. Si ya está cubierta al 100% por esos ficheros sin aportar WHY ni contexto adicional, propone eliminarla.
   - **Tipo `user`**: verifica que el perfil sigue siendo preciso comparándolo con lo que se sabe del usuario en esta sesión.
   - **Tipo `reference`**: verifica que las URLs o rutas siguen siendo válidas.

4. Busca oportunidades de consolidación: memorias del mismo tipo o tema que se pueden unificar en un solo fichero con secciones. Menos ficheros es mejor - propone la fusión concreta (qué ficheros se fusionan, cómo queda el resultado).

5. Identifica huecos: cosas importantes aprendidas en sesiones recientes que no están en ninguna memoria.

6. Presenta un resumen en este formato:
   ```
   OK          user-profile        sin cambios
   OBSOLETA    project-claubox     estado de ramas desactualizado (ver detalle)
   ELIMINAR    feedback-seguridad  cubierta al 100% por agent.md sin WHY adicional
   CONSOLIDAR  feedback-commits + feedback-unicode -> feedback-estilo
   NUEVA       -                   [descripción de lo que falta]
   ```

7. Para cada entrada que no sea OK, muestra el cambio concreto y pregunta al usuario si lo ejecuta.

8. Ejecuta solo los cambios aprobados: escribe los ficheros nuevos, borra los obsoletos, actualiza `MEMORY.md`.

## Notas
- No elimines memorias sin confirmación explícita del usuario.
- Las memorias de `feedback` raramente se vuelven inválidas; solo proponer eliminarlas si hay contradicción real o redundancia total sin WHY.
- Al consolidar, el fichero resultante debe mantener toda la información de los originales, sin perder el WHY ni el contexto.
