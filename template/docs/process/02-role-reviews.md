# 02 — Role reviews

The mechanism that turns a single agent into a review board. This is the highest-value
part of the kit and also the easiest to fake, so the rules below are mostly about
preventing fake reviews.

---

## What a role review is

You adopt one role's playbook from `docs/roles/`, read the actual artifact — plan, diff,
running system — through that role's concerns only, and produce findings.

**It is not** a paragraph of praise per role. **It is not** a restatement of what the
change does. **It is not** a list of generic best practices that were not checked against
this code.

### The evidence rule for reviews

Every finding names a location and a consequence:

> `<file>:<line>` (or `<screen>` / `<endpoint>` / `<doc section>`) — *what is wrong* —
> *what goes wrong because of it* — *what would fix it*.

Every review states what it checked, including when it found nothing:

> Checked: all 6 new endpoints for authorisation on the object (not just the route),
> the two migrations for a down path, and the audit log for token leakage. No findings.

A review that cannot say what it checked did not happen. Write "not reviewed — no access
to X" rather than implying coverage you do not have.

---

## Stages

| Stage | Reads | Catches |
| --- | --- | --- |
| **Design review** — after PLAN, before BUILD | the plan + current code | wrong approach, missing constraint, unconsidered failure mode, scope that violates a policy |
| **Ship review** — after VERIFY, before merge/release | the diff + the running result | dead affordances, missing states, drifted copy, unhandled errors, missing tests, doc drift |

Design review is cheap and prevents expensive rework. Do not skip it to "just start
coding" on a Tier 1 or Tier 2 item.

---

## Who reviews what

Start from the charter's active roles, then select by **change surface** — what the work
actually touches — rather than reviewing with every role every time.

| The change touches… | Roles that must engage |
| --- | --- |
| Scope, priority, or what a user can do | product-manager |
| Module boundaries, dependencies, data flow, build/runtime shape | architect |
| Any screen, flow, or interaction | ux-designer, accessibility |
| Visual language, tokens, layout, imagery, brand expression | brand-designer |
| Any user-visible text | copywriter |
| Publicly discoverable content, URLs, metadata, structure | seo |
| A conversion path, funnel step, form, pricing, or CTA | cro-analyst |
| Authentication, authorisation, secrets, input handling, sessions, isolation | security |
| Build, deploy, infra, config, observability, backups | devops-sre |
| Any behaviour with acceptance criteria | qa |
| Personal data, tracking, consent, retention, terms, claims about the business | privacy-legal |

**Tier 1** additionally engages product-manager, architect, security, and qa regardless
of surface — those four are the standing board for high-risk work.

**Tier 3** usually engages zero or one role. A typo fix in body copy engages copywriter,
nothing else.

---

## Verdicts

| Verdict | Meaning | Consequence |
| --- | --- | --- |
| **Pass** | No findings above S3 within this role's remit. | Proceed. |
| **Pass with conditions** | Proceed now; named follow-ups are tracked with IDs and owners. | Conditions become backlog items before merge, not "later". |
| **Block** | An S0/S1 finding, or an S2 on a release-critical surface. | Work stops. |

### On a Block

1. Stop building. Do not "note and proceed".
2. Either fix it and re-review, or escalate to a human with the finding, the options,
   and a recommendation.
3. **You may not waive your own blocker.** A waiver requires a named human, a written
   reason, and a tracked follow-up item. Record all three in the review file.

This rule exists because the single most common way an agent-run process degrades is a
review that finds a real problem, notes it politely, and continues anyway. That is worse
than not reviewing — it launders the problem into a document that looks like diligence.

---

## Running a review well

**Do:**
- Read the real artifact. Open the files. Run the thing if it runs.
- Stay in role. The security reviewer does not comment on button radius; the brand
  reviewer does not comment on query performance. Cross-role concerns get handed to the
  owning role, not opined on.
- Rank by consequence, not by how easy the finding was to spot.
- Look hardest at what the change *did not* touch but should have — the missing
  migration, the untouched test, the doc now contradicted, the second code path with the
  same bug.
- Be specific enough that a fix requires no further investigation.

**Do not:**
- Pad with findings you do not believe, to look thorough. Three real findings beat
  fifteen padded ones, and padding trains the reader to skim.
- Repeat the same finding across roles. Assign it to the role that owns it and reference
  it from the others.
- Review your own plan sympathetically. The purpose is to find what you missed. Actively
  try to break your own approach; assume it is wrong and look for the reason.

---

## Record format

One file per review: `project/reviews/{{PREFIX}}-###-<design|ship>.md`, from
`templates/role-review.md`. Findings carry S0–S4 severity per `04-quality-gates.md`.

For Tier 2, the same content can live in the response and be summarised in the worklog
entry. For Tier 1 it must be a file — it is the audit trail for the approval.

---

## Anti-patterns, named so they can be called out

| Anti-pattern | What it looks like | Fix |
| --- | --- | --- |
| **Rubber stamp** | "SEO review: metadata looks good. Pass." | State what was checked and how. |
| **Generic advice** | "Consider adding rate limiting" on a change with no endpoint. | Findings must be grounded in this diff. |
| **Severity inflation** | Everything is S1, so nothing is. | Reserve S0/S1 for actual data loss, security, or total unavailability. |
| **Severity deflation** | A cross-tenant leak logged as S3 because it is "unlikely". | Severity is by consequence, not by likelihood. |
| **Self-waiver** | "Blocked on X — proceeding as X is low risk." | Escalate. Only a human waives. |
| **Review theatre** | Twelve role sections on a typo fix. | Select roles by surface and tier. |
| **Finding without location** | "Some error handling is missing." | Name the file and line. |
