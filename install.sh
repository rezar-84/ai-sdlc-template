#!/usr/bin/env bash
# Install the AI SDLC doc kit into a project.
#
#   ./install.sh [target-project-dir] [PREFIX] [--docs-dir <name>] [-y] [--upgrade]
#
# Run in a terminal, it opens a short guided setup: what the project is, what you are
# building, and the handful of answers that decide which roles and rules apply. Every
# question has a default and Enter takes it. Those answers are written into the charter
# and AGENTS.md, so the kit arrives already fitted to the project instead of arriving as
# a stack of empty tables. Piped/redirected stdin, or -y, takes every default silently.
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
DOCS_DIR=""
DOCS_DIR_GIVEN=0
UPGRADE=0
ASSUME_YES=0
WANT_SKILLS=1

usage() {
  cat >&2 <<EOF
usage: $0 [target-project-dir] [PREFIX] [--docs-dir <name>] [-y] [--upgrade]

  target dir    defaults to the current directory when a terminal is attached
  PREFIX        2-4 uppercase letters for work item IDs, e.g. ACME
  --docs-dir    install docs under a different name (default: docs)
  -y, --yes     no questions: take every default (also implied when stdin is not a
                terminal, so CI and piped runs never hang)
  --no-skills   do not install anything into .claude/skills/
  --upgrade     refresh docs/process/, docs/roles/, and any already-installed skill
                from this version of the kit. Overwrites exactly those. Never touches
                docs/project/, AGENTS.md, or .claude/commands/, and never adds a skill
                the project did not choose.
EOF
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --docs-dir) [ -n "${2:-}" ] || usage; DOCS_DIR="$2"; DOCS_DIR_GIVEN=1; shift 2 ;;
    --upgrade)  UPGRADE=1; shift ;;
    -y|--yes|--non-interactive) ASSUME_YES=1; shift ;;
    --no-skills) WANT_SKILLS=0; shift ;;
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

# A question nobody is there to answer is a hang, not a prompt. Interactive means: a
# real terminal on stdin, not -y, and not --upgrade (which is a mechanical refresh).
INTERACTIVE=0
if [ "$ASSUME_YES" -eq 0 ] && [ "$UPGRADE" -eq 0 ] && [ -t 0 ]; then
  INTERACTIVE=1
fi

if [ -z "$TARGET" ]; then
  if [ "$INTERACTIVE" -eq 1 ]; then TARGET="."; else usage; fi
fi
[ -d "$TARGET" ] || { echo "no such directory: $TARGET" >&2; exit 1; }

TARGET="$(cd "$TARGET" && pwd)"
PROJECT_NAME="$(basename "$TARGET")"
[ -n "$DOCS_DIR" ] || DOCS_DIR="docs"

# ---------------------------------------------------------------- output helpers

if [ -t 1 ]; then
  C_B="$(printf '\033[1m')"; C_D="$(printf '\033[2m')"; C_R="$(printf '\033[0m')"
else
  C_B=""; C_D=""; C_R=""
fi

SKIP_ALL=0
SKIP_SECTION=0

section() {
  SKIP_SECTION=0
  [ "$INTERACTIVE" -eq 1 ] || return 0
  printf '\n%s-- %s %s\n' "$C_B" "$1" "$C_R"
}

note() { [ "$INTERACTIVE" -eq 1 ] && printf '  %s%s%s\n' "$C_D" "$1" "$C_R"; return 0; }

# ask VAR "question" "default" ["hint"]
#   Enter accepts the default; "-" clears the field; "s" takes defaults for the rest of
#   this section; "S" takes defaults for the rest of the wizard.
ask() {
  local __var="$1" q="$2" def="${3:-}" hint="${4:-}" ans=""
  if [ "$INTERACTIVE" -eq 0 ] || [ "$SKIP_ALL" -eq 1 ] || [ "$SKIP_SECTION" -eq 1 ]; then
    printf -v "$__var" '%s' "$def"; return 0
  fi
  [ -n "$hint" ] && printf '  %s%s%s\n' "$C_D" "$hint" "$C_R"
  if [ -n "$def" ]; then
    printf '  %s %s[%s]%s ' "$q" "$C_D" "$def" "$C_R"
  else
    printf '  %s %s[blank]%s ' "$q" "$C_D" "$C_R"
  fi
  IFS= read -r ans || ans=""
  case "$ans" in
    "") ans="$def" ;;
    -)  ans="" ;;
    s)  SKIP_SECTION=1; ans="$def"; note "-> rest of this section: defaults" ;;
    S)  SKIP_ALL=1;     ans="$def"; note "-> rest of the setup: defaults" ;;
  esac
  printf -v "$__var" '%s' "$ans"
}

# ask_yn VAR "question" y|n  -> sets VAR to "y" or "n"
ask_yn() {
  local __var="$1" q="$2" def="$3" ans="" prompt
  if [ "$def" = "y" ]; then prompt="Y/n"; else prompt="y/N"; fi
  if [ "$INTERACTIVE" -eq 0 ] || [ "$SKIP_ALL" -eq 1 ] || [ "$SKIP_SECTION" -eq 1 ]; then
    printf -v "$__var" '%s' "$def"; return 0
  fi
  while :; do
    printf '  %s %s[%s]%s ' "$q" "$C_D" "$prompt" "$C_R"
    IFS= read -r ans || ans=""
    case "$ans" in
      "")        ans="$def"; break ;;
      y|Y|yes)   ans="y"; break ;;
      n|N|no)    ans="n"; break ;;
      s)         SKIP_SECTION=1; ans="$def"; note "-> rest of this section: defaults"; break ;;
      S)         SKIP_ALL=1;     ans="$def"; note "-> rest of the setup: defaults"; break ;;
      *)         note "answer y or n (Enter = $def)" ;;
    esac
  done
  printf -v "$__var" '%s' "$ans"
}

# ask_key VAR "question" "allowed-letters" "default-letter"
ask_key() {
  local __var="$1" q="$2" keys="$3" def="$4" ans=""
  if [ "$INTERACTIVE" -eq 0 ] || [ "$SKIP_ALL" -eq 1 ] || [ "$SKIP_SECTION" -eq 1 ]; then
    printf -v "$__var" '%s' "$def"; return 0
  fi
  while :; do
    printf '  %s %s[%s]%s ' "$q" "$C_D" "$def" "$C_R"
    IFS= read -r ans || ans=""
    [ -z "$ans" ] && ans="$def"
    if [ "$ans" = "S" ]; then SKIP_ALL=1; ans="$def"; note "-> rest of the setup: defaults"; break; fi
    case "$keys" in *"$ans"*) [ -n "$ans" ] && break ;; esac
    note "answer one of: $keys"
  done
  printf -v "$__var" '%s' "$ans"
}

