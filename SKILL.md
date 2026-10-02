---
name: master-wiki-generator
description: Scaffold a cross-workstream master wiki, a synthesis layer above N workstream wikis that surfaces shared decisions, dependencies, risks, and timeline interlocks. Creates the master raw/wiki/output vault, installs its `master-compile`, `master-audit` and `update-master-wiki` companion skills inside it, and by default fully scaffolds each workstream as its own wiki vault under `raw/<ws-slug>-wiki/` (CLAUDE.md, raw/, wiki/, output/, `raw-compile`, `audit-wiki` and `update-wiki` skills), or leaves empty placeholders to wire existing wikis into. Re-running it on an existing master adds workstreams. Sibling of `wiki-generator` (which scaffolds a single workstream wiki); use this one to span two or more. Use when the user says "set up a master wiki", "scaffold/generate a master wiki", "spin up a cross-workstream wiki", "add a workstream to the master wiki", "install the master wiki skills", or runs /master-wiki-generator.
---

# Master Wiki Generator

Scaffolds a complete cross-workstream master wiki in a target directory: master-level folder layout (`raw/`, `wiki/`, `output/`), master-specific `CLAUDE.md`, empty `_master-index.md`, the companion `master-compile`, `master-audit` and `update-master-wiki` skills, and a version stamp. By default, it also fully scaffolds each workstream as its own wiki vault inside `raw/<ws-slug>-wiki/`, with its own `CLAUDE.md`, `raw/`, `wiki/`, `output/`, project-scoped `raw-compile`, `audit-wiki` and `update-wiki` companion skills, and its own stamp, so the entire hierarchy is ready to use in one step. Users who already have workstream wikis to wire in can opt to create empty placeholder folders instead.

This is the master-wiki sibling of `wiki-generator`. Use `wiki-generator` to scaffold a *single* workstream wiki on its own. Use this skill when you want a master synthesis layer spanning multiple workstream wikis, starting from scratch (fresh-scaffold mode) or with workstream wikis you already have (placeholder mode). Each fresh workstream wiki is the same set of files `wiki-generator` scaffolds from the release named in `templates/ws-templates/VERSION`, so it updates from `wiki-generator` like any other wiki.

## When to invoke
- User says "set up a master wiki", "scaffold a master wiki", "generate a master wiki", "spin up a cross-workstream wiki", or "install the master wiki skills"
- User wants to add workstreams to a master wiki that already exists
- User runs `/master-wiki-generator`
- User mentions wanting a wiki that spans multiple workstreams, projects, or teams
- User wants to bootstrap a cross-workstream synthesis layer — either fresh end-to-end or on top of existing wikis

## Before scaffolding, ask yourself
- **Single wiki vs. master**: If the user only has one workstream/project, they don't need a master wiki — the standard `wiki-generator` skill is enough. Surface this before scaffolding. The master wiki earns its keep specifically by synthesizing across two or more workstream wikis.
- **Target sanity**: Is the target directory empty (or non-existent)? Scaffolding into an in-use folder risks colliding with the user's existing `CLAUDE.md`, `wiki/`, or `.claude/skills/`. Confirm before writing.
- **Nested target**: Walk up from the target. If any ancestor directory already contains *both* `CLAUDE.md` and `wiki/_master-index.md`, that's an existing wiki vault, and placing a master wiki inside it is almost always a mistake (it produces two competing master indexes). Surface this to the user and require explicit confirmation. *(Note: the master wiki intentionally contains wiki vaults inside its own `raw/<ws-slug>-wiki/` folders. `master-compile` reads each one's `wiki/` subfolder and skips its `raw/` and `output/`, and the master's `.claude/settings.json` switches the workstream skills off in sessions opened at its root.)*
- **Existing master**: Is the target already a master wiki? Then the user either wants newer templates, which is `update-master-wiki`'s job (say **"update"** at the master root), or wants to add workstreams, which this skill does without rewriting any of the master's files (step 2).
- **Template integrity**: `scripts/scaffold.sh` checks this for you — it aborts before any write if a required template for the chosen mode is missing (the skill package would be broken and a partial scaffold would silently produce a non-functional master wiki). You do not need to pre-verify the templates by hand.
- **Global copies**: Does `~/.claude/skills/` already hold `master-compile`, `master-audit`, `update-master-wiki`, `raw-compile`, `audit-wiki` or `update-wiki`, from another project or an old global install? Claude Code runs a skill there ahead of a project skill with the same name, so the new master and its workstreams would run those copies instead of the ones this scaffold installs, and updates made inside them never reach those copies. Check before writing (step 3).

