# AI SDLC Template

A portable, stack-agnostic documentation kit that makes an AI coding agent work like a
disciplined product team instead of a fast typist.

Drop it into any project. From then on, an agent that reads `AGENTS.md` will:

1. **Frame** the request as a tracked unit of work with an ID.
2. **Plan** before editing, at a depth proportional to risk.
3. **Review** the plan (and later the result) from named professional perspectives —
   product, architecture, UX, brand, copy, SEO, CRO, security, DevOps/SRE, QA,
   accessibility, privacy/legal — recording findings and verdicts.
4. **Build** to a stated Definition of Done.
5. **Verify** with real commands and real output, never assertion.
6. **Log** what shipped, what was verified, and what is still open.
7. **Close** the loop — backlog status, ADRs, updated docs, flagged assumptions.

## What it deliberately does NOT do

- **No tech stack.** No framework, language, package manager, cloud, CI system, or test
  runner is named anywhere in the process docs. Each project declares its own in
  `docs/project/charter.md`, and everything else refers to it indirectly ("the project's
  typecheck command").
- **No architecture.** Monolith, monorepo, serverless, microservices, a single script —
  all fine. The architect role reviews *whatever the project chose* against its own
  stated constraints.
- **No domain assumptions.** Works for a marketing site, an internal CLI, a data
  pipeline, a mobile app, a library, or a docs-only repo. Roles that do not apply are
  switched off in the charter, not awkwardly forced.
- **No ceremony tax.** A one-line copy fix does not trigger thirteen role reviews. Risk
  tiers (defined in `AGENTS.md`) scale both the process and the *reading* to the change —
  a Tier 3 fix has a reading list of one charter section.

## Install into a project

```sh
./install.sh /path/to/your-project
```

Run in a terminal, that opens a guided setup — ten short sections, every question with a
default, **Enter** to take it:

| Key | Does |
| --- | --- |
| `Enter` | accept the value in brackets |
| `-` | leave the field blank |
| `s` | take the defaults for the rest of this section |
| `S` | take the defaults for the rest of the setup |
| `b` | go back to the previous question |
| `?` | why this question is being asked |
| `q` | quit without writing anything |

The first question is where to install. It has no default and is never guessed: the
installer refuses its own directory (and anything inside it), so running `./install.sh`
from the kit cannot scatter a project's `AGENTS.md`, `docs/` and `.claude/` over the
template. A destination that does not exist yet can be created on the spot — or pass
`--create` for the same thing without questions.

It asks who and what the project is, then what you are building — **choose every type that
applies**, `1,3` for an app that is also an API — defaulted from what is actually in the
repository. That selection derives six yes/no facts (interface, visual interface, public
discoverability, deployment, personal data, conversion goal) which decide which of the
thirteen roles review your work and which skills get installed. It then shows the stack,
the check commands, and the architecture it read out of the repository for you to confirm,
asks about languages if the project has an interface or public content, and takes approvers
and risk defaults.

Nothing is written until the **review screen**: every answer listed and numbered, `Enter`
to write, a number to change that one answer, `q` to quit.

What it writes into the installed files:

- `docs/project/charter.md` — identity, stack, commands, default branch, approvers,
  staleness, managed platform, accessibility target, languages and localisation, and the
  **active roles table**, ticked and unticked with the reason each row came from.
- `docs/project/architecture.md` — instantiated, not left blank: the component inventory
  (monorepo packages, compose services) and the external dependencies it found in your
  dependency list, each row marked `_(detected at install)_` for you to confirm, plus the
  three things you told it that no file could say.
- `AGENTS.md` — the "Human approval required for" and "Forbidden in this project" lines of
  the Project overrides section.

Anything it could not establish is left blank on purpose. A blank cell is read as *Unknown*
by the process; a wrong one produces confidently false "verified" claims, so nothing is
guessed — not one check command, not one data category.

For scripts, CI, or a plain copy with no questions:

```sh
./install.sh /path/to/your-project ACME -y          # ACME = the work-item ID prefix
```

`-y` (also implied when stdin is not a terminal) takes every default, tailors nothing, and
installs only the skills that do not depend on an answer. The target directory is required
in this mode — without a terminal there is nobody to ask. Other flags: `--docs-dir <name>`
to install the docs under a different directory, `--create`, `--no-skills`, `--dry-run`,
`--lang <code>`, `--scaffold-tests`, `--scaffold-ci <github|gitlab>`, and `--upgrade`.

The installer is `install.py` (Python 3.6+, standard library only); `install.sh` is a
wrapper that runs it. Nothing the kit *installs* needs Python — only the installer does.

`--docs-dir` is for a project whose `docs/` already means something else. The installed
contract, commands, and skills all follow the chosen name automatically.

## Stack adapters and scaffolding

The portable process accepts any stack. The installer additionally recognises common
project markers for Node/TypeScript, Python, Go, Rust, PHP, Ruby, Java/Kotlin with Maven
or Gradle, and C#/.NET. Adapters detect existing frameworks, test tooling, ORMs, database
drivers, migration tools, and quality commands; they do not install or replace them.

Detected data layers include Prisma, Drizzle, TypeORM, SQLAlchemy/Alembic, Django ORM,
GORM/sqlc, Diesel/SQLx/SeaORM, Eloquent, Doctrine, Active Record, JPA/Hibernate,
Flyway/Liquibase, Entity Framework Core, and Dapper. Engine markers cover PostgreSQL,
MySQL/MariaDB, SQLite, MongoDB, Redis, SQL Server, and Oracle.

Two explicit flags turn detection into project-owned starting files:

```sh
./install.sh /path/to/project ACME -y --scaffold-tests
./install.sh /path/to/project ACME -y --scaffold-ci github
./install.sh /path/to/project ACME -y --scaffold-ci gitlab
```

`--scaffold-tests` creates `docs/project/test-plan.md` and
`.ai-sdlc/testing-profile.json`, both marked as detected and requiring confirmation.
`--scaffold-ci` creates `.github/workflows/quality.yml` or `.gitlab-ci.yml` from the
project's detected/confirmed commands. It refuses an empty command set. Scaffolding never
overwrites an existing file, never installs a dependency, and leaves runtime and service
version confirmation to the project charter. Generated jobs are manual-only until a
human confirms the commands and deliberately enables push or pull-request triggers.

The installer copies `AGENTS.md` to the project root, `docs/` into the project, the four
slash commands into `.claude/commands/`, and the selected skills into `.claude/skills/`;
substitutes `{{PROJECT_NAME}}`, `{{PREFIX}}`, and `{{DOCS_DIR}}` in all of them; adds a
`CLAUDE.md` pointer if none exists; and records checksums for portable files in
`.ai-sdlc/manifest.json`. A normal re-run **never overwrites an existing file** — it is
safe, reuses the docs directory it finds, and only fills in what is missing.

Manual install is a copy plus a find-and-replace — the substitution is not optional, and
skipping it leaves `{{PREFIX}}-###` as a literal path in the docs the agent follows:

```sh
cp    template/AGENTS.md          /path/to/your-project/AGENTS.md
cp -r template/docs               /path/to/your-project/docs
cp -r optional/claude-commands    /path/to/your-project/.claude/commands
cp -r optional/skills             /path/to/your-project/.claude/skills   # or just the ones you want
cd /path/to/your-project
grep -rl '{{' docs AGENTS.md .claude | xargs sed -i 's/{{PREFIX}}/ACME/g; s/{{PROJECT_NAME}}/your-project/g; s/{{DOCS_DIR}}/docs/g'
```

Then, in the target project:

1. Read `docs/project/charter.md` and correct or complete it. Guided setup fills in what it
   can establish; constraints, environments, and sources of truth are yours. An agent that
   guesses a check command because the charter was blank will produce confidently false
   "verified" claims.
2. Confirm nothing was missed: `grep -rn '{{' docs AGENTS.md .claude` should be empty.
3. Fill in the rest of the "Project overrides" section of `AGENTS.md`.

That is all. The installed kit is plain Markdown: no build step, no dependency, and
nothing to run.

## Skills

`optional/skills/` is a catalogue of fourteen skills that make the process fire on its own.
The slash commands wait to be typed; skills are model-invoked — the agent loads one when the
situation its description names actually appears.

| Skill | Fires when | Installed when |
| --- | --- | --- |
| `sdlc-intake` | a request arrives with no work item | always |
| `sdlc-evidence-check` | about to claim "done", "passing", "verified" | always |
| `sdlc-charter-audit` | before relying on the charter, or when it looks stale | always |
| `sdlc-adr` | a decision would be expensive to reverse | always |
| `sdlc-accessibility-audit` | UI is added or changed | there is an interface |
| `sdlc-design-review` | screens, components, or tokens change | there is a visual interface |
| `sdlc-content-seo` | public pages, copy, routes, or metadata change | content is public |
| `sdlc-privacy-review` | forms, analytics, tracking, logs, or claims change | personal data is held |
| `sdlc-threat-model` | auth, uploads, payments, or an external interface appears | data is held, or it deploys |
| `sdlc-release` | shipping to a real environment | it deploys |
| `sdlc-postmortem` | something broke, or a release was reverted | it deploys |
| `sdlc-i18n-audit` | strings, screens, or locales change | it ships in 2+ languages |
| `sdlc-translation-review` | content appears in a non-source language | it ships in 2+ languages |
| `sdlc-managed-platform` | editing platform config, history, or deploys | a platform co-owns the repo |

Setup evaluates that list against your six answers and installs only what applies — an
unused skill is a description competing for attention in every future context window. Add
one later by copying its directory into `.claude/skills/` and replacing the placeholders.
See `optional/skills/README.md` for how to write your own.

## Installing into a managed platform (Lovable, Replit, Bolt, …)

A project that lives on an AI app builder or cloud IDE is co-owned by another agent: the
platform edits files, syncs the repository, and often deploys the default branch on its
own. The kit is designed not to break that:

- **The installer detects** common platform markers (`.replit` / `replit.nix` /
  `replit.md`, a Lovable project, `.bolt/`, `.idx/`, `glitch.json`, CodeSandbox config)
  and prints platform-specific next steps. Detection is read-only, and the installer
  still never overwrites or edits an existing file — platform config is left exactly as
  found.
- **The charter declares the platform** in its "Managed platform" table: the sync model,
  the files the platform owns (never hand-edited), where the platform's own agent reads
  its instructions, and how deploys happen.
- **Process rules yield to that table.** "Managed platforms" in
  `docs/process/05-change-control.md` sets the standing rules: no hand-edits to
  platform-owned files, no history rewrites on any branch the platform syncs, treat an
  auto-deployed merge as a release, and point the platform's instruction file
  (`replit.md`, Lovable project knowledge) at `AGENTS.md` so the platform's agent and
  this process cannot drift apart.

Platform names appear only in this README and in the charter you fill in — the process
docs stay platform-agnostic the same way they stay stack-agnostic.

## Layout

```
template/
  AGENTS.md                  the operating contract — the file the agent always reads
  docs/
    README.md                map of the kit + cold-start reading order for an agent
    process/                 HOW we work. Portable. Same in every project. Rarely edited.
      00-operating-model.md      the loop, the modes, and what to do when a human is needed
      01-lifecycle-gates.md      appendix: G0..G6, for standing up a new project only
      02-role-reviews.md         who reviews what, at which stage, and what a verdict means
      03-ready-and-done.md       Definition of Ready / Definition of Done
      04-quality-gates.md        test strategy, CI gate order, bug severity ladder
      05-change-control.md       branches, commits, PRs, approvals, ADRs, rollback
      06-evidence-and-claims.md  the no-fabrication doctrine; provenance; assumptions
      07-traceability.md         IDs, the backlog row spec, what gets logged where
      08-content-and-translation.md  source language, machine translation, RTL, per-locale checks
    roles/                   WHO reviews. One playbook per professional perspective.
      README.md + 13 role playbooks
    templates/               Blank artifacts to copy when a project needs one.
    project/                 WHERE this project's filled-in reality lives.
      charter.md  backlog.md  worklog.md  assumptions-and-risks.md
      adr/  reviews/  plans/  postmortems/  worklog-archive/
optional/
  claude-commands/           Claude Code slash commands that drive the loop
  skills/                    model-invoked skills, installed per project need
  locales/                   translations of the installer's own prompts
install.py                   the installer; install.sh is a wrapper around it
validate.py                  source and installed-output validation
tests/smoke.py               installer boundary and workflow tests
.github/workflows/           continuous validation and tag-based releases
VERSION                      the kit version, stamped into installed AGENTS.md
LICENSE · SECURITY.md · CONTRIBUTING.md · CHANGELOG.md
                             distribution and project governance
```

## The three kinds of file

Keeping these separate is the main structural idea of the kit.

| Kind | Lives in | Edited | Purpose |
| --- | --- | --- | --- |
| **Standard** | `docs/process/`, `docs/roles/` | Almost never, and only deliberately | Defines how work is done. Identical across projects, so an agent's behaviour is predictable everywhere. |
| **Template** | `docs/templates/` | Never (copied, not edited) | Blank forms. Copy into `docs/project/` when the project needs that artifact. |
| **Project record** | `docs/project/` | Constantly | This project's truth: charter, backlog, worklog, decisions, reviews, risks. |

A common failure in hand-rolled agent docs is mixing these — process rules get buried
inside a project brief, so they cannot be reused, and project facts get written into
process docs, so they go stale silently. Do not merge the directories.

## Upgrading the kit later

```sh
./install.sh /path/to/your-project ACME --upgrade
```

`--upgrade` manages `docs/README.md`, `docs/process/`, `docs/roles/`, `docs/templates/`,
and any kit skill the project already has. It verifies their recorded checksums first and
stops if a managed file was locally modified or removed. It backs up affected files under
`.ai-sdlc/backups/`, writes updates
atomically, removes obsolete files previously owned by the manifest, and restores the old
state if an update fails. Legacy installations receive a full portable-file backup on
their first manifest-based upgrade.

`docs/project/`, `AGENTS.md`, and `.claude/commands/` are never touched, because they may
carry project edits; the installer prints a `diff` command for `AGENTS.md` so newer
portable contract changes can be merged by hand. Skills the project did not choose are
not added by an upgrade — `ls optional/skills` shows what a newer version ships.

This only works if you keep project-specific rules where they belong: in `AGENTS.md`
("Project overrides") and in `docs/project/`, never inside `process/` or `roles/`. The
installed `AGENTS.md` carries the kit version it came from, in an HTML comment near the
top. The manifest records the version of the managed process, role, and skill files;
`VERSION` here is the current one.

## Validating and contributing

The kit validates itself with standard-library-only commands:

```sh
python3 validate.py
python3 tests/smoke.py
python3 -m py_compile install.py validate.py tests/smoke.py
```

CI runs these checks on every push and pull request. Tags shaped like `v2.5.0` are checked
against `VERSION` before release creation. See `CONTRIBUTING.md`, `SECURITY.md`,
`CHANGELOG.md`, and `LICENSE` for project governance and distribution terms.

## Conventions used in the docs

- `{{PLACEHOLDER}}` — a value to find-and-replace at install time.
- `_(fill in)_` — prose you write per project; delete the marker when filled.
- `<angle brackets>` — an example value in a command or path.
- Every artifact in `docs/project/` carries a frontmatter block with `status`, `owner`,
  and `last-reviewed`. An agent must treat a missing or old `last-reviewed` as a signal
  that the document may not describe reality — verify before relying on it.
