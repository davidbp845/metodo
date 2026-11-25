#!/usr/bin/env bash
# Proyecto de ejemplo para las evals: un repo git con un `## Método` genérico. Se crea en el
# directorio de trabajo del caso; ninguna eval toca un repo ni un tablero reales.
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
mkdir -p app tests
printf 'def total(xs):\n    return sum(xs)\n' > app/calculo.py
printf 'from app.calculo import total\n\ndef test_total():\n    assert total([1, 2]) == 3\n' > tests/test_calculo.py
git init -q && git add . && git -c user.name=eval -c user.email=eval@example.invalid commit -qm "chore: proyecto de ejemplo"
