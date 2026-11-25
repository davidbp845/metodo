#!/usr/bin/env bash
# Proyecto de ejemplo para la eval de publicar-version: el de comun/proyecto.sh con un campo
# Versionado, una etiqueta v0.1.0 y, tras ella, un commit de docs y otro que añade un campo
# obligatorio a config.yaml (minor), sin fallos a propósito que el review pueda encontrar. Ninguna eval toca un repo ni un tablero reales.
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
- Versionado:
  - Minor: el cambio obliga a tocar `config.yaml` de quien instala la app (campo nuevo, retirado u obligatorio)
  - Apartado de minor: Cambios para quien instala
MD
mkdir -p app tests
printf 'def total(xs):\n    return sum(xs)\n' > app/calculo.py
printf 'from app.calculo import total\n\ndef test_total():\n    assert total([1, 2]) == 3\n' > tests/test_calculo.py
printf '[project]\nname = "ejemplo"\nversion = "0.1.0"\ndependencies = ["PyYAML"]\n' > pyproject.toml
printf 'nombre: Tienda\n' > config.yaml
c() { git -c user.name=eval -c user.email=eval@example.invalid commit -qm "$1"; }
git init -q && git add . && c "chore: proyecto de ejemplo"
git -c user.name=eval -c user.email=eval@example.invalid tag -a v0.1.0 -m v0.1.0
printf '# Ejemplo\n\nInstalación: `pip install -e .`\n' > README.md
git add . && c "docs(readme): cómo instalar"
printf 'nombre: Tienda\nmoneda: EUR\n' > config.yaml
cat > app/config.py <<'PY'
import yaml


def cargar(ruta):
    with open(ruta, encoding="utf-8") as f:
        datos = yaml.safe_load(f) or {}
    moneda = datos.get("moneda") if isinstance(datos, dict) else None
    if not isinstance(moneda, str) or not moneda:
        raise ValueError(f"{ruta}: falta moneda (un código como EUR)")
    return datos
PY
cat > tests/test_config.py <<'PY'
import pytest

from app.config import cargar


def test_con_moneda(tmp_path):
    ruta = tmp_path / "config.yaml"
    ruta.write_text("nombre: Tienda\nmoneda: EUR\n", encoding="utf-8")
    assert cargar(ruta)["moneda"] == "EUR"


@pytest.mark.parametrize("contenido", ["", "nombre: Tienda\n", "moneda: 978\n", "- EUR\n"])
def test_sin_moneda_valida(tmp_path, contenido):
    ruta = tmp_path / "config.yaml"
    ruta.write_text(contenido, encoding="utf-8")
    with pytest.raises(ValueError, match="falta moneda"):
        cargar(ruta)
PY
printf '\nConfiguración: `config.yaml` con `nombre` y `moneda` (un código como `EUR`).\n' >> README.md
git add . && c "feat(config): moneda de la tienda"
