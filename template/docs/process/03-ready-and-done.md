# 03 — Definition of Ready / Definition of Done

Two checklists that prevent the two most common wastes: starting work that cannot
succeed, and declaring work finished that is not.

---

## Definition of Ready

A work item may not enter BUILD until all of these are true. If one fails, the item is
`Blocked` with the reason recorded — not started optimistically.

- [ ] **It has an ID** and a row in `project/backlog.md`.
- [ ] **The outcome is stated in one sentence** — what will be true afterwards that is
      not true now. Not "improve the dashboard" but "the dashboard shows the last
      successful sync time per report".
- [ ] **Acceptance criteria are testable**, including at least one negative case (what
      must *not* happen, or what must be refused).
- [ ] **The risk tier is assigned.**
- [ ] **Dependencies are identified and satisfied**, or the item is explicitly a
      partial that stops at the dependency boundary.
- [ ] **Unknowns are resolved or bounded.** An unresolved unknown is either answered by
      a human, made irrelevant by a stated assumption, or the item is blocked. It is
      never silently guessed.
- [ ] **The affected artifacts are known** — which `project/` docs this will falsify.
- [ ] **Design/plan exists** at the depth the tier requires, and has passed design
      review for Tier 1–2.
- [ ] **It is small enough to finish.** If it cannot plausibly reach Done in one working
      session, split it into items that can, each independently valuable.

---

## Definition of Done

An item is `Done` only when all of these are true. Anything unmet is either fixed or
becomes a tracked follow-up named in the worklog entry — never an unstated gap.

### Function
- [ ] Every acceptance criterion demonstrably met, including the negative cases.
- [ ] Failure paths handled: empty, loading, error, timeout, unauthorised, forbidden,
      not-found, malformed input, concurrent action.
- [ ] No dead affordances — every control does what it appears to do, or is removed.
- [ ] No placeholder data presented as real. Placeholders are visibly labelled and
      logged.

### Quality
- [ ] Tests written and passing, covering the happy path *and* the refusals.
- [ ] The project's full check sequence run, with real output reported
      (`04-quality-gates.md`).
- [ ] No new lint/type/security-scan warnings introduced, or each one justified in
      writing.
- [ ] Performance within the budgets the charter names, where budgets exist.

### Review
- [ ] Required role reviews complete for the tier, with verdicts recorded.
- [ ] No open S0/S1. S2 fixed or waived in writing by a named human with a follow-up ID.
- [ ] Human approvals obtained where `AGENTS.md` §8 requires them.

### Documentation
- [ ] Worklog entry appended: what changed, what was verified and how, what was
      deferred, what was discovered.
- [ ] Backlog status updated; follow-ups created with IDs.
- [ ] Every `project/` artifact the change falsified is updated, or marked `stale` with
      a backlog item.
- [ ] ADR written for any material decision; superseded ADRs marked, not edited.
- [ ] `assumptions-and-risks.md` reconciled — resolved entries closed, new ones added.

### Operability *(anything that deploys)*
- [ ] Configuration and secrets documented; no secret in the repository or the logs.
- [ ] Migration has a tested reverse path, or its irreversibility is explicitly accepted
      in writing.
- [ ] Observability exists for the new behaviour — you can tell from outside whether it
      is working.
- [ ] Rollback procedure stated and known to work.

---

## Definition of Abandoned

Rarely written down, and it should be. An item may be closed without being done when:

- the underlying need disappeared (record why);
- it was superseded by another item (link it);
- it was blocked for longer than the charter's staleness threshold and nobody needs it.

Move it to a `Dropped` status with a one-line reason. Do not silently delete backlog
rows — the record that something was considered and rejected is worth keeping, and
deleting it guarantees someone proposes it again.
