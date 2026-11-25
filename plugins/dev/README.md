# Plugin `dev`

Ciclo de desarrollo con un tablero de GitHub Projects (Status: Backlog → Ready → In progress → In review → Done). Los skills son los mismos para todos los proyectos; lo que cambia entre proyectos lo leen de la sección `## Método` del `CLAUDE.md` del proyecto.

Se instala con `/plugin install dev --marketplace davidbp845/metodo`.

| Skill | Qué hace |
|---|---|
| `/dev:ayuda` | Lista los comandos disponibles en el proyecto (los suyos y los del plugin) |
| `/dev:crear-issue` | Crea un issue en el tablero |
| `/dev:detectar-bug` | Diagnostica un comportamiento y, si es bug real, abre el issue |
| `/dev:resolver-issue` | Implementa y cierra un issue de punta a punta |
| `/dev:sprint` | Encadena todos los issues en Ready, en paralelo los independientes |
| `/dev:siguiente` | Decide qué toca sin preguntar: nada si la cola de In review está llena, el sprint si hay Ready y, si no, los barridos pendientes de `barridos.md` |
| `/dev:crear-retoque` | Apunta un retoque de UI/UX en el issue paraguas de su zona, sin implementarlo |
| `/dev:resolver-retoques` | Resuelve uno a uno los retoques pendientes de una zona |
| `/dev:cerrar-issue` | Cierra un issue verificado y lo pasa a In review |
| `/dev:cerrar-issue-wontfix` | Cierra un issue descartado y lo pasa a Done |
| `/dev:crear-decision` | Registra una ADR y, si implica código, su issue de implementación |
| `/dev:nueva-vision` | Actualiza el documento de visión y, si ya es accionable, abre issues |
| `/dev:higiene-tablero` | Propone qué Done archivar, qué Backlog cerrar o mover y qué etiquetas de rama borrar, y avisa de los issues en In review o Done con commits sin subir |
| `/dev:retro` | Retrospectiva del periodo con 3 mejoras accionables |
| `/dev:retro-metodo` | Retrospectiva agregada de todos los proyectos con `## Método`, desde el repo del método; un hook de usuario la recuerda cada 14 días |
| `/dev:revisar-docs` | Comprueba que la documentación sigue al día tras un cambio |
| `/dev:publicar-version` | Revisa el diff desde la última etiqueta y abre un issue por hallazgo, propone patch o minor, sube el número, etiqueta y publica la release de GitHub, con confirmación antes de etiquetar |
| `/dev:streamlit` | Carga la guía de apps Streamlit del Método o, con `revisar`, contrasta una app con ella y abre un issue con las reglas que no cumple |
| `dev:developing-with-streamlit` | Guía de Streamlit de la versión instalada en el proyecto (se carga antes de tocar un panel; no es un comando) |

## Metodología en tres niveles

[`metodologia.md`](metodologia.md) es la parte común de la metodología de diseño y desarrollo: los niveles A (visión y ADR) y C (ciclo del issue, C1–C7, uno por Status del tablero), y el mantenimiento periódico. Un proyecto la adopta con el campo **Metodología** de su `## Método`, que apunta a su propio documento: este enlaza a la parte común y añade su nivel B y sus ajustes (capas que activan C2 y C3, etiquetas, comprobaciones de C5, destinos de C7).

## Latido de los issues en curso

Mientras una sesión trabaja en un issue *In progress*, el plugin escribe la hora UTC (ISO 8601) en el campo de texto `Latido` del tablero, para que quien lo lea sepa que ese issue se está resolviendo ahora y no lleva días parado. Al pasar por GitHub vale igual en local que en un servidor.

- `/dev:resolver-issue` y `/dev:sprint` lo fijan al pasar el issue a *In progress* (`scripts/latido.sh fijar`); `/dev:cerrar-issue` y el sprint lo quitan al cerrar (`latido.sh quitar <issue>`). Una sesión puede llevar varios a la vez, como los del grupo en paralelo de un sprint.
- Los hooks de `hooks/hooks.json` lo mantienen: `UserPromptSubmit` y `PostToolUse` reescriben la hora como mucho cada 5 minutos, `Stop` vacía el campo al acabar el turno, salvo que la sesión tenga trabajo en segundo plano (tests, evaluaciones…): entonces lo sigue reescribiendo mientras ese trabajo dure (`latido.sh mantener`). `SessionEnd` además olvida los issues. Si la sesión muere sin avisar, el lector lo da por caducado a los 15 minutos.
- Para activarlo en un tablero, se le crea un campo de texto llamado `Latido` (`gh project field-create <número> --owner <owner> --name Latido --data-type TEXT`). Sin él, `fijar` lo dice y no escribe nada. El `gh` de cada máquina necesita el alcance `project`.

