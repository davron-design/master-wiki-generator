---
name: update-master-wiki
description: Update this master wiki's own machinery to the latest published master-wiki-generator release. Fetches the released CLAUDE.md, master-compile, master-audit and update-master-wiki files from GitHub, compares them with this master's copies and with the release it installed, shows local edits and what changed, asks before writing anything, and then lists which workstream wikis in raw/ need their own update. Use when the user says "update", "update the master wiki", "update the skills", "check for updates", "am I on the latest version", "repair the skills", "reinstall the skills", or runs /update-master-wiki in a session opened at a master wiki's root. Only the managed master files are rewritten; wiki/, raw/ and output/ are never touched. In a session opened inside a workstream folder, that workstream's update-wiki handles update instead.
---

# Update Master Wiki

This master wiki was scaffolded from the `master-wiki-generator` templates, and those
templates keep moving upstream. This skill pulls the current versions of the master's own
files down and applies them here, leaving every synthesis article, raw source, workstream wiki
and audit report exactly as it is.

## When to invoke
- User says "update", "update the master wiki", "update the skills", or "upgrade the master"
- User says "repair", "reinstall the skills", or "force update". Every run compares the files
  themselves, so `repair` adds one thing: it also offers to restore skill files that carry
  local edits the new release doesn't touch (step 9)
- User asks which version this master wiki is on, or whether it is behind
- User runs `/update-master-wiki`

Do **not** invoke this for wiki content: "update the index" and "update that article" are
compile and audit work.

## What this skill owns

Five paths, three entries in the master's settings file (step 13), and nothing else in the
vault.

| Upstream file | Local path |
|---|---|
| `templates/CLAUDE.md` | `<master>/CLAUDE.md` |
| `templates/master-compile.SKILL.md` | `<skills>/master-compile/SKILL.md` |
| `templates/master-audit.SKILL.md` | `<skills>/master-audit/SKILL.md` |
| `templates/update-master-wiki.SKILL.md` | `<skills>/update-master-wiki/SKILL.md` (this file) |
| `templates/VERSION` | `<skills>/.master-wiki-version` (stamp, written by step 12) |

`<skills>` is always `<master>/.claude/skills/`. Step 13 also makes sure `<master>/.claude/settings.json`
switches the workstream skills off in sessions opened at the master root, adding three
entries and leaving every other setting as it is. Everything else is off limits: `wiki/`, `raw/`,
`output/` and `.git/` are read-only to this skill. `raw/` holds the workstream wikis, each with
its own `CLAUDE.md`, skills and stamp, and each updates in a session opened in its own folder
with its own `update-wiki`. Step 15 only reads them, to tell the user which ones are behind.
`wiki/_master-index.md` is the master's navigation map: the scaffold seeds it once, and
nothing here writes it.

Upstream: `https://raw.githubusercontent.com/davron-design/master-wiki-generator`, read at two
refs:
- `main/templates/VERSION` names the latest release. It is the only file read from `main`.
- `refs/tags/v<VERSION>/` holds that release: the four templates and `CHANGELOG.md`. A tag
  never moves, so every file fetched from it belongs to the same release. The pristine copies
  of the release this master installed come from that release's own tag.

`raw.githubusercontent.com` caches each file for 5 minutes, separately. Right after a push,
`main` can serve a new file next to an old one, which is why templates never come from `main`.

## Before updating, ask yourself
- **Right root**: Is the working directory the master's root? A workstream wiki in `raw/` also
  holds `CLAUDE.md` and `wiki/_master-index.md`, and writing the master's files there would
  give that workstream a second set of conventions.
- **Which copies run**: Claude Code runs a skill in `~/.claude/skills/` ahead of a project
  skill with the same name. If global copies of `master-compile`, `master-audit` or
  `update-master-wiki` exist, this master has been running those, and refreshing its own
  copies changes nothing until the global ones move out of the way.
- **Local edits**: Does a managed file differ from the release it was installed from? The
  pristine copy from that release's tag answers this exactly. `CLAUDE.md` is the one people
  extend with project conventions, and a silent overwrite deletes that work with no trace.
- **Fetch integrity**: Did every file download cleanly? A truncated `SKILL.md` breaks compile
  in ways that only surface on the next run, so the fetch is all-or-nothing.
- **Undo path**: Is this vault a git repo with a clean tree? If it is, the whole update is one
  `git checkout` away from being reverted, which is worth telling the user before they decide.

## The stamp

`<skills>/.master-wiki-version` records which release each managed file came from:

```
# Managed by master-wiki-generator. Do not edit by hand.
source: https://github.com/davron-design/master-wiki-generator
version: 2026-10-02
updated: 2026-10-02
held-back: CLAUDE.md@unknown
```

- `version:` is the release every managed file came from, except the files listed in
  `held-back:`.
- `held-back:` is optional. It lists files that sit at a different release, comma-separated,
  as `<name>@<version>` or `<name>@unknown`. The names are `CLAUDE.md`, `master-compile`,
  `master-audit` and `update-master-wiki`.
- A file's **base version** is its `held-back:` version when it is listed there, and
  `version:` otherwise.
- A `version:` value that isn't a date (`YYYY-MM-DD` or `YYYY-MM-DD.N`) counts as `unknown`.
- No stamp at all means the master predates versioning: every base is `unknown`.

## Procedure

