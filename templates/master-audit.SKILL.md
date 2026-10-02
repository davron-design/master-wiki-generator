---
name: master-audit
description: Audit the master wiki/ for cross-workstream synthesis quality (workstream-internal drift, unflagged contradictions, upstream staleness where a source WS wiki has revised a claim the master echoes, missing attributions, missing cross-workstream comparisons, theme drift, and the usual structural issues), then produce a numbered audit report in output/_audits that includes a 0–100 master-wiki integrity score and how it changed this round. Use when the user says "audit", "lint", or "audit the master wiki" in a session opened at a master wiki's root. Defaults to report-only and changes article contents only after explicit user confirmation. In a session opened inside a workstream folder, that workstream's audit-wiki handles audit instead.
---

# Master Wiki Audit

You are the librarian of the master wiki's `wiki/` folder. This skill reviews the cross-workstream synthesis for quality issues and produces a structured audit report. Unlike a single-wiki audit, this one also reads the upstream workstream wikis (in `raw/ws<N>-wiki/`) to detect staleness — claims the master is echoing that the source has since revised.

## When to invoke
- User says "audit", "lint", or "audit the master wiki"
- User asks for a review of cross-workstream synthesis quality, consistency, or coverage
- User asks you to check for stale or contradictory master-wiki content

## Before auditing, ask yourself
- **Cross-cutting test**: Does every master-wiki article actually synthesize across workstreams, or have some workstream-internal pages drifted in? Flag the latter.
- **Attribution coverage**: Can every claim trace back to a `[[wiki link]]` into a workstream wiki or a loose cross-cutting source? Unattributed claims are unverifiable.
- **Staleness vs upstream**: Has a workstream wiki updated a claim that the master is still echoing in its old form? Auditing a synthesis without checking the sources is fiction.
- **Scope honesty**: Am I auditing what the user asked, or wandering into adjacent themes?
- **Round positioning**: What did the last audit leave open? Re-flagging Round N-1's resolved items is noise.
- **Findings vs. proposals**: Real issues to flag (Findings) and new article ideas (Suggested New Articles) live in different sections — the user reads them with different intent.
- **Evidence strength**: Can I cite file:line for every claimed issue? For contradictions and staleness, can I cite file:line **on both sides** (master and upstream)? If not, it's a hunch, not a finding.

## Check the folder first

This skill audits the master wiki whose root is the session's working directory: a folder holding `wiki/_master-index.md`, plus at least one master marker: a `CLAUDE.md` whose first line starts with `# Master Wiki`, a `.claude/skills/master-compile/` or `.claude/skills/update-master-wiki/` folder, or a `.claude/skills/.master-wiki-version` stamp. If the working directory is anything else, stop and change nothing. In a session opened inside a workstream folder (`raw/<ws-slug>-wiki/` or below), Claude Code loads this skill from the master's folder too, and `audit` there belongs to the workstream's own `audit-wiki`. Tell the user so.

Reading a workstream's files in a session opened here makes Claude Code load that workstream's `CLAUDE.md` and skills. In this session the master's `CLAUDE.md` still governs, and every later `audit` runs this skill again. The master's `.claude/settings.json` switches the workstream skills off here.

## Scope question first
Before starting, confirm scope if it isn't clear:
- **Whole master wiki** → report file is `output/_audits/YYYY-MM-DD_master_audit-round-N.md`
- **Single theme** (e.g. `wiki/risks/`) → report file is `output/_audits/YYYY-MM-DD_<theme>_audit-round-N.md`

Round numbering is **per scope**. The whole-master audit has its own round sequence; each theme has its own too. Determine `N` by scanning past reports in `output/_audits/` for the same scope.

## Procedure

1. **Read past audits.** List `output/_audits/`. Read recent reports for the same scope so you don't re-flag resolved items and so you can carry forward unresolved "Known Open Items".
2. **Read the master index layer.** Start with `wiki/_master-index.md`, then each in-scope theme's `_index.md`.
3. **Sample the upstream state.** For each workstream folder in `raw/` (any child folder whose name ends in `-wiki`, or that holds a `CLAUDE.md`, a `wiki/` folder, a `.claude/` folder or a `.git` entry), read its `wiki/_master-index.md` and spot-check articles the master cites. This is the staleness check: you need a current picture of upstream to know what the master might be lagging on.
   Also read each workstream's `wiki/_pending-reconciliation.md` if it exists. An open row there means the workstream itself hasn't settled that claim. A master article that states such a claim as settled has an unflagged contradiction.
