# Ficheros que usa Claude Code

Mapa de todo lo que Claude Code lee o escribe en una máquina con el método instalado: su configuración de usuario, el repo `Metodo` y lo propio de cada proyecto. `<config>` es el directorio de configuración del usuario (`~/.claude`, o `$CLAUDE_CONFIG_DIR`) y `<datos>` la carpeta que contiene `Metodo`, `Apps`, `Cursos`...

## 1. Configuración de usuario

### Instrucciones, permisos y hooks

Se generan desde `maquina/` con `instalar.sh` (ver `README.md`); no se editan a mano.

| Fichero | Qué es |
|---|---|
| `<config>/CLAUDE.md` | Instrucciones globales, desde `CLAUDE.plantilla.md`. Importa con `@` las reglas de `estilo/` |
| `<config>/settings.json` | Permisos (`allow`/`ask`/`deny`), hooks y marketplace del método, desde `settings.plantilla.json` |
| `<config>/metodo-maquina.json` | Carpetas de proyectos y reglas de una sola máquina, fuera del repo; las reglas se suman a las de la plantilla |
| `<config>/hooks/*.sh` | Hooks de usuario, copiados de `maquina/hooks/` |
| `<config>/*.bak-AAAAMMDD-HHMMSS` | Copias que deja `instalar.sh --sobrescribir` |
| `~/.claude.json` | Estado de Claude Code: proyectos abiertos, servidores MCP de usuario, preferencias. Lo gestiona Claude Code |

### Plugins

| Fichero | Qué es |
|---|---|
| `<config>/plugins/known_marketplaces.json` | Marketplaces registrados: `metodo` (la carpeta local `Metodo`) y el oficial de Anthropic |
| `<config>/plugins/installed_plugins.json` | Plugins instalados y su alcance: `dev@metodo` a nivel de usuario, `marketing@metodo` solo en los proyectos que lo activan |
| `<config>/plugins/cache/`, `marketplaces/`, `data/` | Copias de los plugins y sus datos de trabajo |
| `<config>/plugins/synced`, `<config>/skills/synced` | Plugins y skills sincronizados desde la cuenta de claude.ai |

### Memoria y sesiones

| Fichero | Qué es |
|---|---|
| `<config>/projects/<ruta-del-proyecto>/memory/` | Memoria de cada proyecto: `MEMORY.md` (índice que se carga en cada sesión) y un `.md` por recuerdo |
| `<config>/projects/<ruta-del-proyecto>/*.jsonl` | Conversaciones del proyecto y resultados largos de herramientas |
| `<config>/history.jsonl`, `file-history/`, `sessions/`, `session-env/`, `shell-snapshots/`, `paste-cache/`, `jobs/`, `state/`, `cache/`, `ide/`, `backups/`, `stats-cache.json`, `telemetry/`, `feedback/`, `daemon/` | Datos internos de Claude Code (historial, versiones de ficheros editados para deshacer, entorno del terminal...). No se tocan a mano |

### Fuera de `<config>`

Rutas de Linux; en Windows cambian de sitio. Todas las gestiona Claude Code salvo la última fila.

| Ruta | Qué es |
|---|---|
| `~/.local/bin/claude` | El ejecutable: enlace a la versión en uso |
| `~/.local/share/claude/versions/` | Versiones descargadas de Claude Code |
| `~/.local/state/claude/locks/` | Bloqueos para que dos sesiones no actualicen a la vez |
| `~/.cache/claude/` | Descargas a medio instalar de una actualización |
| `~/.cache/claude-cli-nodejs/<ruta-del-proyecto>/` | Registros de los servidores MCP, por proyecto (`mcp-logs-*`); es lo primero que mirar cuando uno falla |
| `~/.config/Claude/` | La app de escritorio (perfil de navegador: caché, cookies, almacenamiento) |
| `/tmp/claude-<uid>/<ruta-del-proyecto>/<sesión>/` | Temporales de cada sesión: `scratchpad/` (ficheros de trabajo que no van al repo) y `tasks/` (salida de los comandos en segundo plano y de los subagentes). Se pierden al reiniciar |
| `/tmp/claude-<uid>/bash-edit-diff/` | Diferencias de las ediciones hechas desde el terminal |
| Las de `additionalDirectories` en `settings.json` | Carpetas fuera de los proyectos a las que se da acceso: aquí `~/.cache/huggingface` y `~/.cache/torch`, donde se guardan los modelos descargados |

