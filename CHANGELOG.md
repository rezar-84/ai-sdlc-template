# Changelog

This project follows semantic versioning. User-visible changes are recorded here.

## Unreleased

- Nothing yet.

## 3.2.0 — 2026-09-03

The question this release answers is whether the kit needs a GUI. Researched rather than
guessed, the answer was: one small read-only page, and distribution — not a web product.
Claude Code Remote Control already drives local sessions from `claude.ai/code` and mobile,
and the independent agent-orchestration GUIs have not found a business model (Bloop, the
company behind vibe-kanban, shut down in April 2026 saying exactly that).

### Added

- **`docs/dashboard.html`** — a read-only status page over the installed state. Open it
  from the filesystem; no server, no dependency, no build. Shows open work by status and
  tier, artifacts stale or undated, roles unticked with nobody's reason, check stages with
  no command, budgets and baselines, and whether anything points at `AGENTS.md`.
  The page is kit-managed and upgradeable; its state lives in `docs/dashboard-state.js`,
  a project record derived from the files and never from the wizard's answers. It states
  its own generation date and declares itself untrustworthy past the charter's staleness
  window. `validate.py` fails if it invents a backlog status the standard lacks, or if a
  form or `contenteditable` appears in it.
- **`/sdlc-doctor` refreshes the page's state** and is told not to write a value it did
  not read from a file.
- **Claude Code plugin packaging** (`.claude-plugin/`) — `/plugin marketplace add
  rezar-84/ai-sdlc-template`. Commands only: skills are model-invoked and cost context in
  every turn whether they fire or not, so choosing them per project stays with the
  installer, which is the whole point of the fact model.
- **README positioning** for Spec Kit, Kiro and Tessl (complementary — they specify a
  feature, this governs a change), for the AI app builders (a place to install this, not a
  thing to replace), and for why there is no web UI.

### Not built, deliberately

A web installer, and a Lovable-style surface driving local agents. Both are argued in the
README and the decision record; the second belongs in a separate repository that consumes
this kit, if it is ever built at all.

## 3.1.0 — 2026-09-03

Profiling 3.0.0 found three defects and one cost regression. This release fixes them and
makes the kit work outside Claude Code.

### Fixed

- **The kit could install itself into permanent silence.** The `CLAUDE.md` pointer was
  written only when no `CLAUDE.md` existed — which is almost never in a real project — so
  `AGENTS.md` was never auto-loaded and nothing was printed about it. An existing
  instruction file is now appended to (never overwritten), re-running adds no second
  pointer, and an install that wires nothing warns loudly and prints the line to add.
- **A compact install could never be upgraded**, because `find_docs()` used a numbered
  process document as the marker for an installed kit.

### Added

- **`docs/CARD.md`** — the operating card. 2,252 tokens covering tiers, the seven
  evidence words, the check sequence, the severity ladder, verdicts and traceability. It
  replaces reading `02`, `04`, `06` and `07` for ordinary work; those become named
  escalation, and the full document wins wherever they disagree. `validate.py` reads the
  rules the card actually asserts and fails if it invents or drops one.
- **`--harness <list>`** — pointer files for Claude Code, Gemini CLI, Amp, Copilot,
  Cursor, Windsurf, Cline and Aider. Codex, Jules, Zed, Factory and opencode read
  `AGENTS.md` directly and are told so. Pointers reference; they never copy.
- **`--profile compact`** — installs the card, roles, templates and project records but
  omits the numbered `process/` documents. For a small context window or a weaker model.
- **`--hooks`** — two deterministic Claude Code guards: a commit with no work item ID is
  denied, and an edit to a path in `.ai-sdlc/protected.txt` is denied. Merged into an
  existing `settings.json` without disturbing it.
- **`process/10-multi-agent.md`** — claiming, single-writer files, review fan-out, why a
  subagent's result is *Reported* and not *Verified*, and handoff. Conditional.
- Charter: **Agent environment** and **Concurrency** tables. `/sdlc-doctor` checks that
  something points at `AGENTS.md` and rates its absence the highest finding it can make.

### Changed

- **The always-list costs 11,624 tokens instead of 18,222** — a 36% cut, and 26% below
  where 3.0.0 started. A Tier 2 change with two roles: 22.7k full, 17.3k compact.
- `AGENTS.md`'s per-tier figures are measured, and CI fails if they drift.

### Upgrading

`--upgrade` delivers `CARD.md` and `10-multi-agent.md`. Merge the `AGENTS.md` reading-list
changes with the printed `diff` — Tier 2 and Tier 1 now read the card instead of four
process documents, and that is the whole token saving. Copy the new charter tables if the
project needs them. `--harness`, `--profile` and `--hooks` apply to a fresh install.

## 3.0.0 — 2026-09-03

The kit covered web and content projects well and engineering-heavy ones barely. This
release closes that without growing what a web project *reads*: every review, skill, and
gate is fact-gated, and a content site's role roster and installed skills are byte-for-byte
what 2.5.0 produced (a smoke test asserts exactly that).

What does grow is the portable tree on disk. `docs/process/`, `docs/roles/`, and
`docs/templates/` are installed whole in every project, as they always have been, so that
`--upgrade` can manage them and a project can activate a role later without reinstalling.
A content site therefore gains eleven files it never opens: the reading list in
`AGENTS.md` §3 is what bounds an agent's context, and an inactive role's playbook is not
on it. `09-probabilistic-and-data-systems.md` says so in its own opening line.

