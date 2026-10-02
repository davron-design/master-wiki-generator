---
name: master-compile
description: Compile cross-workstream source material from raw/ into the master wiki/. Use when the user says "compile" in a session opened at a master wiki's root, drops new files into the master's raw/, or asks to refresh the cross-workstream synthesis. Reads each workstream wiki folder (raw/<ws-slug>-wiki/) as a live source, plus any loose cross-cutting files dropped directly into raw/, and writes synthesis articles into cross-cutting theme folders such as risks, decisions and dependencies. Archives the loose files after compiling and leaves the workstream wiki folders in place. In a session opened inside a workstream folder, that workstream's raw-compile handles compile instead.
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

## Check the folder first

This skill compiles the master wiki whose root is the session's working directory: a folder holding `wiki/_master-index.md`, plus at least one master marker: a `CLAUDE.md` whose first line starts with `# Master Wiki`, a `.claude/skills/master-compile/` or `.claude/skills/update-master-wiki/` folder, or a `.claude/skills/.master-wiki-version` stamp. If the working directory is anything else, stop and change nothing. In a session opened inside a workstream folder (`raw/<ws-slug>-wiki/` or below), Claude Code loads this skill from the master's folder too, and `compile` there belongs to the workstream's own `raw-compile`. Tell the user so.

Reading a workstream's files in a session opened here makes Claude Code load that workstream's `CLAUDE.md` and skills. In this session the master's `CLAUDE.md` still governs, and every later `compile` runs this skill again. The master's `.claude/settings.json` switches the workstream skills off here. If one of them gets invoked in this session anyway, don't follow it: a workstream's `raw-compile` run here would archive the workstream folders.

**Workstream folders.** A child folder of the master's `raw/` is a workstream folder when its name ends in `-wiki`, or when it holds a `CLAUDE.md`, a `wiki/` folder, a `.claude/` folder or a `.git` entry. A workstream folder is a live source: compile reads its `wiki/` subfolder, never moves or archives anything inside it, and never treats its files as loose files. Every other entry in `raw/` (files, and folders that are none of these) is loose material.

## Procedure

First, take stock of what's actually new. Unlike the leaf compile, the workstream folders are always present, so their mere existence is **not** a signal to compile. List the master's `raw/` and set aside everything that isn't a loose source: the workstream folders (see above), the archive folders (`_<date>-compiled/` and `_archive/`), dotfiles such as `.gitkeep` and `.DS_Store`, Office lock files whose names start with `~$`, empty folders, and the scaffold's `_workstream-setup-notes.md`. The setup notes are orientation for the user: never write synthesis from them, and don't count them as work. When a run archives loose files, archive the setup notes with them. A run has real work only when at least one of these holds: loose cross-cutting files are left over, or a workstream wiki has moved upstream since the last compile (compare against the most recent `raw/_<date>-compiled/` archive, or ask the user what changed). If neither is true, say so and stop. Create no dated archive folder, and write no synthesis for upstream that hasn't changed, since it would duplicate articles that already exist.

1. **Inventory `raw/`.** Two kinds of inputs:
   - **Workstream wikis**, the workstream folders defined above (`raw/<ws-slug>-wiki/`). Read only their `wiki/` subfolder, which holds the polished output. **Skip** their own `raw/` (input zone, not yet synthesized) and `output/` (their own reports). Start with each WS's `wiki/_master-index.md` and theme indexes, then read articles selectively, starting with the ones most likely to surface cross-cutting threads.
     - **Open conflicts inside a workstream.** If a workstream's `wiki/_pending-reconciliation.md` has an open row on an article you draw on, that workstream hasn't settled the claim yet. Attribute it as disputed inside that workstream, or leave it out of the synthesis.
   - **Loose files** directly in `raw/` (cross-cutting docs). Read each in full: text, tables, pictures, charts and speaker notes. *Reading source files* below says how to read each format, and every `.pptx`, `.docx` and `.xlsx` needs it, because text extraction misses pictures and chart values. If you could read only part of a file, compile what you read and list the unread items in the run report. If you can't read it at all, leave it in `raw/`, skip it, and flag it in the run report. Never compile from a filename or a guess at unreadable contents.

