#!/usr/bin/env python3
"""Smoke tests for install.py. Standard library only.

    python3 tests/smoke.py [-v]

Every test installs into a throwaway directory under the system temp dir. The wizard runs
through a pty, driven by rules of the form "prompt substring" -> "answer", so the tests
exercise the same prompt loop a person sees rather than a private API.
"""

import hashlib
import json
import os
import pty
import re
import select
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INSTALL = os.path.join(ROOT, "install.py")
VERBOSE = "-v" in sys.argv
ANSI = re.compile(r"\x1b\[[0-9;]*m")

sys.path.insert(0, ROOT)
import install as installer

failures = []


def run(args, cwd=ROOT):
    p = subprocess.Popen([sys.executable, INSTALL] + args, cwd=cwd,
                         stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT)
    out, _ = p.communicate()
    return p.returncode, out.decode("utf-8", "replace")


def drive(args, rules, timeout=60):
    """Run the wizard on a pty. `rules` is a list of (substring, answer); the first match
    against the text printed since the last prompt wins, otherwise Enter."""
    master, slave = pty.openpty()
    p = subprocess.Popen([sys.executable, INSTALL] + args, cwd=ROOT,
                         stdin=slave, stdout=slave, stderr=slave, close_fds=True)
    os.close(slave)
    buf, log, deadline = b"", [], time.time() + timeout
    used = set()
    while time.time() < deadline and p.poll() is None:
        ready, _, _ = select.select([master], [], [], 0.3)
        if ready:
            try:
                chunk = os.read(master, 8192)
            except OSError:
                break
            if not chunk:
                break
            buf += chunk
            log.append(chunk)
            continue
        text = ANSI.sub("", buf.decode("utf-8", "replace"))
        buf = b""
        answer = ""
        for i, (needle, reply) in enumerate(rules):
            if needle in text and i not in used:
                answer, _ = reply, used.add(i)
                break
        try:
            os.write(master, (answer + "\n").encode("utf-8"))
        except OSError:
            break
    try:
        p.wait(timeout=10)
    except subprocess.TimeoutExpired:
        p.kill()
    os.close(master)
    return p.returncode, ANSI.sub("", b"".join(log).decode("utf-8", "replace"))


def check(name, condition, detail=""):
    if condition:
        print("  ok    %s" % name)
    else:
        print("  FAIL  %s%s" % (name, (" -- " + detail) if detail else ""))
        failures.append(name)


def fixture(kind):
    d = tempfile.mkdtemp(prefix="sdlc-%s-" % kind)
    if kind == "next":
        write(d, "package.json", """{"dependencies":{"next":"15","@prisma/client":"6",
            "next-auth":"5","stripe":"14","@sentry/nextjs":"8"},
            "scripts":{"dev":"next dev","build":"next build","test":"vitest run"}}""")
        write(d, "tsconfig.json", "{}")
        write(d, "prisma/schema.prisma", 'datasource db {\n  provider = "postgresql"\n}\n')
    elif kind == "fastapi":
        write(d, "pyproject.toml", 'dependencies = ["fastapi", "pytest", "ruff"]\n')
    elif kind == "astro-i18n":
        write(d, "package.json", '{"dependencies":{"astro":"4","astro-i18next":"2"}}')
        for locale in ("en", "fa", "tr"):
            write(d, "locales/%s/common.json" % locale, "{}")
    elif kind == "monorepo":
        write(d, "package.json", '{"workspaces":["apps/*","packages/*"]}')
        write(d, "pnpm-workspace.yaml", "packages:\n  - apps/*\n")
        for part in ("apps/web", "apps/api", "packages/ui"):
            write(d, "%s/package.json" % part, "{}")
        write(d, "docker-compose.yml", "services:\n  db:\n    image: postgres\n  cache:\n    image: redis\n")
    return d


