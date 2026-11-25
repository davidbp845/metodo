#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): pasa el formateador del proyecto por el fichero editado.
# Lo lee del campo Formateador del `## Método` del CLAUDE.md más cercano hacia arriba:
#   - Formateador: `./venv/bin/ruff format` para `*.py`; `npx prettier --write` para `*.ts`, `*.css`
# Cada orden se ejecuta desde la carpeta del campo Repo (o la del CLAUDE.md) con el fichero como
# último argumento, y solo si el fichero está dentro de esa carpeta. Si falla, se lo dice a Claude.
set -u

fichero=$(jq -r '.tool_input.file_path // empty')
[ -n "$fichero" ] && [ -f "$fichero" ] || exit 0

dir=$(dirname "$fichero")
while :; do
	if [ -f "$dir/CLAUDE.md" ] && grep -q '^## Método' "$dir/CLAUDE.md"; then break; fi
	[ "$dir" = / ] || [ "$dir" = . ] && exit 0
	dir=$(dirname "$dir")
done

seccion=$(awk '/^## Método/ { p = 1; next } /^## / { p = 0 } p' "$dir/CLAUDE.md")
campo=$(printf '%s\n' "$seccion" | sed -n 's/^- Formateador:[[:space:]]*//p' | head -1)
[ -n "$campo" ] || exit 0

carpeta=$dir
repo=$(printf '%s\n' "$seccion" | sed -n 's/^- Repo:.* en `\([^`]*\)`.*/\1/p' | head -1)
[ -n "$repo" ] && carpeta="$dir/${repo%/}"
case "$fichero" in "$carpeta"/*) ;; *) exit 0 ;; esac
nombre=$(basename "$fichero")

IFS=';' read -ra reglas <<<"$campo"
for regla in "${reglas[@]}"; do
	# Entre comillas invertidas: primero la orden, después los patrones.
	trozos=()
	while IFS= read -r trozo; do trozos+=("$trozo"); done < <(printf '%s' "$regla" | grep -o '`[^`]*`' | tr -d '`')
	[ "${#trozos[@]}" -ge 2 ] || continue
	for patron in "${trozos[@]:1}"; do
		# shellcheck disable=SC2053
		if [[ $nombre == $patron ]]; then
			if ! salida=$(cd "$carpeta" && eval "${trozos[0]} \"\$fichero\"" 2>&1); then
				printf 'El formateador (%s) falló con %s:\n%s\n' "${trozos[0]}" "$fichero" "$salida" >&2
				exit 2
			fi
			break
		fi
	done
done
exit 0
