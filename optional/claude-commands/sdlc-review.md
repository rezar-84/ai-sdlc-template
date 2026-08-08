---
description: Run a multi-role review of the current changes (or a named artifact)
argument-hint: "[optional: a path, commit range, plan file, or work item ID]"
---

Run a role review per `docs/process/02-role-reviews.md` on:

$ARGUMENTS

(If no argument is given, review the uncommitted and unpushed changes on the current
branch.)

1. **Establish what you are reviewing.** Read the actual diff and the surrounding code.
   Run the thing if it runs. State the commit range or files you examined.

2. **Select roles** by change surface and tier, using the table in
   `docs/process/02-role-reviews.md` and the active roster in
   `docs/project/charter.md`. Include the charter's project-specific role checks. Do not
   review with every role reflexively, and do not skip a role whose surface was touched.

3. **For each role**, work through its playbook in `docs/roles/` against the real
   artifact. Produce:
   - **Checked:** what you examined and how — required even when there are no findings.
   - **Not checked:** what this review does not cover. Never imply coverage you lack.
   - **Findings:** severity (S0–S4 per `docs/process/04-quality-gates.md`), location as
     `file:line`, what is wrong, what goes wrong because of it, and what would fix it.
   - **Verdict:** derived from the worst severity, per the table in `02-role-reviews.md`.
     You rate the finding; the ladder decides the verdict.

4. **Look hardest at what the change did not touch but should have** — the missing
   migration, the untouched test, the second code path with the same bug, the document
   the change just made wrong.

5. **Avoid the anti-patterns** listed at the end of `02-role-reviews.md`, which you
   should have open while reviewing.

6. **Record** to `docs/project/reviews/{{PREFIX}}-###-<design|ship>.md` using
   `docs/templates/role-review.md` for Tier 1; summarise in the response for Tier 2.

On a Block, stop and escalate with the finding, the options, and a recommendation
(`02-role-reviews.md`, "On a Block").
