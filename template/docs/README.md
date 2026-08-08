# Documentation map

This tree is the delivery system for {{PROJECT_NAME}}. `AGENTS.md` at the repository
root is the contract; everything here is the detail behind it.

## Cold start — an agent arriving with no context

Read in this order and stop when you have enough:

1. `project/charter.md` — what this is, who it is for, ID prefix, active roles, stack,
   environments, risk defaults. **Nothing else in this tree is reliable if the charter
   is empty.**
2. `project/backlog.md` — what is planned, in flight, and done.
3. `project/worklog.md` (most recent entries) — what actually happened, and why.
4. `project/assumptions-and-risks.md` — what is unknown, unverified, or contested.
5. The specific artifact your task touches (architecture, design system, test plan…).

Do not bulk-read `process/` and `roles/` up front. Open a process doc when you hit the
step it governs; open a role playbook when you are performing that role's review.

## `process/` — how work is done

Portable standards. Identical in every project that installs this kit. Do not add
project facts here.

| File | Answers |
| --- | --- |
| `00-operating-model.md` | What is the loop? How do I decide how much process a task needs? What are the modes (bootstrap vs. change vs. incident)? |
| `01-lifecycle-gates.md` | What are the phases G0–G6, what must exist to enter and to leave each one? |
| `02-role-reviews.md` | Who reviews what, at which stage, with what verdict, and what happens on a Block? |
| `03-ready-and-done.md` | When is a task ready to start? When is it actually finished? |
| `04-quality-gates.md` | What must be tested, in what order do checks run, how are bugs severity-rated? |
| `05-change-control.md` | Branches, commits, PRs, approvals, ADRs, releases, rollback. |
| `06-evidence-and-claims.md` | What may be stated as fact, what needs a source, how unknowns are recorded. |
| `07-traceability.md` | ID scheme, what gets logged where, how staleness is detected. |

## `roles/` — who reviews

One playbook per professional perspective. Each has the same shape: mission, when to
engage and when to skip, what it reads, a design-review checklist, a ship-review
checklist, a severity calibration table, what it owns, and where it hands findings off.
See `roles/README.md` for the roster and how to run a review.

## `templates/` — blank artifacts

Copy these into `project/` when the project needs one. Never edit a file in `templates/`
to hold project content.

| Template | Copy to | Create when |
| --- | --- | --- |
| `product-brief.md` | `project/product-brief.md` | At G1, always |
| `discovery-audit.md` | `project/discovery-audit.md` | Replacing or migrating an existing system |
| `user-stories.md` | `project/user-stories.md` | Any user-facing scope |
| `architecture.md` | `project/architecture.md` | Any project with more than one moving part |
| `data-model-api.md` | `project/data-model-api.md` | Persistent data or a public/internal API exists |
| `design-system.md` | `project/design-system.md` | A user interface exists |
| `content-seo-plan.md` | `project/content-seo-plan.md` | Public discoverable content exists |
| `measurement-plan.md` | `project/measurement-plan.md` | Success is measured by user behaviour |
| `security-privacy.md` | `project/security-privacy.md` | Always, even if the answer is "no user data" |
| `threat-model.md` | `project/threat-model.md` | Auth, tenancy, payments, PII, or public exposure |
| `test-plan.md` | `project/test-plan.md` | Always |
| `release-runbook.md` | `project/release-runbook.md` | Anything that deploys |
| `adr.md` | `project/adr/NNNN-slug.md` | Per material decision |
| `plan.md` | inline in the response, or `project/plans/{{PREFIX}}-###.md` | Per Tier 1–2 task |
| `role-review.md` | `project/reviews/{{PREFIX}}-###-<stage>.md` | Per Tier 1 review only; Tier 2 and 3 record verdicts in the worklog entry |
| `worklog-entry.md` | appended to `project/worklog.md` | Per completed task |
| `postmortem.md` | `project/postmortems/YYYY-MM-DD-slug.md` | After an S0/S1 incident |

## `project/` — this project's reality

The only directory that changes daily. Every document in it carries frontmatter:

```yaml
---
status: draft | approved | stale
owner: <person or role accountable>
last-reviewed: YYYY-MM-DD
---
```

Two exceptions, both deliberate. **ADRs** carry their own decision lifecycle instead
(`Proposed | Approved | Superseded by NNNN | Deprecated` — see `templates/adr.md`); an
ADR is a dated record of a decision, so it never goes `stale`, it gets superseded. And
the `README.md` in each subdirectory is part of the kit, not a project record.

`status: stale` is a legitimate and useful state. Marking a document stale is better
than leaving a confident, wrong document in place — but the marking must be accompanied
by a backlog item to fix it.
