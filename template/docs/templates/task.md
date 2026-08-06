<!--
A backlog row is TERSE. This file documents what belongs in each column of
docs/project/backlog.md. Narrative belongs in the worklog entry, never in the table —
see ../process/07-traceability.md.
-->

# Backlog row format

```
| ID | Task | Tier | Owner role | Depends on | Status |
```

| Column | Rule |
| --- | --- |
| **ID** | `{{PREFIX}}-###`. Sequential, never reused, never renumbered. |
| **Task** | **One line.** What will be true afterwards. If it needs two sentences, it is two items. |
| **Tier** | 1 / 2 / 3 per `AGENTS.md` §3. Assigned at FRAME, before planning. |
| **Owner role** | The role accountable, from the charter's active roster. |
| **Depends on** | Other IDs, or a named human input ("owner: brand assets"). Blank if none. |
| **Status** | `Ready` · `Blocked` · `In progress` · `In review` · `Done` · `Deferred` · `Dropped` |

## Status meanings

- **Ready** — passes the Definition of Ready (`../process/03-ready-and-done.md`). Anyone
  could pick it up.
- **Blocked** — cannot start. The blocker is named in the Depends-on column, and it is a
  real, identified thing, not "needs more thought".
- **In progress** — actively being built. One or two at a time, not fifteen.
- **In review** — built, awaiting role review or human approval.
- **Done** — meets the Definition of Done, worklog entry written. Nothing is `Done`
  without a worklog entry.
- **Deferred** — valid, not now. Say when it becomes relevant again.
- **Dropped** — will not be done. One-line reason. **Never delete the row** — deleting
  guarantees the idea gets proposed, discussed, and rejected again.

## Writing a good one-line task

| Poor | Better |
| --- | --- |
| Improve the dashboard | Show last successful sync time per report on the dashboard |
| Fix the auth bug | Deny report access when a membership has been revoked |
| SEO work | Add reciprocal language alternates to all published pages |
| Refactor | Extract the entitlement check out of the route handler into the service layer |

The test: could someone else tell whether it is finished, without asking you?
