#!/usr/bin/env bash
# Instala la configuración global del método en esta máquina: CLAUDE.md, settings.json
# y hooks de usuario en el directorio de configuración de Claude Code, los comandos de
# maquina/bin en ~/.local/bin y el plugin dev@metodo.
# Funciona en Linux, en macOS (con su bash 3.2) y en Git Bash (Windows). Uso en maquina/README.md.
set -euo pipefail

uso() {
  cat <<'EOF'
Uso: maquina/instalar.sh [--comprobar | --sobrescribir] [--desatendido]

  (sin opción)    escribe los ficheros que faltan; si uno existe y difiere, enseña el diff y para
  --comprobar     solo compara lo generado con lo instalado; sale con 1 si hay diferencias
  --sobrescribir  reemplaza los que difieren, guardando antes una copia <fichero>.bak-AAAAMMDD-HHMMSS
  --desatendido   incluye el temporizador de las sesiones desatendidas: en Linux, el de systemd
                  en ~/.config/systemd/user/; en macOS, el agente de launchd en
                  ~/Library/LaunchAgents/. Activarlo es aparte (lo dice al terminar)

Directorio de configuración: $CLAUDE_CONFIG_DIR, o ~/.claude si no está definido.
Reglas propias de esta máquina: <config>/metodo-maquina.json (opcional), con la forma
{"carpetas": [...], "permissions": {"allow": [...], "deny": [...], "ask": [...], "additionalDirectories": [...]},
 "mcpServers": {...}}.
"carpetas" son las carpetas de proyectos dentro de la de datos (sin ella, la carpeta de datos
entera): cada una se puede editar y es directorio de trabajo. Las listas de "permissions" se
añaden al final de las de la plantilla. "mcpServers", con la forma de un .mcp.json y rutas
absolutas, se registran a nivel de usuario (claude mcp add-json --scope user).
EOF
}

modo=instalar
desatendido=0
for arg in "$@"; do
  case "$arg" in
    --comprobar) modo=comprobar ;;
    --sobrescribir) modo=sobrescribir ;;
    --desatendido) desatendido=1 ;;
    -h|--help) uso; exit 0 ;;
    *) uso >&2; exit 2 ;;
  esac
done

aqui=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
metodo=$(dirname "$aqui")
data=$(dirname "$metodo")
# Las reglas de permisos usan la ruta en forma POSIX (/d/Data en Git Bash); las importaciones
# @, los directorios y el marketplace, la forma nativa (D:/Data). En Linux coinciden.
if command -v cygpath >/dev/null 2>&1; then data_nativa=$(cygpath -m "$data"); else data_nativa=$data; fi
config=${CLAUDE_CONFIG_DIR:-$HOME/.claude}

# --- Dependencias ---
falta=0
for dep in git gh jq claude; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "Falta $dep." >&2
    case "$dep" in
      gh) echo "  Instálalo: https://cli.github.com (macOS: brew install gh; Windows: winget install GitHub.cli)" >&2 ;;
      jq) echo "  Instálalo: Linux, gestor de paquetes; macOS: brew install jq; Windows: winget install jqlang.jq" >&2 ;;
      claude) echo "  Instálalo: https://code.claude.com/docs/setup" >&2 ;;
    esac
    falta=1
  fi
done
[ "$falta" = 0 ] || exit 1
if ! gh auth status >/dev/null 2>&1; then
  echo "Aviso: gh no tiene sesión iniciada. Los skills de dev la necesitan: gh auth login" >&2
elif noreply=$(gh api user --jq '"\(.id)+\(.login)@users.noreply.github.com"' 2>/dev/null); then
  # Los repos públicos exponen el correo de cada commit: se firma con el noreply de la cuenta.
  email=$(git config --global user.email || true)
  if [ "$email" != "$noreply" ]; then
    echo "Aviso: git firma con '${email:-(sin user.email)}', no con el correo noreply de GitHub." >&2
    echo "  git config --global user.email $noreply" >&2
  fi
fi

# --- Generar en un directorio temporal ---
tmp=$(mktemp -d)
trap 'rm -f "$tmp"/*; rmdir "$tmp"' EXIT

extra="$config/metodo-maquina.json"
carpetas=()
if [ -f "$extra" ]; then
  while IFS= read -r c; do carpetas+=("$c"); done < <(jq -r '.carpetas // [] | .[]' "$extra")
fi
case ${#carpetas[@]} in
  0) proyectos=$data_nativa ;;
  1) proyectos="$data_nativa/${carpetas[0]}" ;;
  *) proyectos="$data_nativa/{$(IFS=,; echo "${carpetas[*]}")}" ;;
