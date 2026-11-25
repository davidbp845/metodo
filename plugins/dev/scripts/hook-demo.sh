#!/usr/bin/env bash
# PreToolUse (Edit|Write|MultiEdit|Bash): cambiar el fichero que elige entre modo real y demo pide
# confirmación. Lo lee del subcampo Fichero del campo Demo del `## Método` del CLAUDE.md más
# cercano hacia arriba, con la ruta relativa a la carpeta de ese CLAUDE.md:
#   - Demo:
#     - Fichero: `configuracion.toml` (`modo = "demo"` o `modo = "real"`)
# Leerlo no pide nada. Desde Bash solo detecta las escrituras habituales (`>`, `sed -i`, `tee`,
# `mv`, `cp`...) en una orden que nombra el fichero.
set -u

entrada=$(cat)
herramienta=$(jq -r '.tool_name // empty' <<<"$entrada")

# Carpeta del CLAUDE.md con `## Método` desde $1 hacia arriba.
raiz_metodo() {
	local dir=$1
	while :; do
		if [ -f "$dir/CLAUDE.md" ] && grep -q '^## Método' "$dir/CLAUDE.md"; then echo "$dir"; return; fi
		{ [ "$dir" = / ] || [ "$dir" = . ]; } && return 1
		dir=$(dirname "$dir")
	done
}

# Ruta absoluta del Fichero de Demo del proyecto de la carpeta $1, si lo hay.
fichero_demo() {
	local raiz nombre
	raiz=$(raiz_metodo "$1") || return 1
	nombre=$(awk '/^## Método/ { p = 1; next } /^## / { p = 0 } p' "$raiz/CLAUDE.md" |
		awk '/^- Demo:/ { d = 1; next } /^- / { d = 0 } d && /^[[:space:]]+- Fichero:/' |
		grep -o '`[^`]*`' | head -1 | tr -d '`')
	[ -n "$nombre" ] || return 1
	echo "$raiz/$nombre"
}

# Ruta absoluta sin enlaces de la carpeta (sin `realpath -m`, que macOS no trae).
absoluta() { (cd "$(dirname "$1")" 2>/dev/null && echo "$(pwd -P)/$(basename "$1")") || echo "$1"; }

preguntar() {
	jq -cn --arg r "$1 es el fichero que elige entre modo real y demo (campo Demo de ## Método). Solo se cambia si el usuario lo ha pedido; para probar en demo, usa la Variable del campo en la propia orden." \
		'{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
	exit 0
}

case "$herramienta" in
Edit | Write | MultiEdit)
	ruta=$(jq -r '.tool_input.file_path // empty' <<<"$entrada")
	[ -n "$ruta" ] || exit 0
	demo=$(fichero_demo "$(dirname "$ruta")") || exit 0
	[ "$(absoluta "$ruta")" = "$(absoluta "$demo")" ] && preguntar "$demo"
	;;
Bash)
	cmd=$(jq -r '.tool_input.command // empty' <<<"$entrada")
	cwd=$(jq -r '.cwd // empty' <<<"$entrada")
	demo=$(fichero_demo "${cwd:-$PWD}") || exit 0
	nombre=$(basename "$demo")
	case "$cmd" in *"$nombre"*) ;; *) exit 0 ;; esac
	if printf '%s' "$cmd" | grep -Eq "(>>?[[:space:]]*[^[:space:]]*$nombre|sed[[:space:]]+(-[a-zA-Z]*[[:space:]]+)*-i|perl[[:space:]]+-[a-zA-Z]*i|(^|[;&|[:space:]])(tee|mv|cp|truncate|rm|install|ln)[[:space:]])"; then
		preguntar "$demo"
	fi
	;;
esac
exit 0
