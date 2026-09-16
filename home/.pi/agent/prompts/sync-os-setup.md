---
description: Review ~/os-setup changes, split into commits, push
argument-hint: [extra instructions]
---
Sync the dotfiles repo at `~/os-setup` (nix-darwin; remote `git@github.com:izzuzantyaf/os-setup.git`, branch `main`).

1. `cd ~/os-setup` and run `git status --short`, `git diff`, `git diff --cached`.
2. If there is nothing to commit, say so and stop. Do not create an empty commit.
3. Read every hunk. If anything looks like a secret (API key, token, password, private key, `.env`, credential file), stop and report it — never stage it.
4. Split the work into separate commits by concern — one commit per logical change, not one giant commit. Stage explicit paths (`git add <path>`, never a blind `git add -A`).
5. Commit messages follow this repo's history: `chore: <lowercase summary>`, no scope, e.g. `chore: bump flake inputs`, `chore: add redis service`.
6. `git push` once at the end, then report each commit hash and its message.
7. Do not run `./rebuild.sh` or anything needing sudo. Read-only git commands plus commit/push only.

Extra instructions: $@