4. **Read in-scope master articles.** Cover every article in scope.
5. **Look for:**
   - **Workstream-internal drift** — articles that turned out to be one-workstream content rather than genuine synthesis. Flag for relocation back to the WS wiki, deletion, or rescoping to be genuinely cross-cutting. Note file:line.
   - **Unflagged contradictions** — claims that conflict across workstreams but the master article reads as if they agree. Note file:line on both sides.
   - **Upstream staleness** — master article claims something the relevant WS wiki has since revised or contradicted. Note master file:line and the upstream file:line that supersedes it.
   - **Missing attributions** — claims in master articles without `[[wiki links]]` to a source page. Note file:line.
   - **Missing cross-workstream comparisons** — concepts that appear in 2+ workstreams but have no master synthesis article. High-leverage gaps.
   - **Theme drift** — articles filed under the wrong cross-cutting theme.
   - **Stale or structural issues** — outdated indexes, orphaned articles, broken `[[links]]`.
   - **Index format drift** — `_master-index.md` and every theme `_index.md` must be markdown tables (`| Theme | Description |` / `| Article | Description |`), with `##` section groupings once a theme exceeds ~5 articles. Flag any index still in bullet-list form, missing descriptions, or with a description so thin it doesn't help navigation.
     Also flag an index whose rows write a piped link with a bare `|` (`[[theme-slug/_index|theme-slug]]`): the row splits into an extra column and the link breaks. Inside a table it must be `\|`. Count this once per index file, however many rows it affects, and not again under broken links. The fix inserts a `\` before each such pipe and changes nothing else in the row.
   - **Loose-file citations**: a `Sources:` item names a loose file by its path and compile date, so check `raw/_<date>-compiled/<path>` before calling it dangling. A file there is read the way master-compile's *Reading source files* section describes; a fact that came from a slide picture or a chart is missing from a text-only read.
6. **Suggest 3–5 new articles** that would strengthen the cross-workstream layer. Rank each by impact:
   - **High** — closes a load-bearing cross-cutting gap; would be referenced by multiple themes; resolves an open question spanning 2+ workstreams
   - **Mid** — useful sibling coverage or consolidation; would be referenced occasionally
   - **Low** — completeness or glossary-style; rarely linked but improves navigability
   
   For each suggestion: proposed title, one-line purpose, impact score, which workstreams it would draw from, and which existing master articles it would connect to. Do **not** create the articles in this pass — surface them in the report so the user can approve, reorder, or defer.
   Say for each suggestion whether the workstream wikis and the archived loose files already hold the facts it needs. A suggestion that needs facts none of them hold also goes on the report's Needs Source Material list.
7. **Default to report-only.** Do NOT edit article contents. Suggest changes in the report and wait for confirmation. For unresolved contradictions you want flagged in-place, propose a `⚠️` callout — but only add it after the user agrees.
8. **Score the master wiki's integrity.** From the issues you just found, compute the 0–100 integrity score (see [Master Wiki Integrity Score](#master-wiki-integrity-score)). This is the *as-found* score — the state before any fixes.
9. **Write the audit report** at `output/_audits/<filename-from-scope-section>` using the template below.

## Audit Report Template

```markdown
# Master Wiki Audit — <theme or "master">, Round N

**Date:** YYYY-MM-DD
**Scope:** articles reviewed (theme path if scoped, e.g. `wiki/risks/`)
**Workstream upstream state:** brief snapshot per WS (article counts, last visible update)
**Outcome:** one-line summary

## Findings

### 1. Workstream-Internal Drift
- Articles that no longer belong in the master wiki — list with file:line and recommendation (relocate to WS<N>, delete, or rescope to be genuinely cross-cutting)

### 2. Unflagged Contradictions
- Cross-workstream conflicts not currently surfaced — file:line on both sides, summary of the conflict, recommendation

