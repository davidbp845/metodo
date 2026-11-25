---
name: resolver-retoques
description: Resuelve, uno a uno, los retoques pendientes del issue paraguas de una zona
argument-hint: "[zona] (opcional si el proyecto solo tiene una)"
---
Si `## Método` indica **Repo**, todos los comandos `gh` llevan `-R <repo>`, y `doc/`, el código, la Verificación y los commits son los de la carpeta que indica, no los de la raíz del proyecto. Con **Repos por área**, el repo, la carpeta y la Verificación son los del área del issue, con las reglas de [Repos por área](../../README.md#repos-por-área).

Resuelve los retoques pendientes de la zona "$ARGUMENTS". Lee antes la sección `## Método` del `CLAUDE.md` del proyecto: la tabla **Retoques** (zona · título del issue paraguas · carpeta · encadena · Status, opcional), la Verificación y las Verificaciones extra. Sin esa tabla, dilo y para.

1. Elige la zona: la del argumento; si no hay argumento y la tabla tiene una sola zona, esa; si no, pregunta.
2. Localiza el issue paraguas abierto de la zona igual que `/dev:crear-retoque`. Si no hay ninguno claro, pregunta.
3. Lista sus comentarios (`gh api repos/<owner>/<repo>/issues/<n>/comments`). Son **pendientes** los que empiezan por `**Retoque:**` y no contienen `Commit:`; los que lo contienen ya están resueltos. Ordénalos del más antiguo al más reciente.
4. Si no hay pendientes, dilo y termina.
5. Para cada pendiente, en orden:
   a. Antes de tocar nada, muestra el texto exacto del retoque y cuántos quedan, incluido este.
   b. Implementa el cambio mínimo en la carpeta de la zona.
   c. Pasa los comandos de Verificación y las Verificaciones extra que correspondan. No levantes servidores en segundo plano salvo que el usuario lo pida en este turno. Si `## Método` tiene **Demo**, nada se verifica contra los datos reales: cada orden que ejecute la app para verificar lleva la Variable del campo, y el retoque se mira en la app de demo si ya está arrancada o el usuario lo pide. El modo del Fichero no se cambia sin confirmación del usuario.
   d. Haz commit local: asunto `tipo(<zona>): resumen breve`, cuerpo con el porqué si no es obvio, pie `Issue: #<n>`. Nunca push.
   e. Comenta en el issue `**Retoque implementado:** <qué se hizo y por qué>` y, en línea aparte, `Commit: <hash corto>`.
   f. Si la zona encadena, sigue con el siguiente sin pausa. Si no, para y espera la confirmación del usuario antes del siguiente; con ella, continúa con la misma lista sin volver a invocar el skill.
6. Si un retoque es ambiguo o implica una decisión de diseño que su texto no dice, pregunta en vez de suponer, y sigue con los demás.
7. Al terminar o al parar, resume: retoques resueltos con su commit y cuántos quedan pendientes. Si no queda ninguno y el paraguas no es permanente (Status `Done` en la tabla), propón cerrarlo con `/dev:cerrar-issue`.