1. **Locate the master root.** Check the working directory, then walk up at most three
   levels. The first folder holding both `CLAUDE.md` and `wiki/_master-index.md` is the root
   you found; don't walk past it. It is a master wiki when `${CLAUDE_SKILL_DIR}` is
   `<root>/.claude/skills/update-master-wiki`, when its `CLAUDE.md` starts with `# Master Wiki`,
   or when it holds `.claude/skills/master-compile/`, `.claude/skills/update-master-wiki/` or
   `.claude/skills/.master-wiki-version`. Stop without writing when:
   - no root turns up. Tell the user where you looked. Do not scaffold anything.
   - the root looks like a standalone wiki that got this skill by mistake: its only master
     markers are this skill's folder and `${CLAUDE_SKILL_DIR}`, it also holds
     `.claude/skills/.wiki-version` or `.claude/skills/raw-compile/` or a `CLAUDE.md` starting
     `# Knowledge Base`, and its `raw/` holds no workstream folder (a child folder with its own
     `CLAUDE.md` and `wiki/_master-index.md`). Ask the user whether this folder is a master
     before going on.
   - the root is a workstream or standalone wiki. `update` there belongs to that wiki's own
     `update-wiki`, and this copy was loaded from a master folder above it or from a global
     install. Tell the user so, and give them the wiki-generator bootstrap prompt from step 15
     if the wiki has no `.claude/skills/update-wiki/`.
   - `<master>/.claude`, `<master>/.claude/skills/` or any managed destination is a symlink:
     `cp` would write through the link into whatever it points at, often a `templates/`
     folder.
   - `<master>/.claude/skills` is the global skills folder, which happens when the root is the
     home folder: a write there would change every project on the machine.

   The last two come from this script. Each `SYMLINK` or `GLOBAL-FOLDER` line is a stop:

   ```bash
   bash <<'EOF'
   W='<master root>'
   case "$W" in *'<'*) echo 'STOP unfilled'; exit 1 ;; esac
   for p in "$W/.claude" "$W/.claude/skills" "$W/CLAUDE.md" "$W/.claude/settings.json" \
            "$W/.claude/skills/.master-wiki-version" "$W"/.claude/skills/{master-compile,master-audit,update-master-wiki} \
            "$W"/.claude/skills/{master-compile,master-audit,update-master-wiki}/SKILL.md; do
     [ -L "$p" ] && echo "SYMLINK $p"
   done
   G="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
   if [ -d "$G" ] && [ -d "$W/.claude/skills" ] && [ "$(cd "$G" && pwd -P)" = "$(cd "$W/.claude/skills" && pwd -P)" ]; then
     echo "GLOBAL-FOLDER $G"
   fi
   true
   EOF
   ```

2. **Work out which copies run.** Record what you find; nothing is written in this step.
   - This copy of `update-master-wiki` was loaded from `${CLAUDE_SKILL_DIR}`. A path under the
     home folder's `.claude/skills/` means a global copy is running. If the path above is
     empty or still shows a placeholder, this Claude Code version doesn't fill it in; rely on
     the search below.
   - Note whether `<master>/.claude/skills/` exists. If this run creates it, the report has to
     mention `/reload-skills`.
   - Search for global copies by their frontmatter `name:`, since Claude Code takes a skill's
     name from that line and a renamed folder still runs:

     ```bash
     bash <<'EOF'
     seen=''
     for G in "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills" "${USERPROFILE:+$USERPROFILE/.claude/skills}"; do
       [ -d "$G" ] || continue
       r=$(cd "$G" && pwd -P)
       case "$seen" in *"|$r|"*) continue ;; esac   # on Windows both names can be one folder
       seen="$seen|$r|"
       grep -lE '^name: *(master-compile|master-audit|update-master-wiki)[[:space:]]*$' "$G"/*/SKILL.md 2>/dev/null |
         while IFS= read -r f; do echo "GLOBAL-SKILL $(dirname "$f")"; done
       grep -lE '^name: *(raw-compile|audit-wiki|update-wiki)[[:space:]]*$' "$G"/*/SKILL.md 2>/dev/null |
         while IFS= read -r f; do echo "GLOBAL-WORKSTREAM-SKILL $(dirname "$f")"; done
     done
     true
     EOF
     ```

     Each `GLOBAL-SKILL` line names a master skill folder, and those exact paths are what
     step 14 may move. A `GLOBAL-WORKSTREAM-SKILL` line names a workstream skill that runs
     ahead of every workstream's own copy. This skill leaves those in place: the `update-wiki`
     run inside a workstream offers to move them once that workstream has its own copies.

   - Look for workstream skills in the master's own skills folder. An older wiki-generator
     `update` run at the master root could have installed them there, where they sit next to
     the master's skills and answer `compile`, `audit` and `update` too. Fill in the master
     root and run:

     ```bash
     bash <<'EOF'
     W='<master root>'
     case "$W" in *'<'*) echo 'STOP unfilled'; exit 1 ;; esac
     grep -lE '^name: *(raw-compile|audit-wiki|update-wiki)[[:space:]]*$' "$W"/.claude/skills/*/SKILL.md 2>/dev/null |
       while IFS= read -r f; do echo "LOCAL-WORKSTREAM-SKILL $(dirname "$f")"; done
     [ -f "$W/.claude/skills/.wiki-version" ] && echo "LOCAL-WORKSTREAM-STAMP $W/.claude/skills/.wiki-version"
     g="$W/.claude/skills/master-wiki-generator"
     if [ -f "$g/SKILL.md" ]; then
       v=pre-versioning
       [ -s "$g/templates/VERSION" ] && v=$(tr -d '[:space:]' < "$g/templates/VERSION")
       echo "GENERATOR-COPY ${v:-pre-versioning}"
     fi
     true
     EOF
     ```

     Those exact paths are what step 14 may move. A `GENERATOR-COPY` line means the master
     holds its own copy of `master-wiki-generator`, which this skill doesn't update. A copy
     marked `pre-versioning` still offers the retired "install for all projects" option, which
     writes skills into `~/.claude/skills/`. A copy older than the latest release scaffolds new
     workstreams from older templates. Either way the report tells the user to refresh it
     (step 16).

   - Check `.claude/skills/` in each parent folder of the master. Claude Code loads project
     skills from parent folders, and on a name clash the root copy runs. The scan stops at the
     git repository root, at the home folder (whose `.claude/skills` is the global folder,
     covered above), or at the filesystem root:

     ```bash
     bash <<'EOF'
     W='<master root>'
     case "$W" in *'<'*) echo 'STOP unfilled'; exit 1 ;; esac
     d=$(cd "$W" && pwd -P); h=$(cd "$HOME" 2>/dev/null && pwd -P || echo /)
     top=$(git -C "$W" rev-parse --show-toplevel 2>/dev/null || true)
     [ -n "$top" ] && top=$(cd "$top" && pwd -P)
     while [ "$d" != / ] && [ "$d" != "$h" ] && [ "$d" != "$top" ]; do
       d=$(dirname "$d")
       [ "$d" = "$h" ] && break
       [ -d "$d/.claude/skills" ] && echo "PARENT-SKILLS $d/.claude/skills"
     done
     true
     EOF
     ```