## Sprint en paralelo

`/dev:sprint` agrupa hasta 3 issues de Ready que no se citan entre sí ni tocan los mismos ficheros, y los resuelve a la vez: cada uno con un subagente en su propio worktree de la carpeta del código, creado dentro del directorio de git para que no aparezca como fichero sin seguimiento. La sesión principal mueve el tablero, comenta, integra los resultados de uno en uno en la rama de trabajo (rebase y `merge --ff-only`), pasa la Verificación tras cada integración y cierra. Un conflicto al integrar devuelve el issue a la secuencia. El worktree no tiene lo que está fuera de git: el entorno virtual se enlaza desde el checkout principal, y la Verificación que cuenta es la de la rama de trabajo tras integrar. La rama de trabajo es la actual del checkout: la principal o una [rama larga](#ramas-largas).

## Ramas largas

Un issue que va a una rama larga, una funcionalidad que se desarrolla aparte y aún no va a la rama principal, lleva la etiqueta `rama:<nombre de la rama>`. Un issue de la rama principal no lleva ninguna: no tener etiqueta de rama ya quiere decir main, y así un issue creado sin pensar en ramas no se pierde del filtro.

- La etiqueta se crea con la rama y se borra cuando la rama se integra en la principal; los issues abiertos que aún la lleven pasan a ser de main. `/dev:higiene-tablero` propone borrar las etiquetas cuya rama ya no existe o está integrada.
- En el tablero, una vista por rama larga filtra `label:rama:<nombre>`, y la de main la excluye con `-label:rama:<nombre>` (una exclusión por cada rama larga abierta).
- Los skills miran la rama actual de la carpeta del código: `/dev:crear-issue` pone la etiqueta de esa rama si no es la principal; `/dev:sprint` solo coge de Ready los issues de esa rama, crea los worktrees desde ella e integra en ella; `/dev:resolver-issue` avisa y pregunta si el issue es de otra rama.

## Repos por área

Un tablero puede tener issues en varios repos: los de un área (p. ej. `marketing`, sin código) en un repo, y el resto en el de siempre. El campo **Repos por área** da, para cada etiqueta de área, su repo y su carpeta, y opcionalmente su Verificación. Sin el campo, todo va al repo de **Repo** (o al de la raíz).

- **Repo de un issue**: el de la línea de su etiqueta de área; si no lleva ninguna listada, el de **Repo**. Un issue con dos etiquetas listadas que apuntan a repos distintos es ambiguo: se pregunta. Al crear un issue, primero se elige la etiqueta de área y de ella sale el repo donde se abre.
- **Carpeta del código**: la de esa misma línea. Ahí se leen `doc/`, se edita, se hace el commit y se mira la rama; los `gh` del issue llevan `-R <su repo>`.
- **Verificación**: la de la línea del área, si la lleva. Si no, no hay verificación automática: el comentario de cierre dice qué tiene que revisar el usuario en In review. Las Verificaciones extra solo cuentan para el repo de **Repo**.
- **Número de issue suelto** (`/dev:resolver-issue 12`): se busca entre los items del tablero (`gh project item-list`, cuyo `content.repository` da el repo de cada uno). Si el número está en más de un repo, se pregunta. También vale `owner/repo#12`.
- **Listados del tablero entero** (`/dev:sprint`, `/dev:higiene-tablero`, `/dev:retro`): el tablero ya da los items de todos los repos; cada comando sobre un issue usa el repo del item, y lo que se lista por repo (`gh issue list`, eventos, commits) se pide a cada repo del proyecto. `scripts/metricas.sh` mide cada repo y suma.

## Modo demo

Un proyecto con el campo **Demo** tiene, junto a sus datos reales, una carpeta de datos inventados y un fichero sin secretos que elige cuál usa la app. Así un cambio visible se prueba entero sin riesgo y sin rehacer datos en cada issue.

- `/dev:resolver-issue`, `/dev:sprint` y `/dev:resolver-retoques` no verifican nunca contra los datos reales: lo visible se comprueba en la app arrancada en demo, y cada orden que ejecuta la app para verificar lleva la Variable, que manda sobre el fichero solo en ese proceso. En el sprint en paralelo, esa comprobación la hace la sesión principal al integrar, porque el worktree no está donde la app busca sus datos.
- El modo del fichero solo se cambia con confirmación del usuario (regla del `CLAUDE.md` global y `scripts/hook-demo.sh`), y antes de una acción que escribe a través de la app se mira en qué modo está. Un servidor MCP sigue el fichero, no la Variable.

Pautas para los datos de demo:

1. Inventados de principio a fin: nombres, direcciones con dominios `.example` o `ejemplo.org`, textos e importes. Nunca se copia nada de los datos reales, ni para anonimizarlo después.
2. Cubren cada flujo de la app con al menos un caso de cada rama (el que dispara cada regla, el que no dispara ninguna, el vacío y el erróneo). Los fixtures de los tests son el punto de partida.
3. Viven donde los datos reales, con la misma estructura, para que el código solo cambie la carpeta raíz.
4. Si el proyecto tiene contenedor sin remoto, se versionan en él y no en el repo público; los cambios se commitean cuando el usuario lo pide, diciendo qué se generó.

## Reglas comprobadas por hook

Las reglas del Método que se pueden comprobar sin interpretar texto las aplica `hooks/hooks.json` en todos los proyectos que activan el plugin, en vez de depender de que Claude las recuerde:

- `scripts/hook-git.sh` (antes de cada Bash) rechaza `git add -A`, `.`, `-u` o `*` y `git commit -a`, que pueden meter cambios de otra sesión, y un asunto de `git commit -m` que no empiece por `feat`, `fix`, `docs`, `refactor`, `test`, `chore` o `perf` (con ámbito o sin él). Pide confirmación para un `feat` o `fix` (también `feat!`) sin pie `Issue: #NN` o `Issues:`, que puede ser un olvido o trabajo que no sale de ningún issue; para encontrar el pie lee el mensaje entero, del heredoc hasta su delimitador o de todos los `-m`. Un mensaje en una variable o en `-F fichero` no lo lee y lo deja pasar.
- `scripts/hook-done.sh` (antes de cada Bash) pide confirmación al pasar un item del tablero a Done con `gh project item-edit`, salvo que el issue esté cerrado como *not planned* (`/dev:cerrar-issue-wontfix`). Si GitHub no responde, deja pasar.
- `scripts/hook-demo.sh` (antes de cada Edit, Write o Bash) pide confirmación al cambiar el Fichero del campo **Demo**: con Edit o Write, o desde Bash con las escrituras habituales (`>`, `sed -i`, `tee`, `mv`, `cp`...) en una orden que lo nombra. Leerlo no pide nada.
- `scripts/hook-formateador.sh` (tras cada Edit o Write) pasa por el fichero editado la orden del campo **Formateador** de `## Método`. Si la orden falla, Claude ve su salida.

## Sección `## Método` del proyecto

Los skills la leen al empezar. Si falta un dato obligatorio, el skill lo dice y para, en vez de suponerlo.

```markdown
## Método

- Tipo: dev
- Tablero: proyecto GitHub "Nombre" (owner `<owner>`, número `N`)
- Repo: `<owner>/nombre` en `carpeta/`
- Repos por área:
  - `marketing`: `<owner>/nombre-negocio` en `.`
  - `datos`: `<owner>/nombre-datos` en `../datos/`, Verificación `venv/bin/pytest`
- Verificación: `venv/bin/pytest`, `venv/bin/ruff check .`
- Formateador: `venv/bin/ruff format` para `*.py`
- Metodología: `doc/A0-Metodologia/metodologia-de-diseno-y-desarrollo.md`
- Documentación: `doc/nombre/`
- Etiquetas de área: `frontend`, `datos`, `infraestructura`, `marketing`
- Etiquetas de tipo: solo bug
- Repos relacionados: `../otro-repo`
- Límite de In review: 10
- Verificaciones extra:
  - Si el cambio toca `X`, verificar además con `Y`.
- Retoques:

| Zona | Issue paraguas | Carpeta | Encadena |
|---|---|---|---|
| panel | "Panel: ajustes finos varios" | `panel/` | sí |

- Mapa de documentación:

| Si cambia... | ...debe estar al día en |
|---|---|
| Variable de entorno | `.env.example` |

- Versionado:
  - Minor: el cambio obliga a tocar la configuración de quien usa el proyecto
  - Fichero: `pyproject.toml`
  - Apartado de minor: Cambios para los usuarios
  - Review: `medium`
- Demo:
  - Fichero: `configuracion.toml` (`modo = "demo"` o `modo = "real"`)
  - Datos: `datos-demo/`
  - Arranque: `./start.sh --demo --server.port 8515` desde `nombre/`, en `http://localhost:8515`
  - Variable: `NOMBRE_MODO=demo`
```

| Campo | Obligatorio | Uso |
|---|---|---|
| Tipo | No | Plugin del Método al que corresponde la sección (`dev`). Ningún skill lo lee: deja claro qué plugin usa el proyecto. Si un proyecto deja de usar `dev`, se quita la sección y se desactiva el plugin en su `.claude/settings.json` (`"enabledPlugins": {"dev@metodo": false}`); solo con la sección quitada, el plugin se sigue cargando |
| Tablero | Sí | Dónde se crean, mueven y cuentan los issues |
| Repo | No | Repo de GitHub y carpeta del código, cuando no son la raíz del proyecto (p. ej. el código está en un submódulo y la raíz no tiene remoto). Con él, los `gh` llevan `-R <repo>` y `doc/`, código, Verificación y commits se toman de esa carpeta |
| Repos por área | No | Repo de GitHub, carpeta y, opcionalmente, Verificación de los issues de una etiqueta de área, una línea por etiqueta. Las etiquetas que no aparecen van al repo de **Repo**. Ver [Repos por área](#repos-por-área) |
| Verificación | Sí | Comandos que deben pasar antes de cerrar un issue |
| Formateador | No | Orden que formatea un fichero y los patrones de nombre a los que se aplica (`` `orden` para `*.py` ``; varias, separadas por `;`). El hook la ejecuta tras cada edición, desde la carpeta del campo Repo o la raíz, con el fichero como último argumento y solo si está dentro de esa carpeta. Sin él, no se formatea nada |
| Metodología | No | Documento de la metodología en tres niveles del proyecto: su nivel B y sus ajustes a los niveles A y C comunes de [`metodologia.md`](metodologia.md), al que enlaza. Con él, `/dev:crear-issue` sigue el índice del cuerpo del issue, `/dev:cerrar-issue` el de la verificación, y `/dev:resolver-issue` y `/dev:sprint` añaden el diseño técnico o UX que faltaba. Sin él, no se aplica tampoco la parte común: no se exige diseño previo y no hay documento de visión ni carpeta de ADR |
| Documentación | No | Carpeta de la visión (A1) y de las carpetas de etapa C (`C3-UX-UI`, `C7-Cierre`...) de este tablero, dentro de la carpeta del código, cuando varios tableros comparten repo y cada uno tiene su documentación (`doc/<proyecto>/`). `/dev:retro` guarda ahí sus retros y `/dev:nueva-vision` edita ahí la visión. La metodología (A0), las ADR (A2) y el despliegue (A3) siguen en `doc/`, comunes al repo. Vale con o sin barra final. Sin él, `doc/` |
| Etiquetas de área | No | Sin ella, se usan las etiquetas que existan en el repo |
| Repos relacionados | No | Otros repos cuyos commits cuentan en `/dev:retro` y `/dev:revisar-docs` |
| Etiquetas de tipo | No | `solo bug`: el issue lleva de tipo solo `bug`, cuando lo es. Sin él, siempre una de tipo (`bug`, `enhancement` o `documentation`) |
| Límite de In review | No | Tamaño de la cola de revisión a partir del cual el sprint para (10 por defecto) |
| Verificaciones extra | No | Reglas de verificación por zona del código, propias del proyecto |
| Retoques | No | Zonas con issue paraguas de retoques para `/dev:crear-retoque` y `/dev:resolver-retoques`: título del paraguas, carpeta del código y si se resuelven seguidos (`sí`) o con pausa entre uno y otro (`no`). Una quinta columna opcional, **Status**, da el Status en que vive el paraguas (In progress si no la hay); con `Done` el paraguas es permanente: sigue abierto pero fuera de la vista del tablero, y no se cierra al quedarse sin pendientes. Sin el campo, esos skills no se usan |
| Mapa de documentación | No | Qué documento debe reflejar cada tipo de cambio. Sin él, `/dev:revisar-docs` revisa `README.md`, `CLAUDE.md`, `doc/` y los `.env.example` |
| Demo | No | Modo demo con datos inventados. Subcampos: **Fichero**, el que elige el modo y el valor de cada uno; **Datos**, la carpeta de datos de demo; **Arranque**, la orden que arranca la app en demo, desde dónde y en qué puerto o URL; **Variable**, opcional, la que fuerza el modo en una sola orden. Las rutas son relativas a la raíz del proyecto, no a la carpeta del campo Repo. Ver [Modo demo](#modo-demo) |
| Versionado | No | Cómo publica versiones `/dev:publicar-version` (SemVer, etiquetas `vX.Y.Z` y releases de GitHub). Subcampos: **Minor**, cuándo un cambio sube minor (obligatorio; lo demás es patch); **Major**, si el proyecto ya tiene criterio de major (sin él, major solo si el usuario lo pide); **Fichero**, dónde vive el número (por defecto `pyproject.toml` o `package.json`); **Apartado de minor**, título del apartado escrito a mano que acompaña a una minor en la release (sin él, solo notas generadas). **Review**, nivel del skill `code-review` que revisa el diff desde la última etiqueta antes de proponer el número (`low` a `max`, o `no` para saltarlo; sin él, `low` en un patch, `medium` en una minor y `high` en una major). Sin el campo, el proyecto no versiona y el skill termina sin hacer nada |

Las tablas de Retoques y Mapa de documentación van sin sangría y entre líneas en blanco, fuera de la lista: Obsidian no pinta una tabla dentro de un elemento de lista.

Sin el campo Repo, el repo de GitHub se deduce de `gh repo view --json nameWithOwner` en la raíz del proyecto.

## Evals

`evals/` tiene una suite de `claude plugin eval` con un caso por skill del ciclo (`crear-issue`, `resolver-issue`, `cerrar-issue`, `sprint`, `publicar-version`), uno del sprint en paralelo (`sprint-paralelo`), uno del sprint en una rama larga (`sprint-rama`), uno de `resolver-issue` en un proyecto con modo demo (`resolver-issue-demo`), otro con un issue de un área de Repos por área (`resolver-issue-areas`) uno del modo `revisar` de `streamlit` y uno de `siguiente` sin nada en Ready, que lanza el barrido de Streamlit. Comprueba lo que hace cada skill, no solo la forma del plugin: Status final, etiquetas, orden de los pasos, nunca Done y nunca push (salvo `publicar-version`, que sube el commit de versión y la etiqueta tras la confirmación). Se ejecuta con `evals/ejecutar.sh` (opciones extra, como `--case crear-issue` o `--runs 1`, se pasan tal cual). Cuesta alrededor de 3 USD con las dos pasadas por caso, y los resultados quedan en `evals/results/`, fuera de git.

Ningún caso toca GitHub: no tienen Bash, y una instrucción de sistema le pide al agente que apunte cada comando `gh` y `git` en vez de ejecutarlo y que los repita todos en un bloque `sh` al final. Los evaluadores `regex` miran ese bloque. Cada caso parte del proyecto de ejemplo de `evals/comun/proyecto.sh`, un repo git con un `## Método` genérico; el de `publicar-version` tiene el suyo, con etiquetas y el campo Versionado, y el de `publicar-version-hallazgo` lo reutiliza con un fallo en el diff, el de `streamlit`, con una app que incumple varias reglas de la guía (y el de `siguiente` lo reutiliza), y el de `sprint-paralelo` añade un segundo módulo para tener dos issues que no tocan los mismos ficheros, el de `resolver-issue-demo`, el campo Demo con datos reales y de demo y un listado que lee unos u otros, y el de `resolver-issue-areas`, el área `marketing` en un segundo repo sin código. Como los casos no lanzan subagentes, en `sprint-paralelo` el agente apunta una línea por subagente y hace él el cambio.

Al crear o cambiar un skill del ciclo, se añade o se ajusta su caso:

1. `evals/<skill>/case.yaml`, copiando uno existente: el mismo `append_system_prompt`, el enlace `proyecto.sh -> ../comun/proyecto.sh` (el scaffold no puede salir de la carpeta del caso) y un `prompt` que nombre el skill y dé los datos que pediría (resultados de búsqueda, Status actual...), porque no puede preguntar.
2. Evaluadores: `tool_used` con `tool: Skill` e `input_match: <skill>` para comprobar que se carga; `regex` sobre los comandos (con `match: not_contains` para lo que nunca debe pasar); y un `llm` solo para lo que no cabe en una regex, como el orden de los pasos.
3. `evals/ejecutar.sh --case <skill> --runs 1` mientras se ajusta, y la suite entera antes del commit.
