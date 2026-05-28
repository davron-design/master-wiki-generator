#!/usr/bin/env bash
# Scaffold a cross-workstream master wiki from this skill's templates/.
#
# This is the END-USER scaffolder: it does the deterministic file emission
# (folder creation, template copy, WORKSTREAMS substitution, .gitkeep drops,
# verification) in a single pass so the running agent does not have to read and
# re-write a dozen-plus templates by hand. The agent still runs the setup wizard
# (target, count, slugs, mode, scope, collision/upgrade judgment) and passes the
# resolved choices in as flags.
#
# Templates are the source of truth; this script only ever copies templates ->
# destination, never the reverse.
#
# Usage:
#   bash scripts/scaffold.sh \
#     --target <absolute-path> \
#     --mode fresh|placeholder \
#     --scope project|global \
#     --workstreams "ws1 ws2 ws3" \
#     [--overwrite-master]
#
# Slugs may be passed with or without a trailing `-wiki`; the script applies the
# suffix rule (append `-wiki` unless already present) and rejects duplicates.
#
# Safety guarantees enforced here (not left to the agent):
#   - Aborts if any required template for the chosen mode is missing.
#   - Never overwrites a `raw/<slug>-wiki/` folder that holds real content
#     (anything beyond a lone `.gitkeep`) — even on the upgrade path.
#   - Master-level files are only overwritten with --overwrite-master.
#   - Global-scope companion skills are skipped if already present (so a user's
#     own wiki-generator install is never clobbered).
#
# Output: WROTE / SKIPPED / FAILED lines the agent parses to report results.
# Exit code is non-zero if any expected file failed to land.

set -euo pipefail

# --- resolve paths ---------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$SKILL_DIR/templates"
WS_TEMPLATES_DIR="$TEMPLATES_DIR/ws-templates"
GLOBAL_SKILLS_DIR="$HOME/.claude/skills"

# --- parse args ------------------------------------------------------------
TARGET=""
MODE=""
SCOPE=""
WORKSTREAMS_RAW=""
OVERWRITE_MASTER=0

die() { echo "ERROR: $*" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)            TARGET="${2:-}"; shift 2 ;;
    --mode)              MODE="${2:-}"; shift 2 ;;
    --scope)             SCOPE="${2:-}"; shift 2 ;;
    --workstreams)       WORKSTREAMS_RAW="${2:-}"; shift 2 ;;
    --overwrite-master)  OVERWRITE_MASTER=1; shift ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -n "$TARGET" ]]          || die "--target is required (absolute path)"
