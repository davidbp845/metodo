---
name: nueva-vision
description: Actualiza el documento de visión (A1) para un cambio de alcance o estrategia, y abre issues de Backlog si ya es accionable
argument-hint: qué cambia en la visión (texto libre)
---
Actualiza el documento de visión del proyecto (`<Documentación>/A1-Vision/`, con la carpeta del campo **Documentación** de `## Método`, `doc/` si no lo tiene) para reflejar "$ARGUMENTS". Es un documento vivo: se actualiza cuando cambia la visión, no se cierra. Si el proyecto no tiene esa carpeta, dilo y pregunta si crearla.

Si `## Método` indica **Repo**, todos los comandos `gh` llevan `-R <repo>`, y `doc/`, el código, la Verificación y los commits son los de la carpeta que indica, no los de la raíz del proyecto. Con **Repos por área**, el repo, la carpeta y la Verificación son los del área del issue, con las reglas de [Repos por área](../../README.md#repos-por-área).

1. Identifica qué ficheros de la visión afecta el cambio (índice en su `README.md`). Si toca varios, actualízalos todos.
2. Si lo que cambia es una decisión de arquitectura (capas, puertos, almacenamiento, frameworks) o contradice una ADR aceptada, no es visión: para y propón `/dev:crear-decision` en su lugar.
3. Si el cambio depende del estado real del código (qué casos de uso o qué piezas existen hoy), audítalo antes de escribir; no lo supongas.
4. Reescribe la sección afectada como si siempre hubiera dicho eso: estado actual, sin historial de cómo se llegó ahí.
5. Valora si lo escrito ya es trabajo accionable (alcance claro, se sabe qué construir) o una idea sin compromiso. En el segundo caso va a "Ampliaciones futuras" y no genera issue.
6. Si es accionable, confirma con el usuario si se abren ya los issues de Backlog (o hazlo directamente si la conversación ya lo deja claro), con `dev:crear-issue` (Skill tool) por cada uno, enlazando a la sección de visión actualizada.
7. Haz commit local de la visión (`docs(vision): ...`). Nunca push.
8. Invoca el skill `dev:revisar-docs` (Skill tool) sin argumento, para que el resto de la documentación (README, Mapa de documentación) refleje la visión nueva.
9. Confirma con un resumen: ficheros tocados, issues creados con su enlace, y que los commits quedan locales.

Si el cambio no encaja con claridad en ninguna sección, pregunta antes de forzarlo.
