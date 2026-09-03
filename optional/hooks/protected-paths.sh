#!/bin/sh
# Deny an edit to a single-writer path.
# The charter's "Managed platform" table names files another agent owns and this one must
# never hand-edit; {{DOCS_DIR}}/process/10-multi-agent.md names the rest. This hook reads
# .ai-sdlc/protected.txt, one shell glob per line, # for comments.
set -u

command -v jq >/dev/null 2>&1 || {
  printf '{"systemMessage":"ai-sdlc: protected-paths hook inactive (jq not installed)."}\n'
  exit 0
}

list=.ai-sdlc/protected.txt
[ -f "$list" ] || exit 0

payload=$(cat)
path=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""')
[ -n "$path" ] || exit 0

rel=${path#"$PWD"/}

while IFS= read -r pattern || [ -n "$pattern" ]; do
  case "$pattern" in ''|'#'*) continue ;; esac
  # shellcheck disable=SC2254  # the glob is the point
  case "$rel" in
    $pattern)
      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s is listed in .ai-sdlc/protected.txt as single-writer: it is owned by a managed platform, generated, or held by another agent. Hand-editing it is what the charter forbids, and the edit would be overwritten or would break the owner. Change the thing that generates it, or take the file up with its owner."}}\n' "$rel"
      exit 0
      ;;
  esac
done < "$list"
exit 0
