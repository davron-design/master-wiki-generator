# Master Wiki — Vault Conventions

This vault is the **cross-workstream synthesis layer**. It does NOT duplicate workstream-internal detail — that lives in each workstream's own wiki. The master wiki exists to surface what cuts across workstreams: shared decisions, dependencies, conflicts in approach, risks that span teams, timeline interlocks.

## Which sessions these rules govern
Claude Code reads this file in every session opened in this folder or in a folder below it, including a session opened inside a workstream folder under `raw/`. A session opened here also loads a workstream's own `CLAUDE.md` and skills once it reads that workstream's files. The folder the session was opened in decides which rules apply:
- **Opened here, at the master root:** this file governs. `compile`, `audit` and `update` mean `master-compile`, `master-audit` and `update-master-wiki`, also after a workstream's `raw-compile`, `audit-wiki` or `update-wiki` has loaded. This folder's `.claude/settings.json` switches those three workstream skills off in sessions opened here. When Claude Code reports one of them as disabled via `skillOverrides`, that is this protection at work: keep the setting, and open the workstream's folder to use its skills.
- **Opened inside `raw/<ws-slug>-wiki/`:** that workstream's `CLAUDE.md` governs, and `compile`, `audit` and `update` mean its `raw-compile`, `audit-wiki` and `update-wiki`. The rest of this file applies only to sessions opened at the master root.

## Vault Structure
- /raw — source material (input zone). Two kinds of inputs live here:
  - `raw/<ws-slug>-wiki/`: entire workstream wikis, scaffolded here or kept in sync via git (`master-compile` defines a workstream folder exactly). Treat these as **live sources**: they re-read on every compile and are **NOT archived**. Moving them breaks upstream sync.
  - **Loose files** dropped directly into `raw/` — cross-cutting documents (steering committee notes, integration plans, exec decisions). These **ARE archived** after compile, like in a normal wiki.
- /wiki — LLM-compiled cross-workstream knowledge base (see Wiki System below)
- /output — query results and generated audit reports

## Mission
The master wiki exists to answer questions no single workstream wiki can answer alone:
- Where do workstreams agree, and where do they conflict?
- What decisions or dependencies cross workstream boundaries?
- What risks affect more than one workstream?
- Are workstream timelines interlocked, and where are the slip points?

If a question is answerable inside a single workstream wiki, the master wiki should point at that workstream rather than re-answer it.

## Wiki System
You are the librarian of the wiki/ folder. You write and maintain everything in it.

### Structure
- wiki/_master-index.md is the entry point — a `| Theme | Description |` table organized around **cross-cutting themes** (e.g., Risks, Decisions, Dependencies, Timeline, Open Questions), **NOT by workstream**.
- Each theme gets its own subfolder with its own _index.md — a `| Article | Description |` table (or multiple tables grouped under `##` section headings once the theme exceeds ~5 articles).
- Index rows use the piped wiki-link form (`[[theme-slug/_index\|theme-slug]]`, `[[article-slug]]`) so links are clean and resolvable. Inside a table row the pipe is written `\|`, because a bare `|` ends the cell.

### Attribution
When synthesizing across workstreams, attribute every claim to its source:
- Use `[[wiki links]]` to source pages inside workstream wikis (e.g., `[[ws1-wiki/wiki/data-governance/principles]]`)
- Make the attribution visible in prose: *"WS1 treats data governance as X, while WS2 treats it as Y."*
- Flag genuine contradictions with a `⚠️` callout and a one-line note of the conflict.
- A claim with no traceable source does not belong in the master wiki.
- An article that draws on loose files from `raw/` ends with a `Sources:` footer: a blank line, `---`, `Sources:`, then one `- <path relative to raw/> (compiled YYYY-MM-DD)` item per file. Workstream pages are cited inline with their links. The compile date is what locates a loose file in `raw/_<date>-compiled/` after archiving.

### Querying
When answering questions against the master wiki:
1. Read wiki/_master-index.md first to find the right theme
2. Read that theme's _index.md to find relevant articles
3. Read the specific articles
4. If a question is workstream-internal (not cross-cutting), point the user at the relevant workstream wiki rather than answering from the master
5. If the master wiki has no relevant knowledge, say so — do not make anything up

### Compiling
When the user says "compile" or drops new material in raw/, use the `master-compile` skill.

### Auditing
When the user says "audit" or "lint", use the `master-audit` skill.

### Updating
When the user says "update", "repair" or "check for updates", use the `update-master-wiki` skill. It fetches the latest published master templates, shows what changed, and asks before rewriting this file or the three master skills. It never touches wiki/, raw/ or output/. The workstream wikis in raw/ update separately: say `update` in a session opened in each workstream's folder. Claude Code reads this file only when a session starts, so after an update that rewrote it, start a new session in this folder before the next compile or audit.

## Conventions
- Always use [[wiki links]] when referencing other notes or upstream workstream pages
- File names: lowercase with hyphens (e.g., cross-workstream-risks.md), and unique across this whole folder, workstream wikis included, because a `[[article-slug]]` link resolves by filename alone
- Keep articles concise — bullet points over paragraphs
- Indexes (`_master-index.md` and every theme `_index.md`) are markdown tables, not bullet lists — group large indexes into `##` sections
- Always include a `## Key Takeaways` section in wiki articles
- Attribute cross-workstream claims to the originating workstream wiki — unattributed claims are not allowed