### 3. Upstream Staleness
- Master claims contradicted or superseded by their source WS wiki — master file:line, upstream file:line that supersedes it, what changed

  *Example:* `wiki/risks/data-migration.md:14` states *"WS2 expects migration in Q3"*; superseded by `raw/ws2-wiki/wiki/timeline/migration-plan.md:8` which now reads *"Q4, blocked on WS1 dependency"*. Recommend updating the master claim and adding the dependency note.

### 4. Missing Attributions
- Claims in master articles without `[[wiki links]]` to a source page — file:line

### 5. Missing Cross-Workstream Comparisons
- Concepts appearing in 2+ WS wikis with no master synthesis — list with which workstreams cover them

### 6. Other Structural Issues
- Orphans, broken links, index format drift, theme placement issues

### 7. Suggested New Articles
- Table: Proposed Title | Purpose | Impact (High/Mid/Low) | Draws From (which WS) | Connects To (existing master articles)
- 3–5 entries, ordered by impact (High first)

### 8. New Articles Created (if any)
- Table: Article | Purpose | Highest Leverage For | Built from (the workstream pages and loose files it draws on)

### 9. Needs Source Material
- Gaps the sources can't close: which workstream would have to write the missing article, or which document would have to go into `raw/`. In a table cell, write any `|` as `\|`.

## Other Changes
- Index reorganizations, structural changes

## State of the Master Wiki After Round N
- Total articles, themes, link edges to workstream wikis

## Master Wiki Integrity Score

Before → After: <before> → <after>   (write `(no change)` after it when no fixes were applied)

## Known Open Items
- Unresolved flags, external actions (e.g., "confirm with WS2 lead"), WIP items
```

## Master Wiki Integrity Score

Each report carries a 0–100 integrity score so the synthesis layer's health is legible at a glance and the round-over-round change is real. The score must be **computed from a fixed rubric, not eyeballed** — the same master-wiki state always yields the same number, otherwise the before→after delta means nothing.

Compute it as `score = max(0, 100 − Σ penalties)`, one penalty per *open* issue (count only issues that appear in your own Findings):

| Issue type | Penalty (each) |
|---|---|
| Unflagged cross-workstream contradiction | −8 |
| Upstream staleness (master claim superseded by its source WS wiki) | −8 |
| Workstream-internal drift (a non-synthesis article sitting in the master) | −5 |
| Broken or orphaned link | −5 |
| Missing attribution (a claim with no `[[wiki link]]` to a source) | −4 |
| Index format drift (a non-table `_index.md` / `_master-index.md`) | −4 |
| Missing cross-workstream comparison (a concept in 2+ workstreams with no synthesis article) | −2 |
| Theme drift (an article filed under the wrong cross-cutting theme) | −2 |
| Convention nit (missing `## Key Takeaways`, threadbare index description, off-convention filename) | −1 |

Contradictions and upstream staleness are the two cardinal sins of a synthesis layer — a master that hides a conflict or echoes a claim its source has since revised is actively misleading — so both carry the heaviest penalty.

You record two numbers:
- **Before:** anchor on the prior round's *After* for this scope — its still-open issues carry forward and stay counted. Re-verify each carried-forward issue (drop any the user fixed out-of-band since last round), then add every new issue this round surfaces. A scope's first-ever round has no prior After, so Before is simply what you found. If a carried-forward count disagrees with last round's, reconcile it under Known Open Items and say why — an unexplained jump means the trend is fiction, not progress.
- **After:** recomputed once the user's chosen fixes land — drop the penalty for each *resolved* issue; anything deferred or declined stays counted. If no fixes are applied, after == before.

**Keep the report side dead simple.** The rubric above is *your* working method, not something the reader needs — so the report shows only one line: `Before → After: <before> → <after>`, with `(no change)` appended when nothing was applied (e.g. a report-only pass). No breakdown table, no per-dimension penalties, no formula in the report — just the number and how it moved.

