#!/usr/bin/env bash
# Scaffold a cross-workstream master wiki from this skill's templates/.
#
# This is the END-USER scaffolder: it does the deterministic file emission
# (folder creation, template copy, WORKSTREAMS substitution, version stamps,
# .gitkeep drops, verification) in a single pass, so the running agent does not
# have to read and re-type a dozen templates by hand. The agent still runs the
# setup wizard (target, count, slugs, mode, collision judgment) and passes the
# resolved choices in as flags.
#
# Templates are the source of truth; this script only ever copies templates ->
# destination, never the reverse.
#
# Usage:
#   bash scripts/scaffold.sh \
#     --target <absolute-path> \
#     --mode fresh|placeholder \
#     --workstreams "ws1 ws2 ws3"
#
# Slugs may be passed with or without a trailing `-wiki`; the script applies the
# suffix rule (append `-wiki` unless already present) and rejects duplicates.
#
# Safety guarantees enforced here (not left to the agent):
#   - Aborts before any write if a required template is missing, a VERSION file
#     isn't a date, a slug isn't lowercase-hyphenated, or the target's
#     .claude/skills would be a symlink or the global ~/.claude/skills.
#   - Never overwrites an existing file. A master that already has a stamp
#     keeps every file; its updates go through update-master-wiki (`update`).
#   - Never touches a `raw/<slug>-wiki/` folder that holds real content
#     (anything beyond a lone `.gitkeep`).
#   - Writes the master's .claude/settings.json, which switches the workstream
#     skills off in sessions opened at the master root, unless one exists.
#   - Stamps the master (.claude/skills/.master-wiki-version) and every new
#     workstream wiki (.claude/skills/.wiki-version), so `update` can later
#     compare each file with the release it came from.
#   - Compares every copied template byte for byte with its source.
#
# Output: WROTE / SKIPPED / MISSING / FAILED lines the agent parses to report
# results. Exit code is non-zero if any expected file failed to land.

set -euo pipefail

# --- resolve paths ---------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$SKILL_DIR/templates"
WS_TEMPLATES_DIR="$TEMPLATES_DIR/ws-templates"
GLOBAL_SKILLS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
TODAY="$(date +%Y-%m-%d)"
DATE_RE='^[0-9]{4}-[0-9]{2}-[0-9]{2}(\.[0-9]+)?$'

# --- parse args ------------------------------------------------------------
TARGET=""
MODE=""
WORKSTREAMS_RAW=""

die() { echo "ERROR: $*" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target|--mode|--workstreams) [[ $# -ge 2 ]] || die "$1 needs a value" ;;
  esac
  case "$1" in
    --target)       TARGET="$2"; shift 2 ;;
    --mode)         MODE="$2"; shift 2 ;;
    --workstreams)  WORKSTREAMS_RAW="$2"; shift 2 ;;
    --scope|--overwrite-master)
      die "$1 was removed: skills always install inside the master, and an existing master updates with \`update\`" ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -n "$TARGET" ]]          || die "--target is required (absolute path)"
[[ "$TARGET" = /* ]]        || die "--target must be an absolute path, got: $TARGET"
while [[ "$TARGET" == */ ]]; do TARGET="${TARGET%/}"; done
[[ -n "$TARGET" ]]          || die "--target can't be the filesystem root"
if [[ -d "$TARGET" && "$(cd "$TARGET" && pwd -P)" == / ]]; then die "--target can't be the filesystem root"; fi
[[ "$MODE" == "fresh" || "$MODE" == "placeholder" ]] || die "--mode must be 'fresh' or 'placeholder'"
[[ -n "$WORKSTREAMS_RAW" ]] || die "--workstreams is required (space-separated slugs)"