3. **Read the stamp** and work out each file's base version (see *The stamp*). Call the
   stamp's `version:` value `LOCAL`, or `unknown` when there is no stamp or the value isn't a
   date.

4. **Fetch the release and the pristine copies in one Bash call.** Shell variables don't
   survive between Bash calls, so everything happens in this single call. Fill in the two
   values at the top from step 3, then run it as shown. Every script in this skill runs
   through `bash <<'EOF'`, because the Bash tool may start another shell (zsh on macOS),
   which splits word lists and handles unmatched globs differently. Copy each script without
   its list indentation, so the closing `EOF` starts its line. Every script takes its values
   in single quotes, so write each `'` inside a value as `'\''`: a folder named
   `Dana's Master` becomes `'/path/to/Dana'\''s Master'`. A script that still holds a `<...>`
   placeholder prints `STOP unfilled` and does nothing; fill the value in and run it again.

   ```bash
   bash <<'EOF'
   LOCAL='<version: from the stamp, or unknown>'
   BASES='<distinct base versions from step 3, space-separated, unknown left out>'
   ANY_UNKNOWN='<yes if any base from step 3 is unknown, else no>'
   case "$LOCAL $BASES $ANY_UNKNOWN" in *'<'*) echo 'STOP unfilled'; exit 1 ;; esac
   R=https://raw.githubusercontent.com/davron-design/master-wiki-generator
   FILES='CLAUDE.md master-compile.SKILL.md master-audit.SKILL.md update-master-wiki.SKILL.md'
   D='[0-9]{4}-[0-9]{2}-[0-9]{2}(\.[0-9]+)?'
   printf '%s' "$LOCAL" | grep -Eqx "$D" || LOCAL=unknown
   T=$(mktemp -d) || { echo 'STOP no-tempdir'; exit 1; }
   echo "TMP $T"
   stop() { echo "STOP $*"; rm -rf "$T"; exit 1; }   # a stopped run leaves no temp folder
   get() {   # get <ref> <path> <dest>: succeeds only on HTTP 200 with a non-empty body
     mkdir -p "$(dirname "$3")"
     c=$(curl -fsSL --retry 2 --connect-timeout 10 --max-time 60 -w '%{http_code}' -o "$3" "$R/$1/$2")
     echo "$c $1/$2"
     [ "$c" = 200 ] && [ -s "$3" ]
   }
   # The latest version: the only file read from main.
   get main templates/VERSION "$T/VERSION" || stop no-version
   V=$(tr -d '[:space:]' < "$T/VERSION")
   printf '%s' "$V" | grep -Eqx "$D" || stop not-github
   echo "LATEST $V"
   if [ "$LOCAL" != unknown ] && [ "$(printf '%s\n' "$LOCAL" "$V" | sort -V | tail -n 1)" != "$V" ]; then
     stop older-than-local
   fi
   # The release, from its tag.
   get "refs/tags/v$V" templates/VERSION "$T/new/VERSION" || stop tag-missing
   [ "$(tr -d '[:space:]' < "$T/new/VERSION")" = "$V" ] || stop tag-mismatch
   for f in $FILES; do
     get "refs/tags/v$V" "templates/$f" "$T/new/$f" || stop release-incomplete
   done
   get "refs/tags/v$V" CHANGELOG.md "$T/new/CHANGELOG.md" || stop release-incomplete
   get "refs/tags/v$V" templates/settings.json "$T/new/settings.json" || stop release-incomplete
   for s in master-compile master-audit update-master-wiki; do
     [ "$(sed -n 1p "$T/new/$s.SKILL.md" | tr -d '\r')" = '---' ] &&
     [ "$(sed -n 2p "$T/new/$s.SKILL.md" | tr -d '\r')" = "name: $s" ] || stop bad-frontmatter "$s"
   done
   opt() {   # like get, for copies that may be missing: 404 is normal, anything else is reported
     get "$@" 2>/dev/null || { [ "$c" = 404 ] || echo "WARN $c $1/$2"; rm -f "$3"; return 1; }
     case "$2" in   # a proxy or portal page can answer 200 too
       *.SKILL.md) [ "$(sed -n 1p "$3" | tr -d '\r')" = '---' ] ;;
       *CLAUDE.md) sed -n 1p "$3" | grep -q '^# ' ;;
     esac || { echo "WARN bad-content $1/$2"; rm -f "$3"; return 1; }
   }
   # Earlier releases, newest first, read from the changelog, to recognize a file left at an
   # older release. The first one is the previous release; the rest matter only for files
   # whose base is unknown.
   tr -d '\r' < "$T/new/CHANGELOG.md" | sed -n 's/^## \([0-9][-0-9.]*\)[[:space:]]*$/\1/p' |
     awk -v v="$V" 'f { print } $0 == v { f = 1 }' > "$T/all-releases"
   if [ "$ANY_UNKNOWN" = yes ]; then cp "$T/all-releases" "$T/releases"; else sed -n 1p "$T/all-releases" > "$T/releases"; fi
   echo "PREVIOUS $(sed -n 1p "$T/all-releases" | grep . || echo none)"
   while IFS= read -r r; do
     n=0
     for f in $FILES; do opt "refs/tags/v$r" "templates/$f" "$T/rel-$r/$f" && n=$((n + 1)); done
     [ "$n" -gt 0 ] || echo "WARN tag-missing v$r"
   done < "$T/releases"
   # Pristine copies of what this master installed. A 404 here is normal for untagged versions.
   for b in $BASES; do
     printf '%s' "$b" | grep -Eqx "$D" || continue
     if [ "$b" = "$V" ]; then cp -R "$T/new" "$T/base-$b"; continue; fi
     if [ -d "$T/rel-$b" ]; then cp -R "$T/rel-$b" "$T/base-$b"; continue; fi
     for f in $FILES; do opt "refs/tags/v$b" "templates/$f" "$T/base-$b/$f" || true; done
   done
   echo DONE
   EOF
   ```

   The first line of output is `TMP <path>`. Use that literal path in every later command.
   After a `STOP` the folder is already gone.
   `DONE` on the last line means the fetch succeeded. A missing pristine copy leaves its files
   without one, which step 7 handles. `PREVIOUS` names the release before this
   one. Step 7 compares files with every earlier release's copies to recognize a file left at
   an older release; a 404 for one of them means that file didn't exist yet in that release.
   A `WARN <status>` line means an earlier copy is missing because of the network or GitHub,
   `WARN bad-content` that something other than GitHub answered for it, and
   `WARN tag-missing v<r>` that the tag of a release the changelog names is gone or not
   pushed. In each case a file can show as "no pristine" for that reason alone. Tell the
   user, and suggest running `update` again later before taking a release over a file with
   local edits. A timeout shows as status `000`.