[[ "$TARGET" = /* ]]        || die "--target must be an absolute path, got: $TARGET"
[[ "$MODE" == "fresh" || "$MODE" == "placeholder" ]] || die "--mode must be 'fresh' or 'placeholder'"
[[ "$SCOPE" == "project" || "$SCOPE" == "global" ]]  || die "--scope must be 'project' or 'global'"
[[ -n "$WORKSTREAMS_RAW" ]] || die "--workstreams is required (space-separated slugs)"

# --- normalize workstream folder names (apply -wiki suffix rule) -----------
declare -a WS_FOLDERS=()
for slug in $WORKSTREAMS_RAW; do
  case "$slug" in
    *-wiki) folder="$slug" ;;
    *)      folder="${slug}-wiki" ;;
  esac
  for existing in "${WS_FOLDERS[@]:-}"; do
    [[ "$existing" == "$folder" ]] && die "duplicate workstream folder: $folder"
  done
  WS_FOLDERS+=("$folder")
done

# --- template integrity check (abort before any write) ---------------------
require_template() { [[ -f "$1" ]] || die "required template missing: $1 (skill package is broken)"; }

require_template "$TEMPLATES_DIR/CLAUDE.md"
require_template "$TEMPLATES_DIR/master-index.md"
require_template "$TEMPLATES_DIR/master-compile.SKILL.md"
require_template "$TEMPLATES_DIR/master-audit.SKILL.md"
if [[ "$MODE" == "fresh" ]]; then
  require_template "$WS_TEMPLATES_DIR/CLAUDE.md"
  require_template "$WS_TEMPLATES_DIR/master-index.md"
  require_template "$WS_TEMPLATES_DIR/raw-compile.SKILL.md"
  require_template "$WS_TEMPLATES_DIR/audit-wiki.SKILL.md"
  require_template "$TEMPLATES_DIR/workstream-setup-notes.fresh.md"
else
  require_template "$TEMPLATES_DIR/workstream-setup-notes.placeholder.md"
fi

# --- bookkeeping -----------------------------------------------------------
declare -a EXPECTED=()   # files that must exist & be non-empty at the end
FAILURES=0

note()  { echo "$1 $2"; }                       # e.g. note WROTE /path
expect(){ EXPECTED+=("$1"); }

# copy SRC -> DEST honoring a policy: always | skip-if-exists | master
copy_file() {
  local src="$1" dest="$2" policy="$3"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" ]]; then
    case "$policy" in
      skip-if-exists) note SKIPPED "$dest (exists)"; expect "$dest"; return ;;
      master)
        if [[ "$OVERWRITE_MASTER" -eq 0 ]]; then
          note SKIPPED "$dest (exists; pass --overwrite-master to replace)"; expect "$dest"; return
        fi ;;
    esac
  fi
  cp "$src" "$dest"
  note WROTE "$dest"
  expect "$dest"
}

make_gitkeep() {
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  [[ -e "$dest" ]] || : > "$dest"
  note WROTE "$dest"
  expect "$dest"
}

# --- master-level folders --------------------------------------------------
mkdir -p "$TARGET/raw" "$TARGET/wiki" "$TARGET/output/_audits"

if [[ "$SCOPE" == "project" ]]; then
  MASTER_SCOPE="$TARGET/.claude/skills"
else
  MASTER_SCOPE="$GLOBAL_SKILLS_DIR"
fi

# --- master-level files ----------------------------------------------------
copy_file "$TEMPLATES_DIR/CLAUDE.md"               "$TARGET/CLAUDE.md"                 master
copy_file "$TEMPLATES_DIR/master-index.md"         "$TARGET/wiki/_master-index.md"     master
# Master companion skills are unique to this skill, so they follow the master
# overwrite policy in both scopes (no risk of clobbering a wiki-generator install).
copy_file "$TEMPLATES_DIR/master-compile.SKILL.md" "$MASTER_SCOPE/master-compile/SKILL.md" master
copy_file "$TEMPLATES_DIR/master-audit.SKILL.md"   "$MASTER_SCOPE/master-audit/SKILL.md"   master

# --- setup-notes with WORKSTREAMS substitution -----------------------------
if [[ "$MODE" == "fresh" ]]; then
  SETUP_SRC="$TEMPLATES_DIR/workstream-setup-notes.fresh.md"
else
  SETUP_SRC="$TEMPLATES_DIR/workstream-setup-notes.placeholder.md"
fi
SETUP_DEST="$TARGET/raw/_workstream-setup-notes.md"

# one bullet per workstream folder, written to a temp file so awk can read it
# (BSD awk rejects embedded newlines in a -v variable, so we read from disk).
BULLETS_FILE="$(mktemp)"
trap 'rm -f "$BULLETS_FILE"' EXIT
for folder in "${WS_FOLDERS[@]}"; do
  printf '%s\n' "- \`raw/${folder}/\`" >> "$BULLETS_FILE"
done

# Replace the WORKSTREAMS:START..END block (markers included) with the bullets,
# and strip any HTML comment block containing "SCAFFOLDER NOTE". The WORKSTREAMS
# marker lines are themselves HTML comments, so they are matched first.
awk -v bfile="$BULLETS_FILE" '
  /<!-- WORKSTREAMS:START -->/ { while ((getline l < bfile) > 0) print l; close(bfile); inb=1; next }
  /<!-- WORKSTREAMS:END -->/   { inb=0; next }
  inb { next }
  /<!--/ {
    block=$0"\n"
    while (block !~ /-->/) { if ((getline line)<=0) break; block=block line"\n" }
    if (block !~ /SCAFFOLDER NOTE/) printf "%s", block
    next
  }
  { print }
' "$SETUP_SRC" > "$SETUP_DEST"
note WROTE "$SETUP_DEST"
expect "$SETUP_DEST"

# --- per-workstream --------------------------------------------------------
GLOBAL_WS_SKILLS_DONE=0  # informational only; skip-if-exists handles write-once

for folder in "${WS_FOLDERS[@]}"; do
  ws_root="$TARGET/raw/$folder"

  # Populated-folder guard: never touch a workstream folder that holds real
  # content (anything beyond a lone .gitkeep).
  if [[ -d "$ws_root" ]]; then
    leftover="$(find "$ws_root" -mindepth 1 ! -name '.gitkeep' -print -quit 2>/dev/null || true)"
    if [[ -n "$leftover" ]]; then
      note SKIPPED "$ws_root (populated workstream — left untouched)"
      continue
    fi
  fi

  mkdir -p "$ws_root"

  if [[ "$MODE" == "placeholder" ]]; then
    make_gitkeep "$ws_root/.gitkeep"
    continue
  fi

  # fresh-scaffold mode: full wiki vault inside the workstream folder
  mkdir -p "$ws_root/raw" "$ws_root/wiki" "$ws_root/output/_audits"

  if [[ "$SCOPE" == "project" ]]; then
    WS_SCOPE="$ws_root/.claude/skills"
  else
    WS_SCOPE="$GLOBAL_SKILLS_DIR"
  fi

  copy_file "$WS_TEMPLATES_DIR/CLAUDE.md"          "$ws_root/CLAUDE.md"               always
  copy_file "$WS_TEMPLATES_DIR/master-index.md"    "$ws_root/wiki/_master-index.md"   always
  # ws-level skills can collide with the user's own wiki-generator install when
  # global — skip-if-exists protects it and naturally writes only once.
  if [[ "$SCOPE" == "global" ]]; then
    copy_file "$WS_TEMPLATES_DIR/raw-compile.SKILL.md" "$WS_SCOPE/raw-compile/SKILL.md" skip-if-exists
    copy_file "$WS_TEMPLATES_DIR/audit-wiki.SKILL.md"  "$WS_SCOPE/audit-wiki/SKILL.md"  skip-if-exists
    GLOBAL_WS_SKILLS_DONE=1
  else
    copy_file "$WS_TEMPLATES_DIR/raw-compile.SKILL.md" "$WS_SCOPE/raw-compile/SKILL.md" always
    copy_file "$WS_TEMPLATES_DIR/audit-wiki.SKILL.md"  "$WS_SCOPE/audit-wiki/SKILL.md"  always
  fi

  make_gitkeep "$ws_root/raw/.gitkeep"
  make_gitkeep "$ws_root/output/_audits/.gitkeep"
done

# --- master-level .gitkeep -------------------------------------------------
make_gitkeep "$TARGET/raw/.gitkeep"
make_gitkeep "$TARGET/output/_audits/.gitkeep"

# --- verification ----------------------------------------------------------
echo ""
echo "--- verifying ---"
for f in "${EXPECTED[@]}"; do
  if [[ "$(basename "$f")" == ".gitkeep" ]]; then
    # .gitkeep is intentionally empty — existence is all that matters
    if [[ ! -e "$f" ]]; then
      note FAILED "$f (missing)"; FAILURES=$((FAILURES + 1))
    fi
  elif [[ ! -s "$f" ]]; then
    note FAILED "$f (missing or empty)"; FAILURES=$((FAILURES + 1))
  fi
done

# the deployed setup-notes must have had its markers substituted out ...
if grep -q 'WORKSTREAMS:START\|WORKSTREAMS:END' "$SETUP_DEST" 2>/dev/null; then
  note FAILED "$SETUP_DEST (WORKSTREAMS markers were not substituted)"
  FAILURES=$((FAILURES + 1))
fi
# ... and the actual workstream bullets must be present
for folder in "${WS_FOLDERS[@]}"; do
  if ! grep -qF "raw/${folder}/" "$SETUP_DEST" 2>/dev/null; then
    note FAILED "$SETUP_DEST (missing workstream bullet: raw/${folder}/)"
    FAILURES=$((FAILURES + 1))
  fi
done

echo ""
if [[ "$FAILURES" -gt 0 ]]; then
  echo "RESULT: FAILED ($FAILURES problem(s)) — do NOT report scaffold complete."
  exit 1
fi
echo "RESULT: OK (${#EXPECTED[@]} files verified)"