# --- normalize workstream folder names (apply -wiki suffix rule) -----------
# read -a splits on whitespace without expanding globs, so a `*` stays a bad slug
declare -a SLUGS=() WS_FOLDERS=()
WORKSTREAMS_RAW="${WORKSTREAMS_RAW//$'\n'/ }"
WORKSTREAMS_RAW="${WORKSTREAMS_RAW//$'\t'/ }"
read -r -a SLUGS <<< "$WORKSTREAMS_RAW" || true
[[ ${#SLUGS[@]} -gt 0 ]] || die "--workstreams holds no slugs"
for slug in "${SLUGS[@]}"; do
  [[ "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || die "workstream slug '$slug' must be lowercase letters, digits and single hyphens"
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
require_template() { [[ -s "$1" ]] || die "required template missing or empty: $1 (skill package is broken)"; }

MASTER_SKILLS=(master-compile master-audit update-master-wiki)
WS_SKILLS=(raw-compile audit-wiki update-wiki)

require_template "$TEMPLATES_DIR/CLAUDE.md"
require_template "$TEMPLATES_DIR/master-index.md"
require_template "$TEMPLATES_DIR/VERSION"
require_template "$TEMPLATES_DIR/settings.json"
for s in "${MASTER_SKILLS[@]}"; do require_template "$TEMPLATES_DIR/$s.SKILL.md"; done
if [[ "$MODE" == "fresh" ]]; then
  require_template "$WS_TEMPLATES_DIR/CLAUDE.md"
  require_template "$WS_TEMPLATES_DIR/master-index.md"
  require_template "$WS_TEMPLATES_DIR/VERSION"
  for s in "${WS_SKILLS[@]}"; do require_template "$WS_TEMPLATES_DIR/$s.SKILL.md"; done
  require_template "$TEMPLATES_DIR/workstream-setup-notes.fresh.md"
else
  require_template "$TEMPLATES_DIR/workstream-setup-notes.placeholder.md"
fi

MASTER_VERSION="$(tr -d '[:space:]' < "$TEMPLATES_DIR/VERSION")"
[[ "$MASTER_VERSION" =~ $DATE_RE ]] || die "templates/VERSION is '$MASTER_VERSION', not a release date (skill package is broken)"
WS_VERSION=""
if [[ "$MODE" == "fresh" ]]; then
  WS_VERSION="$(tr -d '[:space:]' < "$WS_TEMPLATES_DIR/VERSION")"
  [[ "$WS_VERSION" =~ $DATE_RE ]] || die "templates/ws-templates/VERSION is '$WS_VERSION', not a release date (skill package is broken)"
fi

# --- destination guards (abort before any write) ---------------------------
# A skill written into the global skills folder runs ahead of every project's
# own copy, and cp writes through a symlink into whatever it points at.
for p in "$TARGET/.claude" "$TARGET/.claude/skills" "$TARGET/.claude/settings.json" \
         "$TARGET/.claude/skills/.master-wiki-version" "$TARGET/CLAUDE.md" \
         "$TARGET/raw" "$TARGET/wiki" "$TARGET/wiki/_master-index.md" "$TARGET/output" "$TARGET/output/_audits" \
         "$TARGET/raw/_workstream-setup-notes.md" "$TARGET/raw/.gitkeep" "$TARGET/output/_audits/.gitkeep"; do
  if [[ -L "$p" ]]; then die "$p is a symlink; refusing to write through it"; fi
done
for s in "${MASTER_SKILLS[@]}"; do
  for p in "$TARGET/.claude/skills/$s" "$TARGET/.claude/skills/$s/SKILL.md"; do
    if [[ -L "$p" ]]; then die "$p is a symlink; refusing to write through it"; fi
  done
done
if [[ -d "$TARGET" && -d "$HOME" && "$(cd "$TARGET" && pwd -P)" == "$(cd "$HOME" && pwd -P)" ]]; then
  die "the target is the home folder, whose .claude/skills is the global skills folder"
fi
if [[ -d "$GLOBAL_SKILLS_DIR" && -d "$TARGET/.claude/skills" &&
      "$(cd "$TARGET/.claude/skills" && pwd -P)" == "$(cd "$GLOBAL_SKILLS_DIR" && pwd -P)" ]]; then
  die "$TARGET/.claude/skills is the global skills folder; skills there would run in every project"
fi
GLOBAL_CONFIG_DIR="$(dirname "$GLOBAL_SKILLS_DIR")"
canon() {   # canon <path>: the physical path, resolving the deepest folder that exists
  local p="$1" rest=""
  while [[ ! -d "$p" && "$p" == */* ]]; do rest="/$(basename "$p")$rest"; p="$(dirname "$p")"; done
  [[ -d "$p" ]] && p="$(cd "$p" && pwd -P)"
  printf '%s%s\n' "${p%/}" "$rest"
}
if [[ "$(canon "$TARGET/.claude")" == "$(canon "$GLOBAL_CONFIG_DIR")" ]]; then
  die "$TARGET/.claude is the global Claude Code folder; skills written there would run in every project"
fi
# A standalone wiki (CLAUDE.md plus wiki/_master-index.md, no master markers) is
# not a master. Turning it into one would put master skills next to its own and
# a workstream inside its raw/, which its raw-compile would treat as a source.
is_master() {
  [[ -d "$1/.claude/skills/master-compile" || -d "$1/.claude/skills/update-master-wiki" ||
     -e "$1/.claude/skills/.master-wiki-version" ]] && return 0
  [[ -f "$1/CLAUDE.md" ]] && [[ "$(head -n 1 "$1/CLAUDE.md")" == '# Master Wiki'* ]]
}
is_standalone() {
  [[ -f "$1/CLAUDE.md" && -f "$1/wiki/_master-index.md" ]] && return 0
  [[ -d "$1/.claude/skills/raw-compile" || -d "$1/.claude/skills/audit-wiki" ||
     -d "$1/.claude/skills/update-wiki" || -e "$1/.claude/skills/.wiki-version" ]] && return 0
  [[ -f "$1/CLAUDE.md" ]] && [[ "$(head -n 1 "$1/CLAUDE.md")" == '# Knowledge Base'* ]]
}
if is_standalone "$TARGET" && ! is_master "$TARGET"; then
  die "$TARGET is a standalone wiki. A master needs a folder of its own, and the wiki can join it later as a workstream."
fi
EXISTING_MASTER=0
if is_master "$TARGET"; then EXISTING_MASTER=1; fi

# --- bookkeeping -----------------------------------------------------------
declare -a EXPECTED=()   # files that must exist at the end
declare -a COPIED=()     # "src|dest" pairs written this run, compared byte for byte
FAILURES=0

note()  { echo "$1 $2"; }                       # e.g. note WROTE /path
expect(){ EXPECTED+=("$1"); }

# Refuse to write through a symlink: cp follows it into whatever it points at.
no_symlinks() {
  local p
  for p in "$@"; do
    if [[ -L "$p" ]]; then
      note FAILED "$p (symlink, nothing written through it)"; FAILURES=$((FAILURES + 1)); return 1
    fi
  done
}

# copy SRC -> DEST only when DEST is absent; returns 1 when DEST was kept
copy_new() {
  local src="$1" dest="$2"
  expect "$dest"
  no_symlinks "$dest" "$(dirname "$dest")" || return 1
  if [[ -e "$dest" ]]; then
    note SKIPPED "$dest (exists, kept)"
    return 1
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  note WROTE "$dest"
  COPIED+=("$src|$dest")
}

make_gitkeep() {
  local dest="$1"
  expect "$dest"
  no_symlinks "$dest" "$(dirname "$dest")" || return 0
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" ]]; then
    note SKIPPED "$dest (exists)"
  else
    : > "$dest"
    note WROTE "$dest"
  fi
}

# --- master-level files ----------------------------------------------------
mkdir -p "$TARGET/raw" "$TARGET/wiki" "$TARGET/output/_audits"
MASTER_SKILLS_DIR="$TARGET/.claude/skills"
MASTER_STAMP="$MASTER_SKILLS_DIR/.master-wiki-version"
MASTER_STAMP_WRITTEN=0

# The seed index is written once. After the first compile it holds the master's
# whole navigation map.
copy_new "$TEMPLATES_DIR/master-index.md" "$TARGET/wiki/_master-index.md" || true

if [[ -e "$MASTER_STAMP" ]]; then
  # An existing, stamped master: every managed file belongs to update-master-wiki,
  # which compares it with the release the stamp names. A missing file written
  # here would sit under a stamp that names another release.
  note SKIPPED "$MASTER_STAMP (existing master, stamp kept)"
  expect "$MASTER_STAMP"
  for dest in "$TARGET/CLAUDE.md" "$MASTER_SKILLS_DIR/master-compile/SKILL.md" \
              "$MASTER_SKILLS_DIR/master-audit/SKILL.md" "$MASTER_SKILLS_DIR/update-master-wiki/SKILL.md"; do
    if [[ -e "$dest" ]]; then
      note SKIPPED "$dest (exists, kept)"
    elif [[ "$dest" == */update-master-wiki/SKILL.md ]]; then
      note MISSING "$dest (paste the bootstrap prompt from the README's 'If update doesn't do anything', then type /update-master-wiki)"
    else
      note MISSING "$dest (say \`update\` at the master root to restore it)"
    fi
  done
else
  HELD_BACK=""
  copy_new "$TEMPLATES_DIR/CLAUDE.md" "$TARGET/CLAUDE.md" || HELD_BACK="CLAUDE.md@unknown"
  for s in "${MASTER_SKILLS[@]}"; do
    copy_new "$TEMPLATES_DIR/$s.SKILL.md" "$MASTER_SKILLS_DIR/$s/SKILL.md" ||
      HELD_BACK="${HELD_BACK:+$HELD_BACK, }$s@unknown"
  done
  # The stamp vouches only for files this run wrote. A kept file is from an
  # unknown release, so update-master-wiki compares it without a pristine copy.
  no_symlinks "$MASTER_STAMP" || exit 1
  {
    echo "# Managed by master-wiki-generator. Do not edit by hand."
    echo "source: https://github.com/davron-design/master-wiki-generator"
    echo "version: $MASTER_VERSION"
    echo "updated: $TODAY"
    if [[ -n "$HELD_BACK" ]]; then echo "held-back: $HELD_BACK"; fi
  } > "$MASTER_STAMP"
  note WROTE "$MASTER_STAMP (version $MASTER_VERSION${HELD_BACK:+, held back: $HELD_BACK})"
  expect "$MASTER_STAMP"
  MASTER_STAMP_WRITTEN=1
fi

# --- master settings --------------------------------------------------------
# Claude Code loads a workstream's skills into a master-root session once the
# session reads a workstream file. The master's .claude/settings.json switches
# them off there (skillOverrides). Settings apply only to sessions opened in
# their own folder, so the workstreams keep their skills. An existing settings
# file holds the user's own settings and is never replaced; the agent adds the
# missing entries (SKILL.md step 9).
SETTINGS_DEST="$TARGET/.claude/settings.json"
if [[ -L "$SETTINGS_DEST" ]]; then
  echo "NOTE settings $SETTINGS_DEST is a symlink and was left alone; check that it switches off: ${WS_SKILLS[*]}"
elif [[ -e "$SETTINGS_DEST" ]]; then
  MISSING_OFF=""
  if command -v python3 >/dev/null 2>&1; then
    MISSING_OFF="$(python3 -c 'import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    print(" (not valid JSON)"); sys.exit()
o = d.get("skillOverrides") if isinstance(d, dict) else None
o = o if isinstance(o, dict) else {}
print("".join(" " + s for s in sys.argv[2:] if o.get(s) != "off"))' "$SETTINGS_DEST" "${WS_SKILLS[@]}")"
  else
    for s in "${WS_SKILLS[@]}"; do
      tr -d '\n\r' < "$SETTINGS_DEST" |
        grep -Eq "\"skillOverrides\"[[:space:]]*:[[:space:]]*\\{[^}]*\"$s\"[[:space:]]*:[[:space:]]*\"off\"" ||
        MISSING_OFF="$MISSING_OFF $s"
    done
  fi
  if [[ -n "$MISSING_OFF" ]]; then
    echo "NOTE settings $SETTINGS_DEST exists and doesn't switch off:$MISSING_OFF"
  else
    note SKIPPED "$SETTINGS_DEST (exists, workstream skills already off)"
  fi
else
  copy_new "$TEMPLATES_DIR/settings.json" "$SETTINGS_DEST" || true
fi

# --- setup-notes with WORKSTREAMS substitution -----------------------------
if [[ "$MODE" == "fresh" ]]; then
  SETUP_SRC="$TEMPLATES_DIR/workstream-setup-notes.fresh.md"
else
  SETUP_SRC="$TEMPLATES_DIR/workstream-setup-notes.placeholder.md"
fi
SETUP_DEST="$TARGET/raw/_workstream-setup-notes.md"
SETUP_WRITTEN=0

if [[ "$EXISTING_MASTER" -eq 1 ]]; then
  # The first master compile archives the setup notes. A new copy written when
  # workstreams are added later would come back as a loose source.
  echo "NOTE setup notes are written only for a new master; this run adds: ${WS_FOLDERS[*]}"
elif [[ -e "$SETUP_DEST" ]]; then
  note SKIPPED "$SETUP_DEST (exists, kept)"
  UNLISTED=""
  for folder in "${WS_FOLDERS[@]}"; do
    grep -qF "raw/${folder}/" "$SETUP_DEST" || UNLISTED="$UNLISTED $folder"
  done
  if [[ -n "$UNLISTED" ]]; then echo "NOTE the kept setup notes don't list:$UNLISTED"; fi
else
  # one bullet per workstream folder, written to a temp file so awk can read it
  # (BSD awk rejects embedded newlines in a -v variable, so we read from disk).
  BULLETS_FILE="$(mktemp)"
  trap 'rc=$?; rm -f "$BULLETS_FILE"; exit $rc' EXIT
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
  SETUP_WRITTEN=1
fi
if [[ "$SETUP_WRITTEN" -eq 1 || -e "$SETUP_DEST" ]]; then expect "$SETUP_DEST"; fi

# --- per-workstream --------------------------------------------------------
declare -a WS_STAMPS=()

for folder in "${WS_FOLDERS[@]}"; do
  ws_root="$TARGET/raw/$folder"

  if [[ -L "$ws_root" ]]; then
    note FAILED "$ws_root (symlink, left untouched)"; FAILURES=$((FAILURES + 1)); continue
  fi
  # A git submodule that hasn't been checked out yet is an empty folder. Writing
  # a wiki into it would block `git submodule update --init` later.
  if [[ -f "$TARGET/.gitmodules" ]] &&
     grep -Eq "^[[:space:]]*path[[:space:]]*=[[:space:]]*raw/$folder[[:space:]]*$" "$TARGET/.gitmodules"; then
    note SKIPPED "$ws_root (git submodule, run git submodule update --init to fetch it)"
    continue
  fi
  # Populated-folder guard: never touch a workstream folder that holds real
  # content (anything beyond a lone .gitkeep).
  if [[ -d "$ws_root" ]]; then
    leftover="$(find "$ws_root" -mindepth 1 ! -name '.gitkeep' ! -name '.DS_Store' -print -quit 2>/dev/null || true)"
    if [[ -n "$leftover" ]]; then
      note SKIPPED "$ws_root (populated workstream, left untouched)"
      continue
    fi
  fi

  mkdir -p "$ws_root"

  if [[ "$MODE" == "placeholder" ]]; then
    make_gitkeep "$ws_root/.gitkeep"
    continue
  fi

  # fresh-scaffold mode: a full wiki vault inside the workstream folder, the
  # same files wiki-generator scaffolds from release $WS_VERSION.
  mkdir -p "$ws_root/raw" "$ws_root/wiki" "$ws_root/output/_audits"
  copy_new "$WS_TEMPLATES_DIR/CLAUDE.md"       "$ws_root/CLAUDE.md"             || true
  copy_new "$WS_TEMPLATES_DIR/master-index.md" "$ws_root/wiki/_master-index.md" || true
  for s in "${WS_SKILLS[@]}"; do
    copy_new "$WS_TEMPLATES_DIR/$s.SKILL.md" "$ws_root/.claude/skills/$s/SKILL.md" || true
  done
  ws_stamp="$ws_root/.claude/skills/.wiki-version"
  no_symlinks "$ws_stamp" || continue
  {
    echo "# Managed by wiki-generator. Do not edit by hand."
    echo "source: https://github.com/davron-design/wiki-generator"
    echo "version: $WS_VERSION"
    echo "updated: $TODAY"
  } > "$ws_stamp"
  note WROTE "$ws_stamp (version $WS_VERSION)"
  expect "$ws_stamp"
  WS_STAMPS+=("$ws_stamp")

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
    # .gitkeep is intentionally empty; existence is all that matters
    if [[ ! -e "$f" ]]; then
      note FAILED "$f (missing)"; FAILURES=$((FAILURES + 1))
    fi
  elif [[ ! -s "$f" ]]; then
    note FAILED "$f (missing or empty)"; FAILURES=$((FAILURES + 1))
  fi
done

# Every template written this run must match its source byte for byte, because
# update-wiki and update-master-wiki later compare these files with the release.
for pair in "${COPIED[@]:-}"; do
  [[ -n "$pair" ]] || continue
  src="${pair%%|*}"; dest="${pair#*|}"
  if ! cmp -s "$src" "$dest"; then
    note FAILED "$dest (differs from $src)"; FAILURES=$((FAILURES + 1))
  fi
done

if [[ "$MASTER_STAMP_WRITTEN" -eq 1 ]] && ! grep -qx "version: $MASTER_VERSION" "$MASTER_STAMP"; then
  note FAILED "$MASTER_STAMP (no 'version: $MASTER_VERSION' line)"; FAILURES=$((FAILURES + 1))
fi
for st in "${WS_STAMPS[@]:-}"; do
  [[ -n "$st" ]] || continue
  if ! grep -qx "version: $WS_VERSION" "$st"; then
    note FAILED "$st (no 'version: $WS_VERSION' line)"; FAILURES=$((FAILURES + 1))
  fi
done

if [[ "$SETUP_WRITTEN" -eq 1 ]]; then
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
fi

echo ""
if [[ "$FAILURES" -gt 0 ]]; then
  echo "RESULT: FAILED ($FAILURES problem(s)). Do NOT report scaffold complete."
  exit 1
fi
echo "RESULT: OK (${#EXPECTED[@]} files verified)"
