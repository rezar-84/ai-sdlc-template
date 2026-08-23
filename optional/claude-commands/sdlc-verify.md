---
description: Run the project's full check sequence and report real results
argument-hint: "[optional: a stage, path, or work item ID to scope the run]"
---

Run the VERIFY step of the loop per `{{DOCS_DIR}}/process/04-quality-gates.md`, scoped to:

$ARGUMENTS

(If no argument is given, run the full sequence against the current working tree.)

1. **Read the commands** from `{{DOCS_DIR}}/project/charter.md` → Commands. Use them verbatim.
   Do not invent a command or infer one from the ecosystem — a guessed command that
   happens to exit zero produces a confidently false verification.

2. **Run each stage in order**, per the table in `04-quality-gates.md`: format, lint,
   typecheck, unit, integration, contract, build, dependency/secret scan, accessibility,
   end-to-end.

3. **Report each stage** in the vocabulary of `{{DOCS_DIR}}/process/06-evidence-and-claims.md`,
   with no synonyms:
   - **Verified**, and whether it passed or failed, with the real summary (counts,
     duration). Never describe a failing suite as "mostly passing" — paste the output.
   - **Not run** — the stage exists, you did not execute it. Say why.
   - **Absent** — the charter has no command for this stage. An absent stage is a QA
     finding with a reason, not a neutral fact.

4. **Do not fix anything to make a check pass** in this command, and never disable, skip,
   or loosen one (`04-quality-gates.md`).

5. **Then verify behaviour, not only the build.** For anything user-facing, exercise the
   actual path in its real states: empty, loading, error, unauthorised, oversized input —
   and every supported locale, size, and permission level the charter names. For anything
   with a permission model, test the denial cases explicitly.

6. **Summarise** as a table of stage → result, then state plainly what is verified, what
   is not, and what you could not check from here.
