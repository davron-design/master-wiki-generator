# master-wiki-generator — Maintainer Notes

These notes are for whoever maintains the `master-wiki-generator` skill itself.
**Destination users (people running the skill) never need to read this file.**

## Template sync

The files in `templates/` are the **canonical source** for the master-wiki convention. Any deployed copies — the maintainer's own live `.claude/skills/`, and every scaffolded downstream master wiki — are derivatives.

There are two layers of templates:

| Layer | Folder | What it seeds |
|---|---|---|
| Master-level | `templates/` | The master wiki itself: `CLAUDE.md`, `master-index.md`, `master-compile.SKILL.md`, `master-audit.SKILL.md`, and the two `workstream-setup-notes.*.md` variants. |
| Per-workstream | `templates/ws-templates/` | The fully-scaffolded workstream wikis (fresh-scaffold mode only): `CLAUDE.md`, `master-index.md`, `raw-compile.SKILL.md`, `audit-wiki.SKILL.md`. |

When updating `master-compile` or `master-audit`:

1. Edit the file in `master-wiki-generator/templates/`.
2. If the maintainer keeps a live master wiki of their own, run `bash scripts/deploy-to-live.sh` to push the updated templates into the sibling `.claude/skills/master-compile/` and `.claude/skills/master-audit/` next to this generator.
3. New downstream master wikis automatically get the latest version on next scaffold.

## Scripts

There are two scripts in `scripts/`, with opposite audiences — don't confuse them:

| Script | Audience | What it does |
|---|---|---|
| `scaffold.sh` | **End user** (driven by the running skill, `SKILL.md` step 7) | Creates a *new* master wiki from `templates/`: folder layout, template copy, `WORKSTREAMS` substitution, `.gitkeep` drops, and self-verification. Takes `--target`, `--mode`, `--scope`, `--workstreams`, and optional `--overwrite-master`. |
| `deploy-to-live.sh` | **Maintainer only** | Pushes updated `master-compile` / `master-audit` templates into the maintainer's *own* sibling live `.claude/skills/`. Not part of the end-user flow. |

`scaffold.sh` is the source of truth for the deterministic scaffold mechanics. When you change the file layout, the suffix rule, the install-scope routing, the populated-workstream guard, or the setup-notes substitution, change it **in `scaffold.sh`** — and keep `SKILL.md`'s step-7/step-8 description and the trees under "What gets created" in sync with it. The script enforces the safety invariants (template integrity, populated-workstream protection, global skip-if-exists) so they hold even if the agent's prose drifts.

## Relationship to wiki-generator

`master-wiki-generator` is a sibling of `wiki-generator`, not a runtime dependency, but in fresh-scaffold mode it **does** ship copies of `wiki-generator`'s four canonical templates under `templates/ws-templates/`. This bundling makes the master scaffolder self-contained — it can spin up workstream wikis without `wiki-generator` being installed.

**The bundled files in `templates/ws-templates/` are byte-for-byte copies of `wiki-generator/templates/`** — specifically:

- `CLAUDE.md`
- `master-index.md`
- `raw-compile.SKILL.md`
- `audit-wiki.SKILL.md`

If these copies drift from `wiki-generator`, the workstream wikis scaffolded inside a master diverge from the ones users scaffold standalone with `wiki-generator`. That divergence is a silent bug — the two paths *should* produce identical vaults.

**This sync is now automated.** A GitHub Action lives in the `wiki-generator` repo at `.github/workflows/sync-ws-templates.yml`. When any of the four files above changes on `wiki-generator`'s `main`, the Action copies them into `templates/ws-templates/` here and opens a pull request titled *"Sync ws-templates from wiki-generator"*. **Review and merge that PR** to keep the copies current; closing it without merging re-introduces the drift. The Action requires a one-time secret (`MASTER_WIKI_SYNC_TOKEN`) configured in `wiki-generator` — setup steps are documented at the top of the workflow file.

Manual fallback (if you ever need to sync by hand, e.g. before the secret is set up):

```sh
for f in CLAUDE.md master-index.md raw-compile.SKILL.md audit-wiki.SKILL.md; do
  cp "../wiki-generator/templates/$f" "templates/ws-templates/$f"
done
# verify — should report nothing:
diff -q ../wiki-generator/templates/ templates/ws-templates/
```