esac

rellenar() {
  sed -e "s|{{PROYECTOS}}|$proyectos|g" -e "s|{{DATA_NATIVA}}|$data_nativa|g" -e "s|{{DATA}}|$data|g" "$1"
}

rellenar "$aqui/CLAUDE.plantilla.md" > "$tmp/CLAUDE.md"
# Las carpetas de proyectos van delante de la de Metodo en allow, y al principio de additionalDirectories.
rellenar "$aqui/settings.plantilla.json" | jq --arg data "$data" --arg nativa "$data_nativa" '
  ($ARGS.positional | if length == 0 then ["."] else . end) as $c
  | "Edit(/\($data)/Metodo/**)" as $metodo
  | .permissions.allow |= (map(select(. != $metodo))
      + [$c[] | if . == "." then "Edit(/\($data)/**)" else "Edit(/\($data)/\(.)/**)" end] + [$metodo])
  | .permissions.additionalDirectories |=
      ([$c[] | if . == "." then $nativa else "\($nativa)/\(.)" end] + .)
' --args ${carpetas[@]+"${carpetas[@]}"} > "$tmp/settings.base.json"
if [ -f "$extra" ]; then
  jq --slurpfile e "$extra" '
    reduce ("allow","deny","ask","additionalDirectories") as $k (.;
      .permissions[$k] = ((.permissions[$k] // []) + ($e[0].permissions[$k] // [])))
  ' "$tmp/settings.base.json" > "$tmp/settings.json"
else
  jq . "$tmp/settings.base.json" > "$tmp/settings.json"
fi
rm "$tmp/settings.base.json"

# fichero generado -> ruta instalada
destinos=("CLAUDE.md:$config/CLAUDE.md" "settings.json:$config/settings.json")
for h in "$aqui"/hooks/*; do
  cp "$h" "$tmp/hook-$(basename "$h")"
  destinos+=("hook-$(basename "$h"):$config/hooks/$(basename "$h")")
done
# Comandos de maquina/bin: en ~/.local/bin va un lanzador, no una copia, para que un pull de
# Metodo los actualice sin reinstalar.
for b in "$aqui"/bin/*; do
  printf '#!/usr/bin/env bash\nexec "%s" "$@"\n' "$b" > "$tmp/bin-$(basename "$b")"
  destinos+=("bin-$(basename "$b"):$HOME/.local/bin/$(basename "$b")")
done

sistema=$(uname -s)
agente="$HOME/Library/LaunchAgents/metodo-desatendido.plist"
if [ "$desatendido" = 1 ]; then
  # Ni systemd ni launchd heredan el PATH de la shell: se fija con dónde están claude, gh y jq.
  ruta=$(printf '%s\n' "$(dirname "$(command -v claude)")" "$(dirname "$(command -v gh)")" "$(dirname "$(command -v jq)")" \
    /opt/homebrew/bin /usr/local/bin /usr/bin /bin | awk '!visto[$0]++' | paste -sd: -)
  if [ "$sistema" = Darwin ]; then
    rellenar "$aqui/desatendido/metodo-desatendido.plist" | sed -e "s|{{RUTA}}|$ruta|g" -e "s|{{HOME}}|$HOME|g" > "$tmp/metodo-desatendido.plist"
    destinos+=("metodo-desatendido.plist:$agente")
  else
    command -v systemctl >/dev/null 2>&1 || { echo "--desatendido necesita systemd en Linux, o launchd en macOS." >&2; exit 1; }
    unidades=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user
    for u in metodo-desatendido.service metodo-desatendido.timer; do
      rellenar "$aqui/desatendido/$u" | sed "s|{{RUTA}}|$ruta|g" > "$tmp/$u"
      destinos+=("$u:$unidades/$u")
    done
  fi
fi

# --- Comparar e instalar ---
# settings.json se compara por contenido: Claude Code lo reescribe, cambia el orden de las claves
# y, en Windows, guarda la ruta del marketplace con barras invertidas (F:\Data\Metodo). La ruta
# se compara con barras normales y sin barras repetidas; en Linux no cambia nada.
normalizar() {
  jq -S 'if .extraKnownMarketplaces then .extraKnownMarketplaces |= map_values(
           if .source.path then .source.path |= (gsub("\\\\"; "/") | gsub("/+"; "/")) else . end)
         else . end' "$1"
}
iguales() {
  case "$2" in
    */settings.json) cmp -s <(normalizar "$1") <(normalizar "$2") ;;
    *) cmp -s "$1" "$2" ;;
  esac
}
diferencias() {
  case "$2" in
    */settings.json) diff -u --label "$2" --label generado <(normalizar "$2") <(normalizar "$1") || true ;;
    *) diff -u --label "$2" --label generado "$2" "$1" || true ;;
  esac
}

