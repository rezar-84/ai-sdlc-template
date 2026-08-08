#!/usr/bin/env bash
# Install the AI SDLC doc kit into a project.
#
#   ./install.sh <target-project-dir> [PREFIX] [--docs-dir <name>] [--upgrade]
#
# Copies AGENTS.md to the project root, docs/ into the project, and the slash commands
# into .claude/commands/. Substitutes {{PROJECT_NAME}} and {{PREFIX}} in everything it
# writes. Never overwrites an existing file unless --upgrade is given, and --upgrade
# only ever touches the portable standards -- your project records are never rewritten.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(cat "$SRC/VERSION")"
TARGET=""
PREFIX=""
DOCS_DIR="docs"
UPGRADE=0

usage() {
  cat >&2 <<EOF
usage: $0 <target-project-dir> [PREFIX] [--docs-dir <name>] [--upgrade]

  PREFIX        2-4 uppercase letters for work item IDs, e.g. ACME
  --docs-dir    install docs under a different name (default: docs)
  --upgrade     refresh docs/process/ and docs/roles/ from this version of the kit.
                Overwrites those two directories. Never touches docs/project/,
                AGENTS.md, or .claude/commands/.
EOF
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --docs-dir) [ -n "${2:-}" ] || usage; DOCS_DIR="$2"; shift 2 ;;
    --upgrade)  UPGRADE=1; shift ;;
    -h|--help)  usage ;;
    -*)         echo "unknown option: $1" >&2; usage ;;
    *)
      if   [ -z "$TARGET" ]; then TARGET="$1"
      elif [ -z "$PREFIX" ]; then PREFIX="$1"
      else echo "unexpected argument: $1" >&2; usage
      fi
      shift ;;
  esac
done

[ -n "$TARGET" ] || usage
[ -d "$TARGET" ] || { echo "no such directory: $TARGET" >&2; exit 1; }

TARGET="$(cd "$TARGET" && pwd)"
PROJECT_NAME="$(basename "$TARGET")"

# Files this run wrote, so substitution touches only those and never re-substitutes
# (or worse, mangles) a file the project already owns.
written=()

substitute() {
  local f="$1"
  sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$f"
  [ -n "$PREFIX" ] && sed -i "s/{{PREFIX}}/$PREFIX/g" "$f"
  sed -i "s/{{KIT_VERSION}}/$VERSION/g" "$f"
  return 0
}

copied=0
skipped=0
upgraded=0

install_file() {
  local src="$1" dest="$2"
  if [ -e "$dest" ]; then
    skipped=$((skipped + 1))
    echo "  skip (exists)  ${dest#"$TARGET"/}"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  substitute "$dest"
  copied=$((copied + 1))
  echo "  add            ${dest#"$TARGET"/}"
}

# --upgrade only. Overwrites unconditionally; callers must restrict it to process/ and
# roles/, which the kit owns and the project is told never to edit in place.
upgrade_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  substitute "$dest"
  upgraded=$((upgraded + 1))
  echo "  update         ${dest#"$TARGET"/}"
}

# ---------------------------------------------------------------- upgrade mode

if [ "$UPGRADE" -eq 1 ]; then
  if [ ! -d "$TARGET/$DOCS_DIR/process" ]; then
    echo "error: $TARGET/$DOCS_DIR/process does not exist -- nothing to upgrade." >&2
    echo "       Run without --upgrade to install for the first time." >&2
    exit 1
  fi

  # An unset PREFIX would write literal {{PREFIX}} over files that already have the
  # real one. Recover it from the installed charter rather than guessing.
  if [ -z "$PREFIX" ] && [ -f "$TARGET/$DOCS_DIR/project/charter.md" ]; then
    PREFIX="$(grep -m1 -oP '^\| \*\*Work item prefix\*\* \| `\K[A-Z]{2,4}' \
      "$TARGET/$DOCS_DIR/project/charter.md" 2>/dev/null || true)"
    [ -n "$PREFIX" ] && echo "Recovered prefix from charter: $PREFIX"
  fi
  if [ -z "$PREFIX" ]; then
    echo "error: cannot determine the work item prefix." >&2
    echo "       Pass it explicitly: $0 $TARGET <PREFIX> --upgrade" >&2
    exit 1
  fi

  echo "Upgrading AI SDLC kit in $TARGET to v$VERSION"
  echo "  (docs/process/ and docs/roles/ only -- project records untouched)"
  echo

  for dir in process roles; do
    while IFS= read -r -d '' f; do
      upgrade_file "$f" "$TARGET/$DOCS_DIR/$dir/${f#"$SRC/template/docs/$dir/"}"
    done < <(find "$SRC/template/docs/$dir" -type f -print0)
  done

  echo
  echo "Done: $upgraded updated."
  echo
  echo "AGENTS.md and .claude/commands/ were NOT touched -- they may carry project edits."
  echo "Diff them against the kit if this version changed them:"
  echo "  diff $SRC/template/AGENTS.md $TARGET/AGENTS.md"
  exit 0
fi

# ---------------------------------------------------------------- install mode

if [ -d "$TARGET/$DOCS_DIR" ] && [ -n "$(ls -A "$TARGET/$DOCS_DIR" 2>/dev/null)" ] && [ "$DOCS_DIR" = "docs" ]; then
  echo "note: $TARGET/docs already exists and is not empty."
  echo "      Existing files will be kept; only missing ones are added."
  echo "      To install alongside instead, re-run with: --docs-dir sdlc-docs"
  echo
fi

echo "Installing AI SDLC kit v$VERSION into $TARGET"
echo

install_file "$SRC/template/AGENTS.md" "$TARGET/AGENTS.md"

while IFS= read -r -d '' f; do
  install_file "$f" "$TARGET/$DOCS_DIR/${f#"$SRC/template/docs/"}"
done < <(find "$SRC/template/docs" -type f -print0)

# Slash commands. These must be substituted too -- they name {{PREFIX}}-### paths.
for f in "$SRC"/optional/claude-commands/*.md; do
  install_file "$f" "$TARGET/.claude/commands/$(basename "$f")"
done

# Point CLAUDE.md at AGENTS.md if it does not exist yet.
if [ ! -e "$TARGET/CLAUDE.md" ]; then
  printf '# Project instructions\n\nRead and follow `AGENTS.md` in this directory.\n' > "$TARGET/CLAUDE.md"
  echo "  add            CLAUDE.md (pointer to AGENTS.md)"
fi

echo
echo "Done: $copied added, $skipped skipped."
echo

if [ -z "$PREFIX" ]; then
  echo "WARNING: no PREFIX given. {{PREFIX}} is still literal in the installed files."
  echo "         Replace it before use, or re-run against a clean target with a prefix."
  echo
fi

echo "Next:"
echo "  1. Fill in $DOCS_DIR/project/charter.md -- nothing else is reliable until you do."
echo "  2. Fill in the Project overrides section at the end of AGENTS.md."
echo "  3. Check nothing was left unsubstituted:"
echo "       grep -rn '{{' $TARGET/$DOCS_DIR $TARGET/AGENTS.md $TARGET/.claude/commands"
echo
echo "Later, to pick up a newer version of the portable standards:"
echo "  $0 $TARGET ${PREFIX:-<PREFIX>} --upgrade"
