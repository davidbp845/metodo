---
name: cerrar-issue-wontfix
description: Cierra un issue como wontfix (se descarta, no se va a hacer) y cambia su Status a Done
argument-hint: número de issue y, opcionalmente, el motivo
---
Argumentos: `$ARGUMENTS`. El primer número es el issue; el texto que lo siga, si lo hay, es el motivo.

Si `## Método` indica **Repo**, todos los comandos `gh` llevan `-R <repo>`, y `doc/`, el código, la Verificación y los commits son los de la carpeta que indica, no los de la raíz del proyecto. Con **Repos por área**, el repo, la carpeta y la Verificación son los del área del issue, con las reglas de [Repos por área](../../README.md#repos-por-área).

Cierra ese issue del tablero indicado en la sección `## Método` del `CLAUDE.md` del proyecto como **wontfix**: no se implementa nada porque se decide no hacerlo, o no por ahora. Es distinto de `/dev:cerrar-issue`, que cierra trabajo terminado.

1. Busca en la rama del issue (la de su etiqueta `rama:*`, o la principal si no la tiene) commits que citen el issue (`git log <rama> --format='%h %s' --grep '#<issue>\b' -E`) y quita los `docs`. Si queda código, lo que hay en la rama ya hace algo, y cerrar como wontfix dejaría el tablero diciendo que no se hizo. No cierres todavía: propón cerrarlo con `/dev:cerrar-issue` como completado por lo que cubre y abrir con `dev:crear-issue` otro issue para lo que falta, o revertir ese código si no debe quedarse. Sigue con el wontfix solo si el usuario lo confirma, y entonces el comentario del paso 3 nombra esos commits.
2. Añade la etiqueta `wontfix` (`gh issue edit <issue> --add-label wontfix`; si no existe en el repo, pregunta antes de crearla).
3. Comenta el motivo, el de los argumentos o el ya discutido en la conversación. Sé concreto: qué cambió (contexto, prioridad, comportamiento aceptado como está) para que se entienda sin releer el hilo. Si queda absorbido por otro issue o ADR, cítalo.
4. Si el issue señalaba código muerto o una funcionalidad a medias que ya no se hará, comprueba que hay un issue abierto para retirarlo; si no, propón crearlo con `dev:crear-issue`.
5. Cierra con motivo "not planned" (`gh issue close <issue> --reason "not planned"`).
6. Pon su Status a **Done**: no hay nada que revisar.
7. Confirma con un resumen breve: issue cerrado como wontfix, Status final y enlace.

Si el motivo no está claro, pregúntalo antes de cerrar; no inventes una justificación.
