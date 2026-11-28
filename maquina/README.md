# Configuración de máquina

Lo que Claude Code lee del directorio de configuración del usuario (`~/.claude`, o `$CLAUDE_CONFIG_DIR`) y vale en todas las máquinas: el `CLAUDE.md` global, `settings.json` (permisos, hooks, marketplace del método) y los hooks de usuario. Estos ficheros son la fuente; el `~/.claude` de cada máquina se genera a partir de ellos con `instalar.sh`.

| Fichero | Se instala como |
|---|---|
| `CLAUDE.plantilla.md` | `<config>/CLAUDE.md` |
| `settings.plantilla.json` | `<config>/settings.json` |
| `hooks/*` | `<config>/hooks/*` |
| `bin/*` | `~/.local/bin/*`, como lanzador que ejecuta el de `bin/` |

El mapa completo de lo que Claude Code lee y escribe en una máquina (configuración de usuario, este repo y cada proyecto) está en `ficheros.md`.

Los hooks de usuario: `git-push-borrar-rama.sh` pide confirmación antes de borrar una rama remota, y `recordar-retro-metodo.sh` avisa al empezar sesión cuando la última retro agregada de `local/retros/` (`/dev:retro-metodo`) tiene 14 días o más, para que tenga cadencia fija sin depender de acordarse.

Las plantillas no llevan rutas de una máquina: `{{DATA}}` es la carpeta que contiene `Metodo` y las carpetas de proyectos, en forma POSIX para las reglas de permisos (`/d/Data` en Git Bash), y `{{DATA_NATIVA}}` la misma carpeta en la forma del sistema para las importaciones `@`, los directorios y el marketplace (`D:/Data`). En Linux las dos coinciden. El script las deduce de dónde está `Metodo`. `{{PROYECTOS}}` es la ruta de las carpetas de proyectos de `metodo-maquina.json` (ver abajo), o `{{DATA_NATIVA}}` si no declara ninguna.

Los comandos de `bin/` se instalan como un lanzador de dos líneas y no como copia: un pull de `Metodo` los pone al día sin reinstalar. `actualizar-repos` trae a esta máquina lo que otra ha subido: hace fetch de todos los repos con `origin` de las carpetas de proyectos y de `Metodo`, avanza con `pull --ff-only` los que están por detrás y sin cambios, y lista sin tocarlos los que tienen commits sin subir, cambios sin commit, ramas divergidas o un fetch fallido. Con `--simular` solo dice qué haría. Se lanza antes de trabajar en una máquina cuando otra ha trabajado en los mismos repos.

## Instalar en una máquina nueva

1. Instalar `git`, `gh`, `jq` y Claude Code. En Windows, Claude Code ejecuta los comandos con Git Bash, que trae `grep` pero no `jq`: `winget install Git.Git GitHub.cli jqlang.jq`.
2. `gh auth login`, y firmar los commits con el correo noreply de la cuenta (Settings → Emails en GitHub): `git config --global user.email <id>+<usuario>@users.noreply.github.com`. El script avisa si no coincide.
3. Tener `Metodo` dentro de la carpeta de datos (ver abajo si se comparte con otro sistema).
4. Desde Git Bash o una terminal: `<carpeta de datos>/Metodo/maquina/instalar.sh`.

El script comprueba las dependencias, crea los ficheros que faltan (también los lanzadores de `bin/` en `~/.local/bin`), registra los servidores MCP de usuario de `metodo-maquina.json` (ver abajo) y el marketplace e instala `dev@metodo`. Si un fichero ya existe y no coincide con la plantilla, enseña el diff y no lo toca.