difiere=0
for par in "${destinos[@]}"; do
  origen="$tmp/${par%%:*}"; destino="${par#*:}"
  if [ ! -f "$destino" ]; then
    if [ "$modo" = comprobar ]; then echo "Falta: $destino"; difiere=1; continue; fi
    mkdir -p "$(dirname "$destino")"; cp "$origen" "$destino"; echo "Creado: $destino"
  elif iguales "$origen" "$destino"; then
    echo "Al día: $destino"
  else
    difiere=1
    echo "Difiere: $destino"
    diferencias "$origen" "$destino"
    if [ "$modo" = sobrescribir ]; then
      copia="$destino.bak-$(date +%Y%m%d-%H%M%S)"
      cp "$destino" "$copia"; cp "$origen" "$destino"
      echo "Reemplazado (copia en $copia)"
    fi
  fi
  case "$destino" in "$config"/hooks/*|"$HOME"/.local/bin/*) [ -f "$destino" ] && chmod +x "$destino" ;; esac
done

# --- Servidores MCP de usuario ---
# Los "mcpServers" de metodo-maquina.json se registran a nivel de usuario, para tenerlos en
# cualquier sesión y no solo en la carpeta de su proyecto. Claude Code los guarda en
# .claude.json, que no es una plantilla: se comparan por servidor, sin los campos vacíos que
# añade al guardarlos.
if [ -f "$extra" ]; then
  estado=${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR/.claude.json}
  estado=${estado:-$HOME/.claude.json}
  limpiar='with_entries(select(.value != [] and .value != {} and (.key != "type" or .value != "stdio")))'
  while IFS= read -r nombre; do
    quiere=$(jq -cS --arg n "$nombre" ".mcpServers[\$n] | $limpiar" "$extra")
    tiene=$( (jq -cS --arg n "$nombre" ".mcpServers[\$n] // empty | $limpiar" "$estado" 2>/dev/null) || true)
    if [ -z "$tiene" ]; then
      if [ "$modo" = comprobar ]; then echo "Falta: servidor MCP $nombre"; difiere=1; continue; fi
      claude mcp add-json --scope user "$nombre" "$quiere" >/dev/null && echo "Creado: servidor MCP $nombre"
    elif [ "$tiene" = "$quiere" ]; then
      echo "Al día: servidor MCP $nombre"
    else
      difiere=1
      echo "Difiere: servidor MCP $nombre"
      echo "  instalado: $tiene"
      echo "  generado:  $quiere"
      if [ "$modo" = sobrescribir ]; then
        claude mcp remove --scope user "$nombre" >/dev/null
        claude mcp add-json --scope user "$nombre" "$quiere" >/dev/null && echo "Reemplazado (el instalado era el de arriba)"
      fi
    fi
  done < <(jq -r '.mcpServers // {} | keys[]' "$extra")
fi

if [ "$modo" = comprobar ]; then exit "$difiere"; fi
if [ "$difiere" = 1 ] && [ "$modo" = instalar ]; then
  echo "Hay ficheros que difieren de la plantilla y no se han tocado." >&2
  echo "Si el cambio instalado es bueno, pásalo a maquina/ en Metodo; si no, repite con --sobrescribir." >&2
  exit 1
fi

if [ "$desatendido" = 1 ] && [ "$modo" != comprobar ]; then
  if [ "$sistema" = Darwin ]; then
    if ! launchctl print "gui/$(id -u)/metodo.desatendido" >/dev/null 2>&1; then
      echo "Agente de launchd instalado, sin cargar. Para cargarlo: launchctl bootstrap gui/$(id -u) $agente"
    fi
  else
    systemctl --user daemon-reload 2>/dev/null || true
    if ! systemctl --user is-enabled metodo-desatendido.timer >/dev/null 2>&1; then
      echo "Temporizador instalado, sin activar. Para activarlo: systemctl --user enable --now metodo-desatendido.timer"
    fi
  fi
fi

# --- Plugin ---
if claude plugin list 2>/dev/null | grep -q 'dev@metodo'; then
  echo "Al día: plugin dev@metodo"
else
  # settings.json ya declara el marketplace; add lo descarga a la caché local de plugins.
  claude plugin marketplace add "$data_nativa/Metodo" >/dev/null
  claude plugin install dev@metodo --scope user && echo "Instalado: plugin dev@metodo"
fi
