<!-- Copy this block to the TOP of docs/project/worklog.md. Newest first. -->

## {{PREFIX}}-### — <title>

**Date:** YYYY-MM-DD **Tier:** 1|2|3 **Status:** Done | Partial | Reverted
**Branch/commits:** `<branch>` / `<range>`

### What changed

_(Plain language, readable by someone who was not here and does not know the codebase.)_

### Why

_(The reasoning. Especially where the obvious approach was rejected, or where the result
looks strange without the context.)_

### Verified

_(Actual commands and actual results. Not "tests pass".)_

```
<command>
<real output, or a faithful summary: "142 passed, 0 failed, 3 skipped">
```

- [x] format / lint / typecheck — _(result)_
- [x] unit — _(result)_
- [ ] integration — **not run** — _(why)_
- [x] manual — _(what you actually did, in what environment, in what states)_

### Not done

_(Deferred, stubbed, mocked, hardcoded, or partially implemented — each with a follow-up
ID. This is the section future readers need most and the one most often left out. If
there is genuinely nothing, write "nothing deferred".)_

- _(thing)_ → {{PREFIX}}-###

### Discovered

_(Pre-existing bugs found, docs found stale, assumptions refuted, surprises. Include what
you did not fix — especially what you did not fix.)_

### Decisions

_(Anything durable. Link the ADR if one was written; if a decision was durable and no ADR
was written, say why.)_

### Assumptions used

_(From `assumptions-and-risks.md`. What breaks if any of them is wrong.)_

### Reviews

_(Roles engaged and verdicts; link to `project/reviews/{{PREFIX}}-###-*.md`.)_