| Opción | Qué hace |
|---|---|
| (ninguna) | Instala lo que falta; para si algo difiere |
| `--comprobar` | Solo compara; sale con 1 si hay diferencias |
| `--sobrescribir` | Reemplaza lo que difiere, con copia `<fichero>.bak-AAAAMMDD-HHMMSS` |
| `--desatendido` | Añade el temporizador de las [sesiones desatendidas](#sesiones-desatendidas): systemd en Linux, launchd en macOS; se combina con las otras |

## Sesiones desatendidas

Un temporizador lanza cada 30 minutos `desatendido/lanzar.sh` (en Linux, uno de systemd de usuario; en macOS, un agente de launchd), que recorre los proyectos con `## Método` (los de `carpetas` de `metodo-maquina.json`, o la carpeta de datos entera) y abre `claude -p "/dev:siguiente"` desde la carpeta de cada uno, para que cargue su `.claude/settings.json`, sus hooks y su `.mcp.json`. `/schedule` no sirve para esto: corre en la nube y no ve el disco.

Un proyecto solo abre sesión si:

1. tiene issues en Ready de su rama actual y la cola de In review no ha llegado a su límite. Lo mira con `gh`, sin gastar una sesión. Los issues que se abren desde el móvil o desde un barrido quedan en Backlog y solo entran cuando se pasan a Ready;
2. su checkout no tiene cambios sin commitear y nadie tiene abierta una sesión de Claude en la carpeta;
3. no hay otra ejecución desatendida en marcha en él (un cerrojo por proyecto, un directorio con el pid de quien lo tiene; si ese pid ya no es un `lanzar.sh`, el cerrojo se recupera).

Cada sesión arranca con `--permission-mode auto`, un tope de gasto (`--max-budget-usd`, 5 USD o lo que diga `METODO_TOPE_USD`) y una instrucción de sistema: nadie puede confirmar nada, así que lo que necesita al usuario se para, se deja dicho en el issue y se sigue con lo demás. Si el proyecto tiene campo `Demo` con Variable, la sesión la lleva en el entorno. Los resultados se ven en GitHub (comentarios del issue y paso a In review) y la salida de cada sesión queda en `~/.local/state/metodo-desatendido/`.

La sesión trabaja en el checkout del proyecto, no en un worktree propio: con `claude -w` trabajaría en otra rama, `/dev:sprint` no cogería los issues de la principal y los commits no llegarían a ella. Por eso la condición 2.

| Orden | Qué hace |
|---|---|
| `maquina/instalar.sh --desatendido` | Instala el `.service` y el `.timer` en `~/.config/systemd/user/` (en macOS, `metodo-desatendido.plist` en `~/Library/LaunchAgents/`), con el `PATH` de esta máquina; se combina con `--comprobar` y `--sobrescribir` |
| `systemctl --user enable --now metodo-desatendido.timer` | Lo activa en Linux (y `disable --now` lo para). Para que corra sin sesión gráfica abierta, `loginctl enable-linger` |
| `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/metodo-desatendido.plist` | Lo carga en macOS (y `launchctl bootout gui/$(id -u)/metodo.desatendido` lo para). Corre mientras la sesión del usuario está abierta |
| `desatendido/lanzar.sh --simular` | Dice qué haría en cada proyecto, sin abrir ninguna sesión |
| `desatendido/lanzar.sh --barridos` | Abre la sesión también sin Ready, para que `/dev:siguiente` recorra los barridos. El temporizador no lo hace: costaría una sesión por proyecto en cada pasada |
| `journalctl --user -u metodo-desatendido` | Lo que decidió en cada proyecto en cada pasada (en macOS, `~/Library/Logs/metodo-desatendido.log`) |

## Canal de Telegram

Un bot de Telegram conectado a una sesión de Claude Code sirve para abrir issues desde el móvil: se le escribe al bot, nombrando el proyecto, y la sesión lo crea en su tablero. Las peticiones de permiso de la sesión también llegan al bot y se aprueban desde allí. La sesión se arranca en la carpeta de datos, así que no carga el `.claude/settings.json`, los hooks ni el `.mcp.json` de ningún proyecto: vale para abrir issues, no para resolverlos (eso lo hacen las [sesiones desatendidas](#sesiones-desatendidas) cuando el issue pasa a Ready).

1. Instalar [Bun](https://bun.sh), con el que corre el servidor del plugin, y el plugin: `/plugin install telegram@claude-plugins-official`.
2. Crear el bot con [@BotFather](https://t.me/BotFather) (`/newbot`) y poner a mano el token que devuelve, `TELEGRAM_BOT_TOKEN=<token>`, en `~/.claude/channels/telegram/.env` o en el entorno de la shell. `/telegram:configure` no sirve: escribe ese `.env` y la regla `Edit(**/.env)` lo bloquea.
3. Arrancar la sesión en la carpeta de datos: `claude --channels plugin:telegram@claude-plugins-official`, y comprobar con `/mcp` que el servidor `telegram` sale conectado; si sale con un aspa, «reconnect». La sesión se deja abierta: el bot solo contesta mientras lo está, y lo que se le escribe con ella cerrada se pierde.
4. Escribir al bot, que contesta con un código, y emparejarlo en la sesión con `/telegram:access pair <código>`. Después, `/telegram:access policy allowlist`, para que el bot no conteste a nadie más.

`settings.plantilla.json` deja usar sin preguntar las respuestas, reacciones y ediciones del bot, y el `CLAUDE.md` global no cuenta este canal como servicio externo. Descargar un adjunto sigue pidiendo permiso; las fotos no pasan por ahí, porque el plugin las descarga solo, pero sí lo que se manda como archivo.

## Reglas de una sola máquina

Lo que solo tiene sentido en una máquina (por ejemplo, bloquear una partición de datos personales que solo existe allí) va en `<config>/metodo-maquina.json`, fuera del repo:

```json
{
  "carpetas": ["Apps", "Cursos"],
  "permissions": { "deny": ["Read(//ruta/privada/**)", "Edit(//ruta/privada/**)"] },
  "mcpServers": { "correo": { "command": "/ruta/datos/Apps/correo/mcp.sh" } }
}
```

- `carpetas`: las carpetas de proyectos dentro de la carpeta de datos. Cada una se puede editar sin preguntar y es directorio de trabajo, y la política de operación autónoma del `CLAUDE.md` global se aplica a sus proyectos. Sin ella, cuenta la carpeta de datos entera.
- `permissions`: sus listas se añaden al final de las de la plantilla.
- `mcpServers`: servidores MCP de un proyecto que se quieren en cualquier sesión, no solo en la carpeta de su proyecto. Tienen la forma de su `.mcp.json`, con rutas absolutas, y el script los registra a nivel de usuario (`claude mcp add-json --scope user`, que los guarda en `~/.claude.json`); `--comprobar` y `--sobrescribir` los tratan como a los ficheros. Sus permisos (qué herramientas se usan sin preguntar y cuáles piden confirmación) van en `permissions`, copiados del `.claude/settings.json` del proyecto: fuera de su carpeta, ese fichero no se carga. El `CLAUDE.md` global hace que la sesión lea el `CLAUDE.md` del proyecto antes de usar sus herramientas. Cuándo conviene: [`doc/piezas.md`](../doc/piezas.md).

## Cambiar la configuración

Un cambio en el `CLAUDE.md` global o en `settings.json` se hace en la plantilla, se commitea y se reinstala con `--sobrescribir` en cada máquina. Si se edita directamente lo instalado, `--comprobar` lo detecta: o se pasa a la plantilla o se descarta.

## Compartir `Metodo` entre dos sistemas

En dual boot con una partición NTFS común, Linux y Windows pueden usar el mismo checkout. Así hay un solo `Metodo` y no dos que se desincronizan, pero git tiene que ignorar lo que cada sistema ve distinto:

- Finales de línea: en Windows, `git config --global core.autocrlf false` (el instalador de Git para Windows lo deja en `true`).
- Permisos de ejecución: `git config core.fileMode false` en el propio repo. Vale para los dos sistemas; un script nuevo se marca ejecutable con `git update-index --chmod=+x <fichero>`.

La alternativa es un clon aparte en cada sistema, sin esos ajustes, a costa de hacer push y pull entre ellos.
