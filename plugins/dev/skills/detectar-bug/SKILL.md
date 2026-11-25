---
name: detectar-bug
description: Diagnostica un comportamiento y, si es bug real, abre el issue
argument-hint: descripción del comportamiento observado
---
Diagnostica el comportamiento observado: "$ARGUMENTS"

Si `## Método` indica **Repo**, todos los comandos `gh` llevan `-R <repo>`, y `doc/`, el código, la Verificación y los commits son los de la carpeta que indica, no los de la raíz del proyecto. Con **Repos por área**, el repo, la carpeta y la Verificación son los del área del issue, con las reglas de [Repos por área](../../README.md#repos-por-área).

1. Investiga en el código qué debería pasar frente a lo que se reporta, citando fichero:línea de lo que sustenta el diagnóstico. Si ayuda, ejecuta el test relacionado o reproduce el flujo, con las mismas restricciones de `CLAUDE.md` sobre bases de datos y servicios externos reales. Si un test existente fija el comportamiento reportado, dilo: si está codificado a propósito (y el fix tendrá que cambiar ese test) o si nadie lo cubrió.
2. Decide:
   - **No es un bug**: si el comportamiento es el esperado por diseño, configuración o un límite conocido, explica por qué, qué pasa en realidad y qué habría que cambiar (configuración, uso, o una petición de mejora). No crees issue, salvo el caso del punto 3.
   - **Es un bug**: redacta el diagnóstico (causa raíz si la localizaste; si no, síntomas + hipótesis más probable) y comprueba que no exista ya un issue abierto (`gh issue list --search '<términos clave>' --state open --json number,title`). Si existe, no dupliques: dilo y pregunta si comentas ahí.
3. Si no es un bug pero se arregla con una mejora, comprueba igual que no exista ya un issue para ella y, si no lo hay, invoca `dev:crear-issue` (Skill tool) con un título breve, indicando que salió de algo que parecía un bug y que va como `enhancement`.
4. Si es un bug nuevo, invoca `dev:crear-issue` (Skill tool) con un título breve, indicando que es un `bug`. Ese skill gestiona el cuerpo, el tablero, el Status y las etiquetas.
5. Si falta información para diagnosticar con confianza, pregunta antes de suponer o de crear un issue especulativo.
