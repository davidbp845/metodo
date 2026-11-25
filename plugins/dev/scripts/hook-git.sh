#!/usr/bin/env bash
# PreToolUse (Bash): reglas de commit de `estilo/redaccion.md` que se pueden comprobar.
#   - `git add -A`, `.`, `-u`... y `git commit -a` se rechazan: meten cambios que pueden ser de
#     otra sesión sobre el mismo checkout. Se añaden las rutas propias, por nombre.
#   - El asunto de `git commit -m` (o del heredoc que lo lleva) empieza por un tipo válido.
#   - Un `feat` o `fix` sin pie `Issue: #NN` (o `Issues:`) pide confirmación: puede ser un
#     olvido o trabajo que no sale de ningún issue, y solo quien lo hace lo sabe.
# Lo que no sabe leer (mensaje en una variable, `-F fichero`, sin `-m`) lo deja pasar.
set -u

cmd=$(jq -r '.tool_input.command // empty')

denegar() {
	jq -cn --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
	exit 0
}

preguntar() {
	jq -cn --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
	exit 0
}

git_re='(^|[;&|(`[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+'

# Para buscar opciones, la orden sin el texto entre comillas ni los heredocs: un mensaje que
# menciona `git add -A` no es un `git add -A`.
limpio=$(printf '%s' "$cmd" | tr '\n' '\001' | sed -e 's/<<.*//' -e "s/'[^']*'//g" -e 's/"[^"]*"//g' | tr '\001' '\n')

# Argumentos de la primera orden `git <sub>`, hasta el siguiente separador.
argumentos() {
	printf '%s' "$limpio" | awk -v re="${git_re}$1([[:space:]]|$)" '
		match($0, re) { s = substr($0, RSTART + RLENGTH); sub(/[;&|].*/, "", s); print s; exit }'
}

if printf '%s' "$limpio" | grep -Eq "${git_re}add([[:space:]]|$)"; then
	args=$(argumentos add)
	if printf ' %s ' "$args" | grep -Eq '[[:space:]](-A|--all|-u|--update|\.|\./|:/|\*)[[:space:]]'; then
		denegar "git add con -A, -u, '.' o '*' puede meter cambios de otra sesión. Mira 'git status --short' y añade por nombre solo las rutas propias; un fichero sin seguimiento que no has creado tú no entra sin preguntar."
	fi
fi

printf '%s' "$limpio" | grep -Eq "${git_re}commit([[:space:]]|$)" || exit 0

if printf ' %s ' "$(argumentos commit)" | grep -Eq '[[:space:]](--all|-[b-zA-Z]*a[b-zA-Z]*)[[:space:]]'; then
	denegar "git commit -a mete todos los cambios con seguimiento, también los de otra sesión. Añade antes por nombre las rutas propias con git add y haz el commit sin -a."
fi

# Mensaje completo: el cuerpo del heredoc hasta su delimitador, o todos los `-m` seguidos.
mensaje=
if [[ $cmd =~ \<\<-?[[:space:]]*[\"\']?([A-Za-z_]+) ]]; then
	mensaje=$(printf '%s\n' "$cmd" | awk -v d="${BASH_REMATCH[1]}" '
		f { l = $0; sub(/^[[:space:]]+/, "", l); sub(/[[:space:]]+$/, "", l); if (l == d) exit; print }
		/<</ { f = 1 }')
else
	m_re='(^|[[:space:]])(-[a-zA-Z]*m|--message)([[:space:]]+|=)?("([^"]*)"|'\''([^'\'']*)'\''|([^[:space:]"'\'']+))'
	resto=$cmd
	while [[ $resto =~ $m_re ]]; do
		mensaje+="${BASH_REMATCH[5]}${BASH_REMATCH[6]}${BASH_REMATCH[7]}"$'\n\n'
		resto=${resto#*"${BASH_REMATCH[0]}"}
	done
fi
asunto=$(printf '%s\n' "$mensaje" | awk 'NF { print; exit }')
asunto=$(printf '%s' "$asunto" | sed 's/^[[:space:]]*//')

case "$asunto" in '' | '$'*) exit 0 ;; esac
if ! printf '%s' "$asunto" | grep -Eq '^((feat|fix|docs|refactor|test|chore|perf)(\([^)]+\))?!?: [^[:space:]]|(Merge|Revert) )'; then
	denegar "Asunto de commit fuera de formato: '$asunto'. Debe ser 'tipo(ámbito): resumen breve', con tipo feat, fix, docs, refactor, test, chore o perf, y pie 'Issue: #NN' si sale de un issue (estilo/redaccion.md)."
fi
if printf '%s' "$asunto" | grep -Eq '^(feat|fix)(\([^)]+\))?!?:' &&
	! printf '%s\n' "$mensaje" | grep -Eq '^[[:space:]]*Issues?:.*#[0-9]'; then
	preguntar "Commit '$asunto' sin pie 'Issue: #NN'. Si sale de un issue, añade el pie al final del mensaje; si no sale de ninguno, confirma para seguir (estilo/redaccion.md)."
fi
exit 0