### Temporales de los scripts del método

| Ruta                                   | Qué es                                                                                                        |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `${XDG_RUNTIME_DIR:-/tmp}/dev-latido/` | Estado de `plugins/dev/scripts/latido.sh`: un fichero por sesión con los issues en curso de `/dev:resolver-issue` o `/dev:sprint` (normalmente en `/run/user/<uid>/`) |
| `/tmp/claude-eval-*/`                  | Proyecto y `HOME` de prueba de cada caso de `plugins/dev/evals/ejecutar.sh`; se borran al acabar              |
| `plugins/dev/evals/results/`           | Resultados de los evals, dentro del repo pero ignorados por git                                               |
| Un `mktemp -d` de `instalar.sh`        | Donde se generan los ficheros antes de compararlos con `<config>`; se borra al salir                          |

## 2. Repo `Metodo`

| Ruta | Qué es |
|---|---|
| `CLAUDE.md`, `README.md` | Instrucciones del repo y qué contiene |
| `.claude-plugin/marketplace.json` | Hace de `Metodo` un marketplace de plugins |
| `estilo/redaccion.md`, `estilo/diseno-web.md` | Reglas de escritura y de maquetación, importadas desde el `CLAUDE.md` global |
| `estilo/obsidian/` | Fragmento CSS común de las bóvedas de Obsidian y cómo activarlo |
| `maquina/` | Plantillas del `CLAUDE.md` global y de `settings.json`, hooks de usuario, `instalar.sh` y este mapa |
| `plugins/dev/README.md`, `metodologia.md` | Contrato del `## Método` y parte común de la metodología |
| `plugins/dev/.claude-plugin/plugin.json`, `hooks/hooks.json` | Manifiesto del plugin y sus hooks |
| `plugins/dev/skills/*/SKILL.md` | Skills del ciclo de desarrollo (`/dev:*`), con sus ficheros de apoyo |
| `plugins/dev/scripts/` | Scripts que llaman los hooks y los skills (`hook-*.sh`, `latido.sh`, `metricas.sh`, `sin-subir.sh`) |
| `plugins/dev/evals/` | Pruebas de los skills: `ejecutar.sh` y un caso por carpeta (`case.yaml` y scripts que montan el proyecto) |
| `plugins/marketing/` | Plugin `marketing`: skill `revisar-ads` y `scripts/umami-visitas.py` |
| `local/` | Ignorada por git: retros agregadas (`local/retros/`), tabla de proyectos de la máquina (`local/proyectos.md`) y apps modelo de la guía Streamlit (`local/streamlit.md`) |
| `.github/workflows/verificacion.yml` | CI reutilizable que llaman los proyectos |

## 3. Proyectos

En cada proyecto, Claude Code lee:

| Fichero | Qué es |
|---|---|
| `CLAUDE.md` | Instrucciones del proyecto; si usa el método, con su sección `## Método` |
| `AGENTS.md` | Instrucciones para agentes en general, en proyectos que vienen de fuera |
| `.claude/commands/*.md` | Comandos propios del proyecto |
| `.claude/skills/` | Skills propios del proyecto |
| `.claude/settings.json`, `.claude/settings.local.json` | Permisos y hooks del proyecto (el `.local` no se sube a git) |
| `.claude/hooks/` | Scripts de hooks del proyecto |
| `.mcp.json` | Servidor MCP propio del proyecto |
| El fichero del campo `Demo` | Elige datos reales o de demo (hoy `configuracion.toml`, con `modo = "demo"` o `"real"`) |

La tabla de los proyectos de cada máquina (cuáles tienen `## Método` y qué tienen además del `CLAUDE.md`) va en `local/proyectos.md` del repo del método, ignorado por git.

Las carpetas `<Raíz>_notas` son las bóvedas de Obsidian de cada grupo de proyectos y enlazan a sus notas: sus `CLAUDE.md` son los mismos ficheros, no otros.

## Lo que Claude Code no lee

- Los `.env` y todo lo que hay bajo una carpeta `secrets/`, bloqueados en `settings.json`.
- Las rutas que bloquea `metodo-maquina.json`, con ninguna herramienta.
