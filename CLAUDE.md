# CLAUDE.md

Repo del método común: lo que se repite entre proyectos (skills, plantillas, guía de redacción) vive aquí una sola vez. Qué contiene y cómo lo adopta un proyecto: `README.md`. Contrato del plugin `dev`: `plugins/dev/README.md`.

## Método

- Tipo: dev
- Tablero: proyecto GitHub "Metodo" (owner `davidbp845`, número `10`)
- Verificación: `claude plugin validate .` (debe terminar en `✔ Validation passed`; los avisos de versión, licencia e icono solo cuentan para el directorio público)
- Etiquetas de área: `plugin-dev` (skills del ciclo de desarrollo), `estilo` (guía de redacción y formato, incluido Obsidian), `marketplace` (plugins nuevos, `marketplace.json`, activación por proyecto), `ci` (workflows de integración continua reutilizables y su adopción por proyecto), `maquina` (configuración global de la máquina, plantillas de `maquina/` y sesiones desatendidas)
- Límite de In review: 10
- Verificaciones extra:
  - Un cambio en un skill vale para todos los proyectos que lo usan: comprobar que no rompe a ninguno de los que tienen `## Método` (los campos que lee el skill siguen existiendo o tienen valor por defecto).
  - Un campo nuevo de `## Método` se documenta en la tabla de campos de `plugins/dev/README.md` en el mismo commit.
  - Si el cambio toca `plugins/dev/skills/` o `plugins/dev/evals/`, pasar además `plugins/dev/evals/ejecutar.sh` (cuesta alrededor de 3 USD; mientras se ajusta un caso, `--case <skill> --runs 1`).
- Mapa de documentación:
  | Si cambia... | ...debe estar al día en |
  |---|---|
  | Skill de un plugin (nuevo, renombrado o eliminado) | Tabla de skills del `README.md` de ese plugin |
  | Campo de `## Método` | Ejemplo y tabla de campos de `plugins/dev/README.md` |
  | Plugin (nuevo o eliminado) | `.claude-plugin/marketplace.json` y tabla "Qué hay" del `README.md` |
  | Regla de redacción | `estilo/redaccion.md` |
  | Configuración global (`CLAUDE.md` global, `settings.json`, hooks de usuario) | `maquina/` (plantillas), nunca solo `~/.claude` |

## Reglas

- Los ejemplos de los skills son genéricos: nada de rutas, tableros ni etiquetas de un proyecto concreto. Lo propio de un proyecto va en su `## Método`.
- Los skills siguen `estilo/redaccion.md`, como cualquier otro texto.