# menu VAR "question" <default-index> "label" ...
menu() {
  local __var="$1" q="$2" def="$3"; shift 3
  local items=("$@") i ans=""
  if [ "$INTERACTIVE" -eq 0 ] || [ "$SKIP_ALL" -eq 1 ] || [ "$SKIP_SECTION" -eq 1 ]; then
    printf -v "$__var" '%s' "$def"; return 0
  fi
  printf '  %s\n' "$q"
  for i in "${!items[@]}"; do
    printf '    %s%2d%s  %s\n' "$C_D" "$((i + 1))" "$C_R" "${items[$i]}"
  done
  while :; do
    printf '  choice %s[%s]%s ' "$C_D" "$def" "$C_R"
    IFS= read -r ans || ans=""
    case "$ans" in
      "") ans="$def"; break ;;
      S)  SKIP_ALL=1; ans="$def"; note "-> rest of the setup: defaults"; break ;;
      s)  SKIP_SECTION=1; ans="$def"; note "-> rest of this section: defaults"; break ;;
      *[!0-9]*|"") note "type a number between 1 and ${#items[@]}" ;;
      *)  if [ "$ans" -ge 1 ] && [ "$ans" -le "${#items[@]}" ]; then break; fi
          note "type a number between 1 and ${#items[@]}" ;;
    esac
  done
  printf -v "$__var" '%s' "$ans"
}

# ---------------------------------------------------------------- file writers

# Values now come from free-text answers, so they may contain sed metacharacters.
esc_repl() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }

substitute() {
  local f="$1"
  sed -i "s|{{PROJECT_NAME}}|$(esc_repl "$PROJECT_NAME")|g" "$f"
  [ -n "$PREFIX" ] && sed -i "s|{{PREFIX}}|$(esc_repl "$PREFIX")|g" "$f"
  sed -i "s|{{KIT_VERSION}}|$(esc_repl "$VERSION")|g" "$f"
  sed -i "s|{{DOCS_DIR}}|$(esc_repl "$DOCS_DIR")|g" "$f"
  return 0
}

