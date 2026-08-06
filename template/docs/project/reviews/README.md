# Review records

One file per review: `{{PREFIX}}-###-design.md` or `{{PREFIX}}-###-ship.md`, from
`../../templates/role-review.md`.

## What lands here

| Tier | Design review | Ship review |
| --- | --- | --- |
| 1 | Required — file | Required — file |
| 2 | Required — may be summarised in the response and worklog | Required — may be summarised |
| 3 | Usually none | Usually none |

Tier 1 reviews **must** be files: they are the audit trail behind the two human
approvals.

## What makes a record worth keeping

Each role block states **what was checked**, not only what was found. A review that
found nothing is valuable if it says where it looked; it is worthless if it says
"looks good".

Findings carry a location, a consequence, and a fix. Verdicts are *Pass* / *Pass with
conditions* / *Block*.

**An agent may not waive its own blocker.** A waiver needs a named human, a written
reason, and a tracked follow-up — all three recorded in the file.

Full rules: `../../process/02-role-reviews.md`.

## Index

| Work item | Stage | Date | Outcome |
| --- | --- | --- | --- |
| | | | |
