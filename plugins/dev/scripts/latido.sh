#!/usr/bin/env bash
# Latido de los issues en curso: la hora UTC en el campo de texto `Latido` del tablero mientras
# una sesión de Claude Code trabaja en ellos, para que quien lea el tablero (la Lanzadera, p. ej.) sepa
# que ese In progress se está resolviendo ahora. Pasa por GitHub, así que vale igual en local
# que en un servidor.
#
#   latido.sh fijar <owner del tablero> <número del tablero> <owner/repo> <issue>
#   latido.sh quitar [<issue>]   (sin issue, los quita todos)
#   latido.sh hook        (desde hooks/hooks.json, con el JSON del evento por stdin)
#   latido.sh mantener <sesión> <pid de claude>   (lo lanza el hook al acabar un turno con trabajo de fondo)
#
# Un fichero por sesión guarda una línea por issue en curso (ids del tablero, del item y del
# campo, y el número del issue): un sprint en paralelo lleva varios a la vez. Su fecha de
# modificación es la de la última escritura. Sin campo `Latido` en el tablero, `fijar` lo dice y no hace nada.
set -u

DIR="${XDG_RUNTIME_DIR:-/tmp}/dev-latido"
# Minutos entre dos escrituras: quien lee da el latido por caducado a los 15.
INTERVALO=5

escribir() {
	# En segundo plano: el hook no espera a GitHub (~1 s por llamada).
	local fichero=$1 proyecto item campo issue
	shift
	while read -r proyecto item campo issue; do
		setsid gh project item-edit --project-id "$proyecto" --id "$item" --field-id "$campo" "$@" \
			</dev/null >/dev/null 2>&1 &
	done <"$fichero"
}

ahora() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Proceso `claude` de la sesión: CLAUDE_PID o, si no está, el primer `claude` hacia arriba.
proceso_claude() {
	[ -n "${CLAUDE_PID:-}" ] && { echo "$CLAUDE_PID"; return; }
	local p=$$
	while [ "${p:-1}" -gt 1 ]; do
		[ "$(ps -o comm= -p "$p")" = claude ] && { echo "$p"; return; }
		p=$(ps -o ppid= -p "$p" | tr -d ' ')
	done
	return 1
}

desciende_de() {
	local p=$1
	while [ "${p:-1}" -gt 1 ]; do
		[ "$p" = "$2" ] && return 0
		p=$(ps -o ppid= -p "$p" | tr -d ' ')
	done
	return 1
}

# Hay trabajo de fondo si un proceso del `claude` de la sesión ($1) sigue escribiendo en la salida
# de una tarea en segundo plano. Se busca por proceso y no por el id de la ruta, porque al
# reanudar una sesión ese id ya no es el de la sesión. La ruta es interna de Claude Code: si
# cambia, no se detecta nada y el latido se vacía al acabar el turno, como sin esta comprobación.
trabajo_de_fondo() {
	local salidas pid
	[ -n "$1" ] || return 1
	salidas=$(compgen -G "${CLAUDE_CODE_TMPDIR:-${TMPDIR:-/tmp}}/claude-$(id -u)/*/*/tasks/*.output") || return 1
	# shellcheck disable=SC2086
	for pid in $(fuser $salidas 2>/dev/null | tr -c '0-9\n' ' '); do
		desciende_de "$pid" "$1" && return 0
	done
	return 1
}

