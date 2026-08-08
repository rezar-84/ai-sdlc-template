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
- **No ceremony tax.** A one-line copy fix does not trigger twelve role reviews. Risk
  tiers (defined in `AGENTS.md`) scale both the process and the *reading* to the change —
  a Tier 3 fix has a reading list of one charter section.

## Install into a project

```sh
./install.sh /path/to/your-project ACME          # ACME = the work-item ID prefix
```

The installer copies `AGENTS.md` to the project root, `docs/` into the project, and the
four slash commands into `.claude/commands/`; substitutes `{{PROJECT_NAME}}` and
`{{PREFIX}}` in all of them; adds a `CLAUDE.md` pointer if none exists; and **never
overwrites an existing file** — re-running it is safe and only fills in what is missing.

If the project already uses `docs/` for something else:

```sh
./install.sh /path/to/your-project ACME --docs-dir sdlc-docs
```

…then adjust the `docs/` paths named in `AGENTS.md` (they are listed in one place).

Manual install is a copy plus a find-and-replace — the substitution is not optional, and
skipping it leaves `{{PREFIX}}-###` as a literal path in the docs the agent follows:

```sh
cp    template/AGENTS.md          /path/to/your-project/AGENTS.md
cp -r template/docs               /path/to/your-project/docs
cp -r optional/claude-commands    /path/to/your-project/.claude/commands
cd /path/to/your-project
grep -rl '{{' docs AGENTS.md .claude | xargs sed -i 's/{{PREFIX}}/ACME/g; s/{{PROJECT_NAME}}/your-project/g'
```

Then, in the target project:

1. Fill in `docs/project/charter.md`. This is the only file you *must* complete before
   the kit is usable — it declares the project name, ID prefix, active roles, stack,
   check commands, constraints, and risk defaults. An agent that guesses a check command
   because the charter was blank will produce confidently false "verified" claims.
2. Confirm nothing was missed: `grep -rn '{{' docs AGENTS.md .claude` should be empty.
3. Fill in the "Project overrides" section of `AGENTS.md` — the project-specific rules,
   forbidden shortcuts, and the surfaces where a named human must approve.

That is all. There is no build step, no dependency, and no runtime.

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
    roles/                   WHO reviews. One playbook per professional perspective.
      README.md + 12 role playbooks
    templates/               Blank artifacts to copy when a project needs one.
    project/                 WHERE this project's filled-in reality lives.
      charter.md  backlog.md  worklog.md  assumptions-and-risks.md
      adr/  reviews/  plans/  postmortems/  worklog-archive/
optional/
  claude-commands/           Claude Code slash commands that drive the loop
VERSION                      the kit version, stamped into installed AGENTS.md
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

`docs/process/` and `docs/roles/` are replaceable wholesale — `--upgrade` overwrites
exactly those two directories and nothing else. `docs/project/`, `AGENTS.md`, and
`.claude/commands/` are never touched, because they may carry your edits; the installer
prints a `diff` command for `AGENTS.md` so you can merge by hand if a release changed it.

This only works if you keep project-specific rules where they belong: in `AGENTS.md`
("Project overrides") and in `docs/project/`, never inside `process/` or `roles/`. The
installed `AGENTS.md` carries the kit version it came from, in an HTML comment near the
top; `VERSION` here is the current one.

## Conventions used in the docs

- `{{PLACEHOLDER}}` — a value to find-and-replace at install time.
- `_(fill in)_` — prose you write per project; delete the marker when filled.
- `<angle brackets>` — an example value in a command or path.
- Every artifact in `docs/project/` carries a frontmatter block with `status`, `owner`,
  and `last-reviewed`. An agent must treat a missing or old `last-reviewed` as a signal
  that the document may not describe reality — verify before relying on it.
