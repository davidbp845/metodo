#!/usr/bin/env bash
# Commits sin subir de un proyecto con `## Método`, agrupados por el issue de su pie. Lo usa
# /dev:higiene-tablero para avisar de los issues en In review o Done cuyo código solo está en local.
#
#   sin-subir.sh <carpeta del proyecto>
#
# Mira la carpeta del código (la del campo Repo, o la del proyecto), la de cada línea de Repos por
# área y la de cada repo de Repos relacionados (con su propio campo Repo, si lo tiene), tras un
# `git fetch`. Una carpeta sin
# remoto no cuenta. Una línea por repo e issue, separada por tabuladores:
#
#   <carpeta>  <owner/repo#NN | sin-pie | sin-remota>  <número de commits>
#
# El pie `Issue: #NN` se refiere al repo de GitHub de esa carpeta; `Issue: <owner>/<repo>#NN`, a
# ese repo. Un commit sin pie cuenta en `sin-pie`; una rama sin upstream sale como `sin-remota`.
set -u

carpeta=${1:?uso: sin-subir.sh <carpeta del proyecto>}
claude_md="$carpeta/CLAUDE.md"
[ -f "$claude_md" ] || { echo "No existe $claude_md" >&2; exit 1; }

# Carpeta del código de un proyecto: la del campo Repo de su `## Método`, o la propia carpeta.
codigo_de() {
	local linea
	linea=$(sed -n '/^## Método/,/^## /p' "$1/CLAUDE.md" 2>/dev/null | grep -m1 '^- Repo:')
	if [ -n "$linea" ]; then
		printf '%s/%s' "$1" "$(printf '%s' "$linea" | sed -n 's/.* en `\([^`]*\)`.*/\1/p' | sed 's#/$##')"
	else
		printf '%s' "$1"
	fi
}

carpetas=("$(codigo_de "$carpeta")")
while IFS= read -r rel; do
	[ -n "$rel" ] && carpetas+=("$(codigo_de "$carpeta/$rel")")
done < <(sed -n '/^## Método/,/^## /p' "$claude_md" | grep -m1 '^- Repos relacionados:' | grep -o '`[^`]*`' | tr -d '`')

while IFS= read -r rel; do
	[ -n "$rel" ] && carpetas+=("$carpeta/${rel%/}")
done < <(sed -n '/^## Método/,/^## /p' "$claude_md" | awk '/^- Repos por área:/ { f = 1; next } f && /^- / { exit } f && /^[[:space:]]+- / { print }' |
	sed -n 's/.* en `\([^`]*\)`.*/\1/p')
# Dos áreas, o un área y Repo, pueden compartir carpeta: cada una se mira una vez. Sin mapfile
# ni realpath -m, que el bash 3.2 y el sistema de macOS no traen.
unicas=()
while IFS= read -r d; do unicas+=("$d"); done < <(for d in "${carpetas[@]}"; do
	(cd "$d" 2>/dev/null && pwd -P) || printf '%s\n' "$d"
done | awk '!visto[$0]++')
carpetas=("${unicas[@]}")

for dir in "${carpetas[@]}"; do
	# Sin remoto no hay a dónde subir: un contenedor local, por ejemplo.
	git -C "$dir" remote get-url origin >/dev/null 2>&1 || continue
	git -C "$dir" fetch -q 2>/dev/null
	if ! git -C "$dir" rev-parse -q --verify '@{u}' >/dev/null 2>&1; then
		printf '%s\tsin-remota\t%s\n' "$dir" "$(git -C "$dir" rev-list --count HEAD)"
		continue
	fi
	propio=$(git -C "$dir" remote get-url origin 2>/dev/null | sed -E 's#.*github\.com[:/]##; s#\.git$##')
	git -C "$dir" log '@{u}..HEAD' --format='%x1e%B' | awk -v RS='\x1e' -v propio="$propio" '
		NF == 0 { next }
		{
			refs = ""
			n = split($0, lineas, "\n")
			for (i = 1; i <= n; i++) {
				if (lineas[i] !~ /^Issue: /) continue
				resto = substr(lineas[i], 8)
				while (match(resto, /([A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+)?#[0-9]+/)) {
					ref = substr(resto, RSTART, RLENGTH)
					if (substr(ref, 1, 1) == "#") ref = propio ref
					refs = refs " " ref
					resto = substr(resto, RSTART + RLENGTH)
				}
			}
			if (refs == "") { cuenta["sin-pie"]++; next }
			m = split(refs, lista, " ")
			for (j = 1; j <= m; j++) if (lista[j] != "") cuenta[lista[j]]++
		}
		END { for (k in cuenta) print k "\t" cuenta[k] }
	' | sort | while IFS=$'\t' read -r ref num; do
		printf '%s\t%s\t%s\n' "$dir" "$ref" "$num"
	done
done
