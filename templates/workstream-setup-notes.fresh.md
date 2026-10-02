# Workstream Wikis — Setup Complete

Each workstream folder below was scaffolded by `master-wiki-generator` as a **fully-formed wiki vault**, with its own `CLAUDE.md`, `raw/`, `wiki/`, `output/`, project-scoped companion skills (`raw-compile`, `audit-wiki`, `update-wiki`) and a version stamp. They need no wiring and are ready to use.

<!--
SCAFFOLDER NOTE: replace the WORKSTREAMS block below with one bullet per workstream
folder you actually created. Format: `- \`raw/<ws-slug>-wiki/\``. The scaffolder
substitutes this when writing the file.
-->

## Workstream folders created

<!-- WORKSTREAMS:START -->
- `raw/<ws-slug>-wiki/`  *(scaffolder replaces this block with your actual workstream list)*
<!-- WORKSTREAMS:END -->

---

## How to use each workstream wiki

1. **Open the workstream folder in a new Claude Code session** (e.g., pick `raw/ws1-wiki/` as the folder). Claude Code loads a folder's `CLAUDE.md` and skills when a session starts there, so a session opened at the master root keeps running the master's skills. Each workstream wiki is self-contained with its own conventions in its local `CLAUDE.md`.
2. **Drop source material** — articles, notes, research, transcripts — into that workstream's own `raw/` folder.
3. **Say `compile`** in Claude Code. The workstream's project-scoped `raw-compile` skill activates and writes wiki articles into that workstream's `wiki/` folder, archiving the raw files after.
4. **Say `audit`** periodically to check the workstream wiki for gaps and inconsistencies. Reports land in the workstream's own `output/_audits/`.
5. **Say `update`** now and then. The workstream's `update-wiki` fetches the latest compile and audit rules from `wiki-generator`, shows what changed, and asks before writing anything.

Each workstream wiki operates independently. The master only reads each workstream's polished `wiki/` subfolder when synthesizing.

## How to compile the master wiki

Once one or more workstream wikis have real content in their `wiki/` subfolder, return to the **master root** (the folder containing this `raw/` directory) and say **`compile`** in Claude Code. The `master-compile` skill will:

- Read each workstream's `wiki/` subfolder (skipping their `raw/` and `output/`)
- Read any loose cross-cutting files in the master's `raw/`
- Write synthesis articles into the master's `wiki/`, organized by cross-cutting theme
- Attribute every claim back to the source workstream via `[[wiki links]]`
- **Leave the `raw/<ws-slug>-wiki/` folders alone** — they're live, evolving sources

## Cross-cutting files

Anything that touches multiple workstreams (steering committee notes, integration plans, exec decisions, RFCs that span teams) goes directly into the master's `raw/` folder, next to this file. `master-compile` will absorb them on the next compile and archive them into `raw/_<date>-compiled/`.

## Auditing the master

Say **`audit`** from the master root to run `master-audit`. It reads the master plus the workstreams' `wiki/` subfolders, then surfaces:

- Workstream-internal content that drifted into the master
- Unflagged contradictions between workstreams
- Upstream staleness (master claims a workstream has since revised)
- Missing attributions and missing cross-workstream comparisons

Reports land in the master's `output/_audits/`. Report-only by default — nothing changes until you confirm.

## Keeping the skills current

Say **`update`** at the master root to refresh the master's own files (`CLAUDE.md`, `master-compile`, `master-audit` and `update-master-wiki`). It shows what changed, asks before writing, and then lists which workstream wikis are behind. Each workstream updates itself with **`update`** in a session opened in its own folder.

---

## Anti-patterns to avoid

- **Don't drop master-level synthesis articles inside `raw/<ws-slug>-wiki/wiki/`.** That folder is the workstream's own knowledge base. Master synthesis lives in the master's `wiki/`.
- **Don't reorganize each workstream's `raw/` or `output/` folders.** They belong to each workstream wiki and `master-compile` knows to skip them.
- **Don't share content directly between workstream wikis.** If two workstreams need the same fact, each should have its own copy (with attribution to wherever it originated), and the master can flag the duplication during synthesis.
- **You can later swap a workstream from "fresh scaffold" to a synced upstream repo.** If you decide ws1 should be its own external repo, push the contents of `raw/ws1-wiki/` to a new remote, delete the local copy, and either add it back as a git submodule at the same path or set up a manual sync workflow. See `master-wiki-generator/README.md` for guidance.

---

*(This setup-notes file is itself a cross-cutting file in the master's `raw/`, so the first master compile archives it into `raw/_<date>-compiled/`. That's expected.)*
