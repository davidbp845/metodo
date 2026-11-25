---
name: higiene-tablero
description: Repasa el tablero para proponer qué Done archivar, qué Backlog cerrar o mover y qué etiquetas de rama borrar, y avisa de los issues revisados con commits sin subir, sin actuar sin confirmación
---
Higiene periódica del tablero indicado en la sección `## Método` del `CLAUDE.md` del proyecto. Son cuatro problemas distintos y ninguno se ejecuta sin confirmación del usuario: los dos primeros son decisiones de prioridad, no algo mecánico, el tercero sale del disco y el cuarto quita etiquetas.

Si `## Método` indica **Repo**, todos los comandos `gh` llevan `-R <repo>`, y `doc/`, el código, la Verificación y los commits son los de la carpeta que indica, no los de la raíz del proyecto. Con **Repos por área**, el repo, la carpeta y la Verificación son los del área del issue, con las reglas de [Repos por área](../../README.md#repos-por-área).

1. **Done a archivar**: lista los issues en Status **Done** (`gh project item-list <número> --owner <owner> --format json`, cruzado por número y repo con `gh issue list --state closed --json number,title,closedAt` de cada repo para la fecha de cierre; ver [Item de un issue en el tablero](../../README.md#item-de-un-issue-en-el-tablero)). Señala como candidatos los cerrados hace más de ~3 meses (o el umbral que dé el usuario). Archivar no borra ni reabre: solo los saca de la vista por defecto.
2. **Backlog a revisar**: lista los issues en **Backlog** y, con un vistazo al título y las primeras líneas, da una señal tentativa para cada uno:
   - sigue vigente,
   - candidato a `wontfix` (contexto cambiado, resuelto en otro issue, decisión posterior que lo hizo irrelevante),
   - candidato a **Ready** si el alcance está claro y no depende de nada más.
3. **Commits sin subir**: `<carpeta del plugin>/scripts/sin-subir.sh <carpeta del proyecto>` (la carpeta del plugin está dos niveles por encima de la carpeta base de este skill). Hace `git fetch` en la carpeta del código y en las de Repos relacionados, y da una línea por repo e issue del pie (`owner/repo#NN`) con el número de commits que aún no están en la rama remota. Cruza esas referencias con los issues en **In review** o **Done** del tablero y señala cada uno: su código solo está en local, no llega a otras máquinas ni pasa por el CI. Da aparte los `sin-pie` (commits sin issue) y las `sin-remota` (rama sin upstream), con su recuento por repo.
4. **Etiquetas de rama sin rama**: para cada etiqueta `rama:<nombre>` del repo (`gh label list --search rama: --json name`), mira si la rama sigue viva y sin integrar (`git -C <carpeta del código> branch -a --no-merged <rama principal>`). Si ya está integrada en la rama principal o no existe, propón borrar la etiqueta (ver [Ramas largas](../../README.md#ramas-largas)) y di cuántos issues abiertos la llevan todavía: esos pasan a ser de main.
5. Presenta las cuatro listas y espera la decisión del usuario antes de tocar nada.
6. Tras confirmación explícita, ejecuta lo acordado issue por issue:
   - Archivar: `gh project item-archive <número> --owner <owner> --id <item-id>`.
   - Wontfix: skill `dev:cerrar-issue-wontfix` (Skill tool) para cada uno.
   - A Ready: `gh project item-edit` en el campo Status.
   - Subir: `git push` (sin forzar) del repo que el usuario haya confirmado; sube todos sus commits pendientes, no solo los de un issue.
   - Etiqueta de rama: `gh label delete <etiqueta> --yes`.
7. Resume: cuántos archivados, cuántos cerrados como wontfix, cuántos movidos a Ready, qué repos se subieron, qué etiquetas de rama se borraron y cuántos se quedaron igual.

Si no hay issues en Done ni en Backlog, ni commits sin subir, ni etiquetas de rama sin rama, dilo y termina.