5. **Handle a stop.** A `STOP <code>` line means the run ends here, and nothing in the vault
   has changed, so there is nothing to roll back. The status printed just above the `STOP`
   line tells the network cases apart.

   | Output | What happened | What to tell the user |
   |---|---|---|
   | `no-version`, status `000` | No connection to GitHub: offline, a proxy, or TLS inspection on a corporate network (curl's error line names it) | Network problem. Check the connection or proxy and try again. |
   | `no-version`, status `404` | The repo moved or went private | The update source is gone. Tell the maintainer. |
   | any code, status `429` | GitHub's rate limit for this network | Try again in an hour. |
   | any code, status `000` | The connection dropped during the run | Network problem. Check the connection or proxy and try again. |
   | `no-version`, any other status | A GitHub outage | Try again later. |
   | `not-github` | Something other than GitHub answered, such as a proxy or captive portal page | Something between this computer and GitHub answered instead. Check the network. |
   | `older-than-local` | The cache served an older `VERSION` than this master already runs | Try again in about 10 minutes. Never downgrade. |
   | `tag-missing` | `VERSION` names a release whose tag doesn't exist yet. The tag appears about a minute after a push, and a miss stays cached for 5 minutes | The release is still being published. Wait 10 minutes and try again. If it still fails after an hour, tell the maintainer that tag `v<V>` is missing. |
   | `tag-mismatch`, `release-incomplete`, `bad-frontmatter` | The release itself is broken | Tell the maintainer which code appeared. |
   | `no-tempdir` | No temporary folder could be created | Report the error as printed. |
   | `unfilled` | The script ran with its placeholders still in it | Fill in the values from step 3 and run it again. Nothing to tell the user. |

   Never retry from `main` after a stop. Mixing files from two releases is the failure the
   tags exist to prevent.

   If the script ran without its `bash <<'EOF'` wrapper, or with an indented closing `EOF`,
   its STOP codes can be wrong (zsh, for one, turns the file list into a single word). Rerun
   it as shown before telling the user anything.

6. **Read the changelog gap.** From `<TMP>/new/CHANGELOG.md`, take every entry newer than the
   oldest known base version. Order versions with `sort -V`. If any base is `unknown`, take
   the whole file.

7. **Classify each managed file in one Bash call.** Fill in the literal `TMP` path, the master
   root, and each file's base version from step 3 (`unknown` points at a folder that doesn't
   exist, which is intended).

   ```bash
   bash <<'EOF'
   T='<TMP path from step 4>'; W='<master root>'
   case "$T $W" in *'<'*) echo 'STOP unfilled'; exit 1 ;; esac
   same() { diff -q --strip-trailing-cr "$1" "$2" >/dev/null 2>&1; }
   norm() { tr -d '\r' < "$1" | sed 's/[[:space:]]*$//' | grep -v '^$'; }
   ws()   { [ "$(norm "$1")" = "$(norm "$2")" ]; }   # equal apart from spacing and blank lines
   older() {   # older <local path> <file>: the newest earlier release whose copy equals it
     while IFS= read -r r; do
       [ -f "$T/rel-$r/$2" ] && same "$1" "$T/rel-$r/$2" && { echo "$r"; return 0; }
     done < "$T/releases"
     return 1
   }
   classify() {   # classify <file> <local path> <pristine folder>
     case "$3" in *'<'*) echo 'STOP unfilled'; exit 1 ;; esac
     L=$2; U="$T/new/$1"; P="$3/$1"
     if   [ ! -f "$L" ];  then b='missing locally'
     elif same "$L" "$U"; then b='current'
     elif [ -f "$P" ] && same "$L" "$P"; then b='upstream change only'
     elif r=$(older "$L" "$1"); then b="older release copy $r"
     elif [ ! -f "$P" ];  then b='no pristine'
     elif ws "$L" "$P";   then b='whitespace only'
     elif same "$P" "$U"; then b='local edit only'
     else                      b='local edit + upstream change'
     fi
     printf '%-29s %s\n' "$1" "$b"
   }
   classify CLAUDE.md                    "$W/CLAUDE.md"                                  "$T/base-<CLAUDE.md base>"
   classify master-compile.SKILL.md      "$W/.claude/skills/master-compile/SKILL.md"     "$T/base-<master-compile base>"
   classify master-audit.SKILL.md        "$W/.claude/skills/master-audit/SKILL.md"       "$T/base-<master-audit base>"
   classify update-master-wiki.SKILL.md  "$W/.claude/skills/update-master-wiki/SKILL.md" "$T/base-<update-master-wiki base>"
   EOF
   ```

   `--strip-trailing-cr` keeps a Windows checkout's line endings from posing as local edits.
   In the table, L is the local file, P the pristine copy of its base version, U the release:

   | Bucket | Condition | What the user sees | Question (step 9) | Base if the file is kept |
   |---|---|---|---|---|
   | current | L = U | "current" | none | V |
   | missing locally | no L | "will be installed" | part of the batch question; asked alone: Install (recommended) / Skip | n/a: a skipped file stays missing, gets no `held-back:` entry, and is offered again next run |
   | older release copy `<r>` | L ≠ P, L = the copy from earlier release `<r>` | "Matches release `<r>` exactly, so it carries no local edits; this release changes it." Displayed like an upstream change | Update (recommended) / Keep | `<r>` |
   | upstream change only | L = P, P ≠ U | One line naming the changed `#` headings, with the lines added and removed. Always the full diff for `CLAUDE.md`; for a skill, the full diff on request | Update (recommended) / Keep | its old base |
   | whitespace only | L and P differ only in spacing, line endings or blank lines | "Differs from the installed copy only in whitespace; no real local edits." Displayed like an upstream change | Update (recommended) / Keep | its old base |
   | local edit only | L ≠ P, P = U | "Has local edits; this release leaves it unchanged; kept", plus the full P→L diff | none, except under `repair`: Keep (recommended) / Restore the release copy | V |
   | local edit + upstream change | all three differ | The local edits (full P→L diff), the release's change (P→U, in full for `CLAUDE.md`, summarized for a skill), and every local line the update would drop | Keep mine / Take the release (drops the edits shown) | its old base |
   | no pristine | L ≠ U, no P | "Can't separate local edits from older template text." The full L→U diff for `CLAUDE.md`; for a skill a summary, the number of local lines the update would drop, and the full diff on request | Take the release / Keep mine | `unknown` |

   A file written in step 10 gets base V. "Displayed like an upstream change" means the
   full diff for `CLAUDE.md` and a summary of the changed headings for a skill. For a
   "no pristine" file, when `<TMP>/rel-<PREVIOUS>/<file>` exists, also show
   `diff -u` from it to the local file, labelled "differences from release `<PREVIOUS>`".
   It usually isolates the local edits from the older template text. "Local lines the
   update would drop" means the lines of the local file that the release doesn't contain.