# fill_row FILE "first cell" "value" -- rewrites the first two-column table row whose
# first cell matches. Values travel through the environment, not awk -v, so backslashes
# in an answer survive verbatim.
fill_row() {
  local f="$1" label="$2" value="$3"
  [ -n "$value" ] || return 0
  [ -f "$f" ] || return 0
  LBL="$label" VAL="$value" awk '
    BEGIN { lbl = "| " ENVIRON["LBL"] " |"; done = 0 }
    !done && index($0, lbl) == 1 { print lbl " " ENVIRON["VAL"] " |"; done = 1; next }
    { print }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

# set_role FILE role 1|0 "reason if inactive" -- ticks the Active cell and fills the
# reason cell of the four-column role row, leaving the "Active if" column alone.
set_role() {
  local f="$1" role="$2" act="$3" reason="$4"
  [ -f "$f" ] || return 0
  ROLE="$role" ACT="$act" RSN="$reason" TICK="☑" UNTICK="☐" awk '
    BEGIN { role = "| " ENVIRON["ROLE"] " | "; done = 0 }
    !done && index($0, role) == 1 {
      n = split($0, a, "|")
      if (n >= 6) {
        a[3] = (ENVIRON["ACT"] == "1") ? " " ENVIRON["TICK"] " " : " " ENVIRON["UNTICK"] " "
        a[5] = (ENVIRON["ACT"] == "1") ? " " : " " ENVIRON["RSN"] " "
        line = ""
        for (i = 2; i < n; i++) line = line "|" a[i]
        print line "|"
        done = 1
        next
      }
    }
    { print }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

# fill_field FILE "**Label:**" "value" -- replaces a bold label followed by a possibly
# multi-line _(fill in -- ...)_ placeholder, as used in AGENTS.md section 9.
fill_field() {
  local f="$1" label="$2" value="$3"
  [ -n "$value" ] || return 0
  [ -f "$f" ] || return 0
  LBL="$label" VAL="$value" awk '
    BEGIN { lbl = ENVIRON["LBL"]; done = 0; skip = 0 }
    skip { if ($0 == "") { skip = 0; print } ; next }
    !done && index($0, lbl) == 1 { print lbl " " ENVIRON["VAL"]; done = 1; skip = 1; next }
    { print }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

# ---------------------------------------------------------------- detection
# All read-only, all best-effort. Anything not detected stays empty: the charter treats
# a blank cell as Unknown, which is recoverable, while a wrong command cell produces
# confidently false "verified" claims, which is not.

has_dep() { [ -f "$TARGET/package.json" ] && grep -qE "\"$1\"[[:space:]]*:" "$TARGET/package.json"; }
has_pydep() {
  grep -qiE "(^|[^a-z0-9_-])$1([^a-z0-9_-]|$)" \
    "$TARGET/pyproject.toml" "$TARGET/requirements.txt" "$TARGET/setup.py" 2>/dev/null
}
has_script() {
  [ -f "$TARGET/package.json" ] || return 1
  sed -n '/"scripts"[[:space:]]*:/,/}/p' "$TARGET/package.json" | grep -qE "\"$1\"[[:space:]]*:"
}
add_to() { # add_to VAR "value" -- comma-appends, skipping empties and duplicates
  local __var="$1" val="$2" cur="${!1}"
  [ -n "$val" ] || return 0
  case ", $cur," in *", $val,"*) return 0 ;; esac
  if [ -z "$cur" ]; then printf -v "$__var" '%s' "$val"
  else printf -v "$__var" '%s' "$cur, $val"; fi
}

DET_LANG=""; DET_PM=""; DET_FW=""; DET_DB=""; DET_AUTH=""; DET_HOST=""; DET_CI=""; DET_TEST=""
DET_INSTALL=""; DET_RUN=""; DET_FORMAT=""; DET_LINT=""; DET_TYPECHECK=""
DET_UNIT=""; DET_BUILD=""; DET_SCAN=""; DET_E2E=""

detect_stack() {
  local t="$TARGET" npx="npx"

  if [ -f "$t/package.json" ]; then
    if [ -f "$t/tsconfig.json" ]; then DET_LANG="Node.js + TypeScript"; else DET_LANG="Node.js"; fi
    if   [ -f "$t/bun.lockb" ] || [ -f "$t/bun.lock" ]; then DET_PM="bun"
    elif [ -f "$t/pnpm-lock.yaml" ]; then DET_PM="pnpm"
    elif [ -f "$t/yarn.lock" ];      then DET_PM="yarn"
    else DET_PM="npm"
    fi
    has_dep next            && add_to DET_FW "Next.js"
    has_dep nuxt            && add_to DET_FW "Nuxt"
    has_dep astro           && add_to DET_FW "Astro"
    has_dep "@remix-run/react" && add_to DET_FW "Remix"
    has_dep "@tanstack/react-start" && add_to DET_FW "TanStack Start"
    has_dep "@nestjs/core"  && add_to DET_FW "NestJS"
    has_dep "@angular/core" && add_to DET_FW "Angular"
    has_dep express         && add_to DET_FW "Express"
    has_dep fastify         && add_to DET_FW "Fastify"
    has_dep svelte          && add_to DET_FW "Svelte"
    has_dep vue             && add_to DET_FW "Vue"
    [ -z "$DET_FW" ] && has_dep react && add_to DET_FW "React"
    has_dep vite            && add_to DET_FW "Vite"
    has_dep tailwindcss     && add_to DET_FW "Tailwind CSS"

    if has_dep "@prisma/client" || [ -f "$t/prisma/schema.prisma" ]; then
      local prov=""
      [ -f "$t/prisma/schema.prisma" ] && prov="$(grep -m1 -E '^\s*provider\s*=' "$t/prisma/schema.prisma" | sed -e 's/.*= *"//' -e 's/".*//' || true)"
      if [ -n "$prov" ]; then add_to DET_DB "Prisma ($prov)"; else add_to DET_DB "Prisma"; fi
    fi
    has_dep "drizzle-orm"    && add_to DET_DB "Drizzle"
    has_dep "@supabase/supabase-js" && add_to DET_DB "Supabase (Postgres)"
    has_dep mongoose         && add_to DET_DB "MongoDB"
    has_dep pg               && add_to DET_DB "PostgreSQL"
    has_dep mysql2           && add_to DET_DB "MySQL"
    { has_dep "better-sqlite3" || has_dep sqlite3; } && add_to DET_DB "SQLite"

    has_dep "next-auth"      && add_to DET_AUTH "Auth.js / NextAuth"
    has_dep "@clerk/nextjs"  && add_to DET_AUTH "Clerk"
    has_dep "@supabase/supabase-js" && add_to DET_AUTH "Supabase Auth"
    has_dep passport         && add_to DET_AUTH "Passport"
    has_dep "@nestjs/jwt"    && add_to DET_AUTH "JWT (@nestjs/jwt)"

    has_dep vitest     && add_to DET_TEST "Vitest"
    has_dep jest       && add_to DET_TEST "Jest"
    has_dep mocha      && add_to DET_TEST "Mocha"
    has_dep "@playwright/test" && add_to DET_TEST "Playwright"
    has_dep cypress    && add_to DET_TEST "Cypress"

    has_script dev   && DET_RUN="$DET_PM run dev"
    [ -z "$DET_RUN" ] && has_script start && DET_RUN="$DET_PM start"
    has_script format && DET_FORMAT="$DET_PM run format"
    has_script lint   && DET_LINT="$DET_PM run lint"
    has_script build  && DET_BUILD="$DET_PM run build"
    has_script typecheck && DET_TYPECHECK="$DET_PM run typecheck"
    [ -z "$DET_TYPECHECK" ] && [ -f "$t/tsconfig.json" ] && DET_TYPECHECK="$npx tsc --noEmit"
    has_script test   && DET_UNIT="$DET_PM test"
    has_script e2e    && DET_E2E="$DET_PM run e2e"
    [ -z "$DET_E2E" ] && has_dep "@playwright/test" && DET_E2E="$npx playwright test"
    case "$DET_PM" in
      npm)  DET_INSTALL="npm install";  DET_SCAN="npm audit --audit-level=high" ;;
      pnpm) DET_INSTALL="pnpm install"; DET_SCAN="pnpm audit --audit-level high" ;;
      yarn) DET_INSTALL="yarn install" ;;
      bun)  DET_INSTALL="bun install" ;;
    esac
  fi

  if [ -f "$t/pyproject.toml" ] || [ -f "$t/requirements.txt" ] || [ -f "$t/setup.py" ]; then
    add_to DET_LANG "Python"
    if   [ -f "$t/uv.lock" ];     then add_to DET_PM "uv";      DET_INSTALL="${DET_INSTALL:-uv sync}"
    elif [ -f "$t/poetry.lock" ]; then add_to DET_PM "Poetry";  DET_INSTALL="${DET_INSTALL:-poetry install}"
    elif [ -f "$t/Pipfile" ];     then add_to DET_PM "pipenv";  DET_INSTALL="${DET_INSTALL:-pipenv install}"
    elif [ -f "$t/requirements.txt" ]; then add_to DET_PM "pip"; DET_INSTALL="${DET_INSTALL:-pip install -r requirements.txt}"
    fi
    has_pydep django  && add_to DET_FW "Django"
    has_pydep fastapi && add_to DET_FW "FastAPI"
    has_pydep flask   && add_to DET_FW "Flask"
    if has_pydep pytest || [ -f "$t/pytest.ini" ]; then
      add_to DET_TEST "pytest"; DET_UNIT="${DET_UNIT:-pytest}"
    fi
    has_pydep ruff  && { DET_LINT="${DET_LINT:-ruff check .}"; DET_FORMAT="${DET_FORMAT:-ruff format .}"; }
    has_pydep mypy  && DET_TYPECHECK="${DET_TYPECHECK:-mypy .}"
  fi

  if [ -f "$t/go.mod" ]; then
    add_to DET_LANG "Go"; add_to DET_PM "go modules"; add_to DET_TEST "go test"
    DET_INSTALL="${DET_INSTALL:-go mod download}"
    DET_UNIT="${DET_UNIT:-go test ./...}"
    DET_BUILD="${DET_BUILD:-go build ./...}"
    DET_FORMAT="${DET_FORMAT:-gofmt -l .}"
    DET_LINT="${DET_LINT:-go vet ./...}"
  fi
  if [ -f "$t/Cargo.toml" ]; then
    add_to DET_LANG "Rust"; add_to DET_PM "cargo"; add_to DET_TEST "cargo test"
    DET_INSTALL="${DET_INSTALL:-cargo fetch}"
    DET_UNIT="${DET_UNIT:-cargo test}"
    DET_BUILD="${DET_BUILD:-cargo build --release}"
    DET_FORMAT="${DET_FORMAT:-cargo fmt --check}"
    DET_LINT="${DET_LINT:-cargo clippy}"
  fi
  if [ -f "$t/composer.json" ]; then
    add_to DET_LANG "PHP"; add_to DET_PM "Composer"
    DET_INSTALL="${DET_INSTALL:-composer install}"
    grep -qs 'laravel/framework' "$t/composer.json" && add_to DET_FW "Laravel"
  fi
  if [ -f "$t/Gemfile" ]; then
    add_to DET_LANG "Ruby"; add_to DET_PM "Bundler"
    DET_INSTALL="${DET_INSTALL:-bundle install}"
    grep -qs "rails" "$t/Gemfile" && add_to DET_FW "Rails"
  fi
  if [ -f "$t/pom.xml" ]; then add_to DET_LANG "Java"; add_to DET_PM "Maven"; DET_UNIT="${DET_UNIT:-mvn test}"; fi
  if [ -f "$t/build.gradle" ] || [ -f "$t/build.gradle.kts" ]; then
    add_to DET_LANG "Java / Kotlin"; add_to DET_PM "Gradle"; DET_UNIT="${DET_UNIT:-./gradlew test}"
  fi
  if ls "$t"/*.csproj >/dev/null 2>&1 || ls "$t"/*.sln >/dev/null 2>&1; then
    add_to DET_LANG "C# / .NET"; add_to DET_PM "NuGet"
    DET_INSTALL="${DET_INSTALL:-dotnet restore}"; DET_UNIT="${DET_UNIT:-dotnet test}"
    DET_BUILD="${DET_BUILD:-dotnet build}"
  fi

  [ -f "$t/vercel.json" ]   && add_to DET_HOST "Vercel"
  [ -f "$t/netlify.toml" ]  && add_to DET_HOST "Netlify"
  [ -f "$t/fly.toml" ]      && add_to DET_HOST "Fly.io"
  [ -f "$t/wrangler.toml" ] && add_to DET_HOST "Cloudflare Workers"
  [ -f "$t/render.yaml" ]   && add_to DET_HOST "Render"
  [ -f "$t/Procfile" ]      && add_to DET_HOST "Heroku-style buildpack host"
  { [ -f "$t/Dockerfile" ] || [ -f "$t/docker-compose.yml" ] || [ -f "$t/compose.yaml" ]; } && add_to DET_HOST "Docker"

  [ -d "$t/.github/workflows" ] && add_to DET_CI "GitHub Actions"
  [ -f "$t/.gitlab-ci.yml" ]    && add_to DET_CI "GitLab CI"
  [ -f "$t/Jenkinsfile" ]       && add_to DET_CI "Jenkins"
  [ -d "$t/.circleci" ]         && add_to DET_CI "CircleCI"
  [ -f "$t/azure-pipelines.yml" ] && add_to DET_CI "Azure Pipelines"
  return 0
}

# Managed platforms (AI app builders / cloud IDEs) that co-own a repository. Detection
# is best-effort and read-only -- it seeds the charter's Managed platform row and the
# advice printed at the end.
PLATFORMS=""
if [ -e "$TARGET/.replit" ] || [ -e "$TARGET/replit.nix" ] || [ -e "$TARGET/replit.md" ]; then
  PLATFORMS="$PLATFORMS Replit"
fi
if [ -d "$TARGET/.lovable" ] || grep -qs 'lovable' "$TARGET/package.json"; then
  PLATFORMS="$PLATFORMS Lovable"
fi
if [ -d "$TARGET/.bolt" ]; then PLATFORMS="$PLATFORMS Bolt"; fi
if [ -d "$TARGET/.idx" ]; then PLATFORMS="$PLATFORMS Firebase-Studio"; fi
if [ -e "$TARGET/glitch.json" ]; then PLATFORMS="$PLATFORMS Glitch"; fi
if [ -e "$TARGET/sandbox.config.json" ] || [ -d "$TARGET/.codesandbox" ]; then
  PLATFORMS="$PLATFORMS CodeSandbox"
fi
PLATFORMS="${PLATFORMS# }"

# ---------------------------------------------------------------- skill catalogue
# Skills live in optional/skills/<name>/SKILL.md and are model-invoked: they fire when
# the situation appears, where the slash commands wait to be typed. Which ones a project
# needs follows from the same answers that decide the active roles, so they are
# evaluated, not dumped -- an unused skill is noise in every future context window.

SK_NAME=(); SK_WHY=(); SK_ON=(); SK_OFF=()

sk() { # sk <name> <on:1|0> "<why it is on>" "<why it is off>"
  SK_NAME+=("$1"); SK_ON+=("$2"); SK_WHY+=("$3"); SK_OFF+=("$4")
}

skill_eval() {
  SK_NAME=(); SK_WHY=(); SK_ON=(); SK_OFF=()
  local ui=0 vis=0 pub=0 dep=0 pii=0 plat=0
  [ "$F_UI" = "y" ]     && ui=1
  [ "$F_VISUAL" = "y" ] && vis=1
  [ "$F_PUBLIC" = "y" ] && pub=1
  [ "$F_DEPLOY" = "y" ] && dep=1
  [ "$F_PII" = "y" ]    && pii=1
  [ -n "$PLATFORM" ] && [ "$PLATFORM" != "none" ] && plat=1

  sk sdlc-intake            1 "every request: tier, ID, reading list before any code" ""
  sk sdlc-evidence-check    1 "fires before any 'done / passing / verified' claim" ""
  sk sdlc-charter-audit     1 "keeps the charter's blank and stale cells visible" ""
  sk sdlc-adr               1 "captures durable decisions instead of losing them" ""
  sk sdlc-accessibility-audit "$ui"  "there is an interface to audit" "no user interface in this project"
  sk sdlc-design-review     "$vis"   "there is a visual interface to hold to the design system" "no visual interface"
  sk sdlc-content-seo       "$pub"   "content is publicly discoverable" "nothing is publicly discoverable"
  sk sdlc-privacy-review    "$pii"   "personal data is held or processed" "no personal data held"
  sk sdlc-threat-model      "$(( pii || dep ))" "there is an exposed or data-holding surface to model" "nothing deployed and no personal data"
  sk sdlc-release           "$dep"   "this deploys somewhere and needs a repeatable release" "nothing is deployed from here"
  sk sdlc-postmortem        "$dep"   "running software eventually has incidents" "nothing is operated from here"
  sk sdlc-managed-platform  "$plat"  "a platform co-owns this repository" "plain git repository, no co-owning platform"
  return 0
}

# ---------------------------------------------------------------- the guided setup

WHAT_IS=""; OWNER=""; REPO_URL=""
F_UI="n"; F_VISUAL="n"; F_PUBLIC="n"; F_DEPLOY="n"; F_PII="n"; F_CONV="n"
S_LANG=""; S_PM=""; S_FW=""; S_DB=""; S_AUTH=""; S_HOST=""; S_CI=""; S_TEST=""
C_INSTALL=""; C_RUN=""; C_FORMAT=""; C_LINT=""; C_TYPECHECK=""
C_UNIT=""; C_BUILD=""; C_SCAN=""; C_E2E=""
BRANCH=""; DIRECT_COMMITS="n"; APPROVERS=""; STALENESS="90 days"
APPROVAL_FOR=""; FORBIDDEN=""; PLATFORM=""
A11Y_TARGET=""; PRIMARY_OUTCOME=""
WANT_COMMANDS="y"; WANT_CLAUDEMD="y"; SKILLS=""

git_cfg() { git -C "$TARGET" "$@" 2>/dev/null || true; }

# An install may already be here under docs/ or sdlc-docs/. Reusing it is the difference
# between filling in what is missing and quietly building a second, competing doc tree.
find_existing_docs() {
  local d
  for d in "$DOCS_DIR" docs sdlc-docs; do
    if [ -f "$TARGET/$d/process/00-operating-model.md" ]; then printf '%s' "$d"; return 0; fi
  done
  printf ''
}

recover_prefix() {
  local charter="$TARGET/$1/project/charter.md"
  [ -f "$charter" ] || return 0
  grep -m1 -oP '^\| \*\*Work item prefix\*\* \| `\K[A-Z]{2,4}' "$charter" 2>/dev/null || true
}

derive_prefix() {
  local p
  p="$(printf '%s' "$PROJECT_NAME" | tr -cd '[:alnum:]' | tr '[:lower:]' '[:upper:]')"
  p="${p:0:4}"
  [ "${#p}" -ge 2 ] || p="PRJ"
  printf '%s' "$p"
}

# What the repository looks like decides which project type is offered first. A default
# that matches what is actually there is the difference between Enter being an answer and
# Enter being a shrug.
default_ptype() {
  case "$DET_FW" in
    *Astro*) printf '2'; return 0 ;;
    *Next.js*|*Nuxt*|*Remix*|*"TanStack Start"*|*Angular*|*Svelte*|*Vue*|*React*) printf '1'; return 0 ;;
    *NestJS*|*Express*|*Fastify*|*FastAPI*|*Django*|*Flask*|*Laravel*|*Rails*) printf '3'; return 0 ;;
  esac
  if [ -z "$DET_LANG" ]; then printf '7'; return 0; fi
  if [ -n "$DET_HOST" ]; then printf '3'; else printf '4'; fi
}

wizard() {
  local ans=""
  detect_stack

  if [ "$INTERACTIVE" -eq 1 ]; then
    printf '\n%sAI SDLC kit v%s -- guided setup%s\n' "$C_B" "$VERSION" "$C_R"
    printf '%s  Enter = the value in brackets   -  = leave blank\n' "$C_D"
    printf '  s     = defaults for the rest of a section   S = defaults for everything%s\n' "$C_R"
  fi

  # -- project ---------------------------------------------------------------
  section "1/7  Project"
  ask PROJECT_NAME "Project name" "$PROJECT_NAME"
  ask WHAT_IS      "What is it, in one sentence" "" "One line a stranger would understand. Goes in the charter."
  local found_docs; found_docs="$(find_existing_docs)"
  [ -n "$found_docs" ] && PREFIX="${PREFIX:-$(recover_prefix "$found_docs")}"
  ask PREFIX       "Work item prefix" "${PREFIX:-$(derive_prefix)}" "2-4 uppercase letters. Every branch, commit and worklog entry carries it."
  ask OWNER        "Accountable human" "$(git_cfg config user.name)" "The person who approves Tier 1 work."
  ask REPO_URL     "Repository" "$(git_cfg remote get-url origin)"

  # -- intent ----------------------------------------------------------------
  section "2/7  What you are building"
  local ptype
  menu ptype "What kind of project is this?" "$(default_ptype)" \
    "Web application (users sign in, there is state)" \
    "Marketing or content site (public pages)" \
    "API / backend service (no interface of its own)" \
    "CLI tool or library" \
    "Mobile app" \
    "Data or ML pipeline" \
    "Documentation / research only (no shipped code)" \
    "Something else / mixed"
  case "$ptype" in
    1) F_UI=y; F_VISUAL=y; F_PUBLIC=n; F_DEPLOY=y; F_PII=y; F_CONV=y ;;
    2) F_UI=y; F_VISUAL=y; F_PUBLIC=y; F_DEPLOY=y; F_PII=n; F_CONV=y ;;
    3) F_UI=n; F_VISUAL=n; F_PUBLIC=n; F_DEPLOY=y; F_PII=y; F_CONV=n ;;
    4) F_UI=y; F_VISUAL=n; F_PUBLIC=n; F_DEPLOY=n; F_PII=n; F_CONV=n ;;
    5) F_UI=y; F_VISUAL=y; F_PUBLIC=n; F_DEPLOY=y; F_PII=y; F_CONV=y ;;
    6) F_UI=n; F_VISUAL=n; F_PUBLIC=n; F_DEPLOY=y; F_PII=y; F_CONV=n ;;
    7) F_UI=n; F_VISUAL=n; F_PUBLIC=y; F_DEPLOY=n; F_PII=n; F_CONV=n ;;
    *) F_UI=n; F_VISUAL=n; F_PUBLIC=n; F_DEPLOY=n; F_PII=n; F_CONV=n ;;
  esac

  if [ "$INTERACTIVE" -eq 1 ] && [ "$SKIP_ALL" -eq 0 ] && [ "$SKIP_SECTION" -eq 0 ]; then
    printf '\n  %sThese six answers decide which of the twelve roles review your work:%s\n' "$C_D" "$C_R"
    printf '    interface of any kind (incl. CLI) . %s\n' "$F_UI"
    printf '    visual interface .................. %s\n' "$F_VISUAL"
    printf '    publicly discoverable content ..... %s\n' "$F_PUBLIC"
    printf '    deployed / operated by you ........ %s\n' "$F_DEPLOY"
    printf '    holds personal data ............... %s\n' "$F_PII"
    printf '    has a conversion / activation goal  %s\n' "$F_CONV"
  fi
  ask_key ans "Use these? (y = yes, e = edit each)" "ye" "y"
  if [ "$ans" = "e" ]; then
    ask_yn F_UI     "Is there any interface at all (a CLI counts)?" "$F_UI"
    ask_yn F_VISUAL "Is any of it visual (screens, pages, components)?" "$F_VISUAL"
    ask_yn F_PUBLIC "Is any of it publicly discoverable (search, social)?" "$F_PUBLIC"
    ask_yn F_DEPLOY "Does it deploy to or run somewhere you operate?" "$F_DEPLOY"
    ask_yn F_PII    "Does it hold or process personal data?" "$F_PII"
    ask_yn F_CONV   "Is there a conversion or activation goal to optimise?" "$F_CONV"
  fi

  # -- stack -----------------------------------------------------------------
  section "3/7  Stack"
  S_LANG="$DET_LANG"; S_PM="$DET_PM"; S_FW="$DET_FW"; S_DB="$DET_DB"
  S_AUTH="$DET_AUTH"; S_HOST="$DET_HOST"; S_CI="$DET_CI"; S_TEST="$DET_TEST"
  if [ "$INTERACTIVE" -eq 1 ] && [ "$SKIP_ALL" -eq 0 ]; then
    printf '  %sread from the repository -- confirm, do not assume:%s\n' "$C_D" "$C_R"
    printf '    language / runtime .. %s\n' "${S_LANG:-(not detected)}"
    printf '    package manager ..... %s\n' "${S_PM:-(not detected)}"
    printf '    framework(s) ........ %s\n' "${S_FW:-(not detected)}"
    printf '    data store .......... %s\n' "${S_DB:-(not detected)}"
    printf '    auth ................ %s\n' "${S_AUTH:-(not detected)}"
    printf '    hosting ............. %s\n' "${S_HOST:-(not detected)}"
    printf '    CI .................. %s\n' "${S_CI:-(not detected)}"
    printf '    test tooling ........ %s\n' "${S_TEST:-(not detected)}"
  fi
  ask_key ans "Use these? (y = yes, e = edit each, n = leave the table blank)" "yen" "y"
  case "$ans" in
    n) S_LANG=""; S_PM=""; S_FW=""; S_DB=""; S_AUTH=""; S_HOST=""; S_CI=""; S_TEST="" ;;
    e)
      ask S_LANG "Language / runtime" "$S_LANG"
      ask S_PM   "Package manager"    "$S_PM"
      ask S_FW   "Framework(s)"       "$S_FW"
      ask S_DB   "Data store"         "$S_DB"
      ask S_AUTH "Auth"               "$S_AUTH"
      ask S_HOST "Hosting"            "$S_HOST"
      ask S_CI   "CI"                 "$S_CI"
      ask S_TEST "Test tooling"       "$S_TEST" ;;
  esac

  # -- commands --------------------------------------------------------------
  section "4/7  Check commands"
  C_INSTALL="$DET_INSTALL"; C_RUN="$DET_RUN"; C_FORMAT="$DET_FORMAT"; C_LINT="$DET_LINT"
  C_TYPECHECK="$DET_TYPECHECK"; C_UNIT="$DET_UNIT"; C_BUILD="$DET_BUILD"
  C_SCAN="$DET_SCAN"; C_E2E="$DET_E2E"
  if [ "$INTERACTIVE" -eq 1 ] && [ "$SKIP_ALL" -eq 0 ]; then
    printf '  %sagents run these verbatim and report the result as evidence.\n' "$C_D"
    printf '  A wrong command here produces confidently false "verified" claims.%s\n' "$C_R"
    printf '    install ....... %s\n' "${C_INSTALL:-(none found -- left blank)}"
    printf '    run locally ... %s\n' "${C_RUN:-(none found -- left blank)}"
    printf '    format ........ %s\n' "${C_FORMAT:-(none found -- left blank)}"
    printf '    lint .......... %s\n' "${C_LINT:-(none found -- left blank)}"
    printf '    typecheck ..... %s\n' "${C_TYPECHECK:-(none found -- left blank)}"
    printf '    unit .......... %s\n' "${C_UNIT:-(none found -- left blank)}"
    printf '    build ......... %s\n' "${C_BUILD:-(none found -- left blank)}"
    printf '    scan .......... %s\n' "${C_SCAN:-(none found -- left blank)}"
    printf '    e2e ........... %s\n' "${C_E2E:-(none found -- left blank)}"
  fi
  ask_key ans "Use these? (y = yes, e = edit each, n = leave the table blank)" "yen" "y"
  case "$ans" in
    n) C_INSTALL=""; C_RUN=""; C_FORMAT=""; C_LINT=""; C_TYPECHECK=""; C_UNIT=""; C_BUILD=""; C_SCAN=""; C_E2E="" ;;
    e)
      ask C_INSTALL   "Install"        "$C_INSTALL"
      ask C_RUN       "Run locally"    "$C_RUN"
      ask C_FORMAT    "checks.format"  "$C_FORMAT"
      ask C_LINT      "checks.lint"    "$C_LINT"
      ask C_TYPECHECK "checks.typecheck" "$C_TYPECHECK"
      ask C_UNIT      "checks.unit"    "$C_UNIT"
      ask C_BUILD     "checks.build"   "$C_BUILD"
      ask C_SCAN      "checks.scan"    "$C_SCAN"
      ask C_E2E       "checks.e2e"     "$C_E2E" ;;
  esac

  # -- process ---------------------------------------------------------------
  section "5/7  Process and risk"
  BRANCH="$(git_cfg symbolic-ref --short HEAD)"
  [ -n "$BRANCH" ] || BRANCH="main"
  ask BRANCH "Default branch" "$BRANCH"
  ask_yn DIRECT_COMMITS "Are direct commits to $BRANCH allowed?" "n"
  ask APPROVERS "Approver(s) for Tier 1 work" "${OWNER}" "Named humans. Tier 1 needs two approvals."
  ask STALENESS "Treat project docs as stale after" "90 days"

  local approval_default=""
  [ "$F_DEPLOY" = "y" ] && approval_default="production deploys"
  [ "$F_PII" = "y" ] && approval_default="${approval_default:+$approval_default, }anything touching personal data"
  [ -n "$S_DB" ] && approval_default="${approval_default:+$approval_default, }schema or data migrations"
  approval_default="${approval_default:+$approval_default, }anything outward-facing (public posts, emails, announcements)"
  ask APPROVAL_FOR "Human approval required for" "$approval_default"
  ask FORBIDDEN "Forbidden in this project" "" "The specific shortcuts that would be tempting here. Blank = fill in later."

  PLATFORM="${PLATFORMS:-none}"
  ask PLATFORM "Managed platform co-owning this repo" "$PLATFORM" \
    "AI app builder or cloud IDE that also edits, syncs, or deploys this repo."

  # -- standards -------------------------------------------------------------
  section "6/7  Standards"
  if [ "$F_UI" = "y" ]; then
    ask A11Y_TARGET "Accessibility target" "WCAG 2.2 AA"
  else
    A11Y_TARGET="not applicable — no interface"
  fi
  if [ "$F_CONV" = "y" ]; then
    ask PRIMARY_OUTCOME "Primary outcome success is measured by" "" \
      "The one user action: sign-up, activation, task completion, purchase."
  fi

  # -- what gets installed ---------------------------------------------------
  section "7/7  What to install"
  local docs_answer=""
  found_docs="$(find_existing_docs)"
  if [ -n "$found_docs" ] && [ "$DOCS_DIR_GIVEN" -eq 0 ]; then
    DOCS_DIR="$found_docs"
    note "an install already exists in $DOCS_DIR/ -- reusing it; only missing files are added."
  elif [ -d "$TARGET/$DOCS_DIR" ] && [ -n "$(ls -A "$TARGET/$DOCS_DIR" 2>/dev/null)" ] && [ "$DOCS_DIR_GIVEN" -eq 0 ]; then
    note "$DOCS_DIR/ already exists and is not empty; existing files are never overwritten."
    ask docs_answer "Install the docs under" "sdlc-docs"
    case "$docs_answer" in
      "") note "keeping $DOCS_DIR/" ;;
      */*|.|..) note "not a directory name -- keeping $DOCS_DIR/" ;;
      *) DOCS_DIR="$docs_answer" ;;
    esac
  else
    ask docs_answer "Install the docs under" "$DOCS_DIR"
    case "$docs_answer" in
      "") note "keeping $DOCS_DIR/" ;;
      */*|.|..) note "not a directory name -- keeping $DOCS_DIR/" ;;
      *) DOCS_DIR="$docs_answer" ;;
    esac
  fi
  ask_yn WANT_COMMANDS "Install the four /sdlc-* slash commands?" "y"

  skill_eval
  local i
  if [ "$INTERACTIVE" -eq 1 ] && [ "$SKIP_ALL" -eq 0 ] && [ "$SKIP_SECTION" -eq 0 ] && [ "${#SK_NAME[@]}" -gt 0 ]; then
    printf '\n  %sSkills evaluated against your answers (installed to .claude/skills/):%s\n' "$C_D" "$C_R"
    for i in "${!SK_NAME[@]}"; do
      if [ "${SK_ON[$i]}" = "1" ]; then
        printf '    [x] %-24s %s%s%s\n' "${SK_NAME[$i]}" "$C_D" "${SK_WHY[$i]}" "$C_R"
      else
        printf '    [ ] %-24s %soff: %s%s\n' "${SK_NAME[$i]}" "$C_D" "${SK_OFF[$i]}" "$C_R"
      fi
    done
  fi
  ask_key ans "Install the ticked skills? (y = yes, e = choose each, n = none)" "yen" "y"
  case "$ans" in
    n) for i in "${!SK_NAME[@]}"; do SK_ON[$i]=0; done ;;
    e)
      for i in "${!SK_NAME[@]}"; do
        local on="n" reason
        [ "${SK_ON[$i]}" = "1" ] && on="y"
        if [ "${SK_ON[$i]}" = "1" ]; then reason="${SK_WHY[$i]}"; else reason="${SK_OFF[$i]}"; fi
        ask_yn on "  ${SK_NAME[$i]} — $reason?" "$on"
        [ "$on" = "y" ] && SK_ON[$i]=1 || SK_ON[$i]=0
      done ;;
  esac
  SKILLS=""
  for i in "${!SK_NAME[@]}"; do
    [ "${SK_ON[$i]}" = "1" ] && SKILLS="$SKILLS ${SK_NAME[$i]}"
  done
  SKILLS="${SKILLS# }"

  [ -e "$TARGET/CLAUDE.md" ] && WANT_CLAUDEMD="n"

  # -- confirm ---------------------------------------------------------------
  if [ "$INTERACTIVE" -eq 1 ]; then
    printf '\n%s-- Ready %s\n' "$C_B" "$C_R"
    printf '  into        %s\n' "$TARGET"
    printf '  project     %s (%s)\n' "$PROJECT_NAME" "$PREFIX"
    printf '  docs        %s/\n' "$DOCS_DIR"
    printf '  roles on    %s\n' "$(active_roles_summary)"
    printf '  commands    %s\n' "$([ "$WANT_COMMANDS" = y ] && echo "4 installed" || echo "none")"
    printf '  skills      %s\n' "${SKILLS:-none}"
    local go=""
    printf '  Write these files? %s[Y/n]%s ' "$C_D" "$C_R"
    IFS= read -r go || go="y"
    case "$go" in n|N|no) echo "  Nothing was written."; exit 0 ;; esac
  fi
}

active_roles_summary() {
  local r="product-manager, architect, security, qa"
  [ "$F_UI" = "y" ]     && r="$r, ux-designer, accessibility"
  [ "$F_VISUAL" = "y" ] && r="$r, brand-designer"
  { [ "$F_UI" = "y" ] || [ "$F_PUBLIC" = "y" ]; } && r="$r, copywriter"
  [ "$F_PUBLIC" = "y" ] && r="$r, seo"
  [ "$F_CONV" = "y" ]   && r="$r, cro-analyst"
  [ "$F_DEPLOY" = "y" ] && r="$r, devops-sre"
  [ "$F_PII" = "y" ]    && r="$r, privacy-legal"
  printf '%s' "$r"
}

# ---------------------------------------------------------------- copy machinery

copied=0
skipped=0
upgraded=0
LAST_ADDED=0

install_file() {
  local src="$1" dest="$2"
  LAST_ADDED=0
  if [ -e "$dest" ]; then
    skipped=$((skipped + 1))
    echo "  skip (exists)  ${dest#"$TARGET"/}"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  substitute "$dest"
  copied=$((copied + 1))
  LAST_ADDED=1
  echo "  add            ${dest#"$TARGET"/}"
}

# --upgrade only. Overwrites unconditionally; callers must restrict it to the parts the
# kit owns and the project is told never to edit in place.
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
  echo "  (docs/process/, docs/roles/, and already-installed skills -- project records untouched)"
  echo

  for dir in process roles; do
    while IFS= read -r -d '' f; do
      upgrade_file "$f" "$TARGET/$DOCS_DIR/$dir/${f#"$SRC/template/docs/$dir/"}"
    done < <(find "$SRC/template/docs/$dir" -type f -print0)
  done

  # Skills the project already has are kit-owned standards like process/ and roles/:
  # refresh them in place. Never add one that was not chosen at install time.
  if [ -d "$SRC/optional/skills" ] && [ -d "$TARGET/.claude/skills" ]; then
    for d in "$SRC"/optional/skills/*/; do
      name="$(basename "$d")"
      [ -d "$TARGET/.claude/skills/$name" ] || continue
      while IFS= read -r -d '' f; do
        upgrade_file "$f" "$TARGET/.claude/skills/$name/${f#"$d"}"
      done < <(find "$d" -type f -print0)
    done
  fi

  echo
  echo "Done: $upgraded updated."
  echo
  echo "AGENTS.md and .claude/commands/ were NOT touched -- they may carry project edits."
  echo "Diff them against the kit if this version changed them:"
  echo "  diff $SRC/template/AGENTS.md $TARGET/AGENTS.md"
  echo
  echo "New skills shipped by this version are not added by --upgrade. To see them:"
  echo "  ls $SRC/optional/skills"
  exit 0
