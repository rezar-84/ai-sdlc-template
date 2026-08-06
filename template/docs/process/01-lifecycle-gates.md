# 01 — Lifecycle gates

Seven gates from idea to operation. **They are not a waterfall.** They apply per
increment: a feature can be at G3 while the next one is at G1. A whole project passes
through them once at the start; every change after that passes through a compressed
version of the same sequence.

A gate is *passed* when its exit criteria are met and recorded — not when time has
elapsed.

---

## G0 — Discovery

**Purpose:** understand the problem, the users, and the ground truth before proposing
anything.

**Entry:** a request exists.

**Do:**
- Identify who has the problem, what they do today, and what it costs them.
- Audit what already exists: current system, data, content, traffic, integrations,
  contracts, constraints.
- Collect the non-negotiables — legal, regulatory, brand, budget, timeline, existing
  platform commitments.
- Write down what is *unknown*. This list is as valuable as what is known.

**Artifacts:** `project/charter.md`, `project/discovery-audit.md` (if something already
exists), `project/assumptions-and-risks.md` seeded with the unknowns.

**Exit:** the problem statement is written and an owner agrees it is the right problem.
Unknowns are recorded, not resolved — resolving them is later work.

**Common failure:** designing the solution during discovery, then rationalising the
research to fit it.

---

## G1 — Definition

**Purpose:** decide what will be built, for whom, and how success is judged.

**Entry:** G0 exit.

**Do:**
- Product brief: positioning, audiences, jobs-to-be-done, value, scope in/out.
- Success metrics with baselines. A metric without a baseline is a wish
  (`templates/measurement-plan.md`).
- User stories with acceptance criteria, prioritised.
- Explicit **Not now** list. Scope is defined by what you refuse.

**Artifacts:** `project/product-brief.md`, `project/user-stories.md`,
`project/measurement-plan.md`, populated `project/backlog.md`.

**Exit:** product-manager role review passes; every P0 story has testable acceptance
criteria; the scope boundary is written down.

**Common failure:** acceptance criteria that restate the story ("the user can log in")
instead of specifying observable behaviour including failure states.

---

## G2 — Design

**Purpose:** decide how it will work, before building it.

**Entry:** G1 exit for the increment in question.

**Do:**
- Technical architecture and the stack decision, each material choice as an ADR.
- Information architecture / navigation / interaction design, if there is an interface.
- Design system foundations: tokens, type scale, spacing, components, states.
- Data model and API/contract shape.
- Threat model if auth, tenancy, payments, PII, or public exposure are in scope.
- Content and SEO plan if the output is publicly discoverable.

**Artifacts:** `project/architecture.md`, `project/data-model-api.md`,
`project/design-system.md`, `project/threat-model.md`, `project/content-seo-plan.md`,
ADRs.

**Exit:** architect, security, and design role reviews pass or pass with recorded
conditions. Every "we'll figure that out later" is a logged assumption with an owner.

**Common failure:** a design that never states its failure modes — what the system does
when the dependency is down, the input is hostile, or the list is empty.

---

## G3 — Build

**Purpose:** implement to the design, with tests, in traceable increments.

**Entry:** G2 exit; task passes Definition of Ready.

**Do:** the BUILD step of the loop, per work item.

**Artifacts:** code, tests, updated `project/` docs, worklog entries.

**Exit:** Definition of Done met for each item (`03-ready-and-done.md`).

**Common failure:** the design document and the implementation diverge and nobody
updates the design document, so it becomes actively misleading. Update it or mark it
`stale` — do not leave it confidently wrong.

---

## G4 — Verification

**Purpose:** prove it does what was specified, and does not do what was forbidden.

**Entry:** G3 exit for the increment.

**Do:**
- Run the full check sequence (`04-quality-gates.md`), not just the fast subset.
- Test the acceptance criteria as written, including negative and boundary cases.
- Run role ship reviews.
- Exercise real states: empty, loading, slow, error, unauthorised, oversized input,
  concurrent action, and — where relevant — every supported locale, device size, and
  permission level.

**Artifacts:** `project/test-plan.md` updated with what is actually covered,
`project/reviews/*-ship.md`, verification notes in the worklog.

**Exit:** no open S0 or S1. S2 either fixed or waived in writing by a named human with a
reason and a tracked follow-up.

**Common failure:** verifying the happy path and calling it done; treating "it compiles"
as verification.

---

## G5 — Release

**Purpose:** get it into users' hands without breaking what already worked.

**Entry:** G4 exit.

**Do:**
- Follow `project/release-runbook.md`: pre-flight checks, migration order, deploy,
  smoke test, monitoring window, rollback trigger and procedure.
- Confirm backups/restores are current and *tested*, not merely configured.
- Announce what changed to whoever depends on it.

**Exit:** deployed, smoke-tested in the target environment, monitored for the agreed
window, rollback proven available.

**Common failure:** a rollback plan that has never been executed, and a migration with
no reverse path.

---

## G6 — Operate & learn

**Purpose:** find out whether it actually worked.

**Do:**
- Watch the metrics named in the measurement plan against their baselines.
- Triage incidents; postmortem anything S0/S1 (`templates/postmortem.md`).
- Feed findings back into the backlog as real items, not vague intentions.
- Re-review documents whose `last-reviewed` date has aged past the charter's threshold.

**Exit:** none — this gate is continuous. It closes only when the project is retired,
which itself deserves a documented decommissioning plan (data export, redirects,
credential revocation, dependency notification).

**Common failure:** shipping and never checking whether the success metric moved, so the
next decision is made on the same guesswork as the last one.

---

## Gate summary

| Gate | Question it answers | Blocking role reviews |
| --- | --- | --- |
| G0 Discovery | What is really the problem? | product-manager |
| G1 Definition | What are we building and how will we know it worked? | product-manager, copywriter (if messaging), privacy-legal (if regulated) |
| G2 Design | How will it work? | architect, security, ux-designer, brand-designer, seo |
| G3 Build | Is it built as designed? | qa (continuous) |
| G4 Verification | Does it do what we said, and refuse what we forbade? | qa, security, accessibility, cro-analyst |
| G5 Release | Can we ship and un-ship safely? | devops-sre, security |
| G6 Operate | Did it work? | cro-analyst, product-manager |

Roles not marked blocking may still review; they simply cannot hold the gate.
