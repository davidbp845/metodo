---
name: crear-retoque
description: Apunta un retoque de UI/UX en el issue paraguas de retoques de su zona, sin implementarlo
argument-hint: "[zona] descripción breve del retoque"
---
Si `## Método` indica **Repo**, todos los comandos `gh` llevan `-R <repo>`, y `doc/`, el código, la Verificación y los commits son los de la carpeta que indica, no los de la raíz del proyecto. Con **Repos por área**, el repo, la carpeta y la Verificación son los del área del issue, con las reglas de [Repos por área](../../README.md#repos-por-área).

Registra el retoque "$ARGUMENTS" en el issue paraguas de su zona. Las zonas salen de la tabla **Retoques** de la sección `## Método` del `CLAUDE.md` del proyecto (zona · título del issue paraguas · carpeta · encadena · Status, opcional). Si el proyecto no tiene esa tabla, dilo y para. Un retoque es un ajuste menor que no necesita issue propio ni mockup; si cambia comportamiento o necesita diseño, propón `/dev:crear-issue` en su lugar.

1. Si la primera palabra de los argumentos es una zona de la tabla, esa es la zona y el resto, el retoque. Si la tabla tiene una sola zona, es esa. Si no, deduce la zona por lo que describe el retoque y, si hay duda, pregunta.
2. Busca el issue paraguas abierto de la zona por su título (`gh issue list --search '"<título>" in:title' --state open --json number,title`). No asumas un número fijo: el paraguas se cierra cuando se agota y se abre otro. Si hay más de uno, pregunta. Si no hay ninguno, propón crearlo con `dev:crear-issue` (Skill tool), con ese título y el Status de la zona (**In progress** si la tabla no lo indica), y sigue tras la confirmación.
3. Comprueba que su Status en el tablero es el de la zona (**In progress** si la tabla no lo indica). Si no lo está, avisa y pregunta si continuar.
4. Comenta en el issue `**Retoque:** <descripción>` y, debajo, el análisis de qué hay que cambiar para resolverlo (ficheros de la carpeta de la zona y qué cambia en ellos). Sin mencionar commit: aún no se implementa nada.
5. No toques código. El retoque queda anotado hasta que el usuario pida resolverlos con `/dev:resolver-retoques`.
6. Confirma con un resumen breve: issue en que quedó y enlace al comentario.
