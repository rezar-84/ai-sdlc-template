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
> Two placeholders are used across the installed docs — the project name and the work
> item prefix — and `install.sh` substitutes both. If you installed by hand, replace them
> everywhere: grepping `docs/`, `AGENTS.md`, and `.claude/` for a doubled curly brace
> must return nothing before you rely on any of it.

## Identity

| | |
| --- | --- |
| **Project** | {{PROJECT_NAME}} |
| **What it is** | _(one sentence a stranger would understand)_ |
| **Work item prefix** | `{{PREFIX}}` _(2–4 uppercase letters, e.g. `ACME`)_ |
| **Repository** | _(url or path)_ |
| **Accountable human** | _(name — the person who approves Tier 1 work)_ |

## Stack

**Authoritative.** Every process document refers to these indirectly, so that the process
itself stays portable, and `architecture.md` links here rather than restating them — one
table, so it cannot drift.

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

The reasoning lives in the ADRs; the shape lives in `architecture.md`. This table is for
lookup.

## Constraints

What the design has to live within. The architect role checks every proposal against
this table, so an empty row reads as "unconstrained" — write "none known" if that is
genuinely true.

| | |
| --- | --- |
| **Team / who maintains this** | _(size, skills, whether anyone is on call)_ |
| **Operational capacity** | _(what the team can realistically run and monitor)_ |
| **Budget ceiling** | _(hosting, licences, third-party services)_ |
| **Latency / throughput** | _(what the system must meet, or "not specified")_ |
| **Existing platform commitments** | _(what cannot be replaced, and why)_ |
| **Timeline** | _(fixed dates and what drives them)_ |

## Commands

**Authoritative.** Exact commands, runnable from the repository root. An agent uses these
verbatim; a wrong entry here produces confidently wrong "verified" claims. `test-plan.md`
links here rather than repeating them.

