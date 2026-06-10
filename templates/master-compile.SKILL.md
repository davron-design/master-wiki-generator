---
name: master-compile
description: Compile cross-workstream source material from raw/ into the master wiki/. Use when the user says "compile", drops new files into raw/, or asks to refresh the cross-workstream synthesis. Reads each workstream wiki folder (raw/ws<N>-wiki/) as a live, git-synced source, plus any loose cross-cutting files dropped directly into raw/. Writes synthesis articles organized by cross-cutting theme — NOT by workstream. Workstream wiki folders are never archived; loose files are.
---

# Master Compile — Cross-Workstream Synthesis

You are the librarian of the master wiki's `wiki/` folder. This skill ingests material from workstream wikis (synced into `raw/ws<N>-wiki/`) and loose cross-cutting files in `raw/`, then writes synthesis articles that surface what cuts across workstreams.

## Mission reminder

The master wiki is NOT a copy of the workstream wikis. It is a synthesis layer. If an article only restates one workstream's content, it does not belong here — leave it in that workstream's wiki and reference it with a `[[wiki link]]` if needed.

**A good master-wiki article:**
- Compares how multiple workstreams treat the same concept
- Surfaces a dependency or decision that spans workstreams
- Names a risk that affects more than one workstream
- Reconciles or flags a contradiction between workstreams
- Tracks a timeline interlock or shared deliverable

**A bad master-wiki article:**
- Duplicates a workstream-internal definition
- Restates one workstream's plan with no cross-comparison
- Pulls in workstream-internal noise (sprint notes, internal RACI, etc.)

## When to invoke
- User says "compile" or "compile raw"
- A workstream wiki has been updated upstream and the master needs refreshing
- User drops new cross-cutting files (steering committee notes, integration plans) into `raw/`

