---
name: retro
description: Retrospectiva del periodo (por defecto 7 días) a partir de commits e issues, con 3 mejoras accionables
argument-hint: ventana, 7d por defecto (ej. 14d, 30d, 2w)
---
Retrospectiva del trabajo en la ventana "$ARGUMENTS" (`7d` por defecto; acepta `Nd` o `Nw`). Un único desarrollador + Claude, commits `tipo(ámbito): resumen` con pie `Issue: #NN`, tablero en GitHub Projects. Mide lo que ayuda a decidir qué cambiar en el proceso, no productividad: nada de rankings, horas pico ni líneas por hora.

Si `## Método` indica **Repo**, todos los comandos `gh` llevan `-R <repo>`, y `doc/`, el código, la Verificación y los commits son los de la carpeta que indica, no los de la raíz del proyecto. Con **Repos por área**, el repo, la carpeta y la Verificación son los del área del issue, con las reglas de [Repos por área](../../README.md#repos-por-área).

Es solo lectura salvo el paso 6. Lee antes la sección `## Método` del `CLAUDE.md` del proyecto (tablero, repos relacionados, retoques, metodología, documentación). La carpeta de las retros es `<Documentación>/C7-Cierre/retros/`, con la carpeta del campo **Documentación** (`doc/` si no lo tiene).

1. **Ventana**: fecha de inicio a partir de la fecha de hoy que da el sistema, alineada a medianoche (`--since "AAAA-MM-DDT00:00:00"`). Si el argumento no tiene forma `Nd`/`Nw`, enseña el uso y termina.
2. **Datos**, antes de interpretar nada:
   - Commits del repo y de los repos relacionados: `git -C <repo> log --since ... --format='%h%x09%ad%x09%s' --date=short`, y `--name-only` para los ficheros. Rutas absolutas, nunca `cd` + lectura recursiva.
   - Issues cerrados en la ventana (`gh issue list --state closed --search "closed:>=<inicio>" --json number,title,labels,closedAt,stateReason`) y abiertos (`created:>=<inicio>`).
   - Reaperturas: `gh api repos/<owner>/<repo>/issues/events --paginate --jq '.[] | select(.event=="reopened") | {n: .issue.number, t: .issue.title, at: .created_at}'`, filtradas por la ventana.
   - Items del tablero por Status (`gh project item-list <número> --owner <owner> --format json --limit 500`).
   - Si `## Método` tiene tabla de Retoques: los comentarios `**Retoque:**` añadidos en la ventana a sus issues paraguas.
   - La retro anterior más reciente en la carpeta de las retros, si existe.
3. **Métricas**, en una tabla corta, cada fila con su dato real (si no se pudo obtener, "no disponible", nunca 0):
   - Issues cerrados (completados vs wontfix) y abiertos; saldo neto del Backlog.
   - Issues esperando en **In review** y antigüedad del más viejo (fecha de cierre del issue de cada item, cruzado por número y repo: [Item de un issue en el tablero](../../README.md#item-de-un-issue-en-el-tablero)): es la revisión del usuario, el cuello de botella típico.
   - Reaperturas y commits `fix` que citan un issue cerrado antes de la ventana (señal de verificación insuficiente).
   - Commits por tipo y por repo, y el issue con más commits `fix` (por su pie `Issue:`) y cuántos. Si `fix` supera el 50 %, señálalo, y di si sale sobre todo de ese issue: entonces es la cola de una funcionalidad, no un deterioro general.
   - Puntos calientes: ficheros tocados 5+ veces.
   - Commits sin pie `Issue: #NN` que no sean `docs`/`chore` (trabajo fuera del tablero).
   - Retoques nuevos por zona, si hay tabla de Retoques, y si se repite el mismo tipo de retoque.
4. **Comparación con la retro anterior**, si la hay: delta de las métricas comparables y, para cada una de sus 3 mejoras, `hecha` / `parcial` / `pendiente` con la evidencia. Si es la primera, dilo en una línea.
5. **Informe** en la conversación, en este orden y sin secciones vacías:
   - Una frase de resumen del periodo.
   - Lo entregado: issues cerrados agrupados por etiqueta de área, uno por línea con su número.
   - La tabla de métricas y, si aplica, la comparación.
   - Patrones: 2–4 observaciones concretas apoyadas en datos. Sin elogios genéricos.
   - **3 mejoras** accionables, cada una con el dato que la motiva y dónde se aplicaría: un issue nuevo, un cambio de un skill o de la metodología, una memoria de feedback, el destino que la Metodología del proyecto dé al aprendizaje (p. ej. una nota técnica), o una regla del repo del método común si vale para todos los proyectos. Si no hay tres con fundamento, pon menos.
6. **Guardar**: escribe `AAAA-MM-DD.md` en la carpeta de las retros (sufijo `-2` si ya existe) con la ventana, la tabla de métricas y las 3 mejoras literales. Commit local `docs(retro): retrospectiva AAAA-MM-DD`. El skill no hace push, pero la retro sube con los demás commits del repo cuando el usuario sube: solo lleva métricas, números de issue y hashes, nunca datos reales.
7. Pregunta qué mejoras convertir en issue, memoria o cambio de skill, y solo tras confirmación invoca `dev:crear-issue` (Skill tool) o escribe la memoria. Editar un skill, un `CLAUDE.md` o el repo del método sigue necesitando confirmación explícita. Revisa también si alguna memoria de feedback del proyecto vale para todos y propón pasarla al método común.

Si la ventana no tiene commits ni issues cerrados, dilo, sugiere una ventana más larga y termina sin guardar nada.
