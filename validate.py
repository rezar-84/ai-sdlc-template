#!/usr/bin/env python3
"""Validate the distributable kit using only the Python standard library."""

import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent
ALLOWED_PLACEHOLDERS = {"DOCS_DIR", "KIT_VERSION", "PLACEHOLDER", "PREFIX", "PROJECT_NAME"}
PLACEHOLDER = re.compile(r"\{\{([A-Z][A-Z0-9_]*)\}\}")
LINK = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
VERSION_RE = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")


def markdown_files():
    yield ROOT / "README.md"
    for base in (ROOT / "template", ROOT / "optional"):
        for path in sorted(base.rglob("*.md")):
            yield path


def frontmatter_fields(path):
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "---":
        return set()
    try:
        end = lines.index("---", 1)
    except ValueError:
        return set()
    return {line.split(":", 1)[0].strip() for line in lines[1:end] if ":" in line}


def main():
    errors = []
    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    if not VERSION_RE.match(version):
        errors.append("VERSION is not semantic major.minor.patch: %r" % version)

    required_root = ("LICENSE", "CONTRIBUTING.md", "SECURITY.md", "CHANGELOG.md")
    for name in required_root:
        if not (ROOT / name).is_file():
            errors.append("missing repository file: %s" % name)

    for path in markdown_files():
        text = path.read_text(encoding="utf-8")
        unknown = sorted(set(PLACEHOLDER.findall(text)) - ALLOWED_PLACEHOLDERS)
        if unknown:
            errors.append("%s has unknown placeholders: %s" %
                          (path.relative_to(ROOT), ", ".join(unknown)))
        for target in LINK.findall(text):
            clean = target.split("#", 1)[0]
            if not clean or "://" in clean or clean.startswith(("#", "mailto:")):
                continue
            if not (path.parent / clean).resolve().exists():
                errors.append("%s has broken link: %s" % (path.relative_to(ROOT), target))

    for path in sorted((ROOT / "template" / "docs" / "project").glob("*.md")):
        fields = frontmatter_fields(path)
        missing = {"status", "owner", "last-reviewed"} - fields
        if missing:
            errors.append("%s missing frontmatter fields: %s" %
                          (path.relative_to(ROOT), ", ".join(sorted(missing))))

    for path in sorted((ROOT / "optional" / "skills").glob("*/SKILL.md")):
        fields = frontmatter_fields(path)
        missing = {"name", "description"} - fields
        if missing:
            errors.append("%s missing skill frontmatter: %s" %
                          (path.relative_to(ROOT), ", ".join(sorted(missing))))

    # Exercise the advertised custom directory, not just source text. The installed
    # contract and commands must point at the actual location and contain no placeholders.
    target = Path(tempfile.mkdtemp(prefix="sdlc-validate-"))
    try:
        proc = subprocess.run(
            [sys.executable, str(ROOT / "install.py"), str(target), "VAL", "-y",
             "--docs-dir", "handbook"],
            cwd=str(ROOT), stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            universal_newlines=True)
        if proc.returncode:
            errors.append("custom-directory install failed: %s" % proc.stdout[-500:])
        installed = [target / "AGENTS.md"]
        installed.extend(sorted((target / ".claude" / "commands").glob("*.md")))
        for path in installed:
            text = path.read_text(encoding="utf-8") if path.exists() else ""
            if "{{" in text:
                errors.append("%s contains an unresolved placeholder" % path.relative_to(target))
            if re.search(r"(?<![A-Za-z0-9_-])docs/", text):
                errors.append("%s contains a stale docs/ path" % path.relative_to(target))
            if "handbook/" not in text:
                errors.append("%s does not reference handbook/" % path.relative_to(target))
        manifest = target / ".ai-sdlc" / "manifest.json"
        try:
            data = json.loads(manifest.read_text(encoding="utf-8"))
            if data.get("kit_version") != version or not data.get("files"):
                errors.append("installed manifest has wrong version or no managed files")
        except (IOError, OSError, ValueError):
            errors.append("installed manifest is missing or invalid")
    finally:
        shutil.rmtree(str(target), ignore_errors=True)

    if errors:
        for error in errors:
            print("FAIL  %s" % error)
        print("%d validation error(s)" % len(errors))
        return 1
    print("all kit validations passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
