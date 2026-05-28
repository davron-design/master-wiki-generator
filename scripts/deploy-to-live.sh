#!/usr/bin/env bash
# Push the canonical templates from master-wiki-generator/templates/ into the
# live `.claude/skills/master-compile/` and `.claude/skills/master-audit/`
# folders that sit next to this generator. Templates are the source of truth;
# this script is the deployment direction.
#
# Use this when you (the skill maintainer) keep a working master wiki in the
# same `.claude/skills/` directory as master-wiki-generator itself, and want
# your live copies to match the latest templates after an edit.
#
# Usage: bash scripts/deploy-to-live.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$SKILL_DIR/templates"
LIVE_SKILLS_DIR="$(cd "$SKILL_DIR/.." && pwd)"  # .claude/skills/

echo "Deploying templates from: $TEMPLATES_DIR"
echo "                      to: $LIVE_SKILLS_DIR"
echo ""

mkdir -p "$LIVE_SKILLS_DIR/master-compile" "$LIVE_SKILLS_DIR/master-audit"
cp -v "$TEMPLATES_DIR/master-compile.SKILL.md" "$LIVE_SKILLS_DIR/master-compile/SKILL.md"
cp -v "$TEMPLATES_DIR/master-audit.SKILL.md"   "$LIVE_SKILLS_DIR/master-audit/SKILL.md"

echo ""
echo "Done. The CLAUDE.md template, the workstream-setup-notes variants, and"
echo "the templates/ws-templates/ folder are NOT deployed by this script:"
echo "  - The live master wiki's CLAUDE.md is maintained independently."
echo "  - Setup-notes are per-deployment (they list each master's actual"
echo "    workstream folders and depend on the user's scaffold-mode choice)."
echo "  - ws-templates/ ship into fresh-scaffolded workstream wikis at scaffold"
echo "    time, not into the maintainer's own live master."
echo "Update CLAUDE.md by hand if conventions change."
