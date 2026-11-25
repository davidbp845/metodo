#!/usr/bin/env bash
# SessionStart: avisa cuando toca la retro agregada del método (/dev:retro-metodo), para que la
# cadencia no dependa de acordarse. La fecha sale del nombre de la última retro guardada en
# <Metodo>/local/retros/; sin ninguna, avisa siempre.
#
#   recordar-retro-metodo.sh <carpeta de Metodo> [días entre retros, 14 por defecto]
metodo=${1:?uso: recordar-retro-metodo.sh <carpeta de Metodo> [días]}
cadencia=${2:-14}
[ -d "$metodo" ] || exit 0

ultima=$(find "$metodo/local/retros" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*.md' 2>/dev/null \
	| sed 's|.*/||; s|\(..........\).*|\1|' | sort | tail -n 1)
if [ -n "$ultima" ]; then
	dias=$(( ($(date -u +%s) - $(date -u -d "$ultima" +%s)) / 86400 ))
	[ "$dias" -ge "$cadencia" ] || exit 0
	texto="Toca la retro del método: la última es del $ultima, hace $dias días. Se lanza con /dev:retro-metodo desde Metodo."
else
	texto="No hay ninguna retro del método. Se lanza con /dev:retro-metodo desde Metodo."
fi
jq -n -c --arg t "$texto" '{systemMessage: $t}'
exit 0
