# 06 — Evidence and claims

The rule that matters most when an AI agent produces work product: **anything asserted
as fact must be traceable to a source, or marked as unverified.** Confident invention is
the characteristic failure mode of a language model, and it is far more damaging in a
product than a bug, because bugs get caught by tests and invented facts do not.

This applies to code, documentation, user-facing copy, review findings, and status
reports equally.

---

## Never invent

Do not produce, in any artifact:

- **Numbers** — metrics, percentages, benchmarks, user counts, revenue, performance
  figures, prices, dates, durations, headcount.
- **Credentials of an organisation** — certifications, awards, partnerships, memberships,
  compliance status, years in business, client lists.
- **People** — quotes, testimonials, names, titles, biographies, photographs.
- **References** — citations, standards numbers, URLs, RFCs, legal clauses, library APIs.
- **Outcomes** — case-study results, "customers saw a 40% improvement", success stories.
- **Status** — that a test passed, a check ran, a deploy succeeded, a file exists, a
  document says something. Verify each of these before stating it.

If the artifact needs one of these and you do not have it, write:

```
_(unverified — needs {{OWNER_ROLE}} confirmation: <exactly what is needed and from whom>)_
```

…and add a row to `project/assumptions-and-risks.md`. A visible gap is a working
product with a known hole. An invented value is a broken product that looks finished —
and it may be a legal problem, not just a quality one.

**Publishing an unverified claim about the business is S2** (see `04-quality-gates.md`).
Publishing an invented one is a defect the reviewing role must block.

---

## Sources of truth, in order

When two sources disagree, the higher one wins, and the disagreement gets logged as a
finding.

1. **The running system** — what the code actually does, what the database actually
   contains, what the command actually printed.
2. **The repository** — code, tests, migrations, configuration, git history.
3. **Human owner statements** — recorded with who said it and when.
4. **Project documents** — `project/*`, weighted by their `last-reviewed` date.
5. **External documentation** — cited with a link and an access date.
6. **Your prior belief** — the weakest source. Treat model knowledge about a library's
   API, a standard, or a price as a hypothesis to check, not a fact to state.

Corollary: **do not trust a document over the code**. If `architecture.md` says the
system does X and the code does Y, the code is what the system does; the document is a
defect.

---

## Verification vocabulary

Use these words precisely in every report and review. Ambiguity here is how false
confidence propagates.

| Say | When |
| --- | --- |
| **Verified** | You ran it or read it directly, in this session, and observed the result. |
| **Reported** | A tool, log, or person said so and you are relaying it. Name the source. |
| **Assumed** | You are proceeding on it and it is written in the assumptions register. |
| **Unknown** | You do not know. This is a complete and acceptable answer. |
| **Not run** | The check exists but you did not execute it. Say why. |

Never write "should work", "presumably passes", or "I've made sure that…" for something
you did not observe. If you did not run the tests, the sentence is "tests not run".

---

## Provenance for content and data

When content, data, or assets are migrated, imported, or generated, record for each
item: origin (URL, file, system), date obtained, transformation applied, who reviewed
it, and its disposition (keep / rewrite / drop / needs-approval).

- **Source material is evidence, not product.** Do not edit archived originals,
  snapshots, exports, or checksums. Derive from them; keep the originals byte-identical.
- **Rights before reuse.** Logos, photographs, customer names, quotes, case-study
  details, fonts, and third-party code all require permission or a compatible licence.
  Absence of a licence is not permission.
- **Machine-generated content is a draft.** Text produced by an agent in a language,
  domain, or legal context requiring expertise (marketing claims, legal terms, medical
  or financial guidance, any non-native language) is labelled as needing human review
  and must not be treated as final. Record the label in the worklog so a later reader
  does not mistake it for approved copy.
- **Attribution and licences** for copied code or content are preserved, always.

---

## Assumptions register

`project/assumptions-and-risks.md` is the pressure valve that makes the no-fabrication
rule workable. It lets work proceed without inventing.

Each row: the assumption, why it was needed, what breaks if it is wrong, who can
confirm it, and its status.

Rules:
- An assumption used in shipped work is **stated in the worklog entry** for that work,
  not only in the register.
- Assumptions are reviewed at every gate. A stale assumption nobody has confirmed is a
  risk that has been quietly accepted.
- When an assumption is confirmed or refuted, close the row and note what changed as a
  result. A refuted assumption almost always means something already built is wrong —
  go and check.

---

## When you are uncertain

State the uncertainty and its size, then act. "I could not find where the rate limit is
configured; I searched X, Y, Z. Either it is not implemented or it lives outside this
repository" is a useful contribution. "Rate limiting is handled by the gateway" — when
you did not check — is a fabrication with a plausible tone, and it is worse than
silence.
