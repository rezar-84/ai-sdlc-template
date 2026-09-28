#!/bin/sh
# Deny a commit whose message carries no work item ID.
# AGENTS.md section 6 and {{DOCS_DIR}}/process/07-traceability.md: every branch, commit,
# review and worklog entry carries the same ID. A commit is the one a machine can check.
#
# stdin: the PreToolUse hook payload. stdout: a PreToolUse permission decision.
set -u
. "$(dirname "$0")/lib.sh"
hook_init work-item-id

payload=$(cat)
cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')

# Only real commits. --amend and -m are all still commits; a `git commit` inside a
# longer pipeline is caught by the same substring, which is the conservative direction.
case "$cmd" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

# A prefix nobody configured cannot be enforced.
prefix=""
if [ -f .ai-sdlc/profile.json ]; then
  prefix=$(jq -r '.prefix // ""' .ai-sdlc/profile.json 2>/dev/null)
fi
[ -n "$prefix" ] || exit 0

if printf '%s' "$cmd" | grep -Eq "${prefix}-[0-9]+"; then
  exit 0
fi

hook_deny "This commit carries no work item ID. AGENTS.md section 6 requires ${prefix}-### in the branch, the commit and the worklog entry, because that string is the only join key between the code and the record of why it changed.

Add it to the commit message. If this work genuinely has no backlog item, create one first ({{DOCS_DIR}}/process/07-traceability.md: the next ID is the highest anywhere under project/, including Dropped rows and the archive, plus one)."
