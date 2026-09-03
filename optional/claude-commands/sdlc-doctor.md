---
description: Check this project's SDLC documents for gaps, staleness, and drift
argument-hint: "[optional: charter | roles | staleness | traceability | profile]"
---

Audit the installed kit in this repository and report what is wrong with it. Scoped to:

$ARGUMENTS

(If no argument is given, run every section below.)

This command **reports**; it does not fix. Findings become backlog items, and the ones
that need a human decision — an unticked role, a missing approver — stay with the human.

## 1. Substitution

```sh
grep -rn '[{][{]' {{DOCS_DIR}} AGENTS.md .claude 2>/dev/null
```

(The character class is deliberate — a literal double brace in this file would itself be
substituted at install time.)

Any hit is a broken install: an unsubstituted work-item prefix leaves a literal path in
the docs an agent follows. Report every occurrence with its file.

## 2. Charter completeness

Read `{{DOCS_DIR}}/project/charter.md`. A blank cell is **Unknown**, not "not applicable"
(`{{DOCS_DIR}}/process/06-evidence-and-claims.md`), and an agent that guesses a check
command because the charter was blank produces confidently false "verified" claims.
Report, in this order of severity:

- Blank rows in **Commands** — each one is a stage that cannot be run or reported.
  Distinguish blank (nobody filled it in) from the word "absent" (deliberate).
- Blank **approvers**, **default branch**, or **staleness window**.
- Blank cells in **Model & data** or **Budgets** where the corresponding role is ticked.
- **Unticked roles with an empty reason column.** A blank reason means nobody decided;
  it does not mean the role does not apply. List each one as a question for a human.
- Ticked roles whose owned artifacts do not exist (see `{{DOCS_DIR}}/README.md` → the
  "Create when" column, which is the only statement of which artifacts this project is
  supposed to have).

## 3. Staleness

For every file in `{{DOCS_DIR}}/project/`, read the frontmatter `last-reviewed` and
compare against today and the charter's staleness window. Report anything older, anything
with a missing or malformed date, and anything marked `status: stale` that has no backlog
item to fix it. ADRs are exempt: they are dated records and are superseded, not refreshed.

## 4. Traceability

Per `{{DOCS_DIR}}/process/07-traceability.md`:

- Backlog rows in a done state with no worklog entry carrying that ID.
- Worklog entries whose ID is not in the backlog.
- Items marked `Parked` with no stated blocker or owner.
- Branches or recent commits referencing an ID that exists in neither.

## 5. Worklog size

Report the line count of `{{DOCS_DIR}}/project/worklog.md`. Past the rotation threshold in
`07-traceability.md`, recommend rotating the closed entries into
`{{DOCS_DIR}}/project/worklog-archive/`. An unbounded worklog quietly becomes the largest
file every future agent reads.

## 6. Profile drift

If `.ai-sdlc/profile.json` exists, compare its `commands`, `roles`, and `docs_dir`
against the charter. **The charter is the source of truth**; report any difference as
drift to be corrected in the profile, never the other way round. Report a `kit_version`
older than `.ai-sdlc/manifest.json` as an incomplete upgrade.

## Output

One table: area · finding · severity per `{{DOCS_DIR}}/process/04-quality-gates.md` ·
who can fix it. Then the two or three things worth doing first. If a section is clean,
say so explicitly — "no findings" is a result, and silence is not.
