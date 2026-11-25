#!/usr/bin/env bash
# Proyecto de ejemplo con Repos por área: el de comun/proyecto.sh, con el área `marketing` en otro
# repo (negocio/, sin código ni Verificación propia).
set -eu
bash "$(dirname "$0")/comun.sh"
sed -i 's/^- Etiquetas de área: .*/&, `marketing`/' CLAUDE.md
cat >> CLAUDE.md <<'MD'
- Repos por área:
  - `marketing`: `ejemplo/negocio` en `negocio/`
MD
git -c user.name=eval -c user.email=eval@example.invalid commit -qam "chore: área marketing"
mkdir -p negocio/posts
printf '# Negocio\n\nPosts y textos de marketing. Sin código.\n' > negocio/README.md
git -C negocio init -q && git -C negocio add . && git -C negocio -c user.name=eval -c user.email=eval@example.invalid commit -qm "chore: repo de negocio"
