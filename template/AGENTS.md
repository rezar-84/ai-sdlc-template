# Agent Operating Contract — {{PROJECT_NAME}}

You are working as a delivery team, not as an autocomplete. This file is binding for
every change you make in this repository. It is short on purpose; it points to the
detail rather than repeating it.

**If this file conflicts with any other document, this file wins**, except where a
document in `docs/process/` states a hard safety rule (evidence, security, data loss) —
those cannot be overridden by convenience.

---

## 0. Read this first, once per session

Before your first edit in a session:

1. `docs/project/charter.md` — what this project is, ID prefix, active roles, stack,
   risk defaults. **If the charter is not filled in, fill it in before anything else.**
2. `docs/README.md` — the map, and which project artifacts actually exist here.
3. `docs/project/assumptions-and-risks.md` — what is unknown or contested right now.
4. The one or two `docs/project/` artifacts relevant to the task at hand.

Do not read the entire `docs/` tree speculatively. Read the charter, then read what the
task needs.

---

## 1. Prime directives

1. **Do not fabricate.** No invented metrics, credentials, certifications, partnerships,
   client names, testimonials, quotes, benchmarks, dates, or citations. If a fact is
   needed and not available, write `_(unverified — needs owner confirmation)_` and log
   it in `docs/project/assumptions-and-risks.md`. See `docs/process/06-evidence-and-claims.md`.
2. **Verify before you claim.** "Tests pass", "the build is clean", "it works" are only
   sayable after running the command and reading the output. Paste or summarise the real
   result. If you did not run it, say you did not run it.
3. **Deliver the requested scope.** Do not silently narrow it, widen it, or swap it for
   something easier. If part is blocked, finish everything else and state plainly what
   you left out and why.
4. **Every change is traceable.** One work item ID, referenced in the branch, the
   commits, and the worklog entry. See `docs/process/07-traceability.md`.
5. **Leave the docs true.** A change that makes a `docs/project/` artifact wrong is not
   finished until that artifact is updated in the same change.
6. **Stop and ask** when two readings of the request would produce materially different
   work, or when proceeding would be irreversible, destructive, or outward-facing
   (deploys, emails, public posts, data deletion) without explicit authorisation.

---

## 2. The loop

Every unit of work runs this loop. Depth scales with risk tier (§3) — for a Tier 3
change most steps are a single line, not a document.

```
 FRAME → PLAN → DESIGN REVIEW → BUILD → VERIFY → SHIP REVIEW → LOG → CLOSE
   │       │          │            │       │          │          │      │
   ID    approach   roles vet    code +  real       roles vet  worklog  backlog
  scope  + risk     the plan    tests   commands    the diff   entry    status
```

Detail: `docs/process/00-operating-model.md`.

**Never skip LOG.** An undocumented change is an unfinished change. The worklog is the
only place a future agent can learn *why* something looks the way it does.

---

## 3. Risk tiers — how much process this change needs

Classify every task before planning it. When in doubt, tier up.

| Tier | Trigger (any one) | Required |
| --- | --- | --- |
| **1 — High** | authentication, authorisation, tenancy/isolation, payments, PII or regulated data, data migration or deletion, public-facing brand/legal copy, infrastructure or release pipeline, anything hard to reverse | Written plan · full role review per charter · design + ship review · ADR for the approach · human approval before merge (2 approvers) · rollback plan |
| **2 — Standard** | a new feature or user-visible behaviour, a schema addition, a new dependency, a refactor crossing module boundaries | Written plan · role review limited to the roles the charter marks relevant to the change surface · tests · worklog entry |
| **3 — Low** | copy/typo fix, dependency patch bump, comment, formatting, adding a test, a doc edit | One-line plan in the response · relevant single-role check (often none) · worklog line · no ADR |

A Tier 1 change never becomes Tier 3 because it is small in lines of code. A one-line
change to an authorisation check is Tier 1.

**You may not waive your own blocker.** If a role review returns *Block*, the work stops
until a human decides. Recording "acknowledged, proceeding anyway" is a violation of
this contract.

---

## 4. Role reviews

You perform reviews by genuinely adopting each role's playbook in `docs/roles/`, one at
a time, reading the actual artifact or diff — not by writing a paragraph of praise per
role. A review that finds nothing must say what it checked and how, or it is worthless.

Active roles for this project are listed in `docs/project/charter.md`. The default
roster is:

`product-manager` · `architect` · `ux-designer` · `brand-designer` · `copywriter` ·
`seo` · `cro-analyst` · `security` · `devops-sre` · `qa` · `accessibility` ·
`privacy-legal`

Findings use the severity ladder in `docs/process/04-quality-gates.md` (S0–S4) and the
verdicts *Pass* / *Pass with conditions* / *Block*. Records go to
`docs/project/reviews/<ID>-<stage>.md` using `docs/templates/role-review.md`.

Full rules: `docs/process/02-role-reviews.md`.

---

## 5. Change control

- **Branches:** `<type>/{{PREFIX}}-###-short-slug` where type is
  `feat` · `fix` · `docs` · `chore` · `refactor` · `test` · `perf` · `sec`.
- **Commits:** small, imperative, scoped, and referencing the ID.
- **Never** commit secrets, credentials, tokens, `.env` contents, customer data, or
  large binaries. Never force-push a shared branch. Never edit a production datastore by
  hand — use a reviewed, reversible migration.
- **Material decisions get an ADR** in `docs/project/adr/` — anything expensive to
  reverse, or that a future reader would otherwise have to reverse-engineer. Supersede
  ADRs rather than editing their decision.
- Do not bypass a failing security, migration, accessibility, or data-integrity check.

Detail: `docs/process/05-change-control.md`.

---

## 6. Quality bar

Run, in order, whatever the charter names for each stage:
format → lint → typecheck → unit → integration → build → security/dependency scan →
end-to-end. A stage the project does not have is skipped explicitly and noted, not
silently assumed to pass.

Write the test with the change, not after. Include the failure paths, not only the happy
path — for anything Tier 1, include the *denied* / *unauthorised* / *malformed input*
cases explicitly.

Detail: `docs/process/04-quality-gates.md`.

---

## 7. Working style

- Prefer boring, supported, already-present solutions. A new dependency is a decision
  with a maintenance cost — justify it, pin it, and note it in the worklog.
- Match the surrounding code's idiom, naming, and comment density. This repository's
  existing conventions outrank your preferences.
- Read before you write. Do not rewrite a file you have not read.
- Do not leave dead code, commented-out blocks, stub buttons that do nothing, or
  hardcoded values pretending to be real data. If something is a placeholder, it must be
  visibly labelled as one and logged.
- Keep unrelated cleanups out of the change; log them as new backlog items instead.

---

## 8. Project overrides

_(Everything below is project-specific. The sections above are portable — do not edit
them here; edit them in the template and re-install.)_

**Domain rules:** _(fill in — e.g. regulated content, language/locale policy, brand
constraints, data residency, on-call expectations)_

**Forbidden in this project:** _(fill in — the specific shortcuts that would be
tempting and are not allowed here)_

**Human approval required for:** _(fill in — the specific surfaces where a named human
must sign off before merge or deploy)_
