# Skills

Fourteen skills that make the process fire on its own. The four `/sdlc-*` slash commands in
`../claude-commands/` wait to be typed; these are **model-invoked** — the agent reads the
`description` in each `SKILL.md` frontmatter and loads the skill when the situation it
describes appears. The two are complements, not duplicates: the commands drive the loop,
the skills catch the moments between its steps.

`install.sh` evaluates which of them a project needs from the same six answers that decide
the active roles, and copies only those into the project's `.claude/skills/`. An unused
skill is not free — it is a description competing for attention in every future context
window.

| Skill | Installed when |
| --- | --- |
| `sdlc-intake` | always |
| `sdlc-evidence-check` | always |
| `sdlc-charter-audit` | always |
| `sdlc-adr` | always |
| `sdlc-accessibility-audit` | there is an interface |
| `sdlc-design-review` | there is a visual interface |
| `sdlc-content-seo` | content is publicly discoverable |
| `sdlc-privacy-review` | personal data is held |
| `sdlc-threat-model` | personal data is held, or it deploys somewhere |
| `sdlc-release` | it deploys somewhere you operate |
| `sdlc-postmortem` | it deploys somewhere you operate |
| `sdlc-i18n-audit` | it ships in more than one language |
| `sdlc-translation-review` | it ships in more than one language |
| `sdlc-managed-platform` | a platform co-owns the repository |

Install a skill later by copying its directory:

```sh
cp -r optional/skills/sdlc-release /path/to/project/.claude/skills/
```

…then replace `{{DOCS_DIR}}` and `{{PREFIX}}` in the copy — `install.sh` does this for you,
a manual copy does not.

## Placeholders

Skills use `{{DOCS_DIR}}` (the installed docs directory, default `docs`) and `{{PREFIX}}`
(the work item prefix). Nothing else is substituted.

## Adding your own

One directory, one `SKILL.md`, frontmatter with `name` and `description`. Put the trigger
in the description — when the skill should fire, in the words that will appear in a real
request — because that text is all the agent sees when deciding whether to load it. Keep
the body short enough to be read in full: point at the process documents rather than
restating them, so the skill cannot drift away from the standard it enforces.

Project-specific skills belong in the project's own `.claude/skills/`, not here. `--upgrade`
refreshes only the skills this kit ships and never adds new ones.
