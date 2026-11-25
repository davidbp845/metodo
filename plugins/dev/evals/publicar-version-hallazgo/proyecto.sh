#!/usr/bin/env bash
# Proyecto de ejemplo para la eval de publicar-version con un fallo en el diff: el de
# publicar-version/proyecto.sh más un commit que hace que total() se salte el primer elemento.
set -eu
bash "$(dirname "$0")/base.sh"
printf 'def total(xs):\n    # El primer elemento es la cabecera del pedido.\n    return sum(xs[1:])\n' > app/calculo.py
git add . && git -c user.name=eval -c user.email=eval@example.invalid commit -qm "refactor(calculo): total sin cabecera"
