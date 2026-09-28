#!/bin/sh
# Deny a command that needs a named human's approval.
# AGENTS.md section 9 ("Human approval required for") and the charter's Environments table:
# the agent does everything up to the gate -- prepares the release, the migration, the
# plan -- and a human passes it. This hook reads .ai-sdlc/gates.txt, one shell glob per
# line matched against the whole command, # for comments.
#
# It denies rather than asks. A deny is honoured in every permission mode, headless runs
# included; an "ask" is not documented to be, and a gate that is sometimes open is not one.
#
# The approval route: the human runs the command themselves, or starts the session with
# AI_SDLC_APPROVAL set to the change ticket or work item that authorises it. The agent
# cannot set that variable for the harness from inside the session.
set -u

command -v jq >/dev/null 2>&1 || {
  printf '{"systemMessage":"ai-sdlc: approval-gate hook inactive (jq not installed)."}\n'
  exit 0
}

list=.ai-sdlc/gates.txt
[ -f "$list" ] || exit 0

payload=$(cat)

# The gate list is the human's: removing a gate is itself a change that needs approval.
path=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""')
if [ -n "$path" ]; then
  if [ "${path#"$PWD"/}" = "$list" ]; then
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s lists the commands that need a named human'"'"'s approval. Changing that list is the human'"'"'s decision: propose the edit instead of making it."}}\n' "$list"
  fi
  exit 0
fi

cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
[ -n "$cmd" ] || exit 0

while IFS= read -r pattern || [ -n "$pattern" ]; do
  case "$pattern" in ''|'#'*) continue ;; esac
  # shellcheck disable=SC2254  # the glob is the point
  case "$cmd" in
    $pattern)
      if [ -n "${AI_SDLC_APPROVAL:-}" ]; then
        reason=$(printf 'ai-sdlc: gated command allowed under approval %s (matched %s). Record the approval in the worklog entry.' "$AI_SDLC_APPROVAL" "$pattern" | jq -Rs .)
        printf '{"systemMessage":%s}\n' "$reason"
        exit 0
      fi
      reason=$(printf 'This command matches %s in .ai-sdlc/gates.txt: it needs a named human'"'"'s approval (AGENTS.md section 9). Do not look for another route to the same effect. Stop, and hand the human the exact command, what it will change, and the rollback. They run it themselves, or restart the session with AI_SDLC_APPROVAL=<ticket or ID>.' "$pattern" | jq -Rs .)
      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' "$reason"
      exit 0
      ;;
  esac
done < "$list"
exit 0
