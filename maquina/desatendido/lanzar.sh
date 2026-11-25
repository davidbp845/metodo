#!/usr/bin/env bash
# Sesiones desatendidas: recorre los proyectos con `## Método` y, en cada uno que tenga algo que
# hacer, abre `claude -p "/dev:siguiente"` desde su carpeta, para que cargue su configuración, sus
# hooks y su `.mcp.json`. Lo lanza el temporizador de systemd (metodo-desatendido.timer) o se usa a
# mano. Uso y condiciones en maquina/README.md. Solo Linux: usa `flock` y `/proc`.
#
#   lanzar.sh [--barridos] [--simular]
#
#   --barridos  abre la sesión aunque no haya Ready, para que /dev:siguiente recorra los barridos
#   --simular   solo dice qué haría en cada proyecto, sin abrir ninguna sesión
#
# METODO_TOPE_USD: tope de gasto por sesión (5 por defecto).
set -u

barridos=0
simular=0
for a in "$@"; do
	case "$a" in
	--barridos) barridos=1 ;;
	--simular) simular=1 ;;
	*) sed -n '2,13s/^# \{0,1\}//p' "$0" >&2; exit 2 ;;
	esac
done

aqui=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
metodo=$(dirname "$(dirname "$aqui")")
data=$(dirname "$metodo")
config=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
tope=${METODO_TOPE_USD:-5}
registros=${XDG_STATE_HOME:-$HOME/.local/state}/metodo-desatendido
cerrojos=${XDG_RUNTIME_DIR:-/tmp}/metodo-desatendido
mkdir -p "$registros" "$cerrojos"

instruccion='Sesión desatendida, lanzada por el temporizador del Método: nadie lee esta conversación ni puede confirmar nada. Lo que necesite al usuario (una pregunta, un permiso que se pide, pasar un issue a Done, editar un CLAUDE.md o lo que hay bajo .claude/) no se hace: ese paso se para, el motivo se deja en un comentario del issue y se sigue con lo demás. Nunca push.'

# Las carpetas de proyectos de metodo-maquina.json, como en instalar.sh; sin ellas, la de datos
# entera. Buscar solo ahí evita barrer las rutas que esa máquina bloquea.
raices=()
if [ -f "$config/metodo-maquina.json" ]; then
	while IFS= read -r c; do raices+=("$data/$c"); done < <(jq -r '.carpetas // [] | .[]' "$config/metodo-maquina.json")
fi
if [ ${#raices[@]} -eq 0 ]; then raices=("$data"); profundidad=3; else raices+=("$metodo"); profundidad=2; fi

decir() { printf '%s  %s: %s\n' "$(date '+%F %T')" "$1" "$2"; }

# ¿Hay un proceso de Claude Code con el directorio de trabajo dentro de la carpeta?
sesion_abierta() {
	local p cwd
	for p in /proc/[0-9]*; do
		[ "$(cat "$p/comm" 2>/dev/null)" = claude ] || continue
		cwd=$(readlink "$p/cwd" 2>/dev/null) || continue
		case "$cwd/" in "$1"/*) return 0 ;; esac
	done
	return 1
}

proyecto() {
	local carpeta=$1 nombre metodo_md owner numero limite codigo rama principal items ready en_revision variable
	nombre=$(basename "$carpeta")
	metodo_md=$(sed -n '/^## Método/,/^## /p' "$carpeta/CLAUDE.md")
	owner=$(printf '%s\n' "$metodo_md" | grep -m1 '^- Tablero:' | sed -n 's/.*owner `\([^`]*\)`.*/\1/p')
	numero=$(printf '%s\n' "$metodo_md" | grep -m1 '^- Tablero:' | sed -n 's/.*número `\([0-9]*\)`.*/\1/p')
	if [ -z "$owner" ] || [ -z "$numero" ]; then decir "$nombre" "sin tablero en el ## Método"; return; fi
	limite=$(printf '%s\n' "$metodo_md" | sed -n 's/^- Límite de In review: \([0-9]*\).*/\1/p' | head -1)
	limite=${limite:-10}
	codigo=$carpeta
	local r
	r=$(printf '%s\n' "$metodo_md" | grep -m1 '^- Repo:' | sed -n 's/.* en `\([^`]*\)`.*/\1/p')
	[ -n "$r" ] && codigo="$carpeta/$r"

	# El checkout tiene que estar libre: sin cambios a medias ni otra sesión trabajando en él.
	if [ -n "$(git -C "$codigo" status --porcelain 2>/dev/null)" ]; then decir "$nombre" "cambios sin commitear, no se toca"; return; fi
	if sesion_abierta "$carpeta"; then decir "$nombre" "hay una sesión de Claude abierta en la carpeta"; return; fi

	rama=$(git -C "$codigo" branch --show-current 2>/dev/null)
	principal=$(git -C "$codigo" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
	principal=${principal#origin/}
	if [ -z "$principal" ]; then
		if git -C "$codigo" rev-parse --verify -q main >/dev/null; then principal=main; else principal=master; fi
	fi

	items=$(gh project item-list "$numero" --owner "$owner" --format json --limit 500 2>/dev/null) || { decir "$nombre" "no se pudo leer el tablero"; return; }
	en_revision=$(printf '%s' "$items" | jq '[.items[] | select(.status == "In review")] | length')
	ready=$(printf '%s' "$items" | jq --arg rama "$rama" --arg principal "$principal" '[.items[] | select(.status == "Ready")
		| (.labels // [] | map(select(startswith("rama:")))) as $r
		| select(if $rama == $principal then $r == [] else ($r | index("rama:" + $rama)) != null end)] | length')
	if [ "$en_revision" -ge "$limite" ]; then decir "$nombre" "In review lleno ($en_revision de $limite)"; return; fi
	if [ "$ready" -eq 0 ] && [ "$barridos" = 0 ]; then decir "$nombre" "nada en Ready"; return; fi

	variable=$(printf '%s\n' "$metodo_md" | sed -n 's/^[[:space:]]*- Variable: `\([A-Za-z_][A-Za-z0-9_]*=[^`]*\)`.*/\1/p' | head -1)
	if [ "$simular" = 1 ]; then decir "$nombre" "abriría /dev:siguiente ($ready en Ready${variable:+, con $variable})"; return; fi

	# Un cerrojo por proyecto: una ejecución que se alarga no se solapa con la siguiente.
	local cerrojo="$cerrojos/$(printf '%s' "$carpeta" | sed 's/[^A-Za-z0-9]/-/g').lock"
	local registro="$registros/$nombre-$(date +%Y%m%d-%H%M%S).log"
	(
		flock -n 9 || { decir "$nombre" "otra ejecución desatendida sigue en marcha"; exit 0; }
		decir "$nombre" "abre /dev:siguiente ($ready en Ready), registro en $registro"
		cd "$carpeta" && env ${variable:+"$variable"} claude -p "/dev:siguiente" \
			--permission-mode auto --max-budget-usd "$tope" --append-system-prompt "$instruccion" \
			</dev/null >"$registro" 2>&1
		decir "$nombre" "terminó con código $?"
	) 9>"$cerrojo"
}

find "${raices[@]}" -maxdepth "$profundidad" -type f -name CLAUDE.md -not -path '*/node_modules/*' 2>/dev/null |
	xargs -r grep -l '^## Método' 2>/dev/null | sort -u | while IFS= read -r claude_md; do
		proyecto "$(dirname "$claude_md")"
	done
