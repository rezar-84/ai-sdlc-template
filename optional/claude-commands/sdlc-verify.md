---
description: Run the project's full check sequence and report real results
---

Run the VERIFY step of the loop per `docs/process/04-quality-gates.md`.

1. **Read the commands** from `docs/project/charter.md` → Commands. Use them verbatim.
   Do not invent a command or infer one from the ecosystem — a guessed command that
   happens to exit zero produces a confidently false verification.

2. **Run each stage in order:** format → lint → typecheck → unit → integration → build →
   dependency/secret scan → accessibility → end-to-end.

3. **Report each stage honestly:**
   - **Passed** — with the real summary (counts, duration).
   - **Failed** — with the actual output, faithfully. Never describe a failing suite as
     "mostly passing".
   - **Not run** — and why.
   - **Absent** — this project has no such stage. Note it; an absent stage is a QA
     finding with a reason, not a neutral fact.

4. **Do not fix anything to make a check pass** in this command, and never disable,
   skip, or loosen a check. If a check is wrong, that is a separate tracked item with its
   own justification.

5. **Then verify behaviour, not only the build.** For anything user-facing, exercise the
   actual path in its real states: empty, loading, error, unauthorised, oversized input —
   and every supported locale, size, and permission level the charter names. For anything
   with a permission model, test the denial cases explicitly.

6. **Summarise** as a table of stage → result, then state plainly what is verified, what
   is not, and what you could not check from here.

$ARGUMENTS
