---
name: developing-with-streamlit
description: "Use for ALL Streamlit tasks: creating, editing, debugging, beautifying, styling, theming, optimizing, or deploying Streamlit apps. Also custom components, st.components.v2, HTML/JS/CSS work. Discovers and loads version-matched reference docs from the user's installed Streamlit (>=1.57). Triggers: streamlit, st., dashboard, app.py, beautify, style, CSS, color, background, theme, button, widget styling, custom component, st.components, CCv2, session state, performance, cache, fragment, slow rerun, deploy."
allowed-tools: Bash(python ${CLAUDE_SKILL_DIR}/scripts/discover.py:*) Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/discover.py:*)
---

# Developing with Streamlit

Streamlit (>=1.57) ships detailed reference documentation for building Streamlit apps inside its pip package. The bundled skill is a routing `SKILL.md` plus a `references/` folder of topic-specific reference docs (dashboards, themes, layouts, session state, custom components, etc.).

## Usage

Run the discovery script with the user's project directory:

```bash
python <SKILL_DIR>/scripts/discover.py --project-dir <USER_PROJECT_DIR>
```

The script prints either:

- **A path on stdout** (exit 0) — the bundled `SKILL.md`. Read it; it points into `references/`.
- **An `ERROR:` block on stderr** (non-zero exit). Follow the printed instructions and re-run.

`<SKILL_DIR>` is the directory containing this file; `<USER_PROJECT_DIR>` is the absolute path to the user's project. Passing `--project-dir` matters because the script resolves `.venv`, `../.venv`, `Pipfile`, `poetry.lock`, `pdm.lock`, and `uv.lock` relative to it.

## Nota común (Método)

Copiada de [streamlit/agent-skills](https://github.com/streamlit/agent-skills) en el commit `c69a265`; esta sección es lo único añadido. Las reglas comunes a todas las apps viven en la guía del skill `streamlit`; lo propio de cada proyecto (arranque, puerto, capas), en su `CLAUDE.md` o en su `doc/`.

- **El entorno de los proyectos suele ser `venv/`, no `.venv`**, así que el script no lo detecta solo. Lanza el descubrimiento con `VIRTUAL_ENV=<carpeta del código>/venv python3 <SKILL_DIR>/scripts/discover.py --project-dir <carpeta del código>`, o lee directamente `<carpeta del código>/venv/lib/python3.*/site-packages/streamlit/.agents/skills/developing-with-streamlit/SKILL.md`. Para `streamlit docs st.<comando>`, usa `<carpeta del código>/venv/bin/streamlit`. La carpeta del código es la que indica **Repo** en `## Método`, o la raíz del proyecto si no lo indica.
- **Antes de crear o cambiar una app, lee la guía del Método**: `guia.md` del skill `streamlit`, en la carpeta hermana de la de este (`<SKILL_DIR>/../streamlit/guia.md`). Sus reglas mandan sobre las recomendaciones de esta skill.
- **`doc/` manda sobre esta skill.** Si la visión del proyecto fija un patrón de panel, se sigue aunque la skill recomiende otro. Si choca con la guía del Método, se dice y se propone sustituir la decisión con `/dev:crear-decision`, sin cambiarla. El diseño de cada cambio está en el comentario "Diseño UX/UI" (C3) de su issue.