**Do NOT read the template files into context.** The scaffold is performed by `scripts/scaffold.sh`, which copies `templates/` → destination verbatim and substitutes the workstream list itself. Reading `master-compile.SKILL.md`, `audit-wiki.SKILL.md`, the `CLAUDE.md` templates, etc. into context wastes tokens and changes nothing — the script never needs you to have seen them. (The only file that gets edited rather than copied is the setup-notes, and the script does that substitution; you never edit it by hand.)

## What gets created

### Fresh-scaffold mode (default)

```
<target>/
├── CLAUDE.md                                  # master-wiki vault conventions
├── raw/                                       # input zone for cross-cutting files
│   ├── .gitkeep
│   ├── _workstream-setup-notes.md             # post-scaffold orientation, archived on first compile
│   ├── <ws1-slug>-wiki/                       # fully-formed wiki vault, one per workstream
│   │   ├── CLAUDE.md
│   │   ├── raw/.gitkeep
│   │   ├── wiki/_master-index.md
│   │   ├── output/_audits/.gitkeep
│   │   └── .claude/skills/
│   │       ├── .wiki-version                  # which wiki-generator release it runs
│   │       ├── raw-compile/SKILL.md
│   │       ├── audit-wiki/SKILL.md
│   │       └── update-wiki/SKILL.md
│   ├── <ws2-slug>-wiki/
│   │   └── ...                                # same structure
│   └── ...
├── wiki/                                      # the cross-workstream synthesis layer
│   └── _master-index.md                       # entry point, empty until first compile
├── output/                                    # query results and audit reports
│   └── _audits/.gitkeep
└── .claude/
    ├── settings.json                          # switches the workstream skills off at the master root
    └── skills/
        ├── .master-wiki-version               # which master-wiki-generator release it runs
        ├── master-compile/SKILL.md
        ├── master-audit/SKILL.md
        └── update-master-wiki/SKILL.md
```

### Placeholder mode

```
<target>/
├── CLAUDE.md                                  # master-wiki vault conventions
├── raw/
│   ├── .gitkeep
│   ├── _workstream-setup-notes.md             # wiring instructions: submodule vs. manual sync
│   ├── <ws1-slug>-wiki/                       # empty placeholder folder
│   │   └── .gitkeep
│   ├── <ws2-slug>-wiki/
│   │   └── .gitkeep
│   └── ...
├── wiki/
│   └── _master-index.md
├── output/
│   └── _audits/.gitkeep
└── .claude/
    ├── settings.json
    └── skills/
        ├── .master-wiki-version
        ├── master-compile/SKILL.md
        ├── master-audit/SKILL.md
        └── update-master-wiki/SKILL.md
```

The companion skills always live inside the master and inside each workstream, so every one of them carries and updates its own copies.

The setup-notes file at `raw/_workstream-setup-notes.md` is itself a cross-cutting file, so the first master compile archives it into `raw/_<date>-compiled/`. That's intentional: it only needs to be there until the user has gotten their bearings.

## Procedure

