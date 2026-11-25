#!/usr/bin/env bash
# Métricas de proceso de un proyecto con `## Método` en una ventana, como un objeto JSON en una
# línea. Las usa /dev:retro-metodo para juntar todos los proyectos en una tabla; son las mismas
# que mira /dev:retro en uno solo, en la forma que se puede sumar y comparar entre retros.
#
#   metricas.sh <carpeta del proyecto> <inicio AAAA-MM-DD>
#
# Lee del `## Método` el tablero y, si lo hay, el campo Repo (repo de GitHub y carpeta del
# código). Con Repos por área, mide además cada repo de ese campo y suma (`repos_area` los nombra).
# Un dato que no se puede obtener sale como null, nunca como 0. `fix_max` es el issue con
# más commits `fix` en la ventana y cuántos lleva (`{issue, fix}`), null si ningún `fix` tiene pie.
#
# Repo compartido (`compartido`): alguno de los 100 últimos issues actualizados del repo está en
# un tablero que no es el del proyecto. Se mira fuera de la ventana para que los proyectos del
# mismo repo lo vean igual aunque uno no haya tenido actividad. Si lo es, los issues (cerrados,
# wontfix, abiertos, reaperturas) son solo los del tablero propio, archivados incluidos, y los
# commits son los que citan en el pie `Issue:` un issue del tablero; los que no citan ninguno de
# un tablero van en `repo_sin_tablero`, que es el mismo en todos los proyectos del repo y la retro
# cuenta una vez. Un repo no compartido da `repo_sin_tablero: null` y sus commits son todos.
set -u

carpeta=${1:?uso: metricas.sh <carpeta> <inicio AAAA-MM-DD>}
inicio=${2:?uso: metricas.sh <carpeta> <inicio AAAA-MM-DD>}
claude_md="$carpeta/CLAUDE.md"
[ -f "$claude_md" ] || { echo "No existe $claude_md" >&2; exit 1; }

metodo=$(sed -n '/^## Método/,/^## /p' "$claude_md")
tablero=$(printf '%s\n' "$metodo" | grep -m1 '^- Tablero:')
owner=$(printf '%s' "$tablero" | sed -n 's/.*owner `\([^`]*\)`.*/\1/p')
numero=$(printf '%s' "$tablero" | sed -n 's/.*número `\([0-9]*\)`.*/\1/p')
linea_repo=$(printf '%s\n' "$metodo" | grep -m1 '^- Repo:')
# Líneas de Repos por área: `  - `etiqueta`: `owner/repo` en `carpeta``.
areas=$(printf '%s\n' "$metodo" | awk '/^- Repos por área:/ { f = 1; next } f && /^- / { exit } f && /^[[:space:]]+- / { print }')