8. **Show the user what will change**, before asking anything:
   - `This master: <LOCAL>` (plus any held-back bases) and `Latest: <V>`
   - The changelog entries from step 6, quoted as written
   - Each managed file with its bucket and the display from the table above. Produce every
     diff with `diff -u --strip-trailing-cr`.
   - If the vault is a git repo with a dirty tree, say so and suggest committing first (a
     bootstrap file pasted just before counts, and committing it is fine), so the
     update lands as a reviewable, revertable change.
   - Any global or parent-folder copies found in step 2, and that Claude Code runs those
     instead of this master's copies

9. **Ask before writing.** Use `AskUserQuestion`, which takes at most four questions per call.
   - **Nothing to do:** every file is current or "local edit only", and this run isn't a
     `repair`. Write nothing except the stamp when its bases change (step 12), report
     "up to date on `<V>`" with any local edits kept, and go on to step 13.
   - **No conflicts:** every changed file is "upstream change only", "older release copy",
     "whitespace only" or "missing locally". Ask one question: **Update all** (recommended) /
     **Choose per file** / **Cancel**.
   - **Anything else:** ask one question per non-current file in a single call, with the
     options from the table. There are at most four managed files, which fits the tool's
     limit. "Choose per file" leads to the same per-file questions.
   - **`repair` with nothing to restore:** every file is current. Report "nothing to restore
     on `<V>`" and ask nothing. Steps 13 to 15 still run.
   - **Cancel** means no writes and no stamp change. Steps 13 to 15 still run.