## Before compiling, ask yourself
- **Is this cross-cutting?** Does this material connect two or more workstreams, or is it workstream-internal? If single-workstream, skip it — or, at most, write a thin pointer article. **Not cross-cutting *yet*?** If it's one workstream's content today but will clearly interlock with another soon (a WS1 risk WS2 inherits next quarter), don't synthesize it now — name it as a watch item in your output report so the next compile picks it up once the second workstream actually touches it. Synthesizing a one-sided interlock invents the other half.
- **Attribution discipline**: Can I cite which workstream(s) each piece of synthesis draws from? Every claim must be traceable.
- **Theme placement**: Does this fit an existing cross-cutting theme (Risks, Decisions, Dependencies, Timeline, Open Questions) or warrant a new one? Default to existing themes. Fragmenting the master wiki defeats its purpose.
- **What does "refresh" mean here?** It means *re-read upstream and surface what's new or changed as new synthesis* — NOT open the affected master articles and rewrite them. Compile only ever adds and flags; it never edits an existing article's body. (See [A "refresh" is still additive](#a-refresh-is-still-additive--never-rewrite-an-existing-article).)

## Procedure

First, take stock of what's actually new. Unlike the leaf compile, `raw/ws<N>-wiki/` folders are always present (git-synced), so their mere existence is **not** a signal to compile. A run has real work only when at least one of these holds: loose cross-cutting files are sitting in `raw/`, or a workstream wiki has moved upstream since the last compile (compare against the most recent `raw/_<date>-compiled/` archive, or just ask the user what changed). If neither is true, say so and stop — do not create an empty dated archive folder, and do not re-synthesize unchanged upstream into duplicate articles.

1. **Inventory `raw/`.** Two kinds of inputs:
   - **Workstream wikis** at `raw/ws<N>-wiki/` (or similarly named folders). Read only their `wiki/` subfolder — that's the polished output. **Skip** their own `raw/` (input zone, not yet synthesized) and `output/` (their own reports). Start with each WS's `wiki/_master-index.md` and theme indexes; then read articles selectively, prioritizing the ones most likely to surface cross-cutting threads.
   - **Loose files** directly in `raw/` (cross-cutting docs). Read each fully.

2. **Identify cross-cutting threads.** Look for:
   - The same concept appearing in multiple workstream wikis → synthesis opportunity
   - Dependencies named in one workstream's pages that affect another
   - Conflicting claims, decisions, or approaches across workstreams
   - Risks, timeline items, or open questions surfacing in multiple places

3. **Classify by cross-cutting theme.** Read `wiki/_master-index.md`. Place each synthesis article in an existing theme folder (e.g., `wiki/risks/`, `wiki/decisions/`, `wiki/dependencies/`) or create a new theme folder if no existing theme fits. **Themes are organized by cross-cutting TYPE, not by workstream.** If the genuine fit is two themes, write the article in one and cross-link from the other with `[[wiki links]]`.

4. **Write the synthesis article** at `wiki/<theme>/<article-slug>.md`:
   - Filename: lowercase, hyphenated.
   - Bullet points over paragraphs — keep it concise.
   - **Attribute every claim** in prose: *"Per [[ws1-wiki/wiki/risks/data-migration]]…"*, *"WS2 takes a different view: [[ws2-wiki/wiki/...]]…"*
   - Use `[[wiki links]]` to other master-wiki articles AND to source pages inside workstream wikis.
   - Flag genuine contradictions with a `⚠️` callout and a one-line note of what conflicts.
   - **Always** include a `## Key Takeaways` section.

   Article skeleton:
   ```markdown
   # <Article Title>

   Per [[ws1-wiki/wiki/risks/data-migration]], WS1 treats X as <claim>.
   WS2 takes a different view: per [[ws2-wiki/wiki/risks/migration-plan]],
   they treat X as <other claim>.

   ⚠️ **Conflict:** WS1 expects migration in Q3; WS2's plan assumes Q4.

   - <Synthesis bullet, attributed to [[ws1-wiki/...]] or [[ws2-wiki/...]]>
   - <Synthesis bullet, attributed>

   ## Key Takeaways
   - <One-line takeaway>
   - <One-line takeaway>
   ```

5. **Update the theme's `_index.md`** — markdown table (`| Article | Description |`), not a bullet list. Add a row with `[[article-slug]]` and a description rich enough to navigate by. If the theme folder is new, create `_index.md` first with:
   - A `# <Theme> — Index` heading and a one- or two-line theme summary.
   - At least one section heading (e.g. `## Core`) above the table. Once a theme exceeds ~5 articles, split into multiple sections — each section gets its own table.

6. **Update `wiki/_master-index.md`** — also a markdown table (`| Theme | Description |`), one row per theme. Use the piped wiki-link form `[[theme-slug/_index|theme-slug]]`. Add or update the row when you create a new theme or when an existing description has gone stale. Pack descriptions with which workstreams the theme draws from and signature articles — not just a category name.

7. **Archive loose cross-cutting files only.** Once all loose files for this run are compiled, create `raw/_<YYYY-MM-DD>-compiled/` (use today's date) and move every loose raw file you just compiled into it. **Do NOT touch `raw/ws<N>-wiki/` folders** — those are live, git-synced sources. Moving them breaks sync and they will re-appear on next pull anyway.

## A "refresh" is still additive — never rewrite an existing article

The most common compile is a *refresh*: a workstream wiki moved upstream (say WS2's
own wiki now says the schema registry GA slipped from Q3 to Q4) and a master article
is still echoing the old fact. The natural instinct is to open that master article
and edit it to the new date. **Resist it.** Even on an explicit "refresh," and even
when the upstream change is a plain factual correction rather than an opinion,
compile does not rewrite existing master articles. It captures the change as *new*
synthesis and flags the conflict.

Concretely, when upstream has moved a claim the master still echoes:

1. **Write a new synthesis article** for the change (e.g. `risks/registry-ga-slip-confirmed.md`, or an `open-questions/` article if it raises one). In it:
   - state the change, attributed to the upstream page that now reflects it — `Per [[ws2-wiki/wiki/data-governance/schema-registry]], GA has slipped to Q4`;
   - add a `⚠️` callout naming the conflict — the existing master article and any still-stale workstream pages now disagree with the new fact;
   - link to the existing master article it supersedes, so the connection is explicit (`see [[risks/timeline-slip]]`).
2. **Leave the old article's body untouched.** Updating the theme's `_index.md` row to point at the new article is fine — that's navigation, not a content rewrite.
3. **Name the now-stale existing articles in your output report**, so the user and the next `master-audit` run know exactly what needs reconciling.

**Why compile stays additive — the part worth internalizing:** the existing master
article was synthesized from a known prior state, and someone may have reasoned
against it. Silently rewriting it mid-ingest destroys that synthesis and its
provenance with nobody reviewing the before/after. Deciding to *change* existing
content is precisely what `master-audit` is for: it runs as a report-then-confirm
pass, so a human sees what's about to change before it lands. Keeping compile purely
additive means two things that matter a lot in practice — it's always safe to re-run
(re-running never quietly mutates what's there), and reconciliation lives in exactly
one place (the audit) instead of being smeared, unreviewed, across every compile.
This mirrors how the leaf `raw-compile` works, on purpose.

## When the upstream looks broken

- **Missing `wiki/` subfolder** in `raw/ws<N>-wiki/` — the workstream hasn't synced or is mid-bootstrap. Skip that workstream this run and note it in the output report so the user knows to chase it.
- **Missing `_master-index.md`** in a WS wiki — fall back to walking the theme folders directly, but flag it in the output as a structural gap worth raising with the WS lead.
- **A master article cites a source page that no longer exists** — the WS may be mid-edit or have renamed the page. Leave the master article alone, do NOT delete the cite, and note it for the next `master-audit` run to verify (it will surface as upstream staleness).

## Output to the user

After compiling, report:
- Which workstream wikis were read and a quick snapshot of their state (e.g., article counts, last update)
- Which themes received new synthesis articles (new theme vs. existing)
- Any new theme folders created
- The name of the dated archive folder (if any loose files were processed)
- Any cross-workstream contradictions flagged with `⚠️`
- **Any existing master articles now made stale by an upstream change** — name them so the user and the next `master-audit` run can reconcile them. Compile flags staleness; it does not rewrite the stale article.
- Anything ambiguous you had to make a judgment call on (so the user can correct course)

## Anti-patterns

- **NEVER duplicate workstream-internal content.** If the master article reads like a copy of one workstream's page, it doesn't belong here. Link to the workstream page instead.
- **NEVER organize the master wiki by workstream.** Themes (Risks, Decisions, Dependencies, etc.) cut across workstreams. A `wiki/ws1/` folder is a smell — that's exactly what the WS1 wiki is for.
- **NEVER archive `raw/ws<N>-wiki/` folders.** They are git-synced; moving them breaks sync and they re-create on next pull.
- **NEVER drop articles into `wiki/` root.** Every article belongs to a theme folder — `_master-index.md` is the only navigation entry point at the root.
- **NEVER skip attribution.** A claim without a `[[wiki link]]` back to its source is unverifiable and does not belong in the master wiki.
- **NEVER skip `[[wiki links]]` for cross-references.** Broken graphs are silent failures.
- **NEVER overwrite an existing master-wiki article during compile — not even on a "refresh."** If new upstream material supersedes an existing article, surface it as a *new* article that flags the conflict and links to the one it supersedes (see [A "refresh" is still additive](#a-refresh-is-still-additive--never-rewrite-an-existing-article)), then name the stale article in your report. Reconciling the old article to the new facts is an audit-time decision (run `master-audit`), where the change is reviewed before it lands — not an ingest-time one.
- **NEVER skip the `## Key Takeaways` section.** It is the article's TL;DR — queries depend on it.
- **NEVER write `_master-index.md` or a theme `_index.md` as a bullet list.** Indexes are markdown tables — the extra structure is what makes the wiki navigable at a glance.

(Vault-wide conventions — filenames, wiki-links, attribution, `## Key Takeaways`, index-as-table — live in `CLAUDE.md`. The ones above are the compile-time-critical ones.)
