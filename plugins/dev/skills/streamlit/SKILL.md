---
name: streamlit
description: Carga la guía de apps Streamlit del Método o, con `revisar`, contrasta una app con ella y abre un issue con lo que no cumple
argument-hint: "[revisar]"
---
Si `## Método` indica **Repo**, todos los comandos `gh` llevan `-R <repo>`, y `doc/`, el código, la Verificación y los commits son los de la carpeta que indica, no los de la raíz del proyecto. Con **Repos por área**, el repo, la carpeta y la Verificación son los del área del issue, con las reglas de [Repos por área](../../README.md#repos-por-área).

La guía es `guia.md`, en la carpeta base de este skill: reglas de aspecto (`A1`, `A2`…), que mandan, y reglas técnicas (`T1`, `T2`…). Este skill no cambia código. Si el repo del método común (la carpeta `Metodo` que nombra el `CLAUDE.md` global) tiene `local/streamlit.md`, es el complemento de esta máquina: qué apps sirven de modelo para cada regla y cuáles la cumplen. Se lee junto a la guía; sin él, la guía basta.

## Sin argumento: cargar la guía

1. Lee `guia.md` entera y, si existe, `local/streamlit.md`.
2. Aplícala en el resto de la sesión a todo lo que se cree o cambie en una app Streamlit.
3. Confirma en una línea que está cargada, con el número de reglas de cada tipo.

## `revisar`: contrastar una app con la guía

1. **Localiza la app** en la carpeta del código (la de **Repo**, o la raíz del proyecto). El fichero de entrada es el que se pasa a `streamlit run` (en `start.sh`, el `README` o el `CLAUDE.md`) o, si no consta, el `.py` que llama a `st.set_page_config` fuera de `venv/`, `.venv/` y `tests/`. Si no hay ninguna app, dilo y para. Si hay varias, pregunta cuál.
2. **Lee lo que hace falta**: `guia.md` entera, `local/streamlit.md` si existe, el fichero de entrada y los módulos de página que importa, y el `.streamlit/config.toml` de la carpeta desde la que se arranca. Mira la versión instalada de Streamlit (`venv/bin/python -c "import streamlit; print(streamlit.__version__)"`): algunas reglas piden una versión mínima. Si no se puede leer, la regla que dependa de ella se da por cumplida en cuanto a versión y se dice en el resumen.
3. **Contrasta cada regla** y clasifícala en cumple, no cumple o no aplica:
   - No aplica cuando la regla no tiene sobre qué actuar (A8 en una app de un solo idioma; A7 o T5 sin tablas ni listas).
   - Las reglas que dicen "en las que tenga sentido" se aplican con criterio. Si dudas, cuenta como no aplica y se nombra en el resumen como duda.
   - Si `doc/` del proyecto (visión o ADR) fija a propósito lo que la regla prohíbe, la regla cuenta como no cumplida y la casilla nombra el documento. Propón sustituir la decisión con `/dev:crear-decision`, sin hacerlo.
4. **Si todo cumple**, dilo y para: no se crea issue.
5. **Si algo no cumple**, crea un solo issue con `dev:crear-issue` (Skill tool), titulado `Adaptar la app Streamlit a la guía del Método` (con el nombre de la app si el proyecto tiene más de una). Cuerpo: una frase de situación, la referencia a la guía (`plugins/dev/skills/streamlit/guia.md` del repo del método) y una casilla por regla no cumplida, en el orden de la guía:

   ```markdown
   - [ ] **A2** Menú lateral en vez de pestañas: `app.py:42` reparte los apartados en `st.tabs`. Corrección: un `st.Page` por apartado y `st.navigation`.
   ```

   Cada casilla da el número de regla, el fichero y la línea, y la corrección propuesta. Una casilla por regla, aunque falle en varios sitios: se listan todos en la misma.
6. **Resumen**: cuántas reglas cumple, cuáles no cumple y cuáles no aplican, las dudas, y el enlace al issue si se creó.
