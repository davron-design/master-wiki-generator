# Master Wiki — Vault Conventions

This vault is the **cross-workstream synthesis layer**. It does NOT duplicate workstream-internal detail — that lives in each workstream's own wiki. The master wiki exists to surface what cuts across workstreams: shared decisions, dependencies, conflicts in approach, risks that span teams, timeline interlocks.

## Vault Structure
- /raw — source material (input zone). Two kinds of inputs live here:
  - `raw/ws<N>-wiki/` — entire workstream wikis, kept in sync via git. Treat these as **live sources**: they re-read on every compile and are **NOT archived**. Moving them breaks upstream sync.
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
- Index rows use the piped wiki-link form (`[[theme-slug/_index|theme-slug]]`, `[[article-slug]]`) so links are clean and resolvable.

### Attribution
When synthesizing across workstreams, attribute every claim to its source:
- Use `[[wiki links]]` to source pages inside workstream wikis (e.g., `[[ws1-wiki/wiki/data-governance/principles]]`)
- Make the attribution visible in prose: *"WS1 treats data governance as X, while WS2 treats it as Y."*
- Flag genuine contradictions with a `⚠️` callout and a one-line note of the conflict.
- A claim with no traceable source does not belong in the master wiki.

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

## Conventions
- Always use [[wiki links]] when referencing other notes or upstream workstream pages
- File names: lowercase with hyphens (e.g., cross-workstream-risks.md)
- Keep articles concise — bullet points over paragraphs
- Indexes (`_master-index.md` and every theme `_index.md`) are markdown tables, not bullet lists — group large indexes into `##` sections
- Always include a `## Key Takeaways` section in wiki articles
- Attribute cross-workstream claims to the originating workstream wiki — unattributed claims are not allowed
