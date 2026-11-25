# Configuración de máquina

Lo que Claude Code lee del directorio de configuración del usuario (`~/.claude`, o `$CLAUDE_CONFIG_DIR`) y vale en todas las máquinas: el `CLAUDE.md` global, `settings.json` (permisos, hooks, marketplace del método) y los hooks de usuario. Estos ficheros son la fuente; el `~/.claude` de cada máquina se genera a partir de ellos con `instalar.sh`.

| Fichero | Se instala como |
|---|---|
| `CLAUDE.plantilla.md` | `<config>/CLAUDE.md` |
| `settings.plantilla.json` | `<config>/settings.json` |
| `hooks/*` | `<config>/hooks/*` |

El mapa completo de lo que Claude Code lee y escribe en una máquina (configuración de usuario, este repo y cada proyecto) está en `ficheros.md`.

Los hooks de usuario: `git-push-borrar-rama.sh` pide confirmación antes de borrar una rama remota, y `recordar-retro-metodo.sh` avisa al empezar sesión cuando la última retro agregada de `local/retros/` (`/dev:retro-metodo`) tiene 14 días o más, para que tenga cadencia fija sin depender de acordarse.

Las plantillas no llevan rutas de una máquina: `{{DATA}}` es la carpeta que contiene `Metodo` y las carpetas de proyectos, en forma POSIX para las reglas de permisos (`/d/Data` en Git Bash), y `{{DATA_NATIVA}}` la misma carpeta en la forma del sistema para las importaciones `@`, los directorios y el marketplace (`D:/Data`). En Linux las dos coinciden. El script las deduce de dónde está `Metodo`. `{{PROYECTOS}}` es la ruta de las carpetas de proyectos de `metodo-maquina.json` (ver abajo), o `{{DATA_NATIVA}}` si no declara ninguna.

## Instalar en una máquina nueva

1. Instalar `git`, `gh`, `jq` y Claude Code. En Windows, Claude Code ejecuta los comandos con Git Bash, que trae `grep` pero no `jq`: `winget install Git.Git GitHub.cli jqlang.jq`.
2. `gh auth login`, y firmar los commits con el correo noreply de la cuenta (Settings → Emails en GitHub): `git config --global user.email <id>+<usuario>@users.noreply.github.com`. El script avisa si no coincide.
3. Tener `Metodo` dentro de la carpeta de datos (ver abajo si se comparte con otro sistema).
4. Desde Git Bash o una terminal: `<carpeta de datos>/Metodo/maquina/instalar.sh`.

El script comprueba las dependencias, crea los ficheros que faltan, registra el marketplace e instala `dev@metodo`. Si un fichero ya existe y no coincide con la plantilla, enseña el diff y no lo toca.

| Opción | Qué hace |
|---|---|
| (ninguna) | Instala lo que falta; para si algo difiere |
| `--comprobar` | Solo compara; sale con 1 si hay diferencias |
| `--sobrescribir` | Reemplaza lo que difiere, con copia `<fichero>.bak-AAAAMMDD-HHMMSS` |

## Reglas de una sola máquina

Lo que solo tiene sentido en una máquina (por ejemplo, bloquear una partición de datos personales que solo existe allí) va en `<config>/metodo-maquina.json`, fuera del repo:

```json
{
  "carpetas": ["Apps", "Cursos"],
  "permissions": { "deny": ["Read(//ruta/privada/**)", "Edit(//ruta/privada/**)"] }
}
```

- `carpetas`: las carpetas de proyectos dentro de la carpeta de datos. Cada una se puede editar sin preguntar y es directorio de trabajo, y la política de operación autónoma del `CLAUDE.md` global se aplica a sus proyectos. Sin ella, cuenta la carpeta de datos entera.
- `permissions`: sus listas se añaden al final de las de la plantilla.

## Cambiar la configuración

Un cambio en el `CLAUDE.md` global o en `settings.json` se hace en la plantilla, se commitea y se reinstala con `--sobrescribir` en cada máquina. Si se edita directamente lo instalado, `--comprobar` lo detecta: o se pasa a la plantilla o se descarta.

## Compartir `Metodo` entre dos sistemas

En dual boot con una partición NTFS común, Linux y Windows pueden usar el mismo checkout. Así hay un solo `Metodo` y no dos que se desincronizan, pero git tiene que ignorar lo que cada sistema ve distinto:

- Finales de línea: en Windows, `git config --global core.autocrlf false` (el instalador de Git para Windows lo deja en `true`).
- Permisos de ejecución: `git config core.fileMode false` en el propio repo. Vale para los dos sistemas; un script nuevo se marca ejecutable con `git update-index --chmod=+x <fichero>`.

La alternativa es un clon aparte en cada sistema, sin esos ajustes, a costa de hacer push y pull entre ellos.