1. **Resolve the target directory.** If the user didn't specify, ask with `AskUserQuestion`:
   - **Current directory** (default — the user's CWD)
   - **A subfolder** (prompt for a name, e.g. `./my-master-wiki`)
   - **An absolute path the user types in**

   Refuse the home folder as a target, and any target whose `.claude` or `.claude/skills` is a symlink: skills written there could land in the global skills folder and run in every project. `scripts/scaffold.sh` enforces this too.

2. **Check for an existing master or wiki.** Nothing is written in this step.
   - If the target is a master wiki (its `CLAUDE.md` starts with `# Master Wiki`, or it holds `.claude/skills/master-compile/`, `.claude/skills/update-master-wiki/` or `.claude/skills/.master-wiki-version`), tell the user: newer templates come from saying **"update"** at the master root, which runs `update-master-wiki`, shows what changed and asks before writing. If the master has no `.claude/skills/update-master-wiki/` yet, give them the bootstrap prompt from `README.md` (*If `update` doesn't do anything*), which ends with typing `/update-master-wiki`. Then ask with `AskUserQuestion`: **Add workstreams** (scaffold only workstream folders that don't exist yet, and keep every existing master file as it is) / **Stop here**. An older master without a `.claude/skills/.master-wiki-version` stamp also gets the master files it lacks, such as `update-master-wiki`, and a stamp that marks its existing files `@unknown`, so the next `update` compares them in full. A master without `.claude/settings.json` gets one. No new setup-notes file is written, since the first compile archived the original.
   - If the target holds a standalone wiki (`CLAUDE.md` plus `wiki/_master-index.md`, and not a master), stop. A master needs a folder of its own. The existing wiki can join it later as a workstream, moved or synced into `raw/<ws-slug>-wiki/`.

3. **Check for global copies of the companion skills.** Search by frontmatter `name:`, since Claude Code takes a skill's name from that line and a renamed folder still runs:

   ```bash
   bash <<'EOF'
   seen=''
   for G in "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills" "${USERPROFILE:+$USERPROFILE/.claude/skills}"; do
     [ -d "$G" ] || continue
     r=$(cd "$G" && pwd -P)
     case "$seen" in *"|$r|"*) continue ;; esac   # on Windows both names can be one folder
     seen="$seen|$r|"
     grep -lE '^name: *(master-compile|master-audit|update-master-wiki|raw-compile|audit-wiki|update-wiki)[[:space:]]*$' "$G"/*/SKILL.md 2>/dev/null |
       while IFS= read -r f; do echo "GLOBAL-SKILL $(dirname "$f")"; done
     [ -f "$G/.wiki-version" ] && echo "GLOBAL-STAMP $G/.wiki-version"
   done
   true
   EOF
   ```

   It runs through `bash` explicitly, because the Bash tool may start zsh, which aborts on a glob that matches nothing. Also check `.claude/skills/` in each parent folder of `<target>` up to the git repository root, or up to the home folder when there is none: Claude Code loads project skills from parent folders, and on a name clash the root copy runs.

   If nothing turns up, continue. Otherwise, before writing anything:
   - Tell the user: "Claude Code runs a skill in `~/.claude/skills/` instead of a project skill with the same name, so this master and its workstreams would run those copies instead of the ones being installed."
   - Tell them that other wikis on this computer without their own `.claude/skills/` use those copies, and lose their skills when the copies move. A standalone or workstream wiki gets its own copies back with the `wiki-generator` bootstrap prompt followed by `update`. Another master gets them with the bootstrap prompt in this repo's `README.md`, which ends with typing `/update-master-wiki`.
   - Ask with `AskUserQuestion`: **Move them aside** (recommended) / **Leave them** (the new master runs the global copies until they move).
   - On an explicit yes, move exactly the `GLOBAL-SKILL` folders and `GLOBAL-STAMP` files, each whole, into a new backup folder, and delete nothing. `mv -n` never overwrites, and the script reports anything it couldn't move:

     ```bash
     bash <<'EOF'
     B="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/master-wiki-skills-backup-$(date +%Y-%m-%d-%H%M%S)"
     mkdir "$B" || exit 1
     for p in '<GLOBAL-SKILL folder>' '<GLOBAL-STAMP file>'; do
       if [ -e "$p" ] && mv -n "$p" "$B/" && [ ! -e "$p" ]; then echo "MOVED $p"; else echo "NOT MOVED $p"; fi
     done
     ls -la "$B"
     EOF
     ```

     Report every `NOT MOVED` line; those copies still run. Renaming a folder inside the global skills folder doesn't disable it, so the folders have to leave that directory.
   - Copies in a parent folder's `.claude/skills/` belong to that project. Name their paths and leave the decision to the user.

4. **Resolve the number of workstreams.** Ask with `AskUserQuestion`:
   - **2**, **3** (default), **4**, **5+** — pick the closest match. If the user picks 5+ or "Other", prompt them to type the exact count.
   - If they say 1, gently push back: a single-workstream master wiki is just a regular wiki — recommend running `wiki-generator` instead, and confirm before continuing.
   - When adding workstreams to an existing master, ask how many new ones instead, and accept 1.

5. **Resolve workstream folder names.** For each workstream, ask the user for a short slug. Default sequence: `ws1`, `ws2`, `ws3`, … but encourage descriptive names that reflect what the workstream actually owns (e.g., `data-platform`, `frontend`, `infra`, `ml-research`). Validate each name:
   - Lowercase, hyphenated only — letters, digits, hyphens.
   - If the user enters something with spaces, uppercase, or punctuation, normalize it (e.g., "Data Platform" → `data-platform`), show them the normalized version, and confirm.
   - If they enter a slug already ending in `-wiki` (e.g., `frontend-wiki`), do not double-suffix — use `frontend-wiki` as the folder name directly. Otherwise append `-wiki`.
   - Reject duplicates — two workstreams cannot share a slug. Re-prompt if a collision occurs.

6. **Resolve scaffold mode.** Ask with `AskUserQuestion`:
   - **Fresh scaffold each workstream as a full wiki vault** (default: each `raw/<ws-slug>-wiki/` gets its own `CLAUDE.md`, `raw/`, `wiki/`, `output/`, project-scoped `raw-compile`, `audit-wiki` and `update-wiki` skills, and a stamp). Pick this when starting from scratch.
   - **Leave each workstream as an empty placeholder folder** (creates only an empty `raw/<ws-slug>-wiki/` with a `.gitkeep`, and a setup-notes file with manual-sync vs. git-submodule wiring instructions). Pick this when the user already has external workstream wiki repos to wire in.
   - Frame the trade-off in the prompt so the user understands what each path costs and produces.

7. **Confirm before writing.** Show the resolved file list:
   - Target path
   - Scaffold mode (fresh / placeholder)
   - Every workstream folder that will be created (with the final `-wiki`-suffixed slug)
   - Every file that will be written

   The script never overwrites a file. List every destination that already exists: it is kept as it is, and the report shows it as `SKIPPED`. A kept master file is stamped `@unknown`, so a later `update` shows its differences in full before replacing anything. A workstream folder that already holds real content (anything beyond a lone `.gitkeep`) is left completely untouched and reported as `SKIPPED (populated workstream, left untouched)`. Ask the user to confirm the list, or to abort.

8. **Run the scaffold script.** Invoke `scripts/scaffold.sh` (this skill's sibling) once, with the resolved choices. It creates the folder structure, copies every template, performs the `WORKSTREAMS` substitution in the setup-notes, writes both kinds of version stamp, drops the `.gitkeep` files, and verifies the result, so you do not hand-write any files.

   ```bash
   bash <skill-dir>/scripts/scaffold.sh \
     --target <absolute-target-path> \
     --mode fresh|placeholder \
     --workstreams "<slug1> <slug2> <slug3>"
   ```

   - Pass the **normalized** slugs from step 5, space-separated. The script applies the `-wiki` suffix rule (won't double-suffix), rejects duplicates and any slug that isn't lowercase-hyphenated, but you should already have normalized case/spaces/punctuation and resolved collisions during the wizard.
   - When adding workstreams to an existing master, pass only the new slugs.

9. **Check the result and report.** The script prints `WROTE` / `SKIPPED` / `MISSING` / `FAILED` lines and ends with `RESULT: OK (...)` or `RESULT: FAILED (...)`, exiting non-zero on failure.
   - If the result is **FAILED** (or the script exits non-zero), surface the `FAILED` lines to the user and **stop** — do not claim the scaffold succeeded. A missing per-workstream `CLAUDE.md` or `SKILL.md` leaves a hierarchy that looks set up but breaks on first compile.
   - A `MISSING` line names a master file that an existing, stamped master lacks. Pass on what the line says: `update` at the master root restores it, or for `update-master-wiki` itself the bootstrap prompt from the README.
   - A `NOTE settings` line means `<target>/.claude/settings.json` already existed, so the script left it alone. If it is a symlink, tell the user and leave it. Otherwise read it, and add the entries it lacks with the Edit tool: a `skillOverrides` object holding `"raw-compile": "off"`, `"audit-wiki": "off"` and `"update-wiki": "off"`, with every other setting kept as it was. Ask first if one of the three is set to another value. These entries stop a workstream's skills from running against the master in sessions opened at its root.
   - A `NOTE` about the setup notes means the master's `raw/_workstream-setup-notes.md` doesn't list the workstreams added in this run. Tell the user, and for new placeholder workstreams quote the wiring commands from `templates/workstream-setup-notes.placeholder.md` (Options A and B) in the report. This is the one template you read.
   - If **OK**, report:
     - The resolved target path and scaffold mode
     - The master's version (`templates/VERSION`) and, in fresh-scaffold mode, the wiki-generator release the workstreams run (`templates/ws-templates/VERSION`)
     - The list of workstream folders created (final `-wiki`-suffixed slugs), and any reported as `SKIPPED (populated workstream, left untouched)`
     - For fresh-scaffold mode: a note confirming each new workstream got its own `CLAUDE.md`, vault folders, `raw-compile`, `audit-wiki` and `update-wiki` skills, and stamp
     - Any global copies found in step 3, and whether they moved
     - The next steps below

## Next steps to surface to the user

### Fresh-scaffold mode

- Each workstream folder is a ready-to-use wiki vault. To populate one, **open the workstream's folder in a new Claude Code session** (e.g., `raw/ws1-wiki/` as the folder), drop source material into its `raw/`, then say **"compile"**. That triggers the workstream's own `raw-compile`, which loads with the session.
- Say **"audit"** inside a workstream to audit that workstream wiki (reports land in the workstream's own `output/_audits/`).
- Cross-cutting files (steering committee notes, integration plans, exec decisions) go directly into the master's `raw/`.
- Once at least one workstream has real content in its `wiki/` folder, return to the **master root** in a session opened there and say **"compile"**. That triggers `master-compile` and writes cross-WS synthesis articles into the master's `wiki/`.
- Say **"audit"** at the master root to run `master-audit`; reports land in the master's `output/_audits/`.

### Placeholder mode

- Open **`<target>/raw/_workstream-setup-notes.md`** for per-workstream wiring instructions (git submodules vs. manual sync, with concrete commands).
- Drop any cross-cutting files directly into `<target>/raw/`.
- Once at least one `raw/<ws-slug>-wiki/` has real workstream content, say **"compile"** from the master root.
- Say **"audit"** at the master root to run `master-audit`.

### Both modes

- Before the first compile, start a new Claude Code session with `<target>` as the folder. Claude Code reads `CLAUDE.md` only when a session starts, and a `.claude/skills/` folder created during this session may not load until `/reload-skills` or a new session.
- The folder a session is opened in decides which skills answer. At the master root, `compile`, `audit` and `update` run the master's skills, and the master's `.claude/settings.json` switches the workstream skills off there. In a session opened in a workstream folder, they run that workstream's skills.
- Say **"update"** at the master root to pull newer master templates. It also lists which workstream wikis are behind; each of those updates with **"update"** in a session opened in its own folder.
- The master's `wiki/_master-index.md` is the entry point for queries against the master. It starts empty (no themes yet).

## Maintainer notes

Template sync, versioning and releases, the `deploy-to-live.sh` workflow, the `ws-templates/` sync rule, and the update path for existing downstream master wikis are documented in [`MAINTAINER.md`](MAINTAINER.md). Destination users running this skill do not need to read that file.

## Anti-patterns

- **NEVER scaffold into a non-empty directory without explicit confirmation.** Silent overwrites destroy the user's existing `CLAUDE.md` or wiki content.
- **NEVER scaffold a master wiki inside an existing wiki vault** (i.e., an *ancestor* directory that contains both `CLAUDE.md` and `wiki/_master-index.md`). The intentional nesting *under* the master's own `raw/<ws-slug>-wiki/` is fine — `master-compile` is designed for it. The disallowed case is putting the master itself inside someone else's vault.
- **NEVER re-scaffold an existing master to pick up new templates.** That is what `update-master-wiki` is for: it compares each managed file with the release it came from, shows local edits and the changelog, and asks before writing. Re-running this skill on an existing master only adds workstreams.
- **NEVER install the companion skills into `~/.claude/skills/`.** Claude Code runs a global skill ahead of every project skill with the same name, so one global copy overrides the skills of every master and every wiki on the machine, and `update` inside any of them refreshes copies that never run.
- **NEVER overwrite a `raw/<ws-slug>-wiki/` folder that already contains real content** (anything beyond `.gitkeep`). Also when adding workstreams to an existing master, treat populated workstream folders as live and untouchable.
- **NEVER organize the *master's* `wiki/` folder by workstream.** The placeholder/scaffold folders live in `raw/<ws-slug>-wiki/` because that's where source material lives. The master's `wiki/` folder is organized by **cross-cutting theme** (Risks, Decisions, Dependencies, etc.). Do not seed any `<target>/wiki/<ws-slug>/` folders even if asked. If asked, explain why and steer toward themes.
- **NEVER auto-archive `raw/<ws-slug>-wiki/` folders.** Whether they're freshly scaffolded or synced from upstream, those folders are live sources. `master-compile` already enforces this at compile time; the scaffolder must not pre-fill `.gitignore` rules or archive paths that would conflict.
- **NEVER execute `git submodule add`, `git clone`, or any git command during scaffold.** Placeholder folders exist so the user can wire git themselves on their own terms; the setup-notes file explains the commands but does not run them. For fresh-scaffold mode there's no git interaction at all — each workstream is just regular files until the user chooses to commit, push, or convert any of them to a submodule themselves later.
- **NEVER cross-pollinate fresh-scaffold workstream wikis at scaffold time.** Each `raw/<ws-slug>-wiki/` starts empty (apart from its own boilerplate). Don't pre-seed any of them with content from another workstream, with master-level content, or with topic folders — they're independent vaults that the user will fill in themselves.
- **NEVER inline template content into `SKILL.md`.** Templates live in `templates/` (master-level) and `templates/ws-templates/` (per-workstream) so a single edit flows to every downstream master wiki and to the maintainer's own live skills.
- **NEVER edit `templates/ws-templates/`.** Those files are copies of a `wiki-generator` release, and every workstream's `update-wiki` compares its files with that release's tag. An edit here shows up as a local edit in every workstream scaffolded from it.
- **NEVER copy from a deployed master wiki back into `templates/`.** Direction of truth flows templates → deployments, never the reverse. A deployment edit is local debugging; promoting it requires reapplying the change in `templates/` first.
- **NEVER propagate `master-wiki-generator` itself into the scaffold.** Downstream master wikis are consumers of the master-wiki pattern, not bootstrappers for new master wikis. Including it would create a confusing recursion.
- **NEVER report "scaffold complete" without checking the script's result (step 9).** `scripts/scaffold.sh` verifies every file and ends with `RESULT: OK` or `RESULT: FAILED` (non-zero exit). A silent copy failure on one file, especially a per-workstream `CLAUDE.md` or `SKILL.md`, leaves the user with a hierarchy that *looks* set up but breaks the moment they try to compile. If the result is FAILED, surface it and stop.
- **NEVER hand-write the scaffold file-by-file when `scripts/scaffold.sh` exists.** Reading each template and re-emitting it by hand wastes tokens and reintroduces the silent-failure risk the script was built to eliminate. A re-typed copy also differs from the release by a byte here and there, and `update` then reports it as a local edit. Drive the script; only fall back to manual writes if the script itself is missing from the package, and then copy with `cp`.
