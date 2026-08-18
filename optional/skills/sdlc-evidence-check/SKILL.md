---
name: sdlc-evidence-check
description: Check a status claim before it is written — "done", "tests pass", "verified", "it works", "fixed", "should be fine". Use before reporting completion or progress, and whenever about to describe the state of checks, so every claim comes out as Verified, Not run, Absent, or Unknown with the real command output behind it.
---

# Evidence check — before you claim anything

`{{DOCS_DIR}}/process/06-evidence-and-claims.md` is the authority. This skill is the
pre-flight for the moment you are about to type a claim.

## The only four words

| Word | Means | Requires |
| --- | --- | --- |
| **Verified** | you ran it and read the output | the command, and its real result |
| **Not run** | the check exists, you did not run it | the reason |
| **Absent** | the charter has no command for this stage | naming it as a gap |
| **Unknown** | you cannot establish it from here | who or what could |

No synonyms. "Should work", "looks right", "mostly passing", and "tests are green" (from
memory) are none of these.

## Procedure

1. List every claim you are about to make. Each one is a sentence someone will act on.
2. For each, find the evidence: the command you ran, the output you read, the file you
   opened, the page you exercised. No evidence, no claim — downgrade it to *Not run* or
   *Unknown* and say so plainly.
3. Take commands from the charter's **Commands** table verbatim
   (`{{DOCS_DIR}}/project/charter.md`). Never infer one from the ecosystem: a guessed
   command that happens to exit zero produces a confidently false verification.
4. Paste or summarise real results — counts, failures, durations. A failing suite is
   reported as failing, with its output, in the same message as everything else.
5. Facts you cannot source get the marker `_(unverified — needs confirmation: <what, from
   whom>)_` and a line in `{{DOCS_DIR}}/project/assumptions-and-risks.md`. Never invent a
   metric, date, benchmark, quote, certification, or citation to fill a gap.

## Behaviour, not only the build

For anything user-facing, "it builds" is not "it works". Exercise the real path in its real
states — empty, loading, error, unauthorised, oversized input — and say which states you
actually saw. For anything with a permission model, exercise the denial case explicitly.

## Output

A stage → result table, then one plain paragraph: what is verified, what is not, and what
you could not check from here. No hedging, no overstating.