# Con Repos por área, cada repo se mide en una pasada propia (METRICAS_PAR = `repo<TAB>carpeta`) y
# se suman: los issues y commits de cada repo son distintos, el tablero es el mismo.
if [ -n "$areas" ] && [ -z "${METRICAS_PAR+x}" ]; then
	pares=$(printf '%s\n' "$areas" | sed -n 's/^[^:]*: `\([^`]*\)` en `\([^`]*\)`.*/\1\t\2/p')
	if [ -n "$linea_repo" ]; then
		pares=$(printf '%s\t%s\n%s' "$(printf '%s' "$linea_repo" | sed -n 's/^- Repo: `\([^`]*\)`.*/\1/p')" \
			"$(printf '%s' "$linea_repo" | sed -n 's/.* en `\([^`]*\)`.*/\1/p')" "$pares")
	else
		pares=$(printf '%s\t.\n%s' "$(cd "$carpeta" && gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)" "$pares")
	fi
	printf '%s\n' "$pares" | awk -F'\t' 'NF == 2 && $1 != "" && !visto[$1]++' | while IFS= read -r par; do
		METRICAS_PAR=$par bash "$0" "$carpeta" "$inicio"
	done | jq -s -c '
		def suma(f): if any(.[]; f == null) then null else (map(f) | add) end;
		.[0] + {
			repo: .[0].repo, repos_area: [.[1:][].repo],
			cerrados: suma(.cerrados), wontfix: suma(.wontfix), abiertos: suma(.abiertos), reaperturas: suma(.reaperturas),
			compartido: any(.[]; .compartido),
			commits: suma(.commits), fix: suma(.fix), codigo: suma(.codigo), sin_issue: suma(.sin_issue), fix_tardio: suma(.fix_tardio),
			por_tipo: (if any(.[]; .por_tipo == null) then null else (map(.por_tipo | to_entries) | add | group_by(.key) | map({(.[0].key): (map(.value) | add)}) | add // {}) end),
			fix_max: ([.[].fix_max | select(. != null)] | sort_by(-.fix, .issue) | .[0]),
			repo_sin_tablero: .[0].repo_sin_tablero
		}'
	exit
fi

if [ -n "${METRICAS_PAR+x}" ]; then
	repo=${METRICAS_PAR%%$'\t'*}
	codigo="$carpeta/${METRICAS_PAR#*$'\t'}"
elif [ -n "$linea_repo" ]; then
	repo=$(printf '%s' "$linea_repo" | sed -n 's/^- Repo: `\([^`]*\)`.*/\1/p')
	codigo="$carpeta/$(printf '%s' "$linea_repo" | sed -n 's/.* en `\([^`]*\)`.*/\1/p')"
else
	codigo="$carpeta"
	repo=$(cd "$carpeta" && gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
fi

nulo() { [ -n "$1" ] && printf '%s' "$1" || printf null; }

# Tableros (`owner/número`) de los issues, como objeto JSON {"12": ["owner/4"], ...}. Se usa
# GraphQL porque `projectItems` incluye los items archivados, que `gh project item-list` no da.
# Sin argumentos, los 100 últimos actualizados; con `--desde`, todos los actualizados desde el
# inicio; con números, esos (uno que no existe sale sin tablero).
items_tableros='projectItems(first: 20) { nodes { project { number owner { ... on User { login } ... on Organization { login } } } } }'
tableros_de() {
	local consulta
	case "${1:-}" in
	'') consulta="issues(first: 100, orderBy: {field: UPDATED_AT, direction: DESC}) { nodes { number $items_tableros } }" ;;
	--desde) consulta="issues(first: 100, after: \$endCursor, filterBy: {since: \"${inicio}T00:00:00Z\"}) { pageInfo { hasNextPage endCursor } nodes { number $items_tableros } }" ;;
	*) consulta=$(for n in "$@"; do printf 'i%s: issueOrPullRequest(number: %s) { ... on Issue { number %s } ... on PullRequest { number %s } } ' "$n" "$n" "$items_tableros" "$items_tableros"; done) ;;
	esac
	local variables=''
	[ "${1:-}" = --desde ] && variables='($endCursor: String)'
	local args=(-f "query=query$variables { repository(owner: \"${repo%%/*}\", name: \"${repo#*/}\") { $consulta } }")
	[ "${1:-}" = --desde ] && args=(--paginate "${args[@]}")
	# Con un número inexistente gh sale con error pero da el resto de la respuesta.
	gh api graphql "${args[@]}" 2>/dev/null | jq -s -c '[.[].data.repository // {} | (.issues.nodes // [.[]]) | .[]
		| select(. != null) | {(.number | tostring): [.projectItems.nodes[].project | "\(.owner.login)/\(.number)"]}] | add // {}'
}

# --- Issues: una sola llamada con todo lo actualizado desde el inicio (sin PRs) ---
issues=null
if [ -n "$repo" ]; then
	issues=$(gh api --paginate "repos/$repo/issues?state=all&since=${inicio}T00:00:00Z&per_page=100" \
		--jq '.[] | select(.pull_request | not) | {n: .number, creado: .created_at, cerrado: .closed_at, motivo: .state_reason}' \
		2>/dev/null | jq -s . 2>/dev/null) || issues=null
	[ -n "$issues" ] || issues=null
fi

