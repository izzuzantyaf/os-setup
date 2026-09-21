#!/usr/bin/env bash
# Runnable self-check for the VPS setup: `bash ubuntu/vps/check.sh`.
# Exits non-zero when something drifted from what the config claims.
set -uo pipefail

fails=0
check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc"
    fails=$((fails + 1))
  fi
}

check "nvim config symlinked into the repo" bash -c 'readlink -f ~/.config/nvim | grep -q "^$HOME/.os-setup/"'
check "pi settings symlinked into the repo" bash -c 'readlink -f ~/.pi/agent/settings.json | grep -q "^$HOME/.os-setup/"'
check "pi extensions symlinked into the repo" bash -c 'readlink -f ~/.pi/agent/extensions/guard | grep -q "^$HOME/.os-setup/"'
check "AGENTS.md shim for codex" bash -c 'readlink -f ~/.codex/AGENTS.md | grep -q "^$HOME/.os-setup/"'
check "AGENTS.md shim for gemini" bash -c 'readlink -f ~/.gemini/GEMINI.md | grep -q "^$HOME/.os-setup/"'
check "typesafe skill symlinked into the repo" bash -c 'readlink -f ~/.agents/skills/typesafe | grep -q "^$HOME/.os-setup/"'
check "starship config generated" test -f ~/.config/starship.toml
check "zsh starts" zsh -lc true
check "zu on PATH" bash -lc 'command -v zu'
check "herdr runs (prebuilt binary from pkgs/herdr.nix)" bash -lc 'herdr --version'
check "herdr config symlinked into the repo" bash -c 'readlink -f ~/.config/herdr/config.toml | grep -q "^$HOME/.os-setup/"'
check "rtk on PATH" bash -lc 'command -v rtk'
check "pi (pi-coding-agent) on PATH" bash -lc 'command -v pi'
check "hermes-agent installed by system.sh" bash -lc 'command -v hermes'
# sshd -T needs the privilege separation dir, which systemd only creates while
# ssh is actually running (it lives on tmpfs and disappears with the unit).
mkdir -p /run/sshd
check "sshd: password auth off" bash -c 'sshd -T 2>/dev/null | grep -q "^passwordauthentication no"'
# sshd -T normalizes prohibit-password to the legacy spelling without-password.
check "sshd: root is key-only" bash -c 'sshd -T 2>/dev/null | grep -qE "^permitrootlogin (prohibit|without)-password$"'
check "ufw active" bash -c 'ufw status 2>/dev/null | grep -q "^Status: active"'
check "fail2ban running" systemctl is-active --quiet fail2ban

echo
if [ "$fails" -eq 0 ]; then
  echo "all checks passed"
else
  echo "$fails check(s) failed"
  exit 1
fi
