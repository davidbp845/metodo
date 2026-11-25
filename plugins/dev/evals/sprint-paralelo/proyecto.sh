#!/usr/bin/env bash
# Proyecto de ejemplo del sprint en paralelo: el de comun/proyecto.sh con un segundo módulo, para
# que haya dos issues que no tocan los mismos ficheros.
set -eu
bash "$(dirname "$0")/comun.sh"
printf 'def saludo(nombre):\n    return "Hola " + nombre\n' > app/texto.py
printf 'from app.texto import saludo\n\ndef test_saludo():\n    assert saludo("Ana") == "Hola Ana"\n' > tests/test_texto.py
git branch -M main
git add . && git -c user.name=eval -c user.email=eval@example.invalid commit -qm "chore: módulo de texto"
