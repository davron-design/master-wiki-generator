#!/usr/bin/env bash
# Push the canonical templates from master-wiki-generator/templates/ into the
# live `master-compile/`, `master-audit/` and `update-master-wiki/` skill
# folders that sit next to this generator. Templates are the source of truth;
# this script is the deployment direction.
#
# Use this when you (the skill maintainer) keep a working master wiki whose
# `.claude/skills/` folder also holds master-wiki-generator, and want your live
# copies to match the templates after an edit, before you push.
#
# It refuses to run anywhere else: the generator's parent folder has to be a
# `.claude/skills/` folder inside a master wiki root (a folder holding
# wiki/_master-index.md, and a CLAUDE.md that starts with "# Master Wiki" or a
# master-compile skill), and never the home folder's ~/.claude/skills/.
#
# It does not stamp .master-wiki-version. Deployed templates are unreleased
# until you push and the release tag exists, so `update` should judge them
# against the published release.
#
# Usage: bash scripts/deploy-to-live.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$SKILL_DIR/templates"
LIVE_SKILLS_DIR="$(cd "$SKILL_DIR/.." && pwd)"  # .claude/skills/
MASTER_ROOT="$(cd "$LIVE_SKILLS_DIR/../.." && pwd)"
HOME_SKILLS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
SKILLS="master-compile master-audit update-master-wiki"

fail() { echo "deploy-to-live: $*" >&2; exit 1; }

if [ "$(basename "$LIVE_SKILLS_DIR")" != skills ] || [ "$(basename "$(dirname "$LIVE_SKILLS_DIR")")" != .claude ]; then
  fail "the generator's parent folder is $LIVE_SKILLS_DIR, which is not a .claude/skills/ folder. Run this from a copy of master-wiki-generator inside <master>/.claude/skills/."
fi
if [ -d "$HOME_SKILLS_DIR" ] && [ "$(cd "$HOME_SKILLS_DIR" && pwd -P)" = "$(cd "$LIVE_SKILLS_DIR" && pwd -P)" ]; then
  fail "refusing to deploy into $HOME_SKILLS_DIR: skills there run ahead of every project's own copies."
fi
if [ ! -f "$MASTER_ROOT/CLAUDE.md" ] || [ ! -f "$MASTER_ROOT/wiki/_master-index.md" ]; then
  fail "$MASTER_ROOT is not a master wiki root (it needs CLAUDE.md and wiki/_master-index.md)."
fi
case "$(head -n 1 "$MASTER_ROOT/CLAUDE.md")" in
  '# Master Wiki'*) ;;
  *) [ -d "$LIVE_SKILLS_DIR/master-compile" ] ||
       fail "$MASTER_ROOT has neither a CLAUDE.md starting with '# Master Wiki' nor .claude/skills/master-compile/, so this isn't a master wiki." ;;
esac

for p in "$MASTER_ROOT/.claude" "$LIVE_SKILLS_DIR"; do
  if [ -L "$p" ]; then fail "$p is a symlink; cp would write through it into whatever it points at."; fi
done
for s in $SKILLS; do
  for p in "$LIVE_SKILLS_DIR/$s" "$LIVE_SKILLS_DIR/$s/SKILL.md"; do
    if [ -L "$p" ]; then fail "$p is a symlink; cp would write through it into whatever it points at."; fi
  done
done

VERSION="$(tr -d '[:space:]' < "$TEMPLATES_DIR/VERSION")"
STAMPED="$( { sed -n 's/^version:[[:space:]]*//p' "$LIVE_SKILLS_DIR/.master-wiki-version" 2>/dev/null || true; } | tr -d '[:space:]')"
if printf '%s' "$STAMPED" | grep -Eqx '[0-9]{4}-[0-9]{2}-[0-9]{2}(\.[0-9]+)?' \
   && [ "$(printf '%s\n' "$STAMPED" "$VERSION" | sort -V | tail -n 1)" != "$VERSION" ]; then
  fail "these templates ($VERSION) are older than the release this master runs ($STAMPED). Pull the generator first."
fi

for s in $SKILLS; do
  if grep -qsE "^name: *$s[[:space:]]*\$" "$HOME_SKILLS_DIR"/*/SKILL.md; then
    echo "warning: $HOME_SKILLS_DIR holds a $s skill, which runs instead of the copy deployed here." >&2
  fi
done

echo "Deploying templates from: $TEMPLATES_DIR"
echo "                      to: $LIVE_SKILLS_DIR"
echo ""

for s in $SKILLS; do
  mkdir -p "$LIVE_SKILLS_DIR/$s"
  cp -v "$TEMPLATES_DIR/$s.SKILL.md" "$LIVE_SKILLS_DIR/$s/SKILL.md"
done

echo ""
echo "Done. .master-wiki-version is not stamped, and these are not deployed:"
echo "  - CLAUDE.md: after you push and the tag v$VERSION exists, say \`update\` at the"
echo "    master root. The skills then show as current, and CLAUDE.md is offered with a diff."
echo "  - The setup-notes variants: they are per-scaffold."
echo "  - templates/ws-templates/: workstream wikis update from wiki-generator with \`update\`"
echo "    in a session opened in each workstream's folder."
echo ""
echo "Running Claude Code sessions pick up the SKILL.md changes. A CLAUDE.md change"
echo "takes effect in a new session."
