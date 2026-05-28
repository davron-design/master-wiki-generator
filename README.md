# Master Wiki Generator — Beginner's Guide

A step-by-step guide to setting up a **cross-workstream master wiki** — an AI-maintained synthesis layer that sits above two or more workstream wikis and surfaces what cuts across them: shared decisions, dependencies, risks that span teams, timeline interlocks, conflicts in approach.

By default, this skill **also scaffolds each workstream wiki for you** — you say "I have 3 workstreams called X, Y, Z" and the skill stands up the master plus three fully-formed workstream wikis (each with its own `CLAUDE.md`, vault folders, and `raw-compile` + `audit-wiki` skills) in one command. If you already have workstream wikis as external repos, you can instead pick the "placeholder mode" path that wires them in via git submodules or manual sync.

If you only have one wiki, you don't need this — the standard [`wiki-generator`](https://github.com/davron-design/wiki-generator) skill is enough.

No terminal beyond a few optional git commands. No coding. Just the Claude Code desktop app.

---

## What You'll Need

- The **Claude Code desktop app** installed
- A rough plan for how many workstreams you'll be tracking and what to call them (don't worry — you can use placeholder names like `ws1`, `ws2`, `ws3` and rename later)
- About **10 minutes** for setup (longer if you're wiring in existing external workstream repos)

---

## Step 1: Create a Folder for Your Master Wiki

Pick a spot on your computer where the master wiki will live (your Desktop works fine). Create a new folder and name it whatever you want — e.g. `Program Master Wiki`, `Quarterly Synthesis`, `Cross-Team Knowledge`.

That folder is the **home** of your master wiki. The workstream wikis stay in their own repos; the master pulls them in as live sources.

---

## Step 2: Open the Folder in Claude Code

1. Launch the **Claude Code desktop app**.
2. Open the folder you just created.

You should now see an empty project with a chat box ready to go.

---

## Step 3: Install the Master Wiki Generator Skill

Copy and paste the following prompt into Claude Code and send it:

> Please download the repo at **https://github.com/davron-design/master-wiki-generator** and install it as a **project-scoped skill** in this folder. Put the skill files under `.claude/skills/master-wiki-generator/` so the skill only applies to this project. Once it's installed, list the skills so I can confirm it's ready to use.

If Claude asks for permission, just **Always Allow**.

Claude will:
- Fetch the skill files from the repo
- Place them in the right spot inside your folder
- Confirm the skill is installed

You only need to do this once per master wiki.

---

## Step 4: Run the Setup Wizard

Now scaffold your master wiki.

1. In Claude Code, type:
   ```
   /master-wiki-generator
   ```
2. Claude will walk you through a short wizard:
   - **Where does this master wiki live?** — current folder, a subfolder, or an absolute path.
   - **How many workstreams do you have?** — 2, 3, 4, 5+. Pick the closest match.
   - **What should each workstream folder be called?** — Claude will ask for a short name for each one. You can use defaults (`ws1`, `ws2`, `ws3`…) or descriptive names that reflect what the workstream owns (`data-platform`, `frontend`, `infra`, `ml-research`). Lowercase with hyphens.
   - **How should the workstream folders start out?** — pick one:
     - **Fresh scaffold each workstream as a full wiki vault (recommended)** — Claude builds out each workstream folder with its own `CLAUDE.md`, `raw/`, `wiki/`, `output/`, and project-scoped `raw-compile` + `audit-wiki` skills. You can start filling them in immediately. Best when you're starting from scratch.
     - **Leave each as an empty placeholder** — Claude creates empty folders and writes a setup-notes file with instructions for wiring in *existing* workstream wiki repos (git submodules or manual sync). Best when you already have workstream wikis as separate repos.
   - **Where should the companion skills live?** — project-scoped (only active in this master) or global (active everywhere).

3. Claude will then create your master wiki and (if you picked fresh scaffold) the workstream wikis inside it:
   - **`raw/`** — input zone for cross-cutting files. One folder per workstream (`raw/data-platform-wiki/`, `raw/frontend-wiki/`, …) — either fully scaffolded as wiki vaults or empty placeholders depending on your choice. Plus a file called `_workstream-setup-notes.md` with orientation specific to the path you chose.
   - **`wiki/`** — where cross-workstream synthesis articles will live, organized by **theme** (Risks, Decisions, Dependencies, Timeline, Open Questions) — not by workstream.
   - **`output/`** — where master-level audit reports and query results show up.

It will also install the master's two companion skills (`master-compile` and `master-audit`) automatically — and in fresh-scaffold mode, each workstream's own `raw-compile` + `audit-wiki` skills.

---

## Step 5: Populate Your Workstream Wikis

### If you picked fresh scaffold

Each workstream folder is a ready-to-use wiki vault. To populate one:

1. **cd into the workstream folder** in Claude Code — e.g., open `raw/data-platform-wiki/` as the project root.
2. **Drop source material** (notes, articles, transcripts) into that workstream's own `raw/` folder.
3. **Say `compile`** in Claude Code. The workstream's own `raw-compile` skill activates and writes wiki articles into that workstream's `wiki/` folder.
4. **Say `audit`** periodically to check that workstream wiki for gaps.

Each workstream wiki operates independently. The master only reads each workstream's polished `wiki/` subfolder.

### If you picked placeholder mode

Each workstream folder is empty, waiting for content from an external repo. Open the file `raw/_workstream-setup-notes.md` — it lists every workstream folder and gives you two wiring options:

- **Git submodules** *(recommended for shared / multi-collaborator masters)* — each workstream wiki is added as a submodule; `git submodule update --remote` pulls the latest before every master compile.
- **Manual sync** *(simplest, no git wiring)* — clone each workstream repo somewhere else on your machine and copy its contents into the matching `raw/` folder when you want to refresh.

Pick one option per workstream (you can mix and match) and follow the concrete commands in the setup-notes file.

Once every `raw/<ws-slug>-wiki/` has real workstream content (a `wiki/` subfolder with articles), you're ready to compile the master.

---

## Step 6: Add Cross-Cutting Files (Optional)

Anything that doesn't live inside a single workstream — steering committee notes, integration plans, exec decisions, RFCs that touch multiple teams — drop it directly into the master's `raw/` folder as a loose file. The master will absorb these on the next compile and archive them after.

---

## Step 7: Compile the Master

Now tell Claude to synthesize.

1. In Claude Code, simply say:
   ```
   compile
   ```
2. Claude will:
   - Read each workstream wiki's `wiki/` subfolder
   - Read any loose cross-cutting files in `raw/`
   - Identify what cuts across workstreams — shared concepts, dependencies, conflicts
   - Write synthesis articles into `wiki/`, organized by theme
   - Link every claim back to its source workstream wiki via `[[wiki links]]`
   - Archive the loose cross-cutting files into `raw/_<date>-complied/`
   - **Leave the `raw/<ws-slug>-wiki/` folders alone** — those are live, synced sources

The master wiki is a synthesis layer, not a copy. If something only matters to one workstream, the master will point you back to that workstream rather than re-document it.

---

## Step 8: Audit the Master

Periodically check the master for drift, contradictions, and missing comparisons.

1. In Claude Code, say:
   ```
   audit
   ```
2. Claude will scan the master wiki **and the workstream wikis it cites**, then produce a numbered audit report in `output/_audits/`. The report points out:
   - **Workstream-internal drift** — articles that turned out to be one-workstream content and don't belong in the master
   - **Unflagged contradictions** — places where workstreams disagree but the master glosses over it
   - **Upstream staleness** — claims the master makes that a workstream wiki has since revised
   - **Missing attributions** — claims without a `[[wiki link]]` to a source
   - **Missing cross-workstream comparisons** — concepts present in 2+ workstream wikis with no master synthesis
3. The audit is **report-only** by default — it won't change anything until you say so.

---

## How the Master Differs from a Regular Wiki

Four things that aren't true of a regular wiki, in case they bite you:

- **Themes, not topics.** The master index is organized by cross-cutting theme (Risks, Decisions, Dependencies, Timeline, Open Questions) — not by workstream. A `wiki/ws1/` folder is an anti-pattern.
- **Attribution is required.** Every claim in a master article must link back to its source page in a workstream wiki via `[[wiki links]]`. Unattributed claims are not allowed.
- **Workstream folders are never archived.** `master-compile` only archives loose files dropped directly into `raw/`. The `raw/<ws-slug>-wiki/` folders stay put because they're synced from upstream.
- **The audit checks the sources too.** `master-audit` reads each workstream wiki's index and spot-checks cited articles to flag upstream staleness. A normal audit only reads the wiki itself.

---

## What's Next?

- **In fresh-scaffold mode**: keep populating each workstream wiki independently (drop files in its `raw/`, say `compile` while inside it). When workstreams have new content worth synthesizing, return to the master and say `compile`.
- **In placeholder mode**: refresh upstream before each compile (`git submodule update --remote`, or re-copy your manual sync).
- **Drop new cross-cutting files** into the master's `raw/` whenever something program-wide happens.
- **Compile the master** to fold new material into the synthesis.
- **Audit periodically** to keep the master honest as workstream wikis evolve.
- **Browse in Obsidian** by opening the master folder as a vault — the graph view shows how themes connect across workstreams.
- **Switch a workstream from fresh-scaffold to external repo later**: if a workstream that started inside your master grows large enough to deserve its own repo, push `raw/<ws-slug>-wiki/` to a new remote, delete the local copy, and re-add it as a git submodule at the same path.

---

## Quick Reference

| Action | What to type |
|---|---|
| Set up a new master wiki | `/master-wiki-generator` |
| Compile new material | `compile` |
| Audit the master wiki | `audit` |
| Ask the master wiki a question | Just ask in plain English |

---

That's the whole workflow. Wire in your workstream wikis once, then drop cross-cutting files, compile, and the master grows itself.
