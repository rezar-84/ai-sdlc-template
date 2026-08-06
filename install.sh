#!/usr/bin/env bash
# Install the AI SDLC doc kit into a project.
#
#   ./install.sh <target-project-dir> [PREFIX] [--docs-dir <name>]
#
# Copies AGENTS.md to the project root and docs/ into the project, substitutes
# {{PROJECT_NAME}} and {{PREFIX}}, and never overwrites an existing file.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET=""
PREFIX=""
DOCS_DIR="docs"

usage() { echo "usage: $0 <target-project-dir> [PREFIX] [--docs-dir <name>]" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --docs-dir) [ -n "${2:-}" ] || usage; DOCS_DIR="$2"; shift 2 ;;
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

# Warn rather than clobber if docs/ already has content.
if [ -d "$TARGET/$DOCS_DIR" ] && [ -n "$(ls -A "$TARGET/$DOCS_DIR" 2>/dev/null)" ] && [ "$DOCS_DIR" = "docs" ]; then
  echo "note: $TARGET/docs already exists and is not empty."
  echo "      Existing files will be kept; only missing ones are added."
  echo "      To install alongside instead, re-run with: --docs-dir sdlc-docs"
  echo
fi

copied=0
skipped=0

install_file() {
  local src="$1" dest="$2"
  if [ -e "$dest" ]; then
    skipped=$((skipped + 1))
    echo "  skip (exists)  ${dest#"$TARGET"/}"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  copied=$((copied + 1))
  echo "  add            ${dest#"$TARGET"/}"
}

echo "Installing AI SDLC kit into $TARGET"
echo

install_file "$SRC/template/AGENTS.md" "$TARGET/AGENTS.md"

while IFS= read -r -d '' f; do
  rel="${f#"$SRC/template/docs/"}"
  install_file "$f" "$TARGET/$DOCS_DIR/$rel"
done < <(find "$SRC/template/docs" -type f -print0)

# Substitute placeholders in newly copied files only.
if [ "$copied" -gt 0 ]; then
  echo
  echo "Substituting {{PROJECT_NAME}} -> $PROJECT_NAME"
  find "$TARGET/$DOCS_DIR" "$TARGET/AGENTS.md" -type f -name '*.md' -print0 2>/dev/null \
    | xargs -0 sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g"

  if [ -n "$PREFIX" ]; then
    echo "Substituting {{PREFIX}}       -> $PREFIX"
    find "$TARGET/$DOCS_DIR" "$TARGET/AGENTS.md" -type f -name '*.md' -print0 2>/dev/null \
      | xargs -0 sed -i "s/{{PREFIX}}/$PREFIX/g"
  fi
fi

# Point CLAUDE.md at AGENTS.md if neither exists yet.
if [ ! -e "$TARGET/CLAUDE.md" ]; then
  printf '# Project instructions\n\nRead and follow `AGENTS.md` in this directory.\n' > "$TARGET/CLAUDE.md"
  echo "  add            CLAUDE.md (pointer to AGENTS.md)"
fi

echo
echo "Done: $copied added, $skipped skipped."
echo
echo "Next:"
n=1
echo "  $((n++)). Fill in $DOCS_DIR/project/charter.md — nothing else is reliable until you do."
if [ -z "$PREFIX" ]; then
  echo "  $((n++)). Replace {{PREFIX}} everywhere with your 2-4 letter work-item prefix."
fi
echo "  $((n++)). Optional slash commands:"
echo "       mkdir -p $TARGET/.claude/commands"
echo "       cp $SRC/optional/claude-commands/*.md $TARGET/.claude/commands/"
