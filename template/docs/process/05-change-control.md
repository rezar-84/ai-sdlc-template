# 05 — Change control

How a change moves from a working copy to production, and how it comes back if it was
wrong.

---

## Branches

```
<type>/{{PREFIX}}-###-short-slug
```

`type` ∈ `feat` · `fix` · `docs` · `chore` · `refactor` · `test` · `perf` · `sec`

One branch per work item. If a branch grows a second unrelated purpose, split it — a
mixed branch cannot be reviewed properly or reverted cleanly.

Never commit directly to the default branch unless the charter explicitly permits it for
this project.

---

## Commits

- Small, scoped, and individually coherent. A reviewer should be able to read one commit
  and understand one decision.
- Imperative mood, present tense: `add`, `fix`, `remove` — not `added`, `fixes`.
- Reference the work item ID.
- Never mix a refactor with a behaviour change in the same commit. Reviewing a diff
  where formatting, moving, and changing are entangled is how real bugs get waved
  through.

```
<type>(<scope>): <what changed, imperative, ≤72 chars>

<why it changed — the reasoning a future reader will not be able to infer>
<what was verified>

Refs: {{PREFIX}}-###
```

### Never commit

Secrets, tokens, private keys, `.env` contents, customer or personal data, large
binaries, generated artifacts that belong in a build, or anything under a licence the
project cannot honour. If a secret is committed, it is **compromised** — rotate it; do
not merely remove it in a follow-up commit.

---

## Pull requests

Body must contain:

1. **What** — the change in plain language.
2. **Why** — the problem, linked to the work item.
3. **How** — the approach, and alternatives rejected.
4. **Verification** — the checks run and their real results. Screenshots or output for
   anything user-visible.
5. **Risk** — tier, blast radius, and the rollback procedure.
6. **Review verdicts** — links to `project/reviews/` for Tier 1.
7. **Follow-ups** — what was deliberately left, with IDs.

Keep PRs small enough to review attentively. A PR nobody can hold in their head gets
approved on trust, which defeats the purpose.

---

## Approvals

| Change | Approval |
| --- | --- |
| Tier 3 | Self-merge permitted if all checks pass. |
| Tier 2 | One reviewer. |
| Tier 1 | **Two human approvers**, at least one with domain ownership of the affected surface. |
| Anything the charter names in `AGENTS.md` §8 | As named there, regardless of tier. |

An agent may prepare, propose, and justify a change. An agent does not approve its own
Tier 1 work, and does not count as either of the two approvers.

Never bypass a failing security, migration, accessibility, or data-integrity check. If
the check is wrong, that is a separate tracked change with its own justification.

---

## Architecture Decision Records

Write an ADR when a decision is **expensive to reverse** or when a future reader would
otherwise have to reverse-engineer the reasoning from the code.

**Write one for:** the stack, storage, and hosting choices; authentication and
authorisation model; tenancy/isolation model; public interface shape; a new significant
dependency; a data model that others will build on; anything you chose against the
obvious option.

**Do not write one for:** naming, formatting, or anything a lint rule can express.

Rules:
- Numbered sequentially, never renumbered: `project/adr/0007-slug.md`.
- Status: `Proposed` → `Approved` → (`Superseded by NNNN` | `Deprecated`).
- **Never edit the decision of an approved ADR.** Write a new one that supersedes it and
  link both directions. The record of what was decided *and later abandoned* is the most
  valuable part of the archive.
- Record the rejected options with the actual reason, not "not a good fit".

Template: `templates/adr.md`.

---

## Releases

Follow `project/release-runbook.md`. Every release states:

- what is included (the work item IDs);
- migration steps and their order relative to the deploy;
- the smoke checks that prove it worked;
- the monitoring window and what would trigger a rollback;
- the rollback procedure, which must have been executed at least once in a non-production
  environment.

**Migrations:** forward and reverse paths, both tested. Expand-then-contract for schema
changes so that old and new code can run simultaneously. Never hand-edit a production
datastore — a manual fix that is not a migration is invisible to every other environment
and to the next deploy.

**Irreversible operations** (data deletion, destructive migration, external
notifications, payments) require explicit human authorisation on the specific action.
Authorisation for one such action does not carry to the next.

---

## Rollback and hotfix

- Prefer rolling back over rolling forward when the cause is not understood within the
  first minutes. Diagnose from a stable state.
- A hotfix still gets an ID, a test that reproduces the failure, and a worklog entry —
  written immediately after the fire is out, not "later".
- Any S0/S1 incident produces a postmortem (`templates/postmortem.md`) focused on the
  system that allowed it, not on who typed it.
