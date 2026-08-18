---
name: sdlc-intake
description: Frame an incoming request as a tracked work item before writing any code — read the charter, assign the next {{PREFIX}}-### ID, classify the risk tier, and produce the reading list for that tier. Use whenever a new request, bug report, or idea arrives and no work item exists for it yet, including the ones that look like a two-minute fix.
---

# Intake — turn a request into a tracked work item

The cost of skipping this is not process theatre: it is a change nobody can trace, tiered
by vibes, reviewed by the wrong roles, and merged against a charter nobody read.

## 1. Read first

- `{{DOCS_DIR}}/project/charter.md` — identity, stack, commands, active roles, risk
  defaults. If it is blank where it matters, run the `sdlc-charter-audit` skill and say
  what is Unknown rather than guessing past it.
- `{{DOCS_DIR}}/project/assumptions-and-risks.md` — what is already known to be shaky.
- `{{DOCS_DIR}}/project/backlog.md` — the highest ID in use, including `Dropped` rows.

## 2. Restate

One sentence, in your own words, of what is being asked. If your restatement could
plausibly mean something materially different from the request, ask now — this is the
cheapest moment in the whole loop to ask.

## 3. Assign the ID

`{{PREFIX}}-###`: the highest number found anywhere in `{{DOCS_DIR}}/project/`, plus one.
Numbers are never reused. Add a terse row to `{{DOCS_DIR}}/project/backlog.md`.

## 4. Classify the tier

Use "Risk tiers" in `AGENTS.md`, then the charter's **Risk defaults** — a project may
declare a surface always Tier 1 or never Tier 1. When in doubt, tier up and say why.

The tier decides three things at once: how much planning, which roles review, and how much
you are expected to read. Do not carry a Tier 1 surface at Tier 3 because the diff is
small — the tier follows the blast radius, not the line count.

## 5. Check readiness

The Definition of Ready items knowable now (`{{DOCS_DIR}}/process/03-ready-and-done.md`).
A failing item is recorded as a blocker, not guessed past. If a Tier 1 item is missing an
accountable human, approvers, or the data and jurisdiction facts, park it — see "Waiting
on a human" in `{{DOCS_DIR}}/process/00-operating-model.md`.

## 6. Produce the reading list

Name the specific files this change requires reading before it is designed: the role
playbooks that apply (`{{DOCS_DIR}}/roles/`), the artifacts it will falsify, the code paths
it touches. A Tier 3 reading list is allowed to be one line.

## Output

Report the restatement, the ID, the tier and why, the roles that will review, the reading
list, and any blocker. Then hand off to `/sdlc-plan` — do not start implementing from
inside this skill.