reabiertos=""
reaperturas=null
if [ -n "$repo" ]; then
	reabiertos=$(gh api --paginate "repos/$repo/issues/events?per_page=100" \
		--jq ".[] | select(.event == \"reopened\" and .created_at >= \"${inicio}T00:00:00Z\") | .issue.number" \
		2>/dev/null) && reaperturas=$(printf '%s' "$reabiertos" | grep -c .)
fi

# --- Repo compartido: tableros de los issues, para quedarse con los del propio ---
propio="$owner/$numero"
compartido=false
tableros='{}'
if [ -n "$repo" ] && [ -n "$owner" ] && [ -n "$numero" ]; then
	if [ "$(tableros_de | jq --arg p "$propio" '[.[][] | select(. != $p)] | length > 0')" = true ]; then
		compartido=true
		tableros=$(tableros_de --desde)
	fi
fi
# Completa `tableros` con los issues citados que no se actualizaron en la ventana.
completar_tableros() {
	local faltan
	faltan=$(printf '%s\n' "$@" | sort -un | jq -R -r --argjson t "$tableros" 'select(length > 0 and ($t[.] == null))')
	[ -n "$faltan" ] || return 0
	tableros=$(jq -c -n --argjson a "$tableros" --argjson b "$(tableros_de $faltan)" '$a + $b')
}
if [ "$compartido" = true ]; then
	completar_tableros $reabiertos
	reaperturas=$(printf '%s\n' $reabiertos | jq -R --argjson t "$tableros" --arg p "$propio" \
		'select(length > 0) | select(($t[.] // []) | index($p))' | grep -c .)
	[ "$issues" = null ] || issues=$(printf '%s' "$issues" | jq -c --argjson t "$tableros" --arg p "$propio" \
		'map(select(($t[.n | tostring] // []) | index($p)))')
fi

# --- Tablero: cuántos por Status y antigüedad del In review más viejo ---
tablero_json=null
in_review_dias=null
if [ -n "$owner" ] && [ -n "$numero" ]; then
	items=$(gh project item-list "$numero" --owner "$owner" --format json --limit 500 2>/dev/null) || items=""
	if [ -n "$items" ]; then
		tablero_json=$(printf '%s' "$items" | jq -c '[.items[] | .status // "Sin Status"] | group_by(.) | map({(.[0]): length}) | add // {}')
		hoy=$(date -u +%s)
		mas_viejo=""
		for ref in $(printf '%s' "$items" | jq -r '.items[] | select(.status == "In review" and .content.number != null) | "\(.content.repository)/issues/\(.content.number)"'); do
			c=$(gh api "repos/$ref" --jq '.closed_at // empty' 2>/dev/null)
			[ -n "$c" ] || continue
			if [ -z "$mas_viejo" ] || [[ "$c" < "$mas_viejo" ]]; then mas_viejo=$c; fi
		done
		if [ -n "$mas_viejo" ]; then
			in_review_dias=$(( (hoy - $(date -u -d "$mas_viejo" +%s)) / 86400 ))
		fi
	fi
fi