## Conventions
- **Report-only pass first** — never change article contents without user confirmation.
- **Always include the Master Wiki Integrity Score line** — it's what makes the synthesis layer's health legible round to round (its one-line format and the rubric behind it live in [Master Wiki Integrity Score](#master-wiki-integrity-score)).
- After the user confirms fixes, the report documents both what was fixed AND what remains open.
- Use `⚠️` inline callouts in articles for unresolved cross-workstream contradictions, and reference them under "Known Open Items".
- Round numbering is sequential per scope.
- Use today's date for the filename and the `**Date:**` field.

## Anti-patterns

- **NEVER auto-create the "suggested new articles".** They are proposals for the user to approve, defer, or reject — not actions to execute.
- **NEVER skip the upstream read.** Auditing a synthesis layer without checking the source workstream wikis is fiction — you have no basis for the staleness check.
- **NEVER skip past audits.** Re-flagging items resolved last round wastes the user's attention and signals you didn't do the homework.
- **NEVER inflate findings to make the audit "feel productive".** If a round genuinely finds nothing, write that. A short honest report beats a padded one that trains the user to ignore future audits.
- **NEVER add `⚠️` callouts to articles before the user has approved them.** The report-only pass is binding.
- **NEVER claim a contradiction or staleness issue without `file:line` evidence on both sides** (master + upstream). A finding the user can't navigate to is unactionable.
- **NEVER tune the integrity weights or skip issues to make a round look better.** The rubric is fixed precisely so rounds are comparable; a flattered score is worse than no score.
- **NEVER recompute the Before score from a blank slate when a prior round exists.** Anchor it to the last round's After and carry the still-open issues forward — a Before that ignores history isn't a baseline, it's an unrelated number, and the round-over-round delta becomes meaningless.
- **NEVER report an after-score that assumes fixes you didn't actually apply.** The after-score must reflect the master wiki as it stands once you've stopped editing — deferred and declined issues stay counted.
- **NEVER dump the scoring rubric, penalty breakdown, or per-dimension table into the report.** The rubric is your internal method, not reader-facing clutter.

## Output to the user

After writing the report, surface:
- The audit report path
- The headline counts (findings per category, including the count of suggested new articles)
- The **Master Wiki Integrity Score** as `Before → After: X → Y`
- A short list of the highest-leverage proposed fixes, so the user can approve, reject, or reorder before any edits are made
- The High-impact suggested articles (just titles + one-line purpose), so the user can green-light, defer, or replace them

## Ask how to proceed

After surfacing the summary above, **always** ask the user how they want to proceed before making any changes. Use the `AskUserQuestion` tool with options scoped to what the report actually contains. The tool accepts at most four options per question and adds an "Other" choice of its own, where the user can type the specific items they want; that covers picking à la carte. Choose up to four of these:

- **Apply all fixes**: resolve drift, flag contradictions, refresh stale claims, add missing attributions, and create all High-impact suggested articles
- **Fixes only**: resolve issues and create no new articles
- **New articles only**: create the High-impact suggested articles and leave issues open for now
- **Report-only / do nothing**: leave the master wiki as it is, with the report as the record

Adapt the option set to what was actually found (e.g. drop options whose category is empty). Do not begin any edits until the user has answered.

## After the user chooses

Once the user picks what to apply:
1. Apply exactly the approved fixes and create exactly the approved articles — nothing they deferred or declined.
   - **New articles come from the sources already here.** An article the audit creates may only draw on the master's own articles, the workstream wikis' `wiki/` folders and loose files already archived in `raw/_<date>-compiled/`, and attributes every claim the usual way. If an approved article would need facts none of them hold, write only the part they support (or skip it) and add the rest to the report's Needs Source Material section. General knowledge never enters an article, because a claim with no source gives later reconciliation nothing to check.
   - **Resolving staleness or a contradiction:** point the claim's attribution at the workstream page that now holds it, and remove the article's `⚠️` callout once the conflict is settled, or the next round flags it again.
2. **Recompute the integrity score** over what's left open (resolved issues drop out; deferred/declined ones stay), and **update the report in place**: set the Master Wiki Integrity Score line to `Before → After: <before> → <after>`, and update "State of the Master Wiki After Round N" and "Known Open Items" to match reality.
3. Tell the user the score moved from `<before>` to `<after>` and what's still open, so the round closes with a clear, recorded measure of progress.

If the user chooses report-only / do nothing, the as-found score stands as the round's closing score (before == after) — still record it so the next round has a baseline to trend from.
