---
name: master-wiki-generator
description: Scaffold a cross-workstream master wiki — a synthesis layer above N workstream wikis that surfaces shared decisions, dependencies, risks, and timeline interlocks. Creates the master raw/wiki/output vault, installs its `master-compile` and `master-audit` companion skills, and by default fully scaffolds each workstream as its own wiki vault under `raw/<ws-slug>-wiki/` (CLAUDE.md, raw/, wiki/, output/, `raw-compile` + `audit-wiki` skills) — or leaves empty placeholders to wire existing wikis into. Sibling of `wiki-generator` (which scaffolds a single workstream wiki); use this one to span two or more. Use when the user says "set up a master wiki", "scaffold/generate a master wiki", "spin up a cross-workstream wiki", "install the master wiki skills", or runs /master-wiki-generator.
---

# Master Wiki Generator

Scaffolds a complete cross-workstream master wiki in a target directory: master-level folder layout (`raw/`, `wiki/`, `output/`), master-specific `CLAUDE.md`, empty `_master-index.md`, and the companion `master-compile` and `master-audit` skills. By default, also fully scaffolds each workstream as its own wiki vault inside `raw/<ws-slug>-wiki/` (with its own `CLAUDE.md`, `raw/`, `wiki/`, `output/`, and project-scoped `raw-compile` + `audit-wiki` companion skills) so the entire hierarchy is ready to use in one step. Users who already have workstream wikis to wire in can opt to create empty placeholder folders instead.

This is the master-wiki sibling of `wiki-generator`. Use `wiki-generator` to scaffold a *single* workstream wiki on its own. Use this skill when you want a master synthesis layer spanning multiple workstream wikis — whether you're starting from scratch (fresh-scaffold mode) or already have workstream wikis to plug in (placeholder mode).

## When to invoke
- User says "set up a master wiki", "scaffold a master wiki", "generate a master wiki", "spin up a cross-workstream wiki", or "install the master wiki skills"
- User runs `/master-wiki-generator`
- User mentions wanting a wiki that spans multiple workstreams, projects, or teams
- User wants to bootstrap a cross-workstream synthesis layer — either fresh end-to-end or on top of existing wikis

## Before scaffolding, ask yourself
- **Single wiki vs. master**: If the user only has one workstream/project, they don't need a master wiki — the standard `wiki-generator` skill is enough. Surface this before scaffolding. The master wiki earns its keep specifically by synthesizing across two or more workstream wikis.
- **Target sanity**: Is the target directory empty (or non-existent)? Scaffolding into an in-use folder risks colliding with the user's existing `CLAUDE.md`, `wiki/`, or `.claude/skills/`. Confirm before writing.
- **Nested target**: Walk up from the target. If any ancestor directory already contains *both* `CLAUDE.md` and `wiki/_master-index.md`, that's an existing wiki vault — placing a master wiki inside it is almost always a mistake (it produces two competing master indexes). Surface this to the user and require explicit confirmation. Exception: re-scaffolding the same path as an upgrade is fine. *(Note: the master wiki intentionally contains wiki vaults inside its own `raw/<ws-slug>-wiki/` folders — that's not nesting in the sense that breaks anything, because `master-compile` knows to read each one's `wiki/` subfolder and skip its `raw/` and `output/`.)*
- **Template integrity**: `scripts/scaffold.sh` checks this for you — it aborts before any write if a required template for the chosen mode is missing (the skill package would be broken and a partial scaffold would silently produce a non-functional master wiki). You do not need to pre-verify the templates by hand.
- **Skill scope**: Should the companion skills live inside the master wiki (project-scoped, only active when working in that folder) or in `~/.claude/skills/` (active everywhere)? Project-scoped keeps each master self-contained; global avoids duplication if the user runs many masters. Ask.

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
│   │   └── .claude/skills/                    # project-scoped install only
│   │       ├── raw-compile/SKILL.md
│   │       └── audit-wiki/SKILL.md
│   ├── <ws2-slug>-wiki/
│   │   └── ...                                # same structure
│   └── ...
├── wiki/                                      # the cross-workstream synthesis layer
│   └── _master-index.md                       # entry point, empty until first compile
├── output/                                    # query results and audit reports
│   └── _audits/.gitkeep
└── .claude/                                   # (project-scoped install only)
    └── skills/
        ├── master-compile/SKILL.md
        └── master-audit/SKILL.md
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
└── .claude/                                   # (project-scoped install only)
    └── skills/
        ├── master-compile/SKILL.md
        └── master-audit/SKILL.md
