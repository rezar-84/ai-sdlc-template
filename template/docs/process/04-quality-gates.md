# 04 — Quality gates

What gets tested, in what order checks run, and how problems are rated. Stack-agnostic:
the charter names the actual commands, this document names the *stages*.

---

## Check sequence

Run in this order — cheapest and most localising first, so failures are diagnosed fast.

| # | Stage | Purpose | Charter key |
| --- | --- | --- | --- |
| 1 | Format | Mechanical consistency; removes diff noise. | `checks.format` |
| 2 | Lint | Known-bad patterns. | `checks.lint` |
| 3 | Typecheck / static analysis | Contract violations before runtime. | `checks.typecheck` |
| 4 | Unit | Logic in isolation. | `checks.unit` |
| 5 | Integration | Components against real boundaries — data store, queue, filesystem, auth. | `checks.integration` |
| 6 | Build / package | It actually assembles. | `checks.build` |
| 7 | Dependency + secret scan | Known vulnerabilities, leaked credentials. | `checks.scan` |
| 8 | Accessibility | Automated a11y smoke, where there is an interface. | `checks.a11y` |
| 9 | End-to-end | The real journeys, in a realistic environment. | `checks.e2e` |

**Rules:**
- A stage the project does not have is skipped *explicitly and reported*, not silently
  assumed to pass. "No integration suite exists" is a finding for the QA role, not a
  neutral fact.
- Never disable, skip, or loosen a check to make a change pass. If a check is wrong,
  fix the check as its own tracked item with its own justification.
- A flaky test is a defect. Quarantine it with a tracked ID and a deadline; do not
  normalise re-running until green.
- Anything running in CI must be runnable locally, and vice versa. A check only one of
  them can run will drift.

---

## Test strategy

Generic across stacks. Scale it to the project — a static site does not need a contract
suite; a payments API needs more than a smoke test.

**Unit** — pure logic, validators, policy decisions, formatters, calculations, state
machines. Fast, no I/O, no network. Where the interesting edge cases live.

**Integration** — the seams: persistence and its constraints, authorisation enforced at
the data layer and not only the route, external service clients against recorded or
faked responses, background jobs, file/blob handling.

**Contract** — if anything else consumes your interface, or you consume someone else's:
lock the shape. Breaking changes must fail a test, not a customer.

**End-to-end** — the two to five journeys that, if broken, mean the product is down.
Not a re-implementation of the unit suite through a browser or shell.

**Manual / human** — what automation genuinely cannot judge: language quality by a
native speaker, screen-reader experience, visual/brand judgement, and acceptance by the
person who asked for the thing.

### Non-negotiable test cases for high-risk surfaces

Where the project has them, these are required — not optional extras:

- **Authorisation:** permitted → allowed; not permitted → denied; *another tenant's or
  user's valid ID* → denied **without leaking existence or metadata**; revoked or
  expired access → denied; tampered identifier → denied; stale session →
  re-authentication.
- **Input:** oversized, malformed, wrong type, injection-shaped, unicode/RTL, empty,
  and boundary values.
- **Data:** migration forward and backward; concurrent writes; idempotency of anything
  retryable; deletion actually deletes (including derived copies, caches, and backups
  policy).
- **Money / irreversible actions:** double-submission, partial failure, and reconciliation.

---

## Severity ladder

Rate by **consequence if it reaches users**, never by likelihood or by how hard it is to
fix.

| | Severity | Definition | Response |
| --- | --- | --- | --- |
| **S0** | Critical | Data loss or corruption, security breach, exposure of one user's or tenant's data to another, credential leak, total unavailability. | Stop the release. Incident process. Fix before anything else. |
| **S1** | Major | A core journey is unusable — cannot sign in, cannot complete the primary task, cannot recover from an error. No workaround. | Release blocker. |
| **S2** | Significant | Important function degraded, accessibility barrier, a materially wrong or misleading claim shown to users, a broken public URL or metadata regression. Workaround exists but is poor. | Blocker unless a named human waives it in writing with a tracked follow-up. |
| **S3** | Minor | Localised functional or visual defect, inconsistent behaviour, poor edge-case handling. | Scheduled fix; does not block. |
| **S4** | Trivial | Polish, wording nits, internal documentation gaps. | Backlog. |

**Calibration examples** — the point of these is that the first two are *not* judgement
calls:

- One customer can read another customer's record → **S0**, always, regardless of how
  unlikely the path is.
- A password reset email never arrives → S1.
- A form is unusable by keyboard → S2.
- A published page states an unverified statistic about the business → S2 (see
  `06-evidence-and-claims.md`).
- A button is 2px misaligned on one breakpoint → S4.

---

## Budgets

Where a project has measurable budgets, the charter records them and this is where they
are enforced. Regressions against a budget are S2 by default.

Candidate budgets to set, if applicable: page or interaction latency at the 75th
percentile, payload/bundle size, cold-start time, query count per request, error rate,
availability, build duration, test-suite duration.

If a budget is not set, say so — an unstated budget is not "no budget", it is an
unmeasured one.

---

## CI expectations

- Every stage above runs on every change, or the charter documents which run when and
  why.
- CI runs against a realistic environment — real dependency versions, real data store
  where feasible, not an in-memory substitute that hides the failure mode you care about.
- Nightly or periodic: full end-to-end, dependency vulnerability scan, link/crawl checks
  for public content, and the high-risk matrices above.
- Post-deploy: smoke tests plus synthetic checks on the critical journeys.
- A red main branch is an incident, not a normal state.
