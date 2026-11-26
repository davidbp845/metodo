#!/usr/bin/env bash
# Coste de trabajo de un proyecto en una ventana, por issue, como un objeto JSON en una línea, a
# partir de los registros de sesión de Claude Code (`~/.claude/projects/<carpeta>/*.jsonl`). Lo
# usa metricas.sh para el campo `coste`; sin registros de la carpeta, sale `null`.
#
#   coste.sh <carpeta del proyecto> <inicio AAAA-MM-DD>
#
# Atribución a un issue:
# - En una sesión, lo que va desde un `/dev:resolver-issue <NN>` escrito por el usuario hasta el
#   siguiente comando escrito (o el final de la sesión), con los subagentes que arrancan ahí.
# - Un subagente de `/dev:sprint`, por la ruta de su worktree (`sprint/<NN>`) en el encargo.
# El resto (conversación, integración del sprint, otros comandos) va a `sin_issue`.
#
# Tokens: `entrada` (sin caché y escritura de caché), `cache` (lectura de caché, mucho más barata)
# y `salida`. `minutos`: tiempo activo, sumando los huecos de menos de 5 min entre entradas del
# registro; lo que corre en paralelo (subagentes) suma, así que es tiempo de agente, no de reloj.
set -u

carpeta=${1:?uso: coste.sh <carpeta> <inicio AAAA-MM-DD>}
inicio=${2:?uso: coste.sh <carpeta> <inicio AAAA-MM-DD>}
absoluta=$(cd "$carpeta" 2>/dev/null && pwd) || { echo null; exit 0; }
dir="$HOME/.claude/projects/$(printf '%s' "$absoluta" | sed 's/[^A-Za-z0-9]/-/g')"
[ -d "$dir" ] || { echo null; exit 0; }
ini=$(jq -n --arg d "${inicio}T00:00:00Z" '$d | fromdateiso8601')

# Recorre un registro y suma por clave (número de issue o "sin"). Con $sub, es un subagente: su
# clave sale del encargo (`sprint/<NN>`) o del tramo de la sesión madre ($seg) en que arranca.
programa='
def ts: sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601;
def texto: .message.content | if type == "string" then . else ([.[]? | .text? // empty] | join(" ")) end;
def vacio: {entrada: 0, cache: 0, salida: 0, segundos: 0};
reduce (inputs | select(.timestamp != null)) as $e ({clave: null, prev: null, vistos: {}, tot: {}, seg: []};
	($e.timestamp | ts) as $t
	| if $sub then
		(if .clave == null and $e.type == "user" then
			.clave = (([$e | texto | capture("sprint/(?<n>[0-9]+)")?.n] | first)
				// ([$seg[] | select(.desde <= $t)] | last | .clave // null) // "sin")
		else . end)
	else
		([if $e.type == "user" then ($e | texto | capture("<command-name>(?<c>[^<]*)</command-name>")?.c) else empty end] | first) as $cmd
		| if $cmd == null then . else
			.clave = (if $cmd == "/dev:resolver-issue"
				then ([$e | texto | capture("<command-args>\\s*#?(?<n>[0-9]+)")?.n] | first // null) else null end)
			| .seg += [{clave: .clave, desde: $t}]
		end
	end
	| ((.clave // "sin") | tostring) as $k
	| if $t >= $ini then
		.tot[$k] = (.tot[$k] // vacio)
		| (if .prev != null and ($t - .prev) >= 0 and ($t - .prev) < 300 then .tot[$k].segundos += ($t - .prev) else . end)
		| ($e.message.id // null) as $id
		| if $e.type == "assistant" and $e.message.usage != null and ($id == null or .vistos[$id] == null) then
			($e.message.usage) as $u
			| .tot[$k].entrada += (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0))
			| .tot[$k].cache += ($u.cache_read_input_tokens // 0)
			| .tot[$k].salida += ($u.output_tokens // 0)
			| (if $id != null then .vistos[$id] = true else . end)
		else . end
	else . end
	| .prev = $t)
| {tot, seg}'

# date -d es de GNU; date -r <segundos>, de BSD (macOS).
desde=$(date -d "@$ini" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "$ini" '+%Y-%m-%d %H:%M:%S')
{
	find "$dir" -maxdepth 1 -name '*.jsonl' -newermt "$desde" 2>/dev/null | while IFS= read -r sesion; do
		madre=$(jq -n -c --argjson sub false --argjson seg '[]' --argjson ini "$ini" "$programa" "$sesion" 2>/dev/null) || {
			echo "coste.sh: no se pudo leer $sesion; queda fuera del coste" >&2
			continue
		}
		printf '%s\n' "$madre"
		seg=$(printf '%s' "$madre" | jq -c .seg)
		for agente in "${sesion%.jsonl}"/subagents/*.jsonl; do
			[ -f "$agente" ] || continue
			jq -n -c --argjson sub true --argjson seg "$seg" --argjson ini "$ini" "$programa" "$agente" 2>/dev/null ||
				echo "coste.sh: no se pudo leer $agente; queda fuera del coste" >&2
		done
	done
} | jq -s -c '
	def total: {entrada: (map(.entrada) | add // 0), cache: (map(.cache) | add // 0),
		salida: (map(.salida) | add // 0), minutos: ((map(.segundos) | add // 0) / 60 | round)};
	[.[].tot | to_entries[]] | group_by(.key) | map({key: .[0].key, value: (map(.value) | total)}) as $claves
	| ($claves | map(.value)) as $todo
	| {
		entrada: ($todo | map(.entrada) | add // 0), cache: ($todo | map(.cache) | add // 0),
		salida: ($todo | map(.salida) | add // 0), minutos: ($todo | map(.minutos) | add // 0),
		issues: [$claves[] | select(.key != "sin") | {issue: (.key | tonumber)} + .value] | sort_by(.issue),
		sin_issue: ([$claves[] | select(.key == "sin") | .value] | first // null)
	}'
