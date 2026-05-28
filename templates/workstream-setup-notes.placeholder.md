# Workstream Wiring — Setup Notes

This master wiki expects every workstream wiki to land at `raw/<ws-slug>-wiki/` so that `master-compile` can read each one as a live source on every compile. The scaffolder created empty placeholder folders (each with a `.gitkeep`) for the workstreams you named during setup. **They need to be filled with the real workstream wiki content** before the master can synthesize anything.

You have two wiring options. Pick one per workstream — you can mix and match.

<!--
SCAFFOLDER NOTE: replace the WORKSTREAMS block below with one bullet per workstream
folder you actually created. The scaffolder substitutes this when writing the file.

Example output for workstreams ws1, ws2, ws3:

- `raw/ws1-wiki/`
- `raw/ws2-wiki/`
- `raw/ws3-wiki/`

For custom names (e.g., data-platform, frontend, infra) the folders are named
`raw/data-platform-wiki/`, `raw/frontend-wiki/`, `raw/infra-wiki/`.
-->

## Workstream folders created by the scaffolder

<!-- WORKSTREAMS:START -->
- `raw/<ws-slug>-wiki/`  *(scaffolder replaces this block with your actual workstream list)*
<!-- WORKSTREAMS:END -->

---

## Option A — Git submodules (recommended for shared / multi-collaborator masters)

Each workstream wiki is added as a git submodule so that `git submodule update --remote` pulls the latest upstream content before every compile.

For each workstream folder above:

```bash
# 1. Remove the .gitkeep so the submodule target is empty
rm raw/<ws-slug>-wiki/.gitkeep
rmdir raw/<ws-slug>-wiki

# 2. Add the workstream wiki as a submodule at that path
git submodule add <workstream-wiki-repo-url> raw/<ws-slug>-wiki

# 3. Commit
git add .gitmodules raw/<ws-slug>-wiki
git commit -m "wire <ws-slug> wiki as submodule"
```

Before each compile, refresh upstream:

```bash
git submodule update --remote
```

## Option B — Manual sync (simplest, no git wiring)

Clone each workstream repo somewhere else on your machine and copy its contents into the matching `raw/<ws-slug>-wiki/` folder whenever you want to refresh.

For each workstream folder above:

```bash
# 1. Clone the workstream wiki somewhere outside the master
git clone <workstream-wiki-repo-url> ~/workstreams/<ws-slug>-wiki

# 2. Each time you want to refresh, replace the master's copy
rm -rf raw/<ws-slug>-wiki
cp -R ~/workstreams/<ws-slug>-wiki raw/<ws-slug>-wiki

# 3. Commit the refresh in the master
git add raw/<ws-slug>-wiki
git commit -m "refresh <ws-slug> wiki snapshot"
```

You only need to repeat steps 2–3 when the workstream wiki has new content worth pulling into the master.

---

## Then compile

Once every `raw/<ws-slug>-wiki/` has real workstream content (a `wiki/` subfolder with articles), say **"compile"** in Claude Code. The `master-compile` skill will read each workstream wiki plus any cross-cutting files you've dropped into `raw/`, then write synthesis articles into `wiki/`.

**This setup-notes file (`_workstream-setup-notes.md`) is itself a cross-cutting file in `raw/`.** It will get archived into `raw/_<date>-complied/` on first compile — that's expected. Once your workstreams are wired up you don't need it anymore.

---

## Anti-patterns to avoid

- **Don't nest workstream wikis inside the master's own `wiki/` folder.** They live under `raw/`. The `wiki/` folder is for cross-cutting synthesis articles only.
- **Don't reorganize `raw/<ws-slug>-wiki/` to remove the workstream wiki's own `raw/` or `output/` subfolders.** `master-compile` knows to read only the `wiki/` subfolder and skip the rest. Keep the workstream's own structure intact.
- **Don't manually edit files under `raw/<ws-slug>-wiki/`.** Those are upstream content; edits will be overwritten on the next sync/submodule update. If something needs fixing, fix it in the upstream workstream wiki.