fi

# ---------------------------------------------------------------- install mode

wizard

if [ "$INTERACTIVE" -eq 0 ]; then
  # Nobody answered anything, so nothing may be declared on their behalf: the charter
  # keeps its blank cells, which the process reads as Unknown. Only the unconditional
  # skills -- the ones that do not depend on an answer -- are installed.
  F_UI=n; F_VISUAL=n; F_PUBLIC=n; F_DEPLOY=n; F_PII=n; F_CONV=n
  skill_eval
  SKILLS=""
  for i in "${!SK_NAME[@]}"; do
    [ "${SK_ON[$i]}" = "1" ] && SKILLS="$SKILLS ${SK_NAME[$i]}"
  done
  SKILLS="${SKILLS# }"
  if [ -d "$TARGET/$DOCS_DIR" ] && [ -n "$(ls -A "$TARGET/$DOCS_DIR" 2>/dev/null)" ] && [ "$DOCS_DIR" = "docs" ]; then
    echo "note: $TARGET/docs already exists and is not empty."
    echo "      Existing files will be kept; only missing ones are added."
    echo "      To install alongside instead, re-run with: --docs-dir sdlc-docs"
    echo
  fi
fi
[ "$WANT_SKILLS" -eq 1 ] || SKILLS=""

echo
echo "Installing AI SDLC kit v$VERSION into $TARGET"
echo