# --- Commits del repo del código (sin merges) ---
commits=null
if git -C "$codigo" rev-parse --git-dir >/dev/null 2>&1; then
	commits=$(git -C "$codigo" log --no-merges --since "${inicio}T00:00:00" \
		--format='%h%x1f%s%x1f%b%x1e' |
		jq -R -s 'split("\u001e") | map(ltrimstr("\n")) | map(select(length > 0) | split("\u001f")
			| {h: .[0], tipo: (.[1] | capture("^(?<t>[a-z]+)[(!:]").t // "otro"),
			   issues: (.[2] // "" | [scan("(?m)^Issues?:[^\n]*")] | join(" ") | [scan("#([0-9]+)")[0] | tonumber])})')
fi

# fix que citan un issue cerrado antes de la ventana: señal de verificación insuficiente.
tardios=null
if [ "$commits" != null ] && [ -n "$repo" ]; then
	tardios=()
	declare -A cerrado_antes=()
	while read -r h citados; do
		tardio=0
		for n in $citados; do
			if [ -z "${cerrado_antes[$n]+x}" ]; then
				c=$(gh api "repos/$repo/issues/$n" --jq '.closed_at // empty' 2>/dev/null)
				cerrado_antes[$n]=0
				[ -n "$c" ] && [[ "$c" < "${inicio}T00:00:00Z" ]] && cerrado_antes[$n]=1
			fi
			[ "${cerrado_antes[$n]}" = 1 ] && tardio=1
		done
		[ "$tardio" = 1 ] && tardios+=("$h")
	done < <(printf '%s' "$commits" | jq -r '.[] | select(.tipo == "fix" and (.issues | length) > 0) | "\(.h) \(.issues | map(tostring) | join(" "))"')
	tardios=$(printf '%s\n' "${tardios[@]}" | jq -R -s -c 'split("\n") | map(select(length > 0))')
fi

# En un repo compartido, cada commit va al tablero de los issues que cita; el que no cita
# ninguno de un tablero, a `repo_sin_tablero`.
if [ "$commits" != null ] && [ "$compartido" = true ]; then
	completar_tableros $(printf '%s' "$commits" | jq -r '.[].issues[]')
	commits=$(printf '%s' "$commits" | jq -c --argjson t "$tableros" --arg p "$propio" \
		'map(.tableros = ([.issues[] | $t[tostring] // [] | .[]] | unique)
			| .de = (if .tableros == [] then "repo" elif (.tableros | index($p)) then "propio" else "otro" end))')
fi

jq -n -c \
	--arg proyecto "$(basename "$carpeta")" --arg repo "$repo" --arg inicio "${inicio}T00:00:00Z" \
	--argjson issues "$issues" --argjson todos "$commits" --argjson tablero "$tablero_json" --argjson compartido "$compartido" \
	--argjson reaperturas "$(nulo "$reaperturas")" --argjson tardios "$tardios" --argjson in_review_dias "$(nulo "$in_review_dias")" '
	def cerrados_en_ventana: [$issues[] | select(.cerrado != null and .cerrado >= $inicio)];
	# Métricas de un conjunto de commits: las del proyecto y, si el repo es compartido, las del repo sin tablero.
	def de_commits:
		. as $commits
		| def de_codigo: [$commits[] | select(.tipo != "docs" and .tipo != "chore")];
		{
			commits: (if $commits == null then null else ($commits | length) end),
			por_tipo: (if $commits == null then null else ($commits | group_by(.tipo) | map({(.[0].tipo): length}) | add // {}) end),
			fix: (if $commits == null then null else ($commits | map(select(.tipo == "fix")) | length) end),
			codigo: (if $commits == null then null else (de_codigo | length) end),
			sin_issue: (if $commits == null then null else (de_codigo | map(select(.issues == [])) | length) end),
			fix_tardio: (if $commits == null or $tardios == null then null else ([$commits[] | select(.h as $h | $tardios | index($h))] | length) end),
			# Issue con más commits fix: dice si la tasa de fix se reparte o es la cola de un solo issue.
			fix_max: (if $commits == null then null
				else [$commits[] | select(.tipo == "fix") | .issues | unique | .[]] | group_by(.)
					| map({issue: .[0], fix: length}) | sort_by(-.fix, .issue) | .[0] end)
		};
	def commits_de(de): if $todos == null then null else [$todos[] | select(.de == de)] end;
	{
		proyecto: $proyecto,
		repo: (if $repo == "" then null else $repo end),
		cerrados: (if $issues == null then null else (cerrados_en_ventana | map(select(.motivo != "not_planned")) | length) end),
		wontfix: (if $issues == null then null else (cerrados_en_ventana | map(select(.motivo == "not_planned")) | length) end),
		abiertos: (if $issues == null then null else ([$issues[] | select(.creado >= $inicio)] | length) end),
		tablero: $tablero,
		in_review: (if $tablero == null then null else ($tablero["In review"] // 0) end),
		in_review_dias: $in_review_dias,
		reaperturas: $reaperturas,
		compartido: $compartido
	}
	+ (if $compartido then (commits_de("propio") | de_commits) else ($todos | de_commits) end)
	+ {repo_sin_tablero: (if $compartido and $todos != null then (commits_de("repo") | de_commits) else null end)}'