The two skills share design patterns (`AskUserQuestion`-driven wizard, template-first architecture, strict verification, upgrade-aware collision detection, `deploy-to-live.sh` workflow). The *master-level* files (`templates/CLAUDE.md`, the `master-*.SKILL.md` files, the setup-notes variants) describe different vault conventions on purpose — they are not copies of any `wiki-generator` file. Keep those master-level files in sync with `wiki-generator` only where the convention genuinely overlaps (e.g., the `## Key Takeaways` rule, lowercase-hyphenated filenames).

## The workstream-setup-notes substitution

Both `templates/workstream-setup-notes.placeholder.md` and `templates/workstream-setup-notes.fresh.md` contain a marker block:

```
<!-- WORKSTREAMS:START -->
- `raw/<ws-slug>-wiki/`  *(scaffolder replaces this block with your actual workstream list)*
<!-- WORKSTREAMS:END -->
```

`scripts/scaffold.sh` picks one of the two templates based on the user's scaffold-mode choice and replaces that block (markers included) with one bullet per actual workstream folder before writing it to `<target>/raw/_workstream-setup-notes.md`. The substitution is an `awk` pass that (a) swaps the `WORKSTREAMS:START`…`END` block for the generated bullets and (b) strips any HTML comment block containing `SCAFFOLDER NOTE` so the deployed file is clean. The script then verifies the markers are gone *and* the actual bullets are present.

If you change the marker syntax or the `SCAFFOLDER NOTE` sentinel, update **both** templates and the `awk` program in `scaffold.sh` so the substitution stays correct.

## Upgrade-safety for fresh-scaffolded workstream wikis

The collision logic (`SKILL.md` step 6) treats workstream folders carefully: if `raw/<ws-slug>-wiki/` already contains real content (anything beyond `.gitkeep`), the scaffolder must **not** overwrite it even on the upgrade path. This protects users from accidentally wiping a workstream wiki they've been actively filling in.

This means re-running `master-wiki-generator` against an existing master in fresh-scaffold mode is **safe for the workstreams** — the master-level files get refreshed, but populated workstream folders are left alone. The user gets a report of which workstreams were skipped because they had real content.

If the user changed a workstream's name between runs (e.g., renamed `ws1-wiki` → `data-platform-wiki`), the scaffolder will see the new name as a *new* workstream and create a fresh placeholder/scaffold at `raw/data-platform-wiki/` while leaving the populated `raw/ws1-wiki/` untouched. Flag this clearly in the output report — the user almost certainly wants to manually move content from the old folder to the new one, not have two parallel folders.

## Upgrading existing downstream master wikis

Existing downstream master wikis are not auto-upgraded. The supported upgrade path is to re-run `master-wiki-generator` against the existing target and choose **overwrite** at the collision prompt. The skill detects this case (canonical files all present, plus at least one `raw/<slug>-wiki/` folder) and surfaces it explicitly so the user doesn't accidentally pick the default (skip), which would leave them on stale templates.

Note that re-running the wizard re-asks the workstream count and names. If the user is upgrading and their workstream list hasn't changed, they should re-enter the same names — the scaffolder will detect existing `raw/<slug>-wiki/` folders as collisions and (per upgrade-mode framing) overwrite the `.gitkeep` placeholders without disturbing any synced workstream content already in those folders. **Do not let the scaffolder run if a `raw/<slug>-wiki/` folder contains real workstream content (anything beyond `.gitkeep`)** — that's a sign the user picked a different name than last time and the scaffolder would create a parallel placeholder folder, leaving the real one orphaned.

## Direction of truth

Templates → deployments. **Never the reverse.** If you debug a bug by editing a deployed master wiki's `CLAUDE.md` or one of its companion `SKILL.md` files directly, you must port the fix back into `templates/` before considering the change durable — otherwise the next scaffold or `deploy-to-live.sh` run will overwrite it.

Exception: the deployed `_workstream-setup-notes.md` after substitution intentionally differs from the template (it lists actual workstream folders, not the placeholder block). Don't try to round-trip that file back to `templates/`.
