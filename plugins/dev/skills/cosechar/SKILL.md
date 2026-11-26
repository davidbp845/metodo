---
name: cosechar
description: Busca en las apps Streamlit de todos los proyectos con `## Método` soluciones repetidas que la guía no recoge, y abre un issue por patrón en el tablero del método
argument-hint: ventana, 30d por defecto (ej. 30d, 6w)
---
Cosecha de patrones en la ventana "$ARGUMENTS" (`30d` por defecto; acepta `Nd` o `Nw`): cuando dos o más proyectos resuelven lo mismo de la misma forma en sus apps Streamlit (un patrón de caché, un componente hecho a mano, un truco de CSS) y `guia.md` del skill `streamlit` no lo dice, propone la regla. No edita la guía: una regla nueva cambia todos los proyectos y pasa por issue, `/dev:resolver-issue` y revisión. Se ejecuta desde el repo del método común y no pregunta nada; lo que abre va a Backlog.

1. **Ventana**: fecha de inicio a partir de la fecha de hoy que da el sistema (`AAAA-MM-DD`). Si el argumento no tiene forma `Nd`/`Nw`, enseña el uso y termina.
2. **Proyectos y apps**: los proyectos son los de `/dev:retro-metodo` (paso 2): `CLAUDE.md` con `## Método` hasta tres niveles por debajo de la carpeta de datos, la que contiene el repo del método. De cada uno, la carpeta del código es la de su campo **Repo** (o las de **Repos por área**) o, sin ninguno, la del `CLAUDE.md`. Tiene app si en esa carpeta hay un `.py` fuera de `venv/`, `.venv/` y `tests/` que llama a `st.set_page_config`; la carpeta de la app es la de ese fichero, y un proyecto puede tener varias. Con menos de dos apps no hay nada que comparar: dilo y termina.
3. **Lo que cambió**: de cada app, los commits de la ventana que tocan su carpeta, sin los de `docs`/`chore` (`git -C <carpeta del código> log --since=<inicio> --format='%h %s' -- <carpeta de la app>`), y su diff (`git show <hash> -- <carpeta de la app>`). Una app sin commits en la ventana no aporta nada nuevo, pero su código actual sí vale como segunda aparición de un patrón que otra app acaba de añadir: búscalo con `grep` en ella antes de descartarlo.
4. **Patrones**: lee `guia.md` (en la carpeta del skill `streamlit`, junto a esta) y, si existe, `local/streamlit.md` del repo del método. Un patrón cuenta si cumple las tres cosas:
   - Aparece en dos o más proyectos distintos, no en dos apps del mismo proyecto.
   - Es la misma solución al mismo problema, no solo el mismo widget: dos `st.cache_data` con fines distintos no son un patrón; dos funciones que vacían la caché tras guardar con la misma idea, sí.
   - Ninguna regla de la guía lo dice ya, ni lo contradice. Si lo contradice, es una duda para el resumen (la guía manda o una app se aparta), no un patrón.
   Lo que no llega a dos proyectos se queda fuera, aunque sea buena idea.
5. **Duplicados**: para cada patrón, busca en el repo del método un issue abierto o cerrado que ya lo proponga (`gh issue list --state all --search '<términos clave>' --json number,title,state`). Si lo hay, no abre otro: lo nombra en el resumen.
6. **Evidencia local**: escribe `local/cosechas/AAAA-MM-DD.md` en el repo del método (sufijo `-2` si ya existe), con la ventana, las apps leídas y, por patrón, el proyecto, el fichero con su línea y el commit de cada aparición. `local/` está ignorada por git: el repo del método es público y la evidencia nombra proyectos y rutas de esta máquina.
7. **Un issue por patrón nuevo**, con `dev:crear-issue` (Skill tool) en el repo del método, con `enhancement` y la etiqueta de área que el `## Método` del repo del método da a los skills del plugin `dev`. El cuerpo es genérico, sin nombres de proyecto, rutas ni commits de otros repos:
   - Situación: el problema que resuelve el patrón y en cuántos proyectos aparece, con la referencia a `local/cosechas/AAAA-MM-DD.md` de la máquina para la evidencia.
   - Regla propuesta: tipo (`A` si cambia lo que se ve, `T` si es técnica), el texto en el formato de la guía (enunciado y línea «Cómo:») y un fragmento de código genérico si hace falta.
   - Plan: añadir la regla a `guia.md` y, si es de aspecto, cómo comprobarla con `/dev:streamlit revisar`.
8. **Resumen**: apps leídas y commits por app, patrones con su issue (o el que ya existía), las dudas del paso 4 y la ruta del fichero de evidencia. Si no sale ningún patrón, dilo en una línea.