### Added

- **`Measured`**, a seventh word in the verification vocabulary, for results that are
  numbers rather than passes. It carries method, subject version, N, spread, and date, or
  it is not a claim. A metric with no baseline is not an improvement, it is a number.
- **`process/09-probabilistic-and-data-systems.md`** — models, prompts, retrieval,
  datasets, pipelines, and acquisition. Read only when a change touches one.
- **Three role playbooks**: `data-engineer`, `ml-engineer`, `performance-engineer`.
- **Four extensions to existing playbooks**: `architect` gains asynchronous and
  distributed review plus a clean-code block; `security` gains supply chain and AI/agent
  surfaces; `qa` gains testing non-deterministic systems; `privacy-legal` gains acquired
  data, third-party inference, and generated-content disclosure.
- **Six templates**: `eval-plan`, `data-contract`, `pipeline-runbook`,
  `performance-budget`, `service-catalog`, `model-and-dataset-card`.
- **Seven skills**: `sdlc-eval-gate`, `sdlc-data-contract`, `sdlc-migration`,
  `sdlc-service-contract`, `sdlc-perf-budget`, `sdlc-scrape-compliance`, and
  `sdlc-doctor` (installed always).
- **Four conditional check stages** — `checks.infra`, `checks.data`, `checks.eval`,
  `checks.perf` — with charter rows, installer questions, and CI scaffolding.
- **`.ai-sdlc/profile.json`**, the charter in machine-readable form, so a command or
  skill can branch on the project's facts and commands without parsing prose. The
  charter remains the source of truth and wins on conflict.
- **`/sdlc-doctor`**, the first check that audits an installed project rather than the
  kit's own source: placeholders, blank commands, undecided roles, stale artifacts,
  traceability gaps, worklog size, profile drift.
- Detection for ML/LLM, vector stores, data orchestration and warehouses, messaging,
  IaC, acquisition, and load tooling — each feeding a project-type default.
- A worklog rotation threshold in `07-traceability.md`. The worklog is on the always-read
  list and grew unbounded, one invisible entry at a time.
- Cross-reference validation (roles, templates, skills, and check stages must agree
  everywhere they are named) and a guard that fails if `AGENTS.md`'s stated docs-tree
  size drifts from the measured one.

### Changed

- **Twelve project types and eleven facts**, up from eight and six. `TYPE_FACTS` is keyed
  by fact name rather than position.
- `/sdlc-verify` reads the profile for exact commands, runs the conditional stages, and
  reports `Measured` where the result is a number.
- `AGENTS.md`: prompt, model, retrieval, dataset, and contract changes have explicit tier
  triggers; the reading-list token figures are now measured rather than estimated.
- The installer derives charter command labels from the stage key instead of zipping
  against a parallel list.

### Upgrading

`--upgrade` delivers the new process document, role playbooks, and templates to an
existing installation, and leaves `AGENTS.md` and `docs/project/` alone as always. Two
things need a hand:

- Merge the `AGENTS.md` changes (sections 2, 3, 5, and 7) with the printed `diff`.
- The new charter sections — **Budgets**, **Model & data**, **Data ownership**, the three
  role rows, and the four `checks.*` rows — are not added to an existing charter, because
  the file is project-owned. Copy them from `template/docs/project/charter.md` if the
  project has those surfaces.

New skills are not added by an upgrade; `ls optional/skills` shows what is available.

## 2.5.0 — 2026-08-23

### Added

- Stack adapters for Node/TypeScript, Python, Go, Rust, PHP, Ruby, Maven/Gradle, and .NET.
- ORM, database-driver, migration-tool, and testing-tool detection across those ecosystems.
- `--scaffold-tests` for an instantiated test plan and machine-readable testing profile.
- `--scaffold-ci github|gitlab` for opt-in pipelines generated from confirmed commands.
- Adapter and scaffolding fixtures covering supported language and database families.
- Polyglot command composition so every detected language participates in each quality stage.
- Manifest-managed template upgrades, allowing new testing and data-model guidance to
  reach existing installations without touching project records.

### Safety

- Scaffolding never installs dependencies and never overwrites existing test plans,
  profiles, or CI configuration.
- CI generation refuses repositories with no detected or confirmed quality commands.
- Generated CI is manual-only until a human confirms commands, runtimes, and services.
- Generated database guidance requires real-engine integration tests, migration/restore
  exercises, and synthetic test data.

## 2.4.0 — 2026-08-23

### Added

- Machine-readable manifests for portable managed files.
- Upgrade preflight checks, backups, obsolete-file cleanup, atomic writes, and rollback.
- Stack-neutral validation, continuous integration, and tag-based release automation.
- AI prompt-injection, secret-disclosure, and permission-escalation boundaries.
- Repository licensing, contribution guidance, and a security policy.
- Detection for integration, contract, accessibility, and common namespaced test scripts.

### Changed

- `--docs-dir` now updates the operating contract and Claude commands completely.
- Tier 3 uses a compact reading and worklog path.
- Dry runs and pre-confirmation quits no longer create target directories.
- Detected format, install, typecheck, and lint commands favor non-mutating,
  reproducible, locally installed tools.

## 2.3.0

- Added the navigable installer, localisation role, and architecture seeding.

Earlier history is available in the repository's Git log.
