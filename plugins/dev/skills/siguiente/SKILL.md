---
name: siguiente
description: Decide qué toca en el proyecto (cola de revisión, sprint de Ready o barridos pendientes) y lo lanza, sin preguntar
---
Punto de entrada de una sesión que no tiene encargo concreto, también desatendida: decide qué toca en el proyecto y lo lanza. Lee antes la sección `## Método` del `CLAUDE.md` del proyecto (tablero, límite de In review, 10 si no lo indica).

Si `## Método` indica **Repo**, todos los comandos `gh` llevan `-R <repo>`, y `doc/`, el código, la Verificación y los commits son los de la carpeta que indica, no los de la raíz del proyecto. Con **Repos por área**, el repo, la carpeta y la Verificación son los del área del issue, con las reglas de [Repos por área](../../README.md#repos-por-área).

No pregunta nada: lo que decide sale del tablero y de la lista de barridos. Si un paso necesita una decisión del usuario o algo que la política de `CLAUDE.md` exige confirmar, ese paso se para, se apunta el motivo y se sigue con lo demás.

1. **Cola de revisión**: cuenta los items del tablero en Status **In review**. Si alcanzan el límite, no hace nada más: di cuántos son y que la revisión del usuario va antes que seguir cerrando.
2. **Ready**: lista los issues en Status **Ready** de la rama de trabajo, con el mismo filtro de rama que `/dev:sprint` (ver [Ramas largas](../../README.md#ramas-largas)). Si hay alguno, invoca el skill `dev:sprint` (Skill tool) y termina con su resumen.
3. **Barridos**: sin Ready, lee `barridos.md` (dos niveles por encima de la carpeta base de este skill) y, en su orden, para cada barrido:
   1. Mira si **aplica** al proyecto, con la comprobación que da el barrido. Si no, pasa al siguiente.
   2. Mira si está **hecho**: con el criterio del barrido o con una línea de ese proyecto y ese barrido en `local/barridos.md` del repo del método común (la carpeta `Metodo` que nombra el `CLAUDE.md` global). Si está hecho, pasa al siguiente.
   3. Invoca el skill del barrido (Skill tool) con sus argumentos. Lo que abra va a Backlog: no se resuelve en esta sesión, porque la puerta para trabajar en un issue es Ready. Si el skill termina sin abrir nada porque el proyecto ya lo cumple, añade a `local/barridos.md` la línea `- <carpeta del proyecto> · <barrido> · AAAA-MM-DD`, para que no se repita. `local/` no está en git: es el registro de esta máquina.
4. **Resumen**: qué paso decidió y qué se hizo (el resumen del sprint, o por barrido: no aplica, ya hecho, issue abierto con su enlace, o cumplido y apuntado). Si nada estaba pendiente, dilo en una línea.
