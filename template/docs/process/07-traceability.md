# 07 — Traceability and logging

Any change should be answerable, months later, by: *why does this exist, who decided it,
what was verified, and what was left undone?* Four records carry that, and each has one
job. Keeping their jobs separate is what stops any of them becoming unreadable.

---

## Identifiers

```
{{PREFIX}}-###
```

The prefix is declared in `project/charter.md` (2–4 uppercase letters). Numbers are
sequential, never reused, never renumbered. Once an ID appears anywhere — branch,
commit, review, worklog — it is permanent, even if the work is dropped.

Every branch, commit, review file, and worklog entry carries its ID. That single string
is the join key across all four records.

Work that ships without an ID gets one **retroactively** — logged with a note that it
was retroactive. An untracked change is not erased by pretending it did not happen.

---

## The four records

| Record | File | Contains | Shape | Grows by |
| --- | --- | --- | --- | --- |
| **Backlog** | `project/backlog.md` | What is planned, in flight, done. | Terse table. One line per item. | New rows, status edits |
| **Worklog** | `project/worklog.md` | What actually happened and why. | Prose entries, newest first. | Append only |
| **Decisions** | `project/adr/NNNN-*.md` | Why the durable choices were made. | One file per decision. | New files; existing ones superseded, not edited |
| **Reviews** | `project/reviews/{{PREFIX}}-###-<stage>.md` | What each role checked and found. | One file per review. | New files |

### The separation rule

**The backlog table stays terse. Narrative goes in the worklog.**

This is the single most important formatting rule in the kit, and the one most often
broken. The temptation, when finishing a rich piece of work, is to write the story into
the backlog's description cell. Do that a dozen times and the table has multi-paragraph
cells, the status column is unscannable, and the document that was supposed to answer
"what is left?" in five seconds cannot answer it at all.

A backlog row is: **ID · one-line description · owner role · dependencies · tier ·
status.** Anything more goes in the worklog entry, which the row implicitly points to
via its ID.

---

## What a good worklog entry contains

Use `templates/worklog-entry.md`. Non-negotiable sections:

- **What changed** — plain language, readable by someone who was not here.
- **Why** — the reasoning, especially where the obvious approach was rejected.
- **Verified** — the actual commands and their actual results. Not "tests pass" but
  which suite, how many, against what.
- **Not done** — deferred, stubbed, mocked, or hardcoded, each with the follow-up ID.
  This section is the one future readers need most and the one most often omitted.
- **Discovered** — pre-existing bugs found, docs found stale, assumptions refuted. Even
  if you did not fix them. Especially if you did not fix them.
- **Assumptions used** — anything from the register this work depends on.

An entry that says only what changed is a `git log` with extra steps. The value is in
*why*, *what was verified*, and *what is still wrong*.

---

## Staleness

Every artifact in `project/` carries `last-reviewed: YYYY-MM-DD`.

- When you change something a document describes, you update the document and the date
  in the same change — or mark it `status: stale` and open a backlog item. Both are
  acceptable; leaving it confidently wrong is not.
- An agent reading a document older than the charter's staleness threshold treats it as
  a **hypothesis**, verifies the parts it depends on against the code, and reports the
  drift it finds.
- Document drift is a real defect and belongs in review findings, usually S3, or S2 when
  the document would actively mislead someone into a mistake.

---

## Traceability chain

For any line of shipped code, this chain should be walkable in both directions:

```
code  ←→  commit  ←→  {{PREFIX}}-###  ←→  backlog row
                            │
                            ├─→ plan (what we intended)
                            ├─→ review files (what each role checked)
                            ├─→ ADR (why the durable choice)
                            └─→ worklog entry (what happened, verified, left open)
```

If any link is missing, that is a finding. The most common break is a change that was
made "quickly" without an ID — from which point nothing downstream can be found.

---

## Housekeeping

- **Do not delete backlog rows.** Move them to `Dropped` with a reason. Deleting
  guarantees the idea will be proposed again, discussed again, and rejected again.
- **Do not rewrite worklog history.** If an entry was wrong, append a correction that
  references it. The record of a mistaken belief is part of the record.
- **Archive, do not truncate.** When the worklog gets long, move older entries to
  `project/worklog-archive/YYYY.md` and leave a pointer. Same for completed backlog
  items: a `Done` archive section keeps the active table short.
- **Review the registers at every gate.** Backlog, assumptions, and risks are read and
  reconciled at each gate transition, not only when someone remembers.
