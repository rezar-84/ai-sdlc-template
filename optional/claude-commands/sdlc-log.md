---
description: Close a work item — worklog entry, backlog status, follow-ups, doc updates
---

Run the LOG → CLOSE steps of the loop per `docs/process/00-operating-model.md` for the
work just completed.

$ARGUMENTS

1. **Check the Definition of Done** in `docs/process/03-ready-and-done.md`. Anything
   unmet is either fixed now or becomes a tracked follow-up named in the entry — never
   an unstated gap.

2. **Write the worklog entry** at the top of `docs/project/worklog.md`, using
   `docs/templates/worklog-entry.md`. Required sections:
   - **What changed** — plain language, for someone who was not here.
   - **Why** — especially where the obvious approach was rejected.
   - **Verified** — the real commands and real results. Not "tests pass".
   - **Not done** — everything deferred, stubbed, mocked, or hardcoded, each with a
     follow-up ID. This is the section future readers need most and the one most often
     omitted. If there is genuinely nothing, say so explicitly.
   - **Discovered** — pre-existing bugs, stale docs, refuted assumptions. Include what
     you did not fix, especially what you did not fix.
   - **Decisions** and **Assumptions used**.

3. **Update the backlog** — status change with a pointer, never a bare status flip.
   Create rows for every follow-up, each a single line
   (`docs/templates/task.md`). Narrative stays in the worklog; the table stays terse.

4. **Reconcile `docs/project/assumptions-and-risks.md`** — close what was resolved, note
   what a refuted assumption means for work already shipped, add what is newly unknown.

5. **Update the docs the change falsified.** Any `project/` artifact that is now wrong is
   corrected, with its `last-reviewed` date bumped — or marked `status: stale` with a
   backlog item. Leaving a confidently wrong document is not an option.

6. **Write an ADR** if a durable decision was made and none exists
   (`docs/templates/adr.md`). If a decision was durable and you are not writing an ADR,
   say why.

7. **Report** what is done, what is verified, and what is open — plainly, without
   hedging and without overstating.