2. **Identify cross-cutting threads.** Look for:
   - The same concept appearing in multiple workstream wikis → synthesis opportunity
   - Dependencies named in one workstream's pages that affect another
   - Conflicting claims, decisions, or approaches across workstreams
   - Risks, timeline items, or open questions surfacing in multiple places

3. **Classify by cross-cutting theme.** Read `wiki/_master-index.md`. Place each synthesis article in an existing theme folder (e.g., `wiki/risks/`, `wiki/decisions/`, `wiki/dependencies/`) or create a new theme folder if no existing theme fits. **Themes are organized by cross-cutting TYPE, not by workstream.** If the genuine fit is two themes, write the article in one and cross-link from the other with `[[wiki links]]`.

4. **Write the synthesis article** at `wiki/<theme>/<article-slug>.md`:
   - Filename: lowercase, hyphenated, and unique across this whole folder, workstream wikis included, because a `[[article-slug]]` link resolves by filename alone. Before creating the file, check that `find . -name '<slug>.md' -not -path '*/_*-compiled/*' -not -path '*/_archive/*'` prints nothing. If it prints a path, pick a more specific slug (`<theme>-<slug>.md`).
   - Bullet points over paragraphs — keep it concise.
   - **Attribute every claim** in prose: *"Per [[ws1-wiki/wiki/risks/data-migration]]…"*, *"WS2 takes a different view: [[ws2-wiki/wiki/...]]…"*
   - Use `[[wiki links]]` to other master-wiki articles AND to source pages inside workstream wikis.
   - Flag genuine contradictions with a `⚠️` callout and a one-line note of what conflicts.
   - **Always** include a `## Key Takeaways` section.
   - If the article draws on loose files, **end with a `Sources:` footer**: a blank line, a `---` line, a `Sources:` line, and then one list item per loose file, `- <path relative to raw/> (compiled YYYY-MM-DD)`. Before a file's first citation, fix its archive name: if `raw/_<today>-compiled/<path>` already exists from an earlier run today, cite the next free suffix before the extension (`steerco.pptx` becomes `steerco-2.pptx`, then `steerco-3.pptx`), and step 7 archives the file under that name. Workstream pages are cited inline and need no footer item.

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

6. **Update `wiki/_master-index.md`**: also a markdown table (`| Theme | Description |`), one row per theme. Use the piped wiki-link form, escaped for the table as `[[theme-slug/_index\|theme-slug]]`, because a bare `|` ends the cell and breaks the link. Add or update the row when you create a new theme or when an existing description has gone stale. When you add the first theme row, delete the seed's `_No themes yet…_` placeholder line. Pack each description with the workstreams the theme draws from and its signature articles, so a reader can decide whether to drill in.

