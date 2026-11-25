# Barridos

Trabajo que cada proyecto tiene que tener hecho una vez y que todavía no es un issue. `/dev:siguiente` los recorre en este orden cuando el proyecto no tiene nada en Ready. Cada barrido dice a qué proyectos aplica, cómo se sabe que ya está hecho y qué skill lo hace. Un barrido nuevo es una sección más, con los mismos tres campos.

Además del criterio de cada barrido, cuenta como hecho una línea del proyecto y el barrido en `local/barridos.md` del repo del método: la apunta `/dev:siguiente` cuando el skill termina sin nada que abrir.

## streamlit

- **Aplica**: la carpeta del código tiene una app Streamlit, un `.py` fuera de `venv/`, `.venv/` y `tests/` que llama a `st.set_page_config`.
- **Hecho**: el repo tiene un issue, abierto o cerrado, titulado `Adaptar la app Streamlit a la guía del Método` (`gh issue list --state all --search 'in:title "Adaptar la app Streamlit a la guía del Método"'`).
- **Skill**: `dev:streamlit` con el argumento `revisar`.
