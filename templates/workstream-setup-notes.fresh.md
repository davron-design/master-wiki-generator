# Workstream Wikis — Setup Complete

Each workstream folder below was scaffolded by `master-wiki-generator` as a **fully-formed wiki vault**, with its own `CLAUDE.md`, `raw/`, `wiki/`, `output/`, and project-scoped companion skills (`raw-compile`, `audit-wiki`). No wiring needed — they're ready to use immediately.

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

1. **cd into the workstream folder** in Claude Code (e.g., open `raw/ws1-wiki/` as the project root, or `cd raw/ws1-wiki/` from the terminal). Each workstream wiki is self-contained with its own conventions in its local `CLAUDE.md`.
2. **Drop source material** — articles, notes, research, transcripts — into that workstream's own `raw/` folder.
3. **Say `compile`** in Claude Code. The workstream's project-scoped `raw-compile` skill activates and writes wiki articles into that workstream's `wiki/` folder, archiving the raw files after.
4. **Say `audit`** periodically to check the workstream wiki for gaps and inconsistencies. Reports land in the workstream's own `output/_audits/`.

Each workstream wiki operates independently. The master only reads each workstream's polished `wiki/` subfolder when synthesizing.

## How to compile the master wiki

Once one or more workstream wikis have real content in their `wiki/` subfolder, return to the **master root** (the folder containing this `raw/` directory) and say **`compile`** in Claude Code. The `master-compile` skill will:

- Read each workstream's `wiki/` subfolder (skipping their `raw/` and `output/`)
- Read any loose cross-cutting files in the master's `raw/`
- Write synthesis articles into the master's `wiki/`, organized by cross-cutting theme
- Attribute every claim back to the source workstream via `[[wiki links]]`
- **Leave the `raw/<ws-slug>-wiki/` folders alone** — they're live, evolving sources

## Cross-cutting files

Anything that touches multiple workstreams — steering committee notes, integration plans, exec decisions, RFCs that span teams — drop directly into the master's `raw/` folder (next to this file). `master-compile` will absorb them on the next compile and archive them into `raw/_<date>-complied/`.

## Auditing the master

Say **`audit`** from the master root to run `master-audit`. It reads the master plus the workstreams' `wiki/` subfolders, then surfaces:

- Workstream-internal content that drifted into the master
- Unflagged contradictions between workstreams
- Upstream staleness (master claims a workstream has since revised)
- Missing attributions and missing cross-workstream comparisons

Reports land in the master's `output/_audits/`. Report-only by default — nothing changes until you confirm.

---

## Anti-patterns to avoid

- **Don't drop master-level synthesis articles inside `raw/<ws-slug>-wiki/wiki/`.** That folder is the workstream's own knowledge base. Master synthesis lives in the master's `wiki/`.
- **Don't reorganize each workstream's `raw/` or `output/` folders.** They belong to each workstream wiki and `master-compile` knows to skip them.
- **Don't share content directly between workstream wikis.** If two workstreams need the same fact, each should have its own copy (with attribution to wherever it originated), and the master can flag the duplication during synthesis.
- **You can later swap a workstream from "fresh scaffold" to a synced upstream repo.** If you decide ws1 should be its own external repo, push the contents of `raw/ws1-wiki/` to a new remote, delete the local copy, and either add it back as a git submodule at the same path or set up a manual sync workflow. See `master-wiki-generator/README.md` for guidance.

---

*(This setup-notes file is itself a cross-cutting file in the master's `raw/`. It will get archived into `raw/_<date>-complied/` on the first master compile — that's expected.)*