7. **Archive loose cross-cutting files only.** Once all loose files for this run are compiled, move each one into `raw/_<YYYY-MM-DD>-compiled/` (today's date, which must match the date in every `Sources:` item you wrote this run), preserving its path relative to `raw/`. Create the dated folder only when at least one file is being archived. **Do NOT touch the workstream folders.** They are live sources, and moving one breaks its sync or, for a workstream scaffolded here, takes the workstream wiki itself out of service.
   - **Archive every compiled loose file**, including one that only flagged a conflict. Only files skipped as unreadable stay in `raw/`.
   - **Never overwrite an archived file.** A second compile on the same day finds the dated folder already there, and a plain `mv` replaces a file at the same path without asking. Move each file with `mv -n` to the archive name fixed in step 4, which carries a suffix (`steerco-2.pptx`) when the plain name was taken. A loose file that no article cites has no name from step 4, so pick the next free suffix the same way when you move it. The suffix records a name clash and says nothing about which document is newer.
8. **Verify the trail before reporting.** For every `Sources:` item you wrote this run, confirm a file exists at `raw/_<date>-compiled/<path>`, and confirm that no compiled loose file is still sitting in `raw/`: a skipped `mv -n` leaves it there. Fix any line that doesn't resolve before you report.

## Reading source files

Step 1 reads every file in full. Extracted text from an Office file misses most of what a reader sees: pictures pasted into slides and pages sit in the zip's `media/` folder, native charts keep their values in separate `charts/` files, and speaker notes live in `ppt/notesSlides/`.

Work in a temporary folder outside the vault (`mktemp -d`), and use its literal path in every later command, because shell variables don't carry over between Bash calls. Run multi-line scripts through `bash <<'EOF'`, since the Bash tool may start zsh, which splits words and expands patterns differently. Nothing you render or unzip goes into `raw/`, `wiki/` or `output/`.

- **PDFs and images** (`.pdf`, `.png`, `.jpg`, `.gif`, `.webp`): read them directly. Read a long PDF in page ranges until every page is covered.
- **Office files with LibreOffice** (`.pptx`, `.docx`, and the older `.ppt`, `.doc`, `.xls`):
  - Find `soffice` with `command -v soffice`. The installers usually leave it off PATH, so also try `/Applications/LibreOffice.app/Contents/MacOS/soffice` on macOS and `C:\Program Files\LibreOffice\program\soffice.exe` on Windows (`/c/Program Files/LibreOffice/program/soffice.exe` in Git Bash).
  - Render with `soffice --headless --convert-to pdf --outdir <temp folder> <file>` and read the PDF, including every picture on its pages. Always pass `--outdir`: without it the PDF lands next to the source, and the next compile picks it up as new material. If no PDF appears, LibreOffice may already be open; add `-env:UserInstallation=file://<temp folder>/lo` to run it with a separate profile.
  - Unzip a copy into the temp folder and read what the PDF lacks or blurs: the exact chart values in `charts/chart*.xml` (the `<c:v>` values of each series; a rendered chart shows bars against axis ticks unless it has data labels), the speaker notes in `ppt/notesSlides/`, and every hidden slide, meaning a `ppt/slides/slideN.xml` whose root element carries `show="0"`. The PDF leaves hidden slides out, so read their text and pictures the way the *Office files without LibreOffice* bullet below describes. An older binary file can't be unzipped, so first convert a copy to the current format into the temp folder (`--convert-to pptx`, `docx` or `xlsx`) and unzip that.
- **Office files without LibreOffice:** unzip a copy into the temp folder and read:
  - every `<a:t>` text run in `ppt/slides/`, `ppt/notesSlides/`, `ppt/charts/` and `ppt/diagrams/` (SmartArt), or for `.docx` every `<w:t>` run in `word/document.xml` and its headers, footers and footnotes. Read the XML runs directly, since a loop over a library's text frames skips tables and grouped shapes.
  - every chart's values in `charts/chart*.xml`.
  - every image in `media/`, opened one by one. Match each image to its slide or page through `ppt/slides/_rels/slideN.xml.rels` or `word/_rels/document.xml.rels`. Slide order is set in `ppt/presentation.xml`, and the numbers in the slide file names can differ from it.
  - `.emf` and `.wmf` images (common for content pasted from Excel) can't be opened this way, so count them as unread. The older binary `.ppt`, `.doc` and `.xls` files can't be unzipped and are unreadable without LibreOffice.
- **Spreadsheets** (`.xlsx`): read the cell values of every sheet, hidden ones included (`state="hidden"` in `xl/workbook.xml`). Render the workbook only when it has `xl/media/` or `xl/charts/`, and take chart values from `xl/charts/chart*.xml`.

Then sort each file by what you managed to read:
- **Read in full:** compile it.
- **Partly read** (some images, charts or slides stayed unread): compile what you read, and list each unread item by slide or page in the run report, so the user can check it by hand.
- **Unreadable:** leave it in `raw/`, skip it, and flag it in the run report.

Keep count as you go. For each Office file the run report states how it was read and how many of its images and charts you read out of the number found.

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

- **Missing `wiki/` subfolder** in a workstream folder: the workstream hasn't synced or is mid-bootstrap. Skip that workstream this run and note it in the output report so the user knows to chase it.
- **Missing `_master-index.md`** in a WS wiki — fall back to walking the theme folders directly, but flag it in the output as a structural gap worth raising with the WS lead.
- **A master article cites a source page that no longer exists** — the WS may be mid-edit or have renamed the page. Leave the master article alone, do NOT delete the cite, and note it for the next `master-audit` run to verify (it will surface as upstream staleness).

## Output to the user

After compiling, report:
- Which workstream wikis were read and a quick snapshot of their state (e.g., article counts, last update)
- Which themes received new synthesis articles (new theme vs. existing)
- Any new theme folders created
- The name of the dated archive folder (if any loose files were processed), and any file archived under a suffixed name because its path was already taken
- For each Office file: how it was read (rendered with LibreOffice, or read from the zip), how many of its images and charts you read out of the number found, and any unread items by slide or page
- Loose files skipped as unreadable, which are still waiting in `raw/`
- Any cross-workstream contradictions flagged with `⚠️`
- **Any existing master articles now made stale by an upstream change** — name them so the user and the next `master-audit` run can reconcile them. Compile flags staleness; it does not rewrite the stale article.
- Anything ambiguous you had to make a judgment call on (so the user can correct course)

## Anti-patterns

- **NEVER duplicate workstream-internal content.** If the master article reads like a copy of one workstream's page, it doesn't belong here. Link to the workstream page instead.
- **NEVER organize the master wiki by workstream.** Themes (Risks, Decisions, Dependencies, etc.) cut across workstreams. A `wiki/ws1/` folder is a smell — that's exactly what the WS1 wiki is for.
- **NEVER archive a workstream folder or anything inside one** (see *Workstream folders*). Moving a synced one breaks its sync, and moving one scaffolded here takes that workstream wiki out of service.
- **NEVER compile an Office file from its extracted text alone.** Pictures, chart values and speaker notes sit outside the text, so the article loses them without a trace, and archiving the file hides the loss. Follow *Reading source files*.
- **NEVER overwrite a file that is already archived.** Two compiles on one day can meet at the same path in `raw/_<date>-compiled/`. Archive under the next free suffix (`steerco-2.pptx`) and cite that name.
- **NEVER drop articles into `wiki/` root.** Every article belongs to a theme folder — `_master-index.md` is the only navigation entry point at the root.
- **NEVER skip attribution.** A claim without a `[[wiki link]]` back to its source is unverifiable and does not belong in the master wiki.
- **NEVER skip `[[wiki links]]` for cross-references.** Broken graphs are silent failures.
- **NEVER overwrite an existing master-wiki article during compile — not even on a "refresh."** If new upstream material supersedes an existing article, surface it as a *new* article that flags the conflict and links to the one it supersedes (see [A "refresh" is still additive](#a-refresh-is-still-additive--never-rewrite-an-existing-article)), then name the stale article in your report. Reconciling the old article to the new facts is an audit-time decision (run `master-audit`), where the change is reviewed before it lands — not an ingest-time one.
- **NEVER skip the `## Key Takeaways` section.** It is the article's TL;DR — queries depend on it.
- **NEVER write `_master-index.md` or a theme `_index.md` as a bullet list.** Indexes are markdown tables — the extra structure is what makes the wiki navigable at a glance.

(Vault-wide conventions — filenames, wiki-links, attribution, `## Key Takeaways`, index-as-table — live in `CLAUDE.md`. The ones above are the compile-time-critical ones.)
