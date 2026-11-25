#!/usr/bin/env bash
# Ejecuta la suite de evals del plugin dev; sale con 1 si algún caso queda por debajo de 0,9 de
# media (deja pasar un evaluador suelto que falla en una pasada, no una regresión que se repite).
# Los casos no tienen Bash, así que no tocan GitHub; el scaffold de cada caso (comun/proyecto.sh)
# solo crea un repo git de ejemplo en su directorio.
#
#   evals/ejecutar.sh [opciones extra de claude plugin eval, p. ej. --case crear-issue --runs 1]
set -eu
cd "$(dirname "$0")/.."
exec claude plugin eval . --scaffold --trust-plugin --ablation none --no-publish --threshold 0.9 --allow-tools Edit Write "$@"
