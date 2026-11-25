---
name: retro-metodo
description: Retrospectiva agregada de todos los proyectos con `## Método`, para medir si un cambio del método común ha servido
argument-hint: ventana, 14d por defecto (ej. 14d, 30d, 2w)
---
Retrospectiva del método común en la ventana "$ARGUMENTS" (`14d` por defecto; acepta `Nd` o `Nw`): junta las métricas de proceso de todos los proyectos con `## Método` en una tabla por proyecto y un total, y la compara con la anterior. Mide el proceso, no la productividad, como `/dev:retro`; la retro de un proyecto concreto sigue siendo `/dev:retro`.

Se ejecuta desde el repo del método común. Es solo lectura salvo el paso 6.

1. **Ventana**: fecha de inicio a partir de la fecha de hoy que da el sistema (`AAAA-MM-DD`). Si el argumento no tiene forma `Nd`/`Nw`, enseña el uso y termina.
2. **Proyectos**: la carpeta de datos es la que contiene el repo del método. Son proyectos los `CLAUDE.md` con `## Método` hasta tres niveles por debajo, sin seguir enlaces: `find <datos> -maxdepth 3 -type f -name CLAUDE.md -not -path '*/node_modules/*' -exec grep -l '^## Método' {} +`.
3. **Datos**: para cada proyecto, en paralelo, `<carpeta del plugin>/scripts/metricas.sh <carpeta del proyecto> <inicio>` (la carpeta del plugin está dos niveles por encima de la de este skill). Da una línea JSON por proyecto; un `null` es un dato que no se pudo obtener y se escribe "no disponible", nunca 0. Si un proyecto falla entero, se dice y se sigue con los demás. Con `compartido: true`, el repo lo comparten varios tableros: los issues y los commits del proyecto son solo los de su tablero, y `repo_sin_tablero` (commits que no citan un issue de ningún tablero, con las mismas métricas de commits) es el mismo en todos los proyectos de ese `repo`. Con `repos_area`, el proyecto tiene issues en más repos (campo Repos por área) y sus cifras ya suman todos.
4. **Tabla** por proyecto, más una fila de total, con estas columnas:
   - Cerrados (y wontfix entre paréntesis), abiertos y saldo (abiertos − cerrados − wontfix).
   - In review: cuántos y días del más viejo.
   - Reaperturas y `fix` sobre un issue cerrado antes de la ventana.
   - Commits, y `fix` sobre los commits que no son `docs`/`chore` en %, con el issue que más `fix` concentra (`fix_max`, como `#NN (n)`; sin fila de total). Una tasa que sube por los `fix` de un solo issue es la cola de esa funcionalidad, no un deterioro general: los patrones y la comparación lo leen así.
   - Commits sin pie `Issue: #NN` que no son `docs`/`chore`.
   Un proyecto sin commits ni issues en la ventana va en una línea aparte, debajo de la tabla, en vez de una fila de ceros.
   Los proyectos que comparten `repo` van en filas seguidas, cada uno con lo suyo, y debajo una fila `<repo> sin tablero` con las columnas de commits de `repo_sin_tablero`; esa fila cuenta una vez en el total, aunque la den todos los proyectos del repo.
5. **Comparación** con la retro agregada anterior más reciente en `local/retros/` del repo del método: delta del total y de cada proyecto que cambie de forma notable, y para cada una de sus mejoras, `hecha` / `parcial` / `pendiente` con la evidencia. Si es la primera, dilo: es la línea base. Si entre las dos retros hay commits del repo del método que cambian el proceso (`feat`/`fix` de `plugins/`, `maquina/` o `estilo/`), nómbralos: son los cambios cuyo efecto se está midiendo.
6. **Informe y guardado**: en la conversación, una frase de resumen, la tabla, la comparación, 2–4 patrones apoyados en datos y hasta 3 mejoras accionables para el método común (cada una con el dato que la motiva y dónde se aplicaría). Escribe lo mismo en `local/retros/AAAA-MM-DD.md` del repo del método (sufijo `-2` si ya existe), con la ventana y la lista de proyectos medidos. `local/` está ignorada por git: la retro nombra proyectos de una máquina, así que no se hace commit. Solo números, nombres de proyecto y de repo y números de issue, nunca datos reales de un proyecto.
7. Pregunta qué mejoras convertir en issue del tablero del método, y solo tras confirmación invoca `dev:crear-issue` (Skill tool).
