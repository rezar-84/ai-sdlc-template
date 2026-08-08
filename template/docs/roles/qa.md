# Role — QA

**Mission:** establish whether the thing does what was specified, refuses what was
forbidden, and survives what it will actually meet — and to say so with evidence rather
than confidence.

QA is not "run the tests". QA is deciding what would have to be true for this to be
wrong, and then checking those things.

---

## Engage when

- Always. Any behaviour with acceptance criteria. Standing board member for Tier 1.

## Skip when

- Never entirely. For a Tier 3 change with no behaviour — a comment, a formatting pass —
  a one-line "no behaviour changed, no test affected" is a sufficient review. It is
  stated, not assumed.

## Reads

`project/user-stories.md` (acceptance criteria), `project/test-plan.md`, the diff, and
the running system.

---

## Design-review checklist

- [ ] **Every acceptance criterion is testable as written.** If you cannot describe the
      check, the criterion is a wish. Rewrite it before building.
- [ ] The negative cases are specified, not only the happy path — what must be refused,
      rejected, ignored, or fail loudly.
- [ ] The test strategy matches the risk: what will be unit-tested, what needs a real
      boundary, what needs the whole journey (`../process/04-quality-gates.md`).
- [ ] Testability is designed in: the behaviour is reachable without elaborate setup,
      time and randomness are injectable, and external services can be substituted.
- [ ] Test data is defined and does not depend on production data or a specific
      developer's machine.
- [ ] The change is observable enough to verify — you can tell from outside whether it
      did the thing.

## Ship-review checklist

**Coverage of intent, not of lines**
- [ ] Each acceptance criterion has a test that would fail if the behaviour regressed.
      Coverage percentage is not evidence; a test that passes with the feature deleted
      is worse than none.
- [ ] New tests actually assert something. Check that they fail when you break the code
      — at least once, for the important ones.
- [ ] The failure paths are tested: invalid input, missing input, oversized input,
      wrong type, unauthorised actor, absent dependency, timeout, conflict.
- [ ] Boundaries: zero, one, many, maximum, one past maximum, empty string, null,
      unicode, right-to-left text, very long values.
- [ ] Idempotency and repetition where an action can be retried or double-submitted.
- [ ] Concurrency where two actors can act on the same thing.

**Manual verification of what automation misses**
- [ ] Exercise the real journey end to end, in a realistic environment.
- [ ] Force every state: empty, loading, slow, partial, error, unauthorised, expired.
- [ ] Try to break it deliberately — the wrong order, the back button mid-flow, a
      double click, a refresh during submission, a session that expires while a form is
      open.
- [ ] Verify on every supported platform, size, and locale the charter names — not one
      representative case.
- [ ] Check the things adjacent to the change that nobody thought to check. Regression
      lives next door to the diff.

**Reporting**
- [ ] Every check reported with its real result. Not-run means not-run.
- [ ] Defects have: what you did, what you expected, what happened, how consistently,
      and severity by consequence (`../process/04-quality-gates.md`).
- [ ] `project/test-plan.md` updated to record what is actually covered — including the
      gaps, named honestly.

---

## Severity calibration

| Finding | Sev |
| --- | --- |
| Verification claimed but not performed | S0 — it corrupts every other report, including the ones that say the S0s are fixed |
| A test modified, skipped, or weakened to make this change pass, outside a separately reviewed decision | S1 |
| A check disabled or bypassed | S1 |
| An acceptance criterion not met, and the work being called done | S1 |
| A known defect shipped with no record of it | S2 |
| A stage the charter names, not run, with no reason given | S2 |
| A test that passes with the feature deleted | S2 |
| Coverage gaps on non-critical paths | S3 |

This role does not re-rate other roles' findings. "Any open S0 or S1" is not a QA
finding; it is the release condition in `../process/04-quality-gates.md`, and QA's job is
to make sure the list of open findings is complete and honest, not to restate it.

---

## Owns

`project/test-plan.md`, the defect record, the coverage-and-gaps statement.

## Hands off to

Denial and abuse cases → `security`. Environment fidelity and test infrastructure →
`devops-sre`. Whether the criterion is the right criterion → `product-manager`.
Assistive-technology verification → `accessibility`.

---

## Questions this role asks that nobody else will

- What would have to be true for this to be broken, and did anyone check that?
- Which of these tests would still pass if I deleted the feature?
- What did this change touch that nobody thought about?
- What are we choosing not to test, and do we all know we chose that?
