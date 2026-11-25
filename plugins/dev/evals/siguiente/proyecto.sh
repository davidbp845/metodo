#!/usr/bin/env bash
# Proyecto de ejemplo para la eval de siguiente: el de streamlit/proyecto.sh, con una app Streamlit
# que incumple varias reglas de la guía. Ninguna eval toca un repo ni un tablero reales.
set -eu
cat > CLAUDE.md <<'MD'
# CLAUDE.md

Proyecto de ejemplo: una app web pequeña.

## Método

- Tipo: dev
- Tablero: proyecto GitHub "Ejemplo" (owner `ejemplo`, número `1`)
- Verificación: `venv/bin/pytest`
- Etiquetas de área: `frontend`, `datos`
- Límite de In review: 10
MD
mkdir -p app .streamlit datos
cat > app/panel.py <<'PY'
import pandas as pd
import streamlit as st

st.set_page_config(page_title="Tienda", layout="wide")
st.title("Tienda")

# Unos 400 pedidos y 150 clientes, que crecen cada semana.
pedidos, clientes = st.tabs(["Pedidos", "Clientes"])
with pedidos:
    st.dataframe(pd.read_csv("datos/pedidos.csv"), hide_index=True)
with clientes:
    st.dataframe(pd.read_csv("datos/clientes.csv"))
PY
printf 'id,total\n1,10.5\n2,20.0\n' > datos/pedidos.csv
printf 'nombre,email\nAna,ana@example.invalid\nLuis,luis@example.invalid\n' > datos/clientes.csv
printf '[server]\nport = 8520\n\n[client]\ntoolbarMode = "minimal"\n' > .streamlit/config.toml
printf '#!/usr/bin/env bash\nvenv/bin/python -m streamlit run app/panel.py "$@"\n' > start.sh
git init -q && git add . && git -c user.name=eval -c user.email=eval@example.invalid commit -qm "chore: proyecto de ejemplo"
