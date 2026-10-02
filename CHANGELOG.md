# Changelog

Released versions of the master-level templates in `templates/`: the master's `CLAUDE.md`,
`master-compile`, `master-audit` and `update-master-wiki`. Every master wiki records the
version it runs in `.claude/skills/.master-wiki-version`, and the `update-master-wiki` skill
reads that stamp to tell the user exactly what they are missing.

The workstream wikis inside a master run `wiki-generator`'s templates. Their changes are in
[wiki-generator's changelog](https://github.com/davron-design/wiki-generator/blob/main/CHANGELOG.md).

Versions are dates (`YYYY-MM-DD`). A second release on the same day gets a `.2` suffix.

Bumping is manual and belongs in the same commit as the template edit: change the template,
add an entry here, set `templates/VERSION`. See [MAINTAINER.md](MAINTAINER.md).

## 2026-10-02

- **Master wikis update themselves.** Say `update` at the master root. The new
  `update-master-wiki` skill fetches this release, compares each of the master's files with
  the release it came from, shows your own edits and what changed, and asks before writing.
  It never touches `wiki/`, `raw/` or `output/`. A master set up before this release needs a
  one-line prompt first: see "If `update` doesn't do anything" in the README.
- **`update` also lists the workstream wikis that are behind.** Each workstream wiki updates
  on its own: open its folder in a new session and say `update`. Workstreams set up before
  this release have no `update-wiki` yet, and `update` at the master root gives you the
  one-line prompt for each.
- **New workstream wikis come with `update-wiki` and a version stamp.** They hold the same
  files a standalone `wiki-generator` wiki gets, so they pick up later compile and audit rules
  with `update`.
- **Skills always install inside the master and inside each workstream.** The "install for
  all projects" option is retired, because copies in `~/.claude/skills/` run ahead of every
  project's own and silently override them. If you used it, `update` at the master root
  offers to move the old master skills into a backup folder, and `update` inside each
  workstream does the same for `raw-compile` and `audit-wiki`. The manual steps are in the
  README.
- **The master switches the workstream skills off at its root.** When a session opened at the
  master root reads a workstream's files, Claude Code also loads that workstream's skills, and
  `compile` there could then run the workstream's `raw-compile`, which would archive the
  workstream wikis as if they were source files. The master's new `.claude/settings.json`
  switches `raw-compile`, `audit-wiki` and `update-wiki` off in sessions opened at the master
  root. `update` adds it, or adds its three entries to a settings file you already have, and
  keeps your other settings. Start a new session at the master root afterwards, since Claude
  Code reads settings when a session starts. In a session opened inside a workstream's folder,
  its own skills run as before.
- **`update` flags an outdated copy of the generator.** The generator copy installed in a
  master's `.claude/skills/master-wiki-generator/` isn't updated by `update`, and a copy from
  before this release still offers the retired "install for all projects" option. `update`
  now tells you when to refresh it by pasting the README's Step 3 prompt again.
- **Workstream skills in the master's own skills folder.** An older `update` run at the
  master root could have installed `raw-compile`, `audit-wiki` and `update-wiki` next to the
  master's skills. `update` now finds them and offers to move them into a backup folder.
- **Decks, documents and spreadsheets in the master's `raw/` are read in full:** pictures,
  chart values, speaker notes and hidden slides, rendered with LibreOffice when it is
  installed (free and optional). The compile report says, per file, how many pictures and
  charts were read, and lists anything it couldn't open.
- **Same-day compiles keep every archived file.** A file whose name is taken in today's
  archive folder is stored as `steerco-2.pptx`. An article that draws on a loose file lists it
  in a `Sources:` footer with its compile date, so the citation still resolves after
  archiving.
- **Open conflicts inside a workstream stay visible.** When a workstream's
  `_pending-reconciliation.md` holds an open row on a claim, compile marks that claim as
  disputed, and audit flags a master article that states it as settled.
- **Audit.** The closing question fits the tool's four options; type specific items under
  "Other". Articles the audit creates draw only on the workstream wikis and archived files,
  and a new "Needs Source Material" list holds the rest. Index links must escape the pipe as
  `\|`. **Run `audit` after updating:** the pipe check is new, so the first score can drop
  and can't be compared with earlier rounds.
- **Running the generator on an existing master adds workstreams** and keeps every master
  file as it is. Template updates go through `update`. It refuses a standalone wiki as the
  target, and workstream names must be lowercase letters, digits and hyphens.

## 2026-06-10

The master templates as they stood before versioning. The tag `v2026-06-10` points at them,
so `update` can recognize an unedited copy from that time.
