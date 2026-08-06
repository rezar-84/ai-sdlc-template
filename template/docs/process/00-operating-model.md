# 00 — Operating model

How an agent turns a request into shipped, documented, verified work.

---

## The loop

```
FRAME → PLAN → DESIGN REVIEW → BUILD → VERIFY → SHIP REVIEW → LOG → CLOSE
```

Each step below states its purpose, its output, and how it collapses for low-risk work.
Nothing is skipped; low-risk work simply produces a sentence where high-risk work
produces a document.

### 1. FRAME

Turn a request into a bounded unit of work.

- Restate the request in one sentence, in your own words. If your restatement and the
  request could plausibly mean different things, ask now — before planning, not after
  building.
- Assign or reuse a work item ID (`{{PREFIX}}-###`) and add it to
  `project/backlog.md`. A request that is really three tasks becomes three IDs.
- Classify the **risk tier** (`AGENTS.md` §3). This decides everything downstream.
- Check `project/assumptions-and-risks.md` — the thing you are about to build may
  already be blocked on a decision nobody made.
- Check the **Definition of Ready** (`03-ready-and-done.md`). If it fails, either
  resolve the gap or record the blocker and say so rather than guessing.

**Output:** a backlog row with ID, one-line description, tier, owner role, dependencies,
status `Ready` or `Blocked`.

### 2. PLAN

Decide the approach before touching code.

- Read the existing implementation first. Most plans are wrong because they were written
  against an imagined codebase.
- State the approach, the files/areas affected, the data or contract changes, the test
  strategy, and the rollback story.
- Name the alternatives you rejected and why — one line each. This is what makes a plan
  reviewable rather than merely readable.
- List what you are *not* doing, so scope drift is visible.

**Output:** Tier 1 → `project/plans/{{PREFIX}}-###.md` from `templates/plan.md`.
Tier 2 → the same content, inline in the response. Tier 3 → one sentence.

### 3. DESIGN REVIEW

Vet the plan through the relevant role playbooks *before* building. Catching a
misconceived approach here costs minutes; catching it after implementation costs the
implementation.

See `02-role-reviews.md` for which roles engage at which tier. Reviews at this stage read
the plan and the current code, not a diff.

**Output:** Tier 1 → `project/reviews/{{PREFIX}}-###-design.md`. Tier 2 → findings
summarised in the response. Tier 3 → skipped unless the change touches a role's blocking
list.

**A Block here stops the work.** Revise the plan and re-review, or escalate to a human.

### 4. BUILD

- Implement to the plan. If reality forces a deviation, say so explicitly and record it
  — a plan quietly abandoned mid-build is how untraceable systems are made.
- Write tests alongside the change, including failure and rejection paths.
- Keep the change scoped to the ID. Unrelated improvements become new backlog rows.
- Update any `project/` artifact the change falsifies, in the same change.

### 5. VERIFY

Run the checks the charter names, in the order given by `04-quality-gates.md`. Report the
actual result.

- A check you did not run is reported as *not run*, with the reason.
- A check that cannot run in this environment is reported as *blocked*, with what would
  be needed.
- Failing output is pasted or summarised faithfully. Never describe a failing suite as
  "mostly passing".
- For anything user-facing, verify the behaviour, not only the build: exercise the actual
  path, in the actual states (empty, loading, error, unauthorised, long content).

### 6. SHIP REVIEW

Re-run the relevant role playbooks against the *diff and the running result*, not the
plan. Different findings surface here than at design time: dead buttons, missing empty
states, copy that says something the legal review would not allow, a migration with no
down path.

**Output:** Tier 1 → `project/reviews/{{PREFIX}}-###-ship.md`. Tier 2 → summarised.
Tier 3 → skipped.

### 7. LOG

Append an entry to `project/worklog.md` using `templates/worklog-entry.md`. It must say:

- what changed, in plain terms;
- what was verified and how (the actual commands and results);
- what was **not** done, deferred, or stubbed, and where that is now tracked;
- decisions taken and why, with links to any ADR;
- anything discovered along the way — pre-existing bugs, stale docs, wrong assumptions.

The worklog is prose and can be long. The backlog is a table and stays terse: one line
per item, status only. Do not fold narrative into the backlog table — it becomes
unreadable within a dozen items and the status becomes impossible to scan.

### 8. CLOSE

- Backlog status updated (`Done`, `Blocked`, `Deferred` — with a pointer, never a bare
  status change).
- New items created for everything discovered and not fixed.
- `assumptions-and-risks.md` updated: resolved entries closed, new unknowns added.
- Docs whose `last-reviewed` you invalidated are updated or marked `stale` with a
  backlog item.
- State completion plainly: what is done, what is verified, what is open.

---

## Modes

The loop is the same; the emphasis differs.

### Bootstrap — a new or newly adopted project

Run the gates in `01-lifecycle-gates.md` from G0. The first deliverables are documents,
not code: charter, product brief, discovery audit (if replacing something), architecture,
and a threat model if the risk surface warrants one. Resist writing code before the
charter names the stack — that decision is an ADR, not an accident.

### Change — the normal mode

The loop as written, scaled by tier.

### Incident — something is broken in production

Order changes: **contain → diagnose → fix → verify → log → postmortem.** Process is
compressed but not skipped, and the postmortem is mandatory for S0/S1
(`templates/postmortem.md`). Never let an incident fix bypass review permanently — it
gets a retroactive review and a real backlog ID within the next working session.

### Exploration — spike, prototype, research

Timeboxed and explicitly labelled. Its output is knowledge, not shippable code. A spike
branch is never merged directly; it produces a plan or an ADR, and the real
implementation runs the full loop. Say "this is a spike" in the worklog so nobody
mistakes it for a decision.

---

## Deciding how much process applies

Ask, in order:

1. **Can this hurt someone or something?** (money, data, privacy, availability,
   reputation, legal exposure) → Tier 1, no exceptions.
2. **Does it change behaviour a user or another system depends on?** → Tier 2.
3. **Is it reversible in one commit with no consequence?** → Tier 3.

Two failure modes are equally bad, and the second is the more common with agents:

- **Under-process:** shipping an auth change with no review or test.
- **Over-process:** producing five review documents for a typo fix, burying real
  findings in ceremony, and exhausting the reader's attention so that the one real
  finding is skimmed.

Process is a tool for catching mistakes, not a performance of diligence.

---

## Working agreements

- **Read before writing.** Never rewrite a file you have not read.
- **One thing at a time.** Finish the loop for one ID before starting the next, unless
  they are genuinely independent.
- **Ask at the right time.** Do everything that does not depend on the answer first,
  then ask. Blocking with nothing delivered is for cases where any assumption could be
  unsafe or make the work useless.
- **Report faithfully.** If a step was skipped, say so. If a test fails, show it. A
  correct report of partial work is worth more than a confident report of imagined work.
- **Prefer the smallest change that fully solves the problem.** Then say what a larger
  change would have bought, and log it.