install_file "$SRC/template/AGENTS.md" "$TARGET/AGENTS.md"
AGENTS_FRESH="$LAST_ADDED"

CHARTER_FRESH=0
while IFS= read -r -d '' f; do
  rel="${f#"$SRC/template/docs/"}"
  install_file "$f" "$TARGET/$DOCS_DIR/$rel"
  [ "$rel" = "project/charter.md" ] && CHARTER_FRESH="$LAST_ADDED"
done < <(find "$SRC/template/docs" -type f -print0)

# Slash commands. These must be substituted too -- they name {{PREFIX}}-### paths.
if [ "$WANT_COMMANDS" = "y" ]; then
  for f in "$SRC"/optional/claude-commands/*.md; do
    install_file "$f" "$TARGET/.claude/commands/$(basename "$f")"
  done
fi

# Skills: model-invoked, so they fire on the situation rather than waiting to be typed.
skills_installed=0
if [ -n "$SKILLS" ] && [ -d "$SRC/optional/skills" ]; then
  for name in $SKILLS; do
    [ -d "$SRC/optional/skills/$name" ] || continue
    while IFS= read -r -d '' f; do
      install_file "$f" "$TARGET/.claude/skills/$name/${f#"$SRC/optional/skills/$name/"}"
    done < <(find "$SRC/optional/skills/$name" -type f -print0)
    skills_installed=$((skills_installed + 1))
  done
fi

# Point CLAUDE.md at AGENTS.md if it does not exist yet.
if [ ! -e "$TARGET/CLAUDE.md" ] && [ "$WANT_CLAUDEMD" = "y" ]; then
  printf '# Project instructions\n\nRead and follow `AGENTS.md` in this directory.\n' > "$TARGET/CLAUDE.md"
  echo "  add            CLAUDE.md (pointer to AGENTS.md)"
fi

# ---------------------------------------------------------------- apply the answers
# Only to files this run created. A charter that was already there belongs to the
# project, and an answer given today must not silently rewrite a decision made earlier.

CHARTER="$TARGET/$DOCS_DIR/project/charter.md"

fill_line() { # fill_line FILE "prefix" "replacement line"
  local f="$1" pfx="$2" line="$3"
  PFX="$pfx" LINE="$line" awk '
    BEGIN { pfx = ENVIRON["PFX"]; done = 0 }
    !done && index($0, pfx) == 1 { print ENVIRON["LINE"]; done = 1; next }
    { print }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

tailored=0
if [ "$INTERACTIVE" -eq 1 ] && [ "$CHARTER_FRESH" -eq 1 ] && [ -f "$CHARTER" ]; then
  tailored=1

  [ -n "$OWNER" ] && fill_line "$CHARTER" "owner:" "owner: $OWNER"
  fill_line "$CHARTER" "last-reviewed:" "last-reviewed: $(date +%F)"

  fill_row "$CHARTER" "**What it is**"        "$WHAT_IS"
  fill_row "$CHARTER" "**Repository**"        "$REPO_URL"
  fill_row "$CHARTER" "**Accountable human**" "$OWNER"
  fill_row "$CHARTER" "**Work item prefix**"  "\`$PREFIX\`"

  fill_row "$CHARTER" "Language / runtime" "$S_LANG"
  fill_row "$CHARTER" "Package manager"    "$S_PM"
  fill_row "$CHARTER" "Framework(s)"       "$S_FW"
  fill_row "$CHARTER" "Data store"         "$S_DB"
  fill_row "$CHARTER" "Auth"               "$S_AUTH"
  fill_row "$CHARTER" "Hosting"            "$S_HOST"
  fill_row "$CHARTER" "CI"                 "$S_CI"
  fill_row "$CHARTER" "Test tooling"       "$S_TEST"

  fill_row "$CHARTER" "Install"             "$C_INSTALL"
  fill_row "$CHARTER" "Run locally"         "$C_RUN"
  fill_row "$CHARTER" "\`checks.format\`"    "$C_FORMAT"
  fill_row "$CHARTER" "\`checks.lint\`"      "$C_LINT"
  fill_row "$CHARTER" "\`checks.typecheck\`" "$C_TYPECHECK"
  fill_row "$CHARTER" "\`checks.unit\`"      "$C_UNIT"
  fill_row "$CHARTER" "\`checks.build\`"     "$C_BUILD"
  fill_row "$CHARTER" "\`checks.scan\`"      "$C_SCAN"
  fill_row "$CHARTER" "\`checks.e2e\`"       "$C_E2E"

  fill_row "$CHARTER" "**Default branch**" "$BRANCH"
  if [ "$DIRECT_COMMITS" = "y" ]; then
    fill_row "$CHARTER" "**Direct commits to it**" "allowed"
  else
    fill_row "$CHARTER" "**Direct commits to it**" "not allowed — work goes through a branch and a review"
  fi
  fill_row "$CHARTER" "**Platform**" "$PLATFORM"

  fill_row "$CHARTER" "**Human approval required for**" "$APPROVAL_FOR"
  fill_row "$CHARTER" "**Approvers**" "$APPROVERS"
  fill_row "$CHARTER" "**Staleness threshold**" "$STALENESS"

  fill_row "$CHARTER" "**Accessibility target**" "$A11Y_TARGET"
  fill_row "$CHARTER" "**Primary outcome**" "$PRIMARY_OUTCOME"
  if [ "$F_PII" = "n" ]; then
    fill_row "$CHARTER" "**Data categories held**" \
      "none — declared at install; re-check whenever a feature starts collecting anything"
  fi

  # Active roles. A tick and an unticked-with-reason are both decisions; a blank reason
  # is not, which is why every off row carries the answer it came from.
  set_role "$CHARTER" ux-designer   "$([ "$F_UI" = y ] && echo 1 || echo 0)"     "no interface of any kind in this project"
  set_role "$CHARTER" brand-designer "$([ "$F_VISUAL" = y ] && echo 1 || echo 0)" "no visual interface"
  set_role "$CHARTER" copywriter    "$([ "$F_UI" = y ] || [ "$F_PUBLIC" = y ] && echo 1 || echo 0)" "no user-visible text"
  set_role "$CHARTER" accessibility "$([ "$F_UI" = y ] && echo 1 || echo 0)"     "no interface to make accessible"
  set_role "$CHARTER" seo           "$([ "$F_PUBLIC" = y ] && echo 1 || echo 0)" "nothing here is publicly discoverable"
  set_role "$CHARTER" cro-analyst   "$([ "$F_CONV" = y ] && echo 1 || echo 0)"   "no conversion or activation goal"
  set_role "$CHARTER" devops-sre    "$([ "$F_DEPLOY" = y ] && echo 1 || echo 0)" "not deployed or operated by this team"
  set_role "$CHARTER" privacy-legal "$([ "$F_PII" = y ] && echo 1 || echo 0)"    "no personal data, tracking, or public claims — declared at install"

  echo "  tailored       ${CHARTER#"$TARGET"/}"
fi

if [ "$INTERACTIVE" -eq 1 ] && [ "$AGENTS_FRESH" -eq 1 ]; then
  fill_field "$TARGET/AGENTS.md" "**Human approval required for:**" "$APPROVAL_FOR"
  fill_field "$TARGET/AGENTS.md" "**Forbidden in this project:**" "$FORBIDDEN"
  [ -n "$APPROVAL_FOR$FORBIDDEN" ] && echo "  tailored       AGENTS.md"
fi

# ---------------------------------------------------------------- report

echo
if [ "$tailored" -eq 1 ]; then
  echo "Done: $copied added, $skipped skipped, charter tailored to your answers."
else
  echo "Done: $copied added, $skipped skipped."
fi
[ "$skills_installed" -gt 0 ] && echo "Skills installed: $SKILLS"
echo

if [ -n "$PLATFORMS" ]; then
  echo "note: this project appears to live on a managed platform: $PLATFORMS"
  echo "      The platform also edits, syncs, or deploys this repository. The kit must"
  echo "      not break it:"
  echo "      - Fill in the charter's 'Managed platform' table (sync model, platform-"
  echo "        owned files, deploys). Process rules yield to it where they conflict."
  echo "      - Leave the platform's own files alone (e.g. .replit, replit.nix,"
  echo "        platform config directories). This installer did not touch them."
  echo "      - Point the platform's instruction file or knowledge base (e.g. replit.md,"
  echo "        Lovable project knowledge) at AGENTS.md instead of duplicating it."
  echo "      - See 'Managed platforms' in $DOCS_DIR/process/05-change-control.md."
  echo
fi

if [ -z "$PREFIX" ]; then
  echo "WARNING: no PREFIX given. {{PREFIX}} is still literal in the installed files."
  echo "         Replace it before use, or re-run against a clean target with a prefix."
  echo
fi

echo "Next:"
if [ "$tailored" -eq 1 ]; then
  echo "  1. Read $DOCS_DIR/project/charter.md and correct what setup filled in."
  echo "     Still blank on purpose, because nobody could answer it from here:"
  echo "     constraints, environments, sources of truth, and any check command that"
  echo "     was not found. A blank cell is read as Unknown, never as 'not applicable'."
else
  echo "  1. Fill in $DOCS_DIR/project/charter.md -- nothing else is reliable until you do."
fi
echo "  2. Fill in the Project overrides section at the end of AGENTS.md."
echo "  3. Check nothing was left unsubstituted:"
echo "       grep -rn '{{' $TARGET/$DOCS_DIR $TARGET/AGENTS.md $TARGET/.claude"

if [ "$INTERACTIVE" -eq 1 ]; then
  echo
  echo "Artifacts worth writing first for this kind of project:"
  rec="product-brief, architecture, test-plan"
  [ "$F_UI" = "y" ]     && rec="$rec, user-stories"
  [ "$F_VISUAL" = "y" ] && rec="$rec, design-system"
  [ "$F_PUBLIC" = "y" ] && rec="$rec, content-seo-plan"
  [ "$F_CONV" = "y" ]   && rec="$rec, measurement-plan"
  [ "$F_PII" = "y" ]    && rec="$rec, security-privacy, threat-model"
  [ "$F_DEPLOY" = "y" ] && rec="$rec, release-runbook"
  echo "  $rec"
  echo "  Tick each one in the charter's 'Artifacts in use' list when it actually exists."
fi

echo
echo "Later, to pick up a newer version of the portable standards:"
echo "  $0 $TARGET ${PREFIX:-<PREFIX>} --upgrade"
