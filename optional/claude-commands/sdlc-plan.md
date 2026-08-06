---
description: Frame a request as a tracked work item and produce a reviewed plan
---

Run the FRAME → PLAN → DESIGN REVIEW steps of the loop in `AGENTS.md` for:

$ARGUMENTS

Follow `docs/process/00-operating-model.md`. Specifically:

1. **Read** `docs/project/charter.md` first. If it is not filled in, stop and fill it in
   — nothing else is reliable without it. Then read
   `docs/project/assumptions-and-risks.md`.

2. **Frame.** Restate the request in one sentence. If your restatement could plausibly
   mean something different from what was asked, ask now. Assign the next
   `{{PREFIX}}-###`, classify the risk tier per `AGENTS.md` §3, and add a terse row to
   `docs/project/backlog.md`. Check the Definition of Ready in
   `docs/process/03-ready-and-done.md` — if it fails, record the blocker rather than
   guessing past it.

3. **Plan.** Read the existing implementation before proposing anything; most bad plans
   are written against an imagined codebase. Then produce a plan from
   `docs/templates/plan.md` — Tier 1 as a file in `docs/project/plans/`, Tier 2 inline,
   Tier 3 as a sentence. Include the alternatives you rejected and the reason each lost,
   the failure modes, the rollback, and what you are deliberately not doing.

4. **Design review.** Select roles by change surface and tier per
   `docs/process/02-role-reviews.md`. Adopt each playbook in `docs/roles/` genuinely,
   one at a time, reading the real code. For each: state what you checked, then the
   findings with location, consequence, and fix. A verdict with no "what I checked" is
   not a review.

5. **Report** the tier, the plan, the findings, and the overall verdict. If any role
   returns Block, stop and say what needs deciding — do not proceed and note it.

Do not write implementation code in this command.
