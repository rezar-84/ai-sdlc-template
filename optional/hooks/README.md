# Hooks — the rules that are not persuasion

Everything else in this kit asks an agent to follow a rule. These make two of them
mechanical, by running before the tool call rather than after the fact.

**Claude Code only**, and **opt-in**: `./install.sh <dir> <PREFIX> --hooks`. Nothing
installs them by accident, because a hook executes on your machine on every matching tool
call and that is not something to acquire without deciding to.

## What is here

| Hook | Fires on | Does |
| --- | --- | --- |
| `work-item-id.sh` | `git commit` | Denies a commit whose message carries no `<PREFIX>-###`. `AGENTS.md` §6 requires the ID in the branch, the commit and the worklog; this is the one of the three a machine can check. |
| `protected-paths.sh` | `Write` / `Edit` | Denies an edit to a path listed in `.ai-sdlc/protected.txt` — the charter's platform-owned files, generated files, or anything else single-writer. Does nothing until that file has entries. |

Both are **deterministic**. Neither asks a model whether the rule was followed.

## What is deliberately not here

An evidence hook on `Stop` — "you claimed done without running anything" — was designed
and dropped. A hook cannot reliably tell whether the command that mattered ran this
session, so it would fire on turns that did nothing wrong. A guard that cries wolf gets
switched off within a day, and it takes the two working guards with it when it goes.
Evidence stays enforced where it can be enforced honestly: `sdlc-evidence-check`, and
`/sdlc-verify` running the charter's real commands.

The same reasoning applies to anything you add here. **Only automate a rule whose
violation is decidable from the tool call itself.**

## Requirements and failure mode

The scripts need `jq` and POSIX `sh`. **If `jq` is missing they allow the call** and say
so once, rather than blocking your work over a missing dependency — they are guard rails
for an agent, not a security boundary. Anything that must not happen belongs in
`permissions.deny` in `.claude/settings.json`, which the harness enforces itself.

## Escaping them

Deliberately possible, and deliberately visible: commit outside the tool, or remove the
hook from `.claude/settings.json`. The point is to make the wrong thing take a decision,
not to make it impossible.