10. **Write the approved files** with `mkdir -p` and `cp "<TMP>/new/<file>" "<destination>"`,
    every path quoted. Never use the Write or Edit tool for these files: they re-type the
    content, and these files have to land byte for byte. Write in this order: `CLAUDE.md`,
    `master-compile`, `master-audit`, and `update-master-wiki` last. Writing this file last
    means a failure earlier in the run leaves the updater matching the templates it was
    reasoning about. Rewriting it mid-run is safe: the instructions you are following are
    already loaded.

11. **Verify before stamping.** For every file written this run, run
    `diff -q "<TMP>/new/<file>" "<destination>"`. A file that fails gets base `unknown` and is
    reported as a failure. The stamp vouches only for files that passed.

12. **Stamp the version.** Rewrite `<skills>/.master-wiki-version` with the header from
    *The stamp*, `version: <V>`, `updated:` set to today, and a `held-back:` line listing
    `<name>@<base>` for every file whose base after this run is not V. Leave the line out when
    every file is at V.

    Skip this step when no file was written and no base changed, so a run that kept
    everything leaves the stamp as it was.

    Under-claiming is the safe direction. A stamp that vouches for a file it never wrote hides
    that file from every later run's pristine comparison, and the next update reports a local
    edit as current, or the reverse.

13. **Switch the workstream skills off at the master root.** Claude Code loads a
    workstream's skills into a session opened here as soon as the session reads one of that
    workstream's files, and from then on `compile`, `audit` or `update` could run the
    workstream's copy against the master. `raw-compile` would treat the workstream wikis in
    `raw/` as sources and archive them. The master's `.claude/settings.json` switches those
    skills off for sessions opened here (the `skillOverrides` setting). Settings files apply
    only to sessions opened in their own folder, so the workstreams keep their skills in
    sessions opened in their folders. Fill in the master root and run:

    ```bash
    bash <<'EOF'
    F='<master root>/.claude/settings.json'
    case "$F" in *'<'*) echo 'STOP unfilled'; exit 1 ;; esac
    if [ -L "$F" ]; then echo 'SETTINGS symlink'
    elif [ ! -e "$F" ]; then echo 'SETTINGS missing'
    elif command -v python3 >/dev/null 2>&1; then
      python3 -c 'import json, sys
    try:
        d = json.load(open(sys.argv[1], encoding="utf-8"))
    except Exception:
        print("SETTINGS invalid-json"); sys.exit()
    o = d.get("skillOverrides") if isinstance(d, dict) else None
    o = o if isinstance(o, dict) else {}
    for s in ("raw-compile", "audit-wiki", "update-wiki"):
        print(("OFF " if o.get(s) == "off" else "NOT-OFF ") + s)' "$F"
    else   # no python3: a text check that the entries sit somewhere after "skillOverrides"
      for s in raw-compile audit-wiki update-wiki; do
        if tr -d '\n\r' < "$F" | grep -Eq "\"skillOverrides\"[[:space:]]*:[[:space:]]*\\{[^}]*\"$s\"[[:space:]]*:[[:space:]]*\"off\""; then
          echo "OFF $s"; else echo "NOT-OFF $s"; fi
      done
    fi
    EOF
    ```

    - `OFF` for all three: nothing to do.
    - `SETTINGS missing`: ask **Add the settings file** (recommended) / **Skip**. On yes, copy it
      from the release with `mkdir -p "<master root>/.claude"` and
      `cp -n "<TMP>/new/settings.json" "<master root>/.claude/settings.json"`, and confirm with
      `diff -q`.
    - `NOT-OFF` for any of them: show the file, then ask **Add the entries** (recommended) /
      **Skip**. On yes, edit the file with the Edit tool so it holds a `skillOverrides` object
      with `"raw-compile": "off"`, `"audit-wiki": "off"` and `"update-wiki": "off"`, adding the
      object if it's missing and keeping every other setting exactly as it was. Read the file
      back and check it is still valid JSON. If one of the three is set to another value, the
      user set it on purpose: show it and ask before changing it.
    - `SETTINGS symlink`: leave it, and tell the user the file points somewhere else, so this
      skill won't write through it.
    - `SETTINGS invalid-json`: leave it, and tell the user the file doesn't parse as JSON, so
      Claude Code may be ignoring it. They fix it by hand, then run `update` again.

    The settings file isn't stamped, and step 7 doesn't compare it: it holds the user's own
    settings too. Claude Code reads settings when a session starts, so a change here takes
    effect in the next session opened in this folder.