def write(root, rel, text):
    path = os.path.join(root, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        fh.write(text)


def read(root, rel):
    try:
        with open(os.path.join(root, rel)) as fh:
            return fh.read()
    except IOError:
        return ""


def files(root):
    return sum(len(f) for _, _, f in os.walk(root))


# ---------------------------------------------------------------- tests

def test_guards():
    print("guards")
    code, out = run([ROOT, "ACME", "-y"])
    check("refuses the kit itself", code == 1 and "refusing" in out, out.strip()[:90])
    code, out = run([os.path.join(ROOT, "template"), "ACME", "-y"])
    check("refuses a path inside the kit", code == 1 and "inside the kit" in out)
    code, out = run(["-y"])
    check("no target, no terminal -> usage", code == 1 and "usage:" in out)
    missing = os.path.join(tempfile.gettempdir(), "sdlc-nope-%d" % os.getpid())
    code, out = run([missing, "ACME", "-y"])
    check("missing directory without --create", code == 1 and "no such directory" in out)
    code, out = run([missing, "ACME", "-y", "--create"])
    check("--create makes it", code == 0 and os.path.isdir(missing))
    shutil.rmtree(missing, ignore_errors=True)

    if hasattr(os, "symlink"):
        d = tempfile.mkdtemp(prefix="sdlc-link-target-")
        outside = tempfile.mkdtemp(prefix="sdlc-link-outside-")
        os.symlink(outside, os.path.join(d, ".claude"))
        code, out = run([d, "ACME", "-y"])
        check("refuses a destination symlink escape",
              code == 1 and "escapes project" in out and files(outside) == 0)
        check("symlink refusal happens before installation",
              not os.path.exists(os.path.join(d, "AGENTS.md")))
        shutil.rmtree(d, ignore_errors=True)
        shutil.rmtree(outside, ignore_errors=True)

    check("user text cannot inject a second Markdown line",
          installer.plain_text("Jane: Doe\n# injected {{PREFIX}}") ==
          "Jane: Doe # injected { {PREFIX} }")


def test_non_interactive():
    print("non-interactive (-y)")
    d = tempfile.mkdtemp(prefix="sdlc-y-")
    code, out = run([d, "ACME", "-y"])
    check("exit 0", code == 0)
    manifest = json.loads(read(d, ".ai-sdlc/manifest.json"))
    check("managed manifest written", bool(manifest))
    check("portable README and templates are upgrade-managed",
          "docs/README.md" in manifest.get("files", {}) and
          "docs/templates/test-plan.md" in manifest.get("files", {}))
    check("no leftover placeholders", "{{" not in read(d, "docs/project/charter.md"))
    check("charter not tailored", "_(one sentence a stranger would understand)_"
          in read(d, "docs/project/charter.md"))
    skills = sorted(os.listdir(os.path.join(d, ".claude", "skills")))
    check("only answer-independent skills", skills == ["sdlc-adr", "sdlc-charter-audit",
                                                       "sdlc-doctor", "sdlc-evidence-check",
                                                       "sdlc-intake"],
          str(skills))
    before = files(d)
    run([d, "ACME", "-y"])
    check("re-run adds nothing", files(d) == before)
    code, out = run([d, "--upgrade"])
    check("upgrade recovers the prefix", "Recovered prefix from charter: ACME" in out)
    check("upgrade touches only standards", "project/charter.md" not in out)
    shutil.rmtree(d, ignore_errors=True)


def test_dry_run():
    print("--dry-run")
    d = tempfile.mkdtemp(prefix="sdlc-dry-")
    code, out = run([d, "ACME", "-y", "--dry-run"])
    check("writes nothing", code == 0 and files(d) == 0 and "would add" in out)
    shutil.rmtree(d, ignore_errors=True)

    d = os.path.join(tempfile.gettempdir(), "sdlc-dry-create-%d" % os.getpid())
    shutil.rmtree(d, ignore_errors=True)
    code, out = run([d, "ACME", "-y", "--create", "--dry-run"])
    check("--dry-run --create leaves no directory", code == 0 and not os.path.exists(d))


def test_custom_docs_dir():
    print("--docs-dir")
    d = tempfile.mkdtemp(prefix="sdlc-custom-")
    code, out = run([d, "ACME", "-y", "--docs-dir", "handbook"])
    installed = [read(d, "AGENTS.md")]
    for name in ("sdlc-log.md", "sdlc-plan.md", "sdlc-review.md", "sdlc-verify.md"):
        installed.append(read(d, ".claude/commands/%s" % name))
    check("exit 0", code == 0)
    check("contract and commands use custom path",
          all("handbook/" in text and not re.search(r"(?<![A-Za-z0-9_-])docs/", text)
              for text in installed))
    check("no unresolved placeholders", all("{{" not in text for text in installed))
    manifest = json.loads(read(d, ".ai-sdlc/manifest.json"))
    check("manifest records custom path", manifest.get("docs_dir") == "handbook")
    code, out = run([d, "--upgrade"])
    check("upgrade recovers custom path from manifest",
          code == 0 and "handbook portable docs" in out)
    shutil.rmtree(d, ignore_errors=True)


def test_managed_upgrade():
    print("managed upgrade")
    d = tempfile.mkdtemp(prefix="sdlc-upgrade-")
    run([d, "ACME", "-y"])
    manifest_path = os.path.join(d, ".ai-sdlc", "manifest.json")
    manifest = json.loads(read(d, ".ai-sdlc/manifest.json"))

    changed_rel = "docs/process/00-operating-model.md"
    changed_path = os.path.join(d, changed_rel)
    with open(changed_path, "a") as fh:
        fh.write("\nlegacy-version-marker\n")
    with open(changed_path, "rb") as fh:
        changed_bytes = fh.read()
    manifest["files"][changed_rel] = hashlib.sha256(changed_bytes).hexdigest()

    obsolete_rel = "docs/process/obsolete.md"
    write(d, obsolete_rel, "old managed file\n")
    manifest["files"][obsolete_rel] = hashlib.sha256(b"old managed file\n").hexdigest()
    with open(manifest_path, "w") as fh:
        json.dump(manifest, fh)

    code, out = run([d, "--upgrade"])
    check("upgrade succeeds", code == 0, out[-300:])
    check("outdated managed file refreshed", "legacy-version-marker" not in read(d, changed_rel))
    check("obsolete managed file removed", not os.path.exists(os.path.join(d, obsolete_rel)))
    backups = os.path.join(d, ".ai-sdlc", "backups")
    check("affected files backed up", os.path.isdir(backups) and files(backups) >= 2)

    with open(changed_path, "a") as fh:
        fh.write("\nlocal project edit\n")
    code, out = run([d, "--upgrade"])
    check("local managed edit stops upgrade", code == 1 and "modified or removed" in out)
    check("local edit preserved", "local project edit" in read(d, changed_rel))
    shutil.rmtree(d, ignore_errors=True)


def test_command_detection():
    print("command detection")
    d = tempfile.mkdtemp(prefix="sdlc-detect-")
    write(d, "package.json", json.dumps({
        "dependencies": {"typescript": "5", "@playwright/test": "1"},
        "scripts": {
            "format:check": "prettier --check .", "lint": "eslint .",
            "test:unit": "vitest run", "test:integration": "vitest integration",
            "test:contract": "vitest contract", "test:a11y": "playwright test a11y",
            "test:e2e": "playwright test", "security": "audit-ci", "build": "tsc"
        }
    }))
    write(d, "package-lock.json", "{}")
    write(d, "tsconfig.json", "{}")
    cmds = installer.detect(d).cmds
    check("reproducible npm install detected", cmds.get("install") == "npm ci")
    check("all quality script families detected",
          all(key in cmds for key in ("format", "lint", "typecheck", "unit",
                                      "integration", "contract", "build", "scan",
                                      "a11y", "e2e")), str(cmds))
    shutil.rmtree(d, ignore_errors=True)

    d = tempfile.mkdtemp(prefix="sdlc-detect-go-")
    write(d, "go.mod", "module example.test/kit\n\ngo 1.22\n")
    cmds = installer.detect(d).cmds
    check("Go format gate is recursive and fails on drift",
          "find . -name '*.go'" in cmds.get("format", "") and
          cmds.get("format", "").startswith("test -z"), str(cmds))
    shutil.rmtree(d, ignore_errors=True)


def test_stack_adapters():
    print("language/database adapters")
    cases = [
        ("python", {
            "pyproject.toml": ('dependencies = ["sqlalchemy", "alembic", "psycopg", '
                               '"pytest", "hypothesis"]\n'),
            "alembic.ini": "[alembic]\n",
        }, ("python", "SQLAlchemy", "PostgreSQL", "Alembic", "pytest", "Hypothesis")),
        ("go", {
            "go.mod": ("module example.test/app\n\nrequire (\n gorm.io/gorm v1.0.0\n"
                       " github.com/jackc/pgx/v5 v5.0.0\n"
                       " github.com/stretchr/testify v1.0.0\n)\n"),
            "sqlc.yaml": "version: '2'\n",
        }, ("go", "GORM", "PostgreSQL", "sqlc", "testify")),
        ("rust", {
            "Cargo.toml": ('[package]\nname="x"\nversion="0.1.0"\n[dependencies]\n'
                           'sqlx="1"\nredis="1"\n[dev-dependencies]\nproptest="1"\n'),
            "migrations/001.sql": "select 1;\n",
        }, ("rust", "SQLx", "Redis", "proptest")),
        ("php", {
            "composer.json": json.dumps({
                "require": {"laravel/framework": "1", "ext-pdo_pgsql": "*"},
                "require-dev": {"pestphp/pest": "1"}, "scripts": {"test": "pest"}
            }),
        }, ("php", "Eloquent ORM", "PostgreSQL", "Laravel migrations", "Pest")),
        ("ruby", {
            "Gemfile": "gem 'rails'\ngem 'pg'\ngem 'rspec'\n",
        }, ("ruby", "Active Record", "PostgreSQL", "Rails migrations", "RSpec")),
        ("jvm-maven", {
            "pom.xml": ("<project><dependencies><dependency>spring-data-jpa</dependency>"
                        "<dependency>postgresql</dependency><dependency>flyway</dependency>"
                        "<dependency>junit</dependency><dependency>testcontainers</dependency>"
                        "</dependencies></project>"),
        }, ("jvm-maven", "JPA", "PostgreSQL", "Flyway", "JUnit", "Testcontainers")),
        ("jvm-gradle", {
            "build.gradle.kts": ('dependencies { implementation("org.hibernate:hibernate-core") '
                                 'testImplementation("org.testng:testng") }'),
        }, ("jvm-gradle", "Hibernate", "TestNG")),
        ("dotnet", {
            "App.csproj": ("<Project><ItemGroup>"
                           "<PackageReference Include=\"Microsoft.EntityFrameworkCore\" />"
                           "<PackageReference Include=\"Npgsql.EntityFrameworkCore.PostgreSQL\" />"
                           "<PackageReference Include=\"xunit\" />"
                           "<PackageReference Include=\"Testcontainers\" />"
                           "</ItemGroup></Project>"),
        }, ("dotnet", "Entity Framework Core", "PostgreSQL", "EF Core migrations",
             "xUnit", "Testcontainers")),
    ]
    for name, fixture_files, expected in cases:
        d = tempfile.mkdtemp(prefix="sdlc-adapter-%s-" % name)
        for rel, content in fixture_files.items():
            write(d, rel, content)
        found = installer.detect(d)
        haystack = found.adapters + found.db + found.migrations + found.test
        missing = [value for value in expected if value not in haystack]
        check("%s adapter" % name, not missing, "missing=%s found=%s" % (missing, haystack))
        shutil.rmtree(d, ignore_errors=True)

    d = tempfile.mkdtemp(prefix="sdlc-adapter-polyglot-")
    write(d, "package.json", json.dumps({"scripts": {"test": "vitest run"},
                                          "devDependencies": {"vitest": "1"}}))
    write(d, "requirements.txt", "pytest\nruff\npsycopg\n")
    found = installer.detect(d)
    check("polyglot adapters compose stage commands",
          found.adapters == ["node", "python"] and
          found.cmds.get("install") == "npm install && pip install -r requirements.txt" and
          found.cmds.get("unit") == "npm run test && pytest", str(found.cmds))
    shutil.rmtree(d, ignore_errors=True)


def test_domain_detection():
    print("domain markers select project types")
    cases = [
        ("ai", {"requirements.txt": "langchain\nqdrant-client\nragas\n"},
         [7], ["ai", "data", "deploy", "pii"]),
        ("data", {"requirements.txt": "dagster\ndbt-core\ngreat-expectations\n"},
         [6], ["data", "deploy", "pii"]),
        ("messaging", {"package.json": '{"dependencies":{"kafkajs":"2"}}'},
         [8], ["deploy", "dist", "pii"]),
        ("iac", {"main.tf": 'resource "null_resource" "x" {}\n'},
         [9], ["deploy", "infra"]),
        ("scrape", {"requirements.txt": "scrapy\n"},
         [10], ["acquire", "data", "deploy", "pii"]),
    ]
    for name, fixture_files, want_types, want_facts in cases:
        d = tempfile.mkdtemp(prefix="sdlc-domain-%s-" % name)
        for rel, content in fixture_files.items():
            write(d, rel, content)
        found = installer.detect(d)
        facts = sorted({f for t in found.types for f in installer.TYPE_FACTS.get(t, ())})
        check("%s type detected" % name,
              all(t in found.types for t in want_types), str(found.types))
        check("%s facts derived" % name, facts == want_facts, str(facts))
        shutil.rmtree(d, ignore_errors=True)

    # A content site must be unaffected by any of it: same six facts as before v3.
    d = tempfile.mkdtemp(prefix="sdlc-domain-web-")
    write(d, "package.json", '{"dependencies":{"astro":"4"}}')
    found = installer.detect(d)
    facts = sorted({f for t in found.types for f in installer.TYPE_FACTS.get(t, ())})
    check("content site gains no engineering facts",
          facts == ["conv", "deploy", "public", "ui", "visual"], str(facts))
    shutil.rmtree(d, ignore_errors=True)


def test_role_and_skill_selection():
    print("facts select roles and skills")

    def wizard(facts, db=()):
        w = installer.Wizard.__new__(installer.Wizard)
        w.a = dict((fid, fid in facts) for fid in installer.FACT_IDS)
        w.a["multilingual"] = False
        w.det = installer.Detected()
        w.det.db = list(db)
        w.o = type("O", (), {"want_skills": True})()
        return w

    site = wizard(("ui", "visual", "public", "deploy", "conv"))
    check("content site roster unchanged",
          site.active_roles() == ["product-manager", "architect", "security", "qa",
                                  "ux-designer", "accessibility", "brand-designer",
                                  "copywriter", "seo", "cro-analyst", "devops-sre"],
          str(site.active_roles()))
    check("content site gains no engineering skills",
          not [n for n in site.chosen_skills()
               if n in ("sdlc-eval-gate", "sdlc-data-contract", "sdlc-perf-budget",
                        "sdlc-service-contract", "sdlc-scrape-compliance")],
          str(site.chosen_skills()))

    ai = wizard(("deploy", "pii", "ai", "data"))
    for role in ("ml-engineer", "data-engineer", "performance-engineer"):
        check("ai project activates %s" % role, role in ai.active_roles(),
              str(ai.active_roles()))
    for skill in ("sdlc-eval-gate", "sdlc-data-contract", "sdlc-perf-budget"):
        check("ai project installs %s" % skill, skill in ai.chosen_skills(),
              str(ai.chosen_skills()))

    dist = wizard(("deploy", "pii", "dist"))
    check("distributed project installs sdlc-service-contract",
          "sdlc-service-contract" in dist.chosen_skills(), str(dist.chosen_skills()))
    check("distributed project has no ml-engineer",
          "ml-engineer" not in dist.active_roles(), str(dist.active_roles()))

    # sdlc-migration is gated on detection, not on an answer.
    plain = wizard(("deploy",))
    check("no data layer, no migration skill",
          "sdlc-migration" not in plain.chosen_skills(), str(plain.chosen_skills()))
    withdb = wizard(("deploy",), db=("Prisma",))
    check("detected data layer installs sdlc-migration",
          "sdlc-migration" in withdb.chosen_skills(), str(withdb.chosen_skills()))


def test_profile():
    print("machine-readable project profile")
    d = fixture("next")
    code, out = run([d, "PRF", "-y"])
    check("exit 0", code == 0, out[-300:])
    raw = read(d, ".ai-sdlc/profile.json")
    try:
        profile = json.loads(raw)
    except ValueError:
        profile = {}
    check("profile is valid json with the expected keys",
          set(("kit_version", "facts", "roles", "commands", "detected", "docs_dir"))
          <= set(profile), str(sorted(profile)))
    check("profile records the kit version",
          profile.get("kit_version") == installer.VERSION, str(profile.get("kit_version")))
    check("every fact is present and boolean",
          sorted(profile.get("facts", {})) == sorted(installer.FACT_IDS) and
          all(isinstance(v, bool) for v in profile.get("facts", {}).values()),
          str(profile.get("facts")))
    check("non-interactive declares nothing",
          profile.get("declared") is False and
          not any(profile.get("facts", {}).values()), str(profile.get("facts")))
    check("detection is still recorded",
          "Prisma" in " ".join(profile.get("detected", {}).get("data_layers", [])),
          str(profile.get("detected", {}).get("data_layers")))
    check("commands come from detection",
          profile.get("commands", {}).get("build") == "npm run build",
          str(profile.get("commands")))
    shutil.rmtree(d, ignore_errors=True)


def test_scaffolding():
    print("opt-in test and CI scaffolding")
    d = fixture("next")
    code, out = run([d, "APP", "-y", "--scaffold-tests", "--scaffold-ci", "github"])
    check("GitHub scaffolding exits 0", code == 0, out[-300:])
    test_plan = read(d, "docs/project/test-plan.md")
    profile = json.loads(read(d, ".ai-sdlc/testing-profile.json"))
    workflow = read(d, ".github/workflows/quality.yml")
    check("detected test plan instantiated",
          "## Detected profile" in test_plan and "Prisma" in test_plan)
    check("machine-readable profile records confirmation boundary",
          profile.get("confirmation_required") is True and "node" in profile.get("adapters", []))
    check("charter ticks generated test plan", "☑ test-plan" in read(d, "docs/project/charter.md"))
    check("GitHub CI uses detected commands",
          "actions/checkout@v4" in workflow and "npm run build" in workflow and
          "workflow_dispatch" in workflow and "  pull_request:" not in workflow)
    code, out = run([d, "APP", "-y", "--scaffold-ci", "gitlab"])
    check("GitLab CI adapter generated",
          code == 0 and "npm run build" in read(d, ".gitlab-ci.yml") and
          "when: manual" in read(d, ".gitlab-ci.yml"))
    with open(os.path.join(d, ".gitlab-ci.yml"), "a") as fh:
        fh.write("# project-owned marker\n")
    code, out = run([d, "APP", "-y", "--scaffold-ci", "gitlab"])
    check("existing CI is never overwritten",
          code == 0 and "project-owned marker" in read(d, ".gitlab-ci.yml"))
    shutil.rmtree(d, ignore_errors=True)

    d = fixture("next")
    before = files(d)
    code, out = run([d, "APP", "-y", "--dry-run", "--scaffold-tests",
                     "--scaffold-ci", "github"])
    check("scaffolding dry run writes nothing",
          code == 0 and files(d) == before and "would add" in out)
    shutil.rmtree(d, ignore_errors=True)

    d = tempfile.mkdtemp(prefix="sdlc-scaffold-empty-")
    code, out = run([d, "APP", "-y", "--scaffold-ci", "github"])
    check("CI scaffolding refuses an unknown command set",
          code == 1 and "no quality commands" in out and files(d) == 0)
    shutil.rmtree(d, ignore_errors=True)


def test_multiselect_and_review():
    print("wizard: multi-select, back, review")
    d = fixture("next")
    code, log = drive([d, "SHOP"], [
        ("What kind of project is this?", "1,3"),
        ("Project name", "Shopfront"),
        ("What is it, in one sentence", "b"),          # back to the name
        ("Project name", "Shopfront Two"),
    ])
    check("exit 0", code == 0, log[-400:])
    check("back re-asked the previous question", log.count("Project name") >= 2)
    charter = read(d, "docs/project/charter.md")
    check("multi-select unions the roles",
          "| devops-sre | ☑" in charter and "| ux-designer | ☑" in charter)
    check("detection reached the charter", "| Language / runtime | Node.js + TypeScript |" in charter)
    check("commands detected", "| `checks.unit` | npm run test |" in charter)
    check("architecture.md was seeded", "Stripe" in read(d, "docs/project/architecture.md"))
    shutil.rmtree(d, ignore_errors=True)


def test_review_jump():
    print("wizard: changing an answer from the review screen")
    d = fixture("fastapi")
    code, log = drive([d, "PIPE"], [
        ("What is it, in one sentence", "First answer"),
        ("Enter = write these files", "3"),
        ("What is it, in one sentence", "Second answer"),
    ])
    charter = read(d, "docs/project/charter.md")
    check("the jump re-asked one question", log.count("What is it, in one sentence") >= 2)
    check("the new answer won", "| **What it is** | Second answer |" in charter, charter[:0])
    check("everything else survived", "| **Work item prefix** | `PIPE` |" in charter)
    shutil.rmtree(d, ignore_errors=True)


def test_quit_writes_nothing():
    print("wizard: q at the review screen")
    d = fixture("fastapi")
    code, log = drive([d, "PIPE"], [("Enter = write these files", "q")])
    check("nothing written", files(d) == 1, "files=%d" % files(d))
    check("said so", "Nothing was written." in log)
    shutil.rmtree(d, ignore_errors=True)


def test_multilingual():
    print("wizard: multilingual")
    d = fixture("astro-i18n")
    code, log = drive([d, "SITE"], [("Languages, source language first", "fa, en")])
    charter = read(d, "docs/project/charter.md")
    check("locales detected and offered", "en, fa, tr" in log)
    check("ships in recorded", "| **Ships in** | fa, en |" in charter)
    check("source language recorded", "| **Source language** | fa |" in charter)
    check("rtl derived", "right-to-left for fa" in charter)
    check("localisation role active", "| localisation | ☑" in charter)
    skills = os.listdir(os.path.join(d, ".claude", "skills"))
    check("i18n skills installed", "sdlc-i18n-audit" in skills
          and "sdlc-translation-review" in skills)
    shutil.rmtree(d, ignore_errors=True)

    d = fixture("next")
    code, log = drive([d, "APP"], [("more than one language", "n")])
    charter = read(d, "docs/project/charter.md")
    check("single language: role off with a reason",
          "| localisation | ☐ |" in charter and "declared at install" in charter)
    skills = os.listdir(os.path.join(d, ".claude", "skills"))
    check("single language: no i18n skills", "sdlc-i18n-audit" not in skills)
    shutil.rmtree(d, ignore_errors=True)


def test_architecture():
    print("wizard: architecture seeding")
    d = fixture("monorepo")
    code, log = drive([d, "MONO"], [
        ("What must never go down", "the payment webhook consumer"),
        ("expensive to reverse", "the shared database between apps"),
    ])
    arch = read(d, "docs/project/architecture.md")
    check("components inventoried", "apps/web" in arch and "packages/ui" in arch)
    check("compose services inventoried", "`db`" in arch and "`cache`" in arch)
    check("answers recorded", "payment webhook consumer" in arch
          and "shared database between apps" in arch)
    check("marked as detection", "detected at install" in arch)
    check("artifact ticked in the charter",
          "☑ architecture" in read(d, "docs/project/charter.md"))
    shutil.rmtree(d, ignore_errors=True)


def main():
    for test in (test_guards, test_non_interactive, test_dry_run,
                 test_custom_docs_dir, test_managed_upgrade, test_command_detection,
                 test_stack_adapters, test_domain_detection,
                 test_role_and_skill_selection, test_profile, test_scaffolding,
                 test_multiselect_and_review, test_review_jump,
                 test_quit_writes_nothing,
                 test_multilingual, test_architecture):
        test()
    print("")
    if failures:
        print("%d failed: %s" % (len(failures), ", ".join(failures)))
        return 1
    print("all passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
