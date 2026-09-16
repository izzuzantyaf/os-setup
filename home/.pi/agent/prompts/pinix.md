---
description: Audit ~/.pi/agent against os-setup, report what belongs in nix
argument-hint: [extra instructions]
---
Audit `~/.pi/agent` against the nix-managed dotfiles at `~/os-setup` and report anything worth tracking in nix. Read-only: no `cp`, no writes anywhere under `~/os-setup`, no `git` commands, no `./rebuild.sh`, no `darwin-rebuild`, no sudo. Report and stop.

1. Inventory the live tree. `ls -la ~/.pi/agent`, then one level into `prompts/`, `themes/`, `extensions/`. Classify each entry:
   - MANAGED — symlink whose target contains `-home-manager-files/.pi/agent/`
   - LOCAL — real file or directory on disk, not linked by home-manager

2. Read `~/os-setup/home.nix` and collect every `home.file.".pi/agent/…"` entry with its `source` path. Build two drift sets:
   - LOCAL items in the live tree that no `home.file` entry covers
   - `home.file` entries whose repo path or live path no longer resolves

3. Never propose adding these — machine state, cache, or credential:
   `auth.json`, `trust.json`, `models-store.json`, `models.json`, `settings.json`, `mcp-cache.json`, `mcp-npx-cache.json`, `npm/`, `sessions/`, `web-search-cache/`, `*.bak-*`, `.DS_Store`.

4. Guard limits are real. The `hermes-guards` extension denies reads of `auth.json`, `models.json`, `models-store.json`, `settings.json`, `trust.json` through both the file tools and shell. Judge those by symlink target and mtime only. Never attempt a content read and never shell around the guard. If a guarded file matters to a verdict, name it and let the user decide what to share.

5. Verdict for each remaining LOCAL item: `add` or `skip`. Commented reasons required. For every `add`, print the exact `home.nix` line an apply would need:
   ```nix
   home.file.".pi/agent/extensions/X".source =
     config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions/X";
   ```
   A directory holding several files gets a dir-link, not per-file links. Files that carry a key, token, cookie, or session ID get reported, not copied or quoted.

6. Output, in this order:
   - table `path | managed? | verdict | reason`
   - the proposed `home.nix` hunk as a diff, marked "not applied"
   - `stale:` lines for links that no longer resolve
   - one closing line: `next: /sync-os-setup`

Extra instructions: $@
