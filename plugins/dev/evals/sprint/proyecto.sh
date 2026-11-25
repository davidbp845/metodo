#!/usr/bin/env bash
# Proyecto de ejemplo para las evals: un repo git con un `## Método` genérico y una metodología
# que pide C3 para lo que cambia `templates/`. Ninguna eval toca un repo ni un tablero reales.
set -eu
cat > CLAUDE.md <<'MD'
# CLAUDE.md

Proyecto de ejemplo: una app web pequeña.

## Método

- Tipo: dev
- Tablero: proyecto GitHub "Ejemplo" (owner `ejemplo`, número `1`)
- Verificación: `venv/bin/pytest`
- Metodología: `doc/metodologia.md`
- Etiquetas de área: `frontend`, `datos`
- Límite de In review: 10
MD
mkdir -p app tests templates doc
cat > doc/metodologia.md <<'MD'
# Metodología

Sigue la parte común del método. Ajustes de este proyecto:

- **C2** solo si el issue afecta a más de una capa.
- **C3** si el issue cambia algo visible: todo lo que toca `templates/`.
MD
printf 'def total(xs):\n    return sum(xs)\n' > app/calculo.py
printf 'from app.calculo import total\n\ndef test_total():\n    assert total([1, 2]) == 3\n' > tests/test_calculo.py
printf '<form>\n  <button type="submit">Enviar</button>\n</form>\n' > templates/pedido.html
git init -q && git add . && git -c user.name=eval -c user.email=eval@example.invalid commit -qm "chore: proyecto de ejemplo"