14. **Offer to move stray skill copies aside** when step 2 found `GLOBAL-SKILL` or
    `LOCAL-WORKSTREAM-SKILL` lines. Ask after the update, in a separate question, so this
    master's own copies are already in place.
    - For `GLOBAL-SKILL` lines, tell the user: "Claude Code runs `<global skills folder>/<name>`
      instead of this master's copy, so `compile`, `audit` and `update` here have been running
      those." Other master wikis on this computer without their own `.claude/skills/` use those
      copies too, and lose their master skills when the copies move. Each of them gets its own
      copies with the bootstrap prompt (below), which ends with typing `/update-master-wiki`.
    - For `LOCAL-WORKSTREAM-SKILL` and `LOCAL-WORKSTREAM-STAMP` lines, tell the user: "This
      master's own skills folder holds workstream skills, so `compile`, `audit` and `update`
      here can run those against the master." Step 13's settings switch them off, and moving them
      out also covers Claude Code versions without that setting. Nothing else uses them.
    - Options: **Move them now** / **Leave them**.
    - On an explicit yes, move exactly the paths from step 2, each whole, and delete nothing.
      Global copies go into a backup folder in the Claude Code folder, and copies from the
      master's own skills folder into a backup folder next to it, outside `skills/`. `mv -n`
      never overwrites, and the script reports anything it couldn't move:

      ```bash
      bash <<'EOF'
      move() {   # move <backup folder> <path>...
        case "$*" in *'<'*) echo 'STOP unfilled'; exit 1 ;; esac
        B=$1; shift
        mkdir -p "$B" || exit 1
        for p in "$@"; do
          if [ -e "$p" ] && mv -n "$p" "$B/" && [ ! -e "$p" ]; then echo "MOVED $p"; else echo "NOT MOVED $p"; fi
        done
        ls -la "$B"
      }
      STAMP=$(date +%Y-%m-%d-%H%M%S)
      move "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/master-wiki-skills-backup-$STAMP" '<GLOBAL-SKILL folder>' '<GLOBAL-SKILL folder>'
      move '<master root>/.claude/workstream-skills-backup-'"$STAMP" '<LOCAL-WORKSTREAM-SKILL folder>' '<LOCAL-WORKSTREAM-STAMP file>'
      EOF
      ```

      Leave out a `move` line that has no paths. Report every `NOT MOVED` line; those copies
      still run.
    - Renaming a folder inside a skills folder doesn't disable it, so the folders have to
      leave that directory.
    - Copies in a parent folder's `.claude/skills/` belong to that project. Name their paths
      and leave the decision to the user.
    - `GLOBAL-WORKSTREAM-SKILL` folders stay where they are. Tell the user that they run
      instead of every workstream's own `raw-compile`, `audit-wiki` or `update-wiki`, and that
      saying `update` inside each workstream (step 15) offers to move them once that
      workstream has its own copies.

15. **Check the workstream wikis.** They aren't this skill's to write, so this step only reads
    them and tells the user what each one needs. Fill in the master root, writing each `'`
    of the path as `'\''`, and run:

    ```bash
    bash <<'EOF'
    M='<master root>'
    case "$M" in *'<'*) echo 'STOP unfilled'; exit 1 ;; esac
    shopt -s nullglob
    V=$(curl -fsSL --retry 2 https://raw.githubusercontent.com/davron-design/wiki-generator/main/templates/VERSION 2>/dev/null | tr -d '[:space:]')
    printf '%s' "$V" | grep -Eqx '[0-9]{4}-[0-9]{2}-[0-9]{2}(\.[0-9]+)?' || V=unknown
    echo "WIKI-GENERATOR-LATEST $V"
    for d in "$M"/raw/*/; do
      d=${d%/}; n=$(basename "$d")
      case "$n" in _*) continue ;; esac
      if [ ! -f "$d/CLAUDE.md" ] || [ ! -f "$d/wiki/_master-index.md" ]; then echo "NOT-A-WIKI $n"; continue; fi
      if [ -e "$d/.git" ]; then echo "OWN-REPO $n"; continue; fi
      if [ ! -f "$d/.claude/skills/update-wiki/SKILL.md" ]; then echo "NO-UPDATER $n"; continue; fi
      w=$( { sed -n 's/^version:[[:space:]]*//p' "$d/.claude/skills/.wiki-version" 2>/dev/null || true; } | head -n 1 | tr -d '[:space:]')
      if [ -z "$w" ]; then echo "BEHIND $n no-stamp"
      elif [ "$V" = unknown ]; then echo "VERSION $n $w"
      elif [ "$w" = "$V" ] || [ "$(printf '%s\n' "$w" "$V" | sort -V | tail -n 1)" = "$w" ]; then echo "CURRENT $n $w"
      else echo "BEHIND $n $w"; fi
    done
    EOF
    ```

    | Line | What it means | What to tell the user |
    |---|---|---|
    | `CURRENT <name> <version>` | A workstream on the latest wiki-generator release | Nothing to do. |
    | `BEHIND <name> <version>` | A workstream on an older release, or with no stamp | Open `raw/<name>/` in a new Claude Code session and say `update` there. |
    | `VERSION <name> <version>` | The latest wiki-generator version couldn't be read | Name the workstream's version, and suggest `update` in its folder to check. |
    | `NO-UPDATER <name>` | A workstream scaffolded before workstreams got `update-wiki` | Open `raw/<name>/` in a new Claude Code session, paste the wiki-generator bootstrap prompt below, start another new session there, and say `update`. |
    | `OWN-REPO <name>` | The folder is its own git repository (a submodule or a clone) | It updates in its own repository, outside this master. |
    | `NOT-A-WIKI <name>` | An empty placeholder or a folder of loose files | Nothing to update. |

    The wiki-generator bootstrap prompt for a workstream with no `update-wiki` is, word for
    word:

    > Run this exact command with Bash in this folder, and do not use WebFetch: `curl -fsSL --create-dirs -o .claude/skills/update-wiki/SKILL.md https://raw.githubusercontent.com/davron-design/wiki-generator/main/templates/update-wiki.SKILL.md` Then tell me to start a new Claude Code session here and say `update`.

