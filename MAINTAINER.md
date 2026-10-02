# master-wiki-generator — Maintainer Notes

These notes are for whoever maintains the `master-wiki-generator` skill itself.
**Destination users (people running the skill) never need to read this file.**

## Template sync

The files in `templates/` are the **canonical source** for the master-wiki convention. Any deployed copies (the maintainer's own live `.claude/skills/`, and every scaffolded downstream master wiki) are derivatives.

There are two layers of templates:

| Layer | Folder | What it seeds | Released by |
|---|---|---|---|
| Master-level | `templates/` | The master wiki itself: `CLAUDE.md`, `master-index.md`, `master-compile.SKILL.md`, `master-audit.SKILL.md`, `update-master-wiki.SKILL.md`, `settings.json`, `VERSION`, and the two `workstream-setup-notes.*.md` variants. | This repo, tagged `v<templates/VERSION>` |
| Per-workstream | `templates/ws-templates/` | The fully-scaffolded workstream wikis (fresh-scaffold mode only): `CLAUDE.md`, `master-index.md`, `raw-compile.SKILL.md`, `audit-wiki.SKILL.md`, `update-wiki.SKILL.md`, `VERSION`. | `wiki-generator`, tagged `v<ws-templates/VERSION>` there |

The managed master files, which `update-master-wiki` keeps current in every master, are `CLAUDE.md`, `master-compile.SKILL.md`, `master-audit.SKILL.md` and `update-master-wiki.SKILL.md`. `master-index.md` and the setup-notes are seeds, written once at scaffold time. `settings.json` is written when a master has none. When one exists, `update-master-wiki` (step 13) adds its three entries and keeps the user's other settings, and the scaffold prints `NOTE settings` so the agent adds them. Both name the three skills themselves, so a later change to `templates/settings.json` reaches new masters only, unless step 13 changes with it.

## Releasing master templates

When updating a managed master file:

1. Edit the file in `master-wiki-generator/templates/`.
2. **Bump the version in the same commit.** Set `templates/VERSION` to today's date (`YYYY-MM-DD`, plus `.2` for a second release the same day) and add a matching `## <VERSION>` entry at the top of [`CHANGELOG.md`](CHANGELOG.md). `update-master-wiki` installs a release from its tag, and the release-tag workflow refuses to create a tag for a version without its changelog entry, so an edit shipped without both is invisible to every existing master.
3. If you keep a live master wiki of your own, you can run `bash scripts/deploy-to-live.sh` to try the templates there before you push. It refuses to run unless the generator sits inside `<master>/.claude/skills/`, and it doesn't stamp `.master-wiki-version`.
4. Push to `main`.
5. On the Actions tab, check the **Release tag** run. Its `release` job must be green, and the tag must exist: `git ls-remote --tags origin "v$(tr -d '[:space:]' < templates/VERSION)"`. The job also creates the GitHub release `v<VERSION>` with the CHANGELOG entry as its notes. It refuses a VERSION older than the newest tag, and runs only on `main`.
6. Check that the **Checks** run is green (see *Checks* below).
7. Run the post-push check below.
8. Announce the release no sooner than 10 minutes after the push. Until the tag exists and the 5-minute CDN cache has turned over, `update` can stop with `tag-missing` and tell users the release is still being published.
9. Never move or delete a `v*` tag. Every master on a release compares its files against that tag, so a moved tag shows up as false local edits everywhere. A wrong release gets a new version.

Write changelog entries for the person reading them inside a stale master. They will see the entry with no other context, so name what changed in their compile, audit or update behaviour.

The first versioned release is `2026-10-02`. The tag `v2026-06-10` was created by hand at `4e83adc`, the last commit that changed the master templates before versioning, so `update` can recognize an unedited master from that time as an older release copy.

### Post-push check

Tag results must all read `ok` as soon as the tag exists. `main` results can read `DIFF` for up to 5 minutes after the push, and this only tests the CDN location nearest to you.

```bash
V=$(tr -d '[:space:]' < templates/VERSION); R=https://raw.githubusercontent.com/davron-design/master-wiki-generator
for ref in main "refs/tags/v$V"; do for f in templates/VERSION templates/CLAUDE.md templates/master-compile.SKILL.md templates/master-audit.SKILL.md templates/update-master-wiki.SKILL.md templates/settings.json CHANGELOG.md; do
  curl -fsSL "$R/$ref/$f" | cmp -s - "$f" && echo "ok    $ref $f" || echo "DIFF  $ref $f"; done; done
```

## How existing masters update

Each scaffolded master carries an `update-master-wiki` skill. Saying **"update"** at the master root makes it:

1. read `.claude/skills/.master-wiki-version` for the release each managed file came from (a `held-back:` line lists files at another release, as `<name>@<version>`),
2. fetch `templates/VERSION` from `main`, then the four managed templates and `CHANGELOG.md` from the tag `v<VERSION>`, plus pristine copies of the release the master installed from that release's own tag,
3. compare every file three ways (local copy, installed release, new release), show full diffs for `CLAUDE.md` and for any file with local edits, and ask before writing,
4. copy only the approved files from the fetched release, verify each copy, then re-stamp `.master-wiki-version`,
5. make sure `.claude/settings.json` switches the workstream skills off at the master root, adding the entries and keeping the user's own settings,
6. offer to move global copies of the master skills out of `~/.claude/skills/`, and workstream skills out of the master's own `.claude/skills/`,
7. list the workstream wikis in `raw/` and what each needs. It never writes into them: each workstream updates with its own `update-wiki`, from `wiki-generator`'s releases, in a session opened in its folder.

The skill is the same design as `wiki-generator`'s `update-wiki`. When that one gets a fix to its fetch, classify or stamp logic, check whether `update-master-wiki` needs the same fix.

This depends on the repo staying **public**, because the fetch is an unauthenticated `curl` against `raw.githubusercontent.com`.

Masters scaffolded before `update-master-wiki` existed have no way to run it. The bootstrap paste-prompt lives in `templates/update-master-wiki.SKILL.md` under *Bootstrapping a master that has no `update-master-wiki` yet*, and is repeated word for word in the README; the Checks workflow fails when the two copies differ. Step 15 of the same skill quotes `wiki-generator`'s bootstrap prompt for workstreams without `update-wiki`, and the Checks workflow compares that copy with the one in `ws-templates/update-wiki.SKILL.md`.

## Sessions in nested folders

A master's root holds `CLAUDE.md` and `wiki/_master-index.md`, the same two files that mark a standalone wiki, and its `raw/` holds whole wikis. Claude Code loads `CLAUDE.md` from every parent folder, loads project skills from parent folders (also without a git repo), and loads a subfolder's `CLAUDE.md` and skills once a session reads a file there, keeping them for the rest of the session. So both sets of skills can be loaded in one session. In a master-root session, a workstream's `raw-compile` would treat the workstream wikis in `raw/` as sources and archive them.

The master protects itself, and `wiki-generator` stays unaware of masters:

- `templates/settings.json` becomes the master's `.claude/settings.json` and switches `raw-compile`, `audit-wiki` and `update-wiki` off with `skillOverrides`. That blocks Claude and the user alike, including the renamed copies (`raw/<ws>-wiki:raw-compile`) Claude Code creates once two workstreams are loaded. Project settings apply only to sessions opened in their own folder, so workstream sessions keep their skills. Tested with Claude Code 2.1.287.
- `master-compile`, `master-audit` and `update-master-wiki` check the folder first and stop outside a master's root, which covers workstream sessions, where the master's skills load from the parent folder.
- The master's `CLAUDE.md` opens with the same rule for the model, which is all an older Claude Code without `skillOverrides` has.

## Scripts

There are two scripts in `scripts/`, with opposite audiences. Don't confuse them:

| Script | Audience | What it does |
|---|---|---|
| `scaffold.sh` | **End user** (driven by the running skill, `SKILL.md` step 8) | Creates a *new* master wiki from `templates/`, or adds workstreams to an existing one: folder layout, template copy, `WORKSTREAMS` substitution, version stamps, `.gitkeep` drops, and self-verification. Takes `--target`, `--mode` and `--workstreams`. |
| `deploy-to-live.sh` | **Maintainer only** | Pushes updated `master-compile`, `master-audit` and `update-master-wiki` templates into the maintainer's *own* sibling live `.claude/skills/`. Not part of the end-user flow. |

`scaffold.sh` is the source of truth for the deterministic scaffold mechanics. When you change the file layout, the suffix rule, the stamps, the populated-workstream guard, or the setup-notes substitution, change it **in `scaffold.sh`**, and keep `SKILL.md`'s step-8/step-9 description and the trees under "What gets created" in sync with it. The script enforces the safety invariants (template integrity, slug format, no overwrites, populated-workstream protection, no writes into the global skills folder, byte-for-byte copies) so they hold even if the agent's prose drifts.

## Relationship to wiki-generator

`master-wiki-generator` builds on `wiki-generator`, and the dependency runs one way: `wiki-generator` has no link to this repo. In fresh-scaffold mode this repo ships a copy of one `wiki-generator` release under `templates/ws-templates/`, so it can spin up workstream wikis without `wiki-generator` being installed.

**The bundled files in `templates/ws-templates/` are byte-for-byte copies of `wiki-generator/templates/` at the tag `v<ws-templates/VERSION>`**:

- `CLAUDE.md`
- `master-index.md`
- `raw-compile.SKILL.md`
- `audit-wiki.SKILL.md`
- `update-wiki.SKILL.md`
- `VERSION`

`scaffold.sh` stamps every new workstream with `ws-templates/VERSION`, and that workstream's `update-wiki` later compares its files with `wiki-generator`'s tag of that version. A copy that differs from the tag, even by a byte, shows up as a local edit in every workstream scaffolded from it. So never edit these files here.

**The sync is automated, from this side.** `.github/workflows/sync-ws-templates.yml` here checks `wiki-generator`'s release tags once a day (or on demand from the Actions tab). When a newer release exists, it copies the six files from that tag and opens a pull request titled *"Sync ws-templates from wiki-generator v<version>"*. **Review and merge it** so new workstreams start on the latest release. A closed one leaves them on the older release, which `update` can still move forward. It needs one repository setting: Settings > Actions > General > Workflow permissions, "Allow GitHub Actions to create and approve pull requests". A pull request opened by the workflow token starts no other workflows, so the sync job runs the reading-section and bootstrap-prompt checks itself, lists any file the release adds beyond the six, and writes all three results into the pull request. **Checks** runs on main after the merge. GitHub turns off scheduled workflows in a public repo after 60 days without commits; if the daily run stops, re-enable it on the Actions tab or run it by hand. A run fails when `wiki-generator`'s tags can't be read, so a renamed or private repo shows up as a red run.

Manual fallback, from a `wiki-generator` clone next to this one (`V` is the release to copy):

```sh
V=2026-10-02
for f in CLAUDE.md master-index.md raw-compile.SKILL.md audit-wiki.SKILL.md update-wiki.SKILL.md VERSION; do
  git -C ../wiki-generator show "v$V:templates/$f" > "templates/ws-templates/$f"
done
```

`master-compile.SKILL.md` carries a copy of `raw-compile`'s *Reading source files* section, word for word, so loose files in a master are read the same way as in a workstream. The Checks workflow fails when the two differ. When a sync PR changes that section, copy it into `master-compile` in the same PR, and release the master.

The two skills share design patterns (`AskUserQuestion`-driven wizard, template-first architecture, strict verification, version stamps with tag-based updates, `deploy-to-live.sh` workflow). The *master-level* files (`templates/CLAUDE.md`, the `master-*.SKILL.md` files, the setup-notes variants) describe different vault conventions on purpose and copy no `wiki-generator` file. Keep them in line with `wiki-generator` where the convention overlaps (the `## Key Takeaways` rule, lowercase-hyphenated filenames, escaped pipes in index rows, `Sources:` footers, archive suffixes). `update-master-wiki` follows `update-wiki`'s design, so check it whenever `update-wiki` gets a fix.

## Checks

`.github/workflows/checks.yml` runs on every push and pull request:

- **ws-templates**: the six files equal `wiki-generator`'s tag `v<ws-templates/VERSION>`.
- **reading-section**: `master-compile`'s *Reading source files* section equals the one in `ws-templates/raw-compile.SKILL.md`.
- **bootstrap-prompts**: the `update-master-wiki` prompt is the same in the skill and the README, and the workstream prompt in its step 15 is the same as in `ws-templates/update-wiki.SKILL.md`.

None of them blocks a tag. Sync pull requests don't trigger these checks (see above), so after merging one, check that the run on main is green.

## The workstream-setup-notes substitution

Both `templates/workstream-setup-notes.placeholder.md` and `templates/workstream-setup-notes.fresh.md` contain a marker block:

```
<!-- WORKSTREAMS:START -->
- `raw/<ws-slug>-wiki/`  *(scaffolder replaces this block with your actual workstream list)*
<!-- WORKSTREAMS:END -->
```

`scripts/scaffold.sh` picks one of the two templates based on the user's scaffold-mode choice and replaces that block (markers included) with one bullet per actual workstream folder before writing it to `<target>/raw/_workstream-setup-notes.md`. The substitution is an `awk` pass that (a) swaps the `WORKSTREAMS:START`…`END` block for the generated bullets and (b) strips any HTML comment block containing `SCAFFOLDER NOTE` so the deployed file is clean. The script then verifies the markers are gone *and* the actual bullets are present. An existing setup-notes file is kept as it is.

If you change the marker syntax or the `SCAFFOLDER NOTE` sentinel, update **both** templates and the `awk` program in `scaffold.sh` so the substitution stays correct.

## Adding workstreams to an existing master

`scaffold.sh` never overwrites a file. On an existing master it writes the workstream folders that don't exist yet (or hold nothing but a `.gitkeep` or `.DS_Store`) and keeps every existing master file and setup-notes file as it is. A stamped master gets nothing else. An older, unstamped master also gets the master files it lacks, such as `update-master-wiki`, and a stamp that marks its existing files `@unknown`. A master without `.claude/settings.json` gets one. A workstream folder that already contains real content is reported as `SKIPPED (populated workstream, left untouched)`. The script also refuses a standalone wiki as its target.

If the user changed a workstream's name between runs (e.g., renamed `ws1-wiki` → `data-platform-wiki`), the scaffolder sees the new name as a *new* workstream and creates a fresh folder at `raw/data-platform-wiki/` while leaving the populated `raw/ws1-wiki/` untouched. Flag this clearly in the output report: the user almost certainly wants to move content from the old folder to the new one.

## Adding a new managed file

If you ever add a fifth managed master template, these places have to learn about it in the same commit, or it will freeze at its install-time contents in every master ever scaffolded:

1. `scripts/scaffold.sh`: `require_template`, the copy list, the `MISSING` list and the `held-back:` names
2. `SKILL.md`: the trees under "What gets created"
3. `templates/update-master-wiki.SKILL.md`: the *What this skill owns* table, the stamp names, the `FILES` list in step 4, and a `classify` call in step 7. `AskUserQuestion` takes at most four questions per call, so step 9's one-question-per-file call needs a second call for a fifth file.
4. `.github/workflows/release-tag.yml`: the trigger paths and the `managed` list in the tag check (`templates/settings.json` is on it too, since `update-master-wiki` fetches it from the tag)
5. `scripts/deploy-to-live.sh`, if it is a skill

## Direction of truth

Templates → deployments. **Never the reverse.** If you debug a bug by editing a deployed master wiki's `CLAUDE.md` or one of its companion `SKILL.md` files directly, you must port the fix back into `templates/` (and bump the version) before considering the change durable, or the next `update` will offer to replace it.

Exception: the deployed `_workstream-setup-notes.md` after substitution intentionally differs from the template (it lists actual workstream folders, not the placeholder block). Don't try to round-trip that file back to `templates/`.
