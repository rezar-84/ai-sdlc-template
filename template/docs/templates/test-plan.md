---
status: draft
owner: qa
last-reviewed: YYYY-MM-DD
---

# Test plan — {{PROJECT_NAME}}

> Records what is actually covered, **including the gaps**. A test plan that lists only
> strengths is a marketing document.

## Commands

| Stage | Command | Runs in CI | Notes |
| --- | --- | --- | --- |
| Format | | | |
| Lint | | | |
| Typecheck | | | |
| Unit | | | |
| Integration | | | |
| Build | | | |
| Dependency/secret scan | | | |
| Accessibility | | | |
| End-to-end | | | |

Mark stages this project does not have as **absent**, not blank — an absent stage is a
QA finding to be justified, not a neutral fact.

## Environments

| Environment | Purpose | Data | Who can deploy |
| --- | --- | --- | --- |
| | | _(synthetic / anonymised / production copy — and if production data, why that is permitted)_ | |

## What is covered

### Unit
_(Which logic. Which edge cases matter and are covered.)_

### Integration
_(Which seams against which real boundaries. What is substituted, and what that
substitution hides.)_

### Contract
_(Which interfaces are locked, and against whose expectations.)_

### End-to-end
_(The two to five journeys that mean the product is down if broken.)_

### Manual / human
_(What automation cannot judge: language quality by a qualified speaker, screen-reader
experience, visual judgement, acceptance by the requester. Who does it and when.)_

## High-risk matrices

Required where the project has these surfaces (`../process/04-quality-gates.md`):

**Authorisation** — for every protected resource:

| Case | Expected |
| --- | --- |
| Permitted actor, permitted action | Allowed |
| Permitted actor, unpermitted action | Denied |
| Another owner's valid identifier | Denied, **no existence or metadata leak** |
| Revoked or expired access | Denied |
| Tampered identifier | Denied |
| Stale session | Re-authentication |

**Input** — oversized · malformed · wrong type · injection-shaped · unicode & RTL ·
empty · boundary values.

**Data** — migration forward and backward · concurrent writes · idempotency of
retryables · deletion actually deletes.

## Budgets

| Metric | Budget | Current | Measured by |
| --- | --- | --- | --- |
| | | | |

Regression against a budget is S2 by default. An unset budget is unmeasured, not absent.

## Known gaps

_(The honest list. Each with a backlog ID or an explicit acceptance. This section is why
the document is worth reading.)_

| Gap | Risk | Accepted by / tracked as |
| --- | --- | --- |
| | | |

## Flaky tests

| Test | Since | Symptom | Tracked as | Deadline |
| --- | --- | --- | --- | --- |

A flaky test is a defect with a deadline, not a fact of life.