| Stage | Command |
| --- | --- |
| Install | |
| Run locally | |
| `checks.format` | |
| `checks.lint` | |
| `checks.typecheck` | |
| `checks.unit` | |
| `checks.integration` | |
| `checks.contract` | _(if anything consumes your interface, or you consume someone else's)_ |
| `checks.build` | |
| `checks.scan` | |
| `checks.a11y` | |
| `checks.e2e` | |

Write **absent** in the Command cell for a stage this project does not have, with the
reason. A blank cell is not "absent" — it is "nobody has filled this in", and an agent
must treat it as *Unknown* and say so rather than proceeding as though the stage were
absent (`../process/06-evidence-and-claims.md`).

## Environments

**Authoritative.** `test-plan.md` and `release-runbook.md` link here rather than
repeating this table.

| Environment | Purpose | Deployed from | Who may deploy |
| --- | --- | --- | --- |
| | | | |

| | |
| --- | --- |
| **Default branch** | _(name)_ |
| **Direct commits to it** | _(allowed / not allowed — `../process/05-change-control.md` forbids them unless this says otherwise)_ |

### Managed platform

**Authoritative.** Fill this in if an AI app builder or cloud IDE — e.g. Lovable,
Replit, Bolt, Firebase Studio — also edits, syncs, generates files in, or deploys this
repository. Write "none" if this is a plain git repository. Where this table conflicts
with a process document, this table wins (`../process/05-change-control.md`, "Managed
platforms").

| | |
| --- | --- |
| **Platform** | _(e.g. Lovable / Replit / none)_ |
| **Sync model** | _(e.g. "two-way GitHub sync on the default branch; the platform's agent also commits" — or "git only")_ |
| **Platform-owned files** | _(files the platform generates or requires and an agent must never hand-edit, move, or delete — e.g. `.replit`, `replit.nix`, platform config directories, lockfiles it regenerates)_ |
| **Platform instruction file** | _(where the platform's own agent reads its instructions — e.g. `replit.md`, Lovable project knowledge — and whether it points at `AGENTS.md` so the two contracts cannot diverge)_ |
| **Deploys** | _(e.g. "published from the platform UI" — if so, the release runbook documents the platform's publish and rollback affordances, not a deploy command)_ |

## Active roles

**Every unticked row below is unreviewed by default.** The four at the top are always on.
For the rest, the "Active if" column says what makes the role apply — tick it if that is
true of this project, and if you leave it unticked, say why in the last column. A blank
reason on an unticked row means nobody decided; it does not mean the role does not apply.

| Role | Active | Active if | Reason if inactive |
| --- | --- | --- | --- |
| product-manager | ☑ | always | |
| architect | ☑ | always | |
| security | ☑ | always | |
| qa | ☑ | always | |
| ux-designer | ☐ | there is any interface, including a CLI | |
| brand-designer | ☐ | there is a visual interface | |
| copywriter | ☐ | there is any user-visible text | |
| accessibility | ☐ | there is any interface | |
| seo | ☐ | content is publicly discoverable | |
| cro-analyst | ☐ | there is a conversion or activation goal | |
| devops-sre | ☐ | it deploys or runs somewhere | |
| privacy-legal | ☐ | personal data, tracking, or public claims exist | |
| localisation | ☐ | it ships in more than one language | |

**Project-specific role checks** — additions to a role's playbook for this project only.
Put them here, never by editing files in `../roles/`, so the kit stays upgradeable and
`--upgrade` cannot overwrite them.

| Role | Additional check |
| --- | --- |
| | |

**Project-specific roles** — a perspective this project needs that the thirteen do not
cover (data engineer, firmware, ML evaluation, support, community). Define it
here, in the shape of a role playbook: mission, engage when, reads, what it checks.

| Role | Mission | Engage when | Checks |
| --- | --- | --- | --- |
| | | | |

## Risk defaults

| | |
| --- | --- |
| **Always Tier 1 here** | _(the surfaces that are high-risk in this project specifically)_ |
| **Never Tier 1 here** | _(surfaces from the `AGENTS.md` Tier 1 list that genuinely do not apply — e.g. "no PII: this project holds no personal data, see Data categories held". Without this, "when in doubt, tier up" makes almost everything Tier 1.)_ |
| **Human approval required for** | _(list — mirrors the "Human approval required for" line in `AGENTS.md`, "Project overrides")_ |
| **Approvers** | _(names for Tier 1's two approvals)_ |
| **Staleness threshold** | _(e.g. 90 days — after this, a `project/` doc is treated as a hypothesis)_ |

## Standards & targets

| | |
| --- | --- |
| **Accessibility target** | _(e.g. WCAG 2.2 AA, or "not applicable — no interface")_ |
| **Assistive technologies supported** | _(the screen reader / browser pairs actually tested against, or "none tested" — which is a gap, not a neutral state)_ |
| **Supported platforms / browsers / sizes** | |
| **Performance budgets** | _(or "none set" — which is a known gap, not a neutral state)_ |
| **Primary outcome** | _(the one user action success is measured by: sign-up, activation, task completion, purchase… `cro-analyst` optimises for exactly this)_ |
| **Jurisdictions / regimes** | _(for `privacy-legal`)_ |
| **Data categories held** | _(or "none" — and say how you know)_ |

### Languages & localisation

**Authoritative.** `../process/08-content-and-translation.md` and the `localisation` role
both read this table. Writing direction is a property of the languages listed, not a
separate opinion — a project that ships `fa`, `ar`, `he` or `ur` is bidirectional whether
or not anyone planned for it.

| | |
| --- | --- |
| **Ships in** | _(every language users can see, e.g. `en, fa` — or "one language")_ |
| **Source language** | _(the one strings are authored in; every other language is a translation of it)_ |
| **Writing directions** | _(derived from the languages above: left-to-right, right-to-left, or both)_ |
| **Message catalogue** | _(where translatable strings live, e.g. `locales/` — or "none: strings are in the code", which is a finding)_ |
| **Translation workflow** | _(who translates, whether machine translation is used, and the named human who reviews it before users see it)_ |
| **Terminology / glossary** | _(where the agreed term for a product concept in each language is decided, and who decides it)_ |

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
