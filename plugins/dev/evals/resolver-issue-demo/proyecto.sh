#!/usr/bin/env bash
# Proyecto de ejemplo con modo demo: el de comun/proyecto.sh con el campo Demo, un fichero que
# elige entre datos/ y datos-demo/, y un listado que se ve en la terminal.
set -eu
bash "$(dirname "$0")/comun.sh"
cat >> CLAUDE.md <<'MD'
- Demo:
  - Fichero: `configuracion.toml` (`modo = "demo"` o `modo = "real"`)
  - Datos: `datos-demo/`
  - Arranque: `./start.sh --demo`, en `http://localhost:8600`
  - Variable: `APP_MODO=demo`
MD
printf '# "real" usa datos/; "demo", datos-demo/.\nmodo = "real"\n' > configuracion.toml
mkdir -p datos datos-demo
printf '[{"cliente": "Cliente real", "lineas": [12.5, 3]}]\n' > datos/pedidos.json
printf '[{"cliente": "Ana Ejemplo", "lineas": [10, 2.5]}, {"cliente": "Luis Prueba", "lineas": []}]\n' > datos-demo/pedidos.json
cat > app/listado.py <<'PY'
import json
import os
import tomllib
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent


def modo():
    if "APP_MODO" in os.environ:
        return os.environ["APP_MODO"]
    return tomllib.loads((RAIZ / "configuracion.toml").read_text())["modo"]


def pedidos():
    carpeta = "datos-demo" if modo() == "demo" else "datos"
    return json.loads((RAIZ / carpeta / "pedidos.json").read_text())


def listado():
    return "\n".join(p["cliente"] for p in pedidos())


if __name__ == "__main__":
    print(listado())
PY
printf '#!/usr/bin/env bash\n# Arranca el listado; con --demo, en modo demo.\n[ "${1:-}" = --demo ] && export APP_MODO=demo\nexec venv/bin/python -m app.listado\n' > start.sh
chmod +x start.sh
git add . && git -c user.name=eval -c user.email=eval@example.invalid commit -qm "chore: listado con modo demo"