16. **Report** (see *Output to the user*), then remove the temporary folder with
    `rm -rf '<TMP path from step 4>'`.

## Bootstrapping a master that has no `update-master-wiki` yet

Master wikis scaffolded before this skill existed cannot run it. Give the user this to paste
into Claude Code from inside the master's root folder, once. It ends with the typed command
`/update-master-wiki`, since a word like `update` could still reach an old global copy of
wiki-generator's `update-wiki` in a master that has no settings file yet:

> Run this exact command with Bash in this folder, and do not use WebFetch: `curl -fsSL --create-dirs -o .claude/skills/update-master-wiki/SKILL.md https://raw.githubusercontent.com/davron-design/master-wiki-generator/main/templates/update-master-wiki.SKILL.md` Then tell me to start a new Claude Code session here and type `/update-master-wiki`.

From then on the skill updates itself along with everything else.

## Output to the user

After the run, report:
- The version move (`<before>` to `<after>`), or "already on `<version>`"
- Each managed file: written, already current, kept with local edits, skipped at the user's
  request, or failed verification
- Global copies and stray workstream skills: moved to a backup folder, or still in place and
  still running instead of this master's copies
- The settings file from step 13: already in place, added, or skipped (and then that the
  workstream skills can still answer `compile`, `audit` and `update` here)
- Each workstream wiki from step 15 and what it needs
- A `GENERATOR-COPY` from step 2 that is `pre-versioning` or older than `<V>`: tell the user to
  refresh it before adding workstreams, by pasting the README's Step 3 install prompt again in
  a session opened at the master root. A `pre-versioning` copy still offers the retired
  global install option, so say that too.
- When the changes take effect:
  - Claude Code picks up the new skill files within this session.
  - If this run created `.claude/skills/`, run `/reload-skills` or start a new session, since
    Claude Code isn't watching a folder that didn't exist at launch. If a skill installed
    this run doesn't answer, `/reload-skills` loads it.
  - If `CLAUDE.md` or `.claude/settings.json` was written, start a new Claude Code session in
    this folder before the next compile or audit. Claude Code reads both only when a session
    starts.
- The undo commands when the vault is a git repo, built from what this run did: a
  `git checkout -- <path>` for each written file git already tracked, and an `rm <path>` for
  each file this run created (the stamp when there was none before, any file that was
  "missing locally", a new settings file). A `git checkout` alone would leave a new stamp
  vouching for files it has just reverted. Name any file this run overwrote that git doesn't
  track (an earlier uncommitted stamp, for example): it has no undo.

## Anti-patterns

- **NEVER use WebFetch to retrieve the templates.** It normalizes and can summarize markdown,
  and these files have to land byte for byte. Use `curl -fsSL`.
- **NEVER fetch a template or the changelog from `main`.** Each file on `main` is cached
  separately, so a run shortly after a push can mix a new `VERSION` with an old skill and stamp
  the mix as current. Only `VERSION` is read from `main`, and the templates and changelog come
  from the tag. If the tag is missing, stop and wait.
- **NEVER write anything under `wiki/`, `raw/`, or `output/`.** `raw/` holds the workstream
  wikis, and each one's files belong to its own `update-wiki`. `wiki/_master-index.md` is the
  master's navigation map, and writing the empty seed over it erases every theme row.
- **NEVER run a workstream's update from here.** Its `update-wiki` reads that workstream's
  stamp and asks its own questions, in a session opened in its folder. Step 15 only reads and
  reports.
- **NEVER apply a partial fetch.** If one of the four templates or the changelog fails to
  download or fails its checks, write none of them. Half an update leaves a master whose
  skills disagree with its `CLAUDE.md`.
- **NEVER treat a missing pristine copy as "unmodified".** Without the installed release's own
  file, local edits and older template text look the same. Classify the file as "no pristine"
  and show the diff.
- **NEVER overwrite `CLAUDE.md` without printing the diff first.** It is the one managed file
  teams extend with their own conventions, and an overwrite is unrecoverable outside git.
- **NEVER drop a `held-back:` entry for a file that isn't at the stamped version.** The stamp
  is what the next run trusts; an entry dropped too early points the next comparison at the
  wrong pristine copy.
- **NEVER edit a template while installing it, and never copy a local file back upstream.**
  Templates flow one way, repo to master. A fix belongs in `master-wiki-generator/templates/`
  first, and reaches this master on the next update.
- **NEVER write into `~/.claude/skills/`.** Global copies run ahead of every project's own, so a
  write there changes every master on the machine at once. The only allowed action is moving
  the master skills out (step 14), after the user explicitly agrees, and nothing is ever
  deleted.
- **NEVER replace the master's `.claude/settings.json`.** It holds the user's own settings
  too. Step 13 copies the release's file only when none exists, and otherwise adds the three
  entries and keeps the rest.
- **NEVER run compile or audit as part of an update.** They are separate skills with separate
  confirmation steps, and folding them in hides real content changes inside what the user
  approved as a template refresh.
- **NEVER report success without step 11.** A failed copy leaves a master that looks updated
  with a broken file in it, and the version stamp would then vouch for that file.
