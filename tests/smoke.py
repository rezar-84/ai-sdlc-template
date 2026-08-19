#!/usr/bin/env python3
"""Smoke tests for install.py. Standard library only.

    python3 tests/smoke.py [-v]

Every test installs into a throwaway directory under the system temp dir. The wizard runs
through a pty, driven by rules of the form "prompt substring" -> "answer", so the tests
exercise the same prompt loop a person sees rather than a private API.
"""

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


def test_non_interactive():
    print("non-interactive (-y)")
    d = tempfile.mkdtemp(prefix="sdlc-y-")
    code, out = run([d, "ACME", "-y"])
    check("exit 0", code == 0)
    check("no leftover placeholders", "{{" not in read(d, "docs/project/charter.md"))
    check("charter not tailored", "_(one sentence a stranger would understand)_"
          in read(d, "docs/project/charter.md"))
    skills = sorted(os.listdir(os.path.join(d, ".claude", "skills")))
    check("only answer-independent skills", skills == ["sdlc-adr", "sdlc-charter-audit",
                                                       "sdlc-evidence-check", "sdlc-intake"],
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
    check("the second answer won", "| **Project** | Shopfront Two |" in charter)
    check("multi-select unions the roles",
          "| devops-sre | ☑" in charter and "| ux-designer | ☑" in charter)
    check("detection reached the charter", "| Language / runtime | Node.js + TypeScript |" in charter)
    check("commands detected", "| `checks.unit` | npm test |" in charter)
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
