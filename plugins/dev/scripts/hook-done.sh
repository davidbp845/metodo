#!/usr/bin/env bash
# PreToolUse (Bash): pasar un item del tablero a Done pide confirmación. El ciclo termina en
# In review para que la revisión del usuario no se salte; solo un issue cerrado como
# "not planned" (/dev:cerrar-issue-wontfix) va directo a Done.
# Si GitHub no responde, deja pasar: el hook no debe bloquear el tablero.
set -u

cmd=$(jq -r '.tool_input.command // empty')
printf '%s' "$cmd" | grep -Eq '(^|[;&|(`[:space:]])gh[[:space:]]+project[[:space:]]+item-edit([[:space:]]|$)' || exit 0

valor() { printf '%s' "$cmd" | grep -Eo -- "--$1[= ]+[\"']?[A-Za-z0-9_-]+" | head -1 | sed -E "s/^--$1[= ]+[\"']?//"; }
opcion=$(valor single-select-option-id)
item=$(valor id)
[ -n "$opcion" ] && [ -n "$item" ] || exit 0

datos=$(gh api graphql -f item="$item" -f query='query($item: ID!) {
  node(id: $item) { ... on ProjectV2Item {
    content { ... on Issue { number state stateReason } ... on PullRequest { number state } }
    project { field(name: "Status") { ... on ProjectV2SingleSelectField { options { id name } } } }
  } } }' 2>/dev/null) || exit 0

nombre=$(jq -r --arg o "$opcion" '.data.node.project.field.options[]? | select(.id == $o) | .name' <<<"$datos")
[ "$nombre" = Done ] || exit 0
[ "$(jq -r '.data.node.content.stateReason // empty' <<<"$datos")" = NOT_PLANNED ] && exit 0

numero=$(jq -r '.data.node.content.number // "?"' <<<"$datos")
jq -cn --arg r "Pasar #$numero a Done: el ciclo termina en In review para no saltarse la revisión del usuario; solo un issue cerrado como not planned va directo a Done. Confirma solo si el usuario lo ha pedido para este issue." \
	'{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
