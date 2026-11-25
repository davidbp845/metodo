---
name: cerrar-issue
description: Cierra un issue verificado y cambia su Status a In review
argument-hint: número de issue
---
Si `## Método` indica **Repo**, todos los comandos `gh` llevan `-R <repo>`, y `doc/`, el código, la Verificación y los commits son los de la carpeta que indica, no los de la raíz del proyecto. Con **Repos por área**, el repo, la carpeta y la Verificación son los del área del issue, con las reglas de [Repos por área](../../README.md#repos-por-área).

Cierra el issue `$ARGUMENTS` del tablero indicado en la sección `## Método` del `CLAUDE.md` del proyecto:
1. Comenta en el issue qué se implementó y cómo se verificó (comandos de Verificación, verificaciones extra, comprobaciones manuales). En un `bug`, di también dónde más aparecía el mismo fallo y qué se hizo con cada sitio, o que no aparece en ningún otro. Si el proyecto tiene Metodología, sigue el índice de la verificación de C5: el de la parte común (`metodologia.md` de la carpeta del plugin, dos niveles por encima de la carpeta base de este skill) con lo que añada el documento del proyecto. Si ya se comentó el plan al empezar, este es el comentario de cierre con los resultados. Un issue de un área de **Repos por área** sin Verificación propia no tiene verificación automática: el comentario dice qué tiene que revisar el usuario en In review.
2. Cierra el issue (`gh issue close`).
3. Pon su Status a **In review**, nunca a Done salvo que el usuario lo pida para este issue. El flujo automático del tablero «item closed → Done» puede ejecutarse después y pisarlo: espera unos segundos, vuelve a leer el Status y, si está en Done, ponlo otra vez en **In review**.
   Quita el latido del issue, si se fijó al empezar: `<carpeta del plugin>/scripts/latido.sh quitar $ARGUMENTS` (la carpeta del plugin está dos niveles por encima de la carpeta base de este skill; sin latido fijado, no hace nada).
4. Si una ADR de `doc/A2-ADR/` cita este issue en su `## Estado`, sigue en `Propuesta` y ya tiene todos sus issues cerrados, pregunta si pasa a `Aceptada`: aceptar una decisión es del usuario. Si dice que sí, cambia la primera palabra de su Estado y su fila del índice `README.md`, con commit local `docs(adr): ...`.
5. Confirma con un resumen breve: issue cerrado, Status final y enlace, y la ADR que ha cambiado o queda pendiente de aceptar, si la hay.

Si el issue no está terminado y verificado, dilo en vez de cerrarlo.
