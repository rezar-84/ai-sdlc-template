---
status: draft
owner: _(named human accountable for this project)_
last-reviewed: YYYY-MM-DD
---

# Project charter — {{PROJECT_NAME}}

> **Fill this in first.** Nothing else in `docs/` is reliable until this is complete. It
> is the only file that tells an agent what this project is, what it is built with, and
> which parts of the process apply.
>
> Placeholders used across the installed docs: `{{PROJECT_NAME}}`, `{{PREFIX}}`,
> `{{OWNER_ROLE}}`. Replace them everywhere after filling this in.

## Identity

| | |
| --- | --- |
| **Project** | {{PROJECT_NAME}} |
| **What it is** | _(one sentence a stranger would understand)_ |
| **Work item prefix** | `{{PREFIX}}` _(2–4 uppercase letters, e.g. `ACME`)_ |
| **Repository** | _(url or path)_ |
| **Accountable human** | _(name — the person who approves Tier 1 work)_ |
| **Current gate** | G_ _(see `../process/01-lifecycle-gates.md`)_ |

## Stack

The authoritative declaration. Every process document refers to these indirectly, so
that the process itself stays portable.

| Concern | This project uses |
| --- | --- |
| Language / runtime | |
| Package manager | |
| Framework(s) | |
| Data store | |
| Auth | |
| Hosting | |
| CI | |
| Test tooling | |

Detail and the reasoning live in `architecture.md` and the ADRs. This table is for
lookup.

## Commands

Exact commands, runnable from the repository root. An agent uses these verbatim; a wrong
entry here produces confidently wrong "verified" claims.

| Stage | Command |
| --- | --- |
| Install | |
| Run locally | |
| `checks.format` | |
| `checks.lint` | |
| `checks.typecheck` | |
| `checks.unit` | |
| `checks.integration` | |
| `checks.build` | |
| `checks.scan` | |
| `checks.a11y` | |
| `checks.e2e` | |

Mark absent stages **absent** rather than leaving them blank — a blank reads as an
oversight, an explicit "absent" is a QA finding with a reason.

## Environments

| Environment | Purpose | Deployed from | Who may deploy |
| --- | --- | --- | --- |
| | | | |

## Active roles

Tick the roles that apply. Deactivating a role is a decision — record the reason.

| Role | Active | Reason if inactive |
| --- | --- | --- |
| product-manager | ☑ | always |
| architect | ☑ | always |
| security | ☑ | always |
| qa | ☑ | always |
| ux-designer | ☐ | |
| brand-designer | ☐ | |
| copywriter | ☐ | |
| accessibility | ☐ | |
| seo | ☐ | |
| cro-analyst | ☐ | |
| devops-sre | ☐ | |
| privacy-legal | ☐ | |

**Project-specific role checks** — additions to a role's playbook for this project only.
Put them here, never by editing files in `../roles/`, so the kit stays upgradeable.

| Role | Additional check |
| --- | --- |
| | |

## Risk defaults

| | |
| --- | --- |
| **Always Tier 1 here** | _(the surfaces that are high-risk in this project specifically)_ |
| **Human approval required for** | _(list — mirrors `AGENTS.md` §8)_ |
| **Approvers** | _(names for Tier 1's two approvals)_ |
| **Staleness threshold** | _(e.g. 90 days — after this, a `project/` doc is treated as a hypothesis)_ |

## Standards & targets

| | |
| --- | --- |
| **Accessibility target** | _(e.g. WCAG 2.2 AA, or "not applicable — no interface")_ |
| **Supported platforms / browsers / sizes** | |
| **Languages & writing directions** | |
| **Performance budgets** | _(or "none set" — which is a known gap, not a neutral state)_ |
| **Jurisdictions / regimes** | _(for `privacy-legal`)_ |
| **Data categories held** | _(or "none" — and say how you know)_ |

## Sources of truth

Where the authoritative version of each thing lives, so nobody guesses.

| Thing | Where |
| --- | --- |
| Brand guidelines | |
| Design tokens | |
| Analytics / search data | |
| Content source | |
| Secrets | |
| Issue tracker _(if not `backlog.md`)_ | |

## Artifacts in use

Which templates have been instantiated. Untick means "not needed yet" — say why if it is
a deliberate omission.

☐ product-brief ☐ discovery-audit ☐ user-stories ☐ architecture ☐ data-model-api
☐ design-system ☐ content-seo-plan ☐ measurement-plan ☐ security-privacy
☐ threat-model ☐ test-plan ☐ release-runbook
