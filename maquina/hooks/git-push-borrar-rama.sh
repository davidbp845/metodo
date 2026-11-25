#!/usr/bin/env bash
# PreToolUse (Bash): pide confirmación ante `git push <remoto> :<rama>`,
# que borra una rama remota. Sustituye a la regla "Bash(git push* :*)",
# que no se puede expresar con la sintaxis de permisos (el ":*" final
# se interpreta como prefijo).
cmd=$(jq -r '.tool_input.command // empty')
if printf '%s' "$cmd" | grep -Eq "(^|[;&|(\`[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push([[:space:]]+[^;&|]*)?[[:space:]]+[\"']?:[^[:space:]]"; then
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"git push con refspec :<rama> borra una rama remota; requiere confirmación."}}'
fi
exit 0