```

### Global install variant (either mode)

If install scope is global (`~/.claude/skills/`), the master-level skills (`master-compile`, `master-audit`) and — in fresh-scaffold mode — the workstream-level skills (`raw-compile`, `audit-wiki`) all go to `~/.claude/skills/` instead of being bundled inside the master. Skip any skill that already exists there (don't overwrite the user's own wiki-generator install). The `<target>/.claude/` folder is not created. In fresh-scaffold mode, the per-workstream `.claude/skills/` folders are also skipped — the global copies cover them.

The setup-notes file at `raw/_workstream-setup-notes.md` is itself a cross-cutting file. It gets archived into `raw/_<date>-complied/` on first master compile — that's intentional. It only needs to be there until the user has gotten their bearings.

## Procedure

1. **Resolve the target directory.** If the user didn't specify, ask with `AskUserQuestion`:
   - **Current directory** (default — the user's CWD)
   - **A subfolder** (prompt for a name, e.g. `./my-master-wiki`)
   - **An absolute path the user types in**

2. **Resolve the number of workstreams.** Ask with `AskUserQuestion`:
   - **2**, **3** (default), **4**, **5+** — pick the closest match. If the user picks 5+ or "Other", prompt them to type the exact count.
   - If they say 1, gently push back: a single-workstream master wiki is just a regular wiki — recommend running `wiki-generator` instead, and confirm before continuing.

3. **Resolve workstream folder names.** For each workstream, ask the user for a short slug. Default sequence: `ws1`, `ws2`, `ws3`, … but encourage descriptive names that reflect what the workstream actually owns (e.g., `data-platform`, `frontend`, `infra`, `ml-research`). Validate each name:
   - Lowercase, hyphenated only — letters, digits, hyphens.
   - If the user enters something with spaces, uppercase, or punctuation, normalize it (e.g., "Data Platform" → `data-platform`), show them the normalized version, and confirm.
   - If they enter a slug already ending in `-wiki` (e.g., `frontend-wiki`), do not double-suffix — use `frontend-wiki` as the folder name directly. Otherwise append `-wiki`.
   - Reject duplicates — two workstreams cannot share a slug. Re-prompt if a collision occurs.

4. **Resolve scaffold mode.** Ask with `AskUserQuestion`:
   - **Fresh scaffold each workstream as a full wiki vault** (default — runs the wiki-generator pattern inside each `raw/<ws-slug>-wiki/`, with its own `CLAUDE.md`, `raw/`, `wiki/`, `output/`, and project-scoped `raw-compile` + `audit-wiki` skills). Pick this when starting from scratch.
   - **Leave each workstream as an empty placeholder folder** (creates only an empty `raw/<ws-slug>-wiki/` with a `.gitkeep`, and a setup-notes file with manual-sync vs. git-submodule wiring instructions). Pick this when the user already has external workstream wiki repos to wire in.
   - Frame the trade-off in the prompt so the user understands what each path costs and produces.

5. **Resolve install scope for the companion skills.** Ask with `AskUserQuestion`:
   - **Project-scoped** (default — master skills land in `<target>/.claude/skills/`; in fresh-scaffold mode, each workstream's `raw-compile` and `audit-wiki` land in `<target>/raw/<ws-slug>-wiki/.claude/skills/`)
   - **Global** (all skills land in `~/.claude/skills/`; active everywhere — skip any skill that already exists there to avoid overwriting the user's own wiki-generator install)

6. **Confirm before writing.** Show the resolved file list:
   - Target path
   - Scaffold mode (fresh / placeholder)
   - Install scope
   - Every workstream folder that will be created (with the final `-wiki`-suffixed slug)
   - Every file that will be written
   
   If any destination file already exists, list the collisions and ask whether to **skip**, **overwrite**, or **abort** — these map directly onto how you invoke the script in step 7:
   - **skip** → run without `--overwrite-master` (existing master-level files are left as-is; the script reports them as `SKIPPED`).
   - **overwrite** → run with `--overwrite-master` (master-level files are replaced with the latest templates).
   - **abort** → don't run the script at all.

   Default to **skip** on collisions unless the user says otherwise — *except* if the collisions look like a prior scaffold of this same skill (a present `CLAUDE.md` plus `wiki/_master-index.md` plus the two companion `SKILL.md` files at their canonical paths, plus one or more `raw/<slug>-wiki/` folders). In that case, surface the prompt as **"this looks like an existing master wiki being upgraded — choose `overwrite` to apply the latest templates, or `skip` to leave the current copies untouched"** so the user doesn't unintentionally accept the default and stay on stale templates.

   **Upgrade-safety** (enforced by the script, regardless of `--overwrite-master`): any `raw/<ws-slug>-wiki/` folder that already contains real content (anything beyond a lone `.gitkeep`) is left completely untouched and reported as `SKIPPED (populated workstream)`. Only the master-level files and *newly named* / still-empty workstream folders are (re)written. This protects a workstream wiki the user has been filling in. You do not need to special-case this yourself — but do confirm with the user before passing `--overwrite-master`.

7. **Run the scaffold script.** Invoke `scripts/scaffold.sh` (this skill's sibling) once, with the resolved choices. It creates the folder structure, copies every template, performs the `WORKSTREAMS` substitution in the setup-notes, drops the `.gitkeep` files, and verifies the result — so you do not hand-write any files.

   ```bash
   bash <skill-dir>/scripts/scaffold.sh \
     --target <absolute-target-path> \
     --mode fresh|placeholder \
     --scope project|global \
     --workstreams "<slug1> <slug2> <slug3>" \
     [--overwrite-master]
   ```

   - Pass the **normalized** slugs from step 3, space-separated. The script applies the `-wiki` suffix rule (won't double-suffix) and rejects duplicates, but you should already have normalized case/spaces/punctuation and resolved collisions during the wizard.
   - Add `--overwrite-master` only on a confirmed upgrade (see step 6).
   - The script handles install scope (`project` → `<target>/.claude/skills/`; `global` → `~/.claude/skills/`, skipping any companion skill that already exists so a user's own `wiki-generator` install is never clobbered) and the populated-workstream guard. You do not need to create folders, copy templates, or substitute markers by hand.

8. **Check the result and report.** The script prints `WROTE` / `SKIPPED` / `FAILED` lines and ends with `RESULT: OK (...)` or `RESULT: FAILED (...)`, exiting non-zero on failure.
   - If the result is **FAILED** (or the script exits non-zero), surface the `FAILED` lines to the user and **stop** — do not claim the scaffold succeeded. A missing per-workstream `CLAUDE.md` or `SKILL.md` leaves a hierarchy that looks set up but breaks on first compile.
   - If **OK**, report:
     - The resolved target path, scaffold mode, and install scope
     - The list of workstream folders created (final `-wiki`-suffixed slugs), and any reported as `SKIPPED (populated workstream)`
     - For fresh-scaffold mode: a note confirming each new workstream got its own `CLAUDE.md`, vault folders, and (if project-scoped) its own `raw-compile` + `audit-wiki` skills
     - The next steps below

## Next steps to surface to the user

### Fresh-scaffold mode

- Each workstream folder is a ready-to-use wiki vault. To populate one, **cd into the workstream's folder** in Claude Code (e.g., open `raw/ws1-wiki/` as the project root), drop source material into its `raw/`, then say **"compile"** — that triggers the workstream's own `raw-compile`.
- Say **"audit"** inside a workstream to audit that workstream wiki (reports land in the workstream's own `output/_audits/`).
- Cross-cutting files (steering committee notes, integration plans, exec decisions) go directly into the master's `raw/`.
- Once at least one workstream has real content in its `wiki/` folder, return to the **master root** and say **"compile"** — that triggers `master-compile` and writes cross-WS synthesis articles into the master's `wiki/`.
- Say **"audit"** at the master root to run `master-audit`; reports land in the master's `output/_audits/`.

### Placeholder mode

- Open **`<target>/raw/_workstream-setup-notes.md`** for per-workstream wiring instructions (git submodules vs. manual sync, with concrete commands).
- Drop any cross-cutting files directly into `<target>/raw/`.
- Once at least one `raw/<ws-slug>-wiki/` has real workstream content, say **"compile"** from the master root.
- Say **"audit"** at the master root to run `master-audit`.

### Both modes

- The master's `wiki/_master-index.md` is the entry point for queries against the master. It starts empty (no themes yet).
- If install scope was project-scoped and the user later wants the companion skills available everywhere, copy them to `~/.claude/skills/`.

## Maintainer notes

Template sync, the `deploy-to-live.sh` workflow, the `ws-templates/` sync rule, and the upgrade path for existing downstream master wikis are documented in [`MAINTAINER.md`](MAINTAINER.md). Destination users running this skill do not need to read that file.

## Anti-patterns

- **NEVER scaffold into a non-empty directory without explicit confirmation.** Silent overwrites destroy the user's existing `CLAUDE.md` or wiki content.
- **NEVER scaffold a master wiki inside an existing wiki vault** (i.e., an *ancestor* directory that contains both `CLAUDE.md` and `wiki/_master-index.md`). The intentional nesting *under* the master's own `raw/<ws-slug>-wiki/` is fine — `master-compile` is designed for it. The disallowed case is putting the master itself inside someone else's vault.
- **NEVER accept the default `skip` on a collision prompt that looks like an upgrade.** If the canonical files are present, the user is upgrading templates, not scaffolding; silently skipping leaves them on stale templates with no warning. Surface the upgrade framing in the prompt itself (see step 6).
- **NEVER overwrite a `raw/<ws-slug>-wiki/` folder that already contains real content** (anything beyond `.gitkeep`). Even on the upgrade path, treat populated workstream folders as live and untouchable. Re-write the master-level files only.
- **NEVER organize the *master's* `wiki/` folder by workstream.** The placeholder/scaffold folders live in `raw/<ws-slug>-wiki/` because that's where source material lives. The master's `wiki/` folder is organized by **cross-cutting theme** (Risks, Decisions, Dependencies, etc.). Do not seed any `<target>/wiki/<ws-slug>/` folders even if asked. If asked, explain why and steer toward themes.
- **NEVER auto-archive `raw/<ws-slug>-wiki/` folders.** Whether they're freshly scaffolded or synced from upstream, those folders are live sources. `master-compile` already enforces this at compile time; the scaffolder must not pre-fill `.gitignore` rules or archive paths that would conflict.
- **NEVER execute `git submodule add`, `git clone`, or any git command during scaffold.** Placeholder folders exist so the user can wire git themselves on their own terms; the setup-notes file explains the commands but does not run them. For fresh-scaffold mode there's no git interaction at all — each workstream is just regular files until the user chooses to commit, push, or convert any of them to a submodule themselves later.
- **NEVER cross-pollinate fresh-scaffold workstream wikis at scaffold time.** Each `raw/<ws-slug>-wiki/` starts empty (apart from its own boilerplate). Don't pre-seed any of them with content from another workstream, with master-level content, or with topic folders — they're independent vaults that the user will fill in themselves.
- **NEVER inline template content into `SKILL.md`.** Templates live in `templates/` (master-level) and `templates/ws-templates/` (per-workstream) so a single edit flows to every downstream master wiki and to the maintainer's own live skills.
- **NEVER copy from a deployed master wiki back into `templates/`.** Direction of truth flows templates → deployments, never the reverse. A deployment edit is local debugging; promoting it requires reapplying the change in `templates/` first.
- **NEVER propagate `master-wiki-generator` itself into the scaffold.** Downstream master wikis are consumers of the master-wiki pattern, not bootstrappers for new master wikis. Including it would create a confusing recursion.
- **NEVER report "scaffold complete" without checking the script's result (step 8).** `scripts/scaffold.sh` verifies every file and ends with `RESULT: OK` or `RESULT: FAILED` (non-zero exit). A silent copy failure on one file — especially a per-workstream `CLAUDE.md` or `SKILL.md` — leaves the user with a hierarchy that *looks* set up but breaks the moment they try to compile. If the result is FAILED, surface it and stop.
- **NEVER hand-write the scaffold file-by-file when `scripts/scaffold.sh` exists.** Reading each template and re-emitting it by hand wastes tokens and reintroduces the silent-failure risk the script was built to eliminate. Drive the script; only fall back to manual writes if the script itself is missing from the package.