case "${1:-}" in
fijar)
	[ $# -eq 5 ] || { echo "uso: latido.sh fijar <owner> <número> <owner/repo> <issue>" >&2; exit 2; }
	fichero="$DIR/${CLAUDE_CODE_SESSION_ID:?sin CLAUDE_CODE_SESSION_ID: no es una sesión de Claude Code}"
	ids=$(gh api graphql -f owner="$2" -F numero="$3" -f rowner="${4%%/*}" -f rnombre="${4#*/}" -F issue="$5" \
		-f query='query($owner: String!, $numero: Int!, $rowner: String!, $rnombre: String!, $issue: Int!) {
		  user(login: $owner) { projectV2(number: $numero) { id field(name: "Latido") { ... on ProjectV2Field { id } } } }
		  repository(owner: $rowner, name: $rnombre) { issue(number: $issue) { projectItems(first: 20) { nodes { id project { id } } } } }
		}' --jq '.data.user.projectV2 as $p
		  | [$p.id, (.data.repository.issue.projectItems.nodes[] | select(.project.id == $p.id) | .id), $p.field.id]
		  | map(select(. != null)) | join(" ")') || exit 1
	if [ "$(wc -w <<<"$ids")" -ne 3 ]; then
		echo "Sin latido: el tablero no tiene el campo de texto \`Latido\` o el issue no está en él." >&2
		exit 0
	fi
	mkdir -p "$DIR"
	echo "$ids $5" >"$DIR/.$$.nuevo"
	escribir "$DIR/.$$.nuevo" --text "$(ahora)"
	# Las líneas de los demás issues se quedan; la del mismo item se sustituye.
	{ [ -f "$fichero" ] && awk -v item="$(cut -d' ' -f2 <<<"$ids")" '$2 != item' "$fichero"; cat "$DIR/.$$.nuevo"; } >"$DIR/.$$"
	rm -f "$DIR/.$$.nuevo"
	mv "$DIR/.$$" "$fichero"
	;;
quitar)
	fichero="$DIR/${CLAUDE_CODE_SESSION_ID:-}"
	[ -f "$fichero" ] || exit 0
	if [ $# -lt 2 ]; then
		escribir "$fichero" --clear
		rm -f "$fichero"
		exit 0
	fi
	# Una línea sin número de issue (fijada por una versión anterior) cuenta como la de cualquiera.
	awk -v issue="$2" '$4 == issue || $4 == ""' "$fichero" >"$DIR/.$$.quitar"
	escribir "$DIR/.$$.quitar" --clear
	awk -v issue="$2" '$4 != issue && $4 != ""' "$fichero" >"$DIR/.$$"
	rm -f "$DIR/.$$.quitar"
	if [ -s "$DIR/.$$" ]; then
		mv "$DIR/.$$" "$fichero"
	else
		rm -f "$DIR/.$$" "$fichero"
	fi
	;;
hook)
	read -r sesion evento < <(jq -r '"\(.session_id) \(.hook_event_name)"')
	fichero="$DIR/$sesion"
	[ -f "$fichero" ] || exit 0
	case "$evento" in
	UserPromptSubmit | PostToolUse)
		if [ -z "$(find "$fichero" -mmin -"$INTERVALO")" ]; then
			touch "$fichero"
			escribir "$fichero" --text "$(ahora)"
		fi
		;;
	Stop)
		claude=$(proceso_claude)
		if trabajo_de_fondo "$claude"; then
			# El turno acaba pero el trabajo sigue (tests, evaluaciones...): se mantiene mientras dure.
			setsid "$0" mantener "$sesion" "$claude" </dev/null >/dev/null 2>&1 &
		else
			# Fin del turno: nadie trabaja hasta el siguiente mensaje, que vuelve a escribir sin esperar.
			escribir "$fichero" --clear
			touch -d "1 hour ago" "$fichero"
		fi
		;;
	SessionEnd)
		escribir "$fichero" --clear
		rm -f "$fichero"
		;;
	esac
	;;
mantener)
	fichero="$DIR/${2:?uso: latido.sh mantener <sesión> <pid de claude>}"
	# Uno por sesión: cada fin de turno con trabajo de fondo lo lanza otra vez.
	exec 9>"$fichero.mantener"
	flock -n 9 || exit 0
	# Termina sin vaciar el campo: el aviso de fin de la tarea abre un turno, y su Stop lo vacía.
	while [ -f "$fichero" ] && trabajo_de_fondo "${3:-}"; do
		if [ -z "$(find "$fichero" -mmin -"$INTERVALO")" ]; then
			touch "$fichero"
			escribir "$fichero" --text "$(ahora)"
		fi
		sleep 60
	done
	rm -f "$fichero.mantener"
	;;
*)
	echo "uso: latido.sh fijar|quitar|hook|mantener" >&2
	exit 2
	;;
esac
