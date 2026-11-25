---
name: ayuda
description: Lista los comandos disponibles en el proyecto
---
Muestra solo la lista final, sin describir los pasos.

Reúne los comandos de estos sitios, sin inventar ninguno que no exista como fichero:
- `.claude/commands/*.md` y `.claude/skills/*/SKILL.md` del proyecto.
- Los skills de cada plugin de `${CLAUDE_PLUGIN_ROOT}/..` (el repo `Metodo`) activo en esta sesión: `dev` siempre, y cada `<plugin>@metodo` con valor `true` en `enabledPlugins` de `~/.claude/settings.json`, `.claude/settings.json` o `.claude/settings.local.json` del proyecto. De cada uno, `<raíz del plugin>/skills/*/SKILL.md`, con prefijo `<plugin>:`.

De cada uno, toma del frontmatter `description` y, si lo tiene, `argument-hint`, y preséntalos en bloques (primero los del proyecto, luego uno por plugin, `dev` el primero), ordenados alfabéticamente:

- `/nombre [argumento]` — descripción.

No ejecutes nada más.
