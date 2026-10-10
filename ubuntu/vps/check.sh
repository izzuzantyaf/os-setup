#!/usr/bin/env bash
# Runnable self-check for the VPS setup. Needs root for the sshd/ufw/systemd
# checks, so run it with sudo:
#   sudo bash ubuntu/vps/check.sh
# Exits non-zero when something drifted from what the config claims.
set -uo pipefail

# Under sudo $HOME is /root, but the dotfile checks are about the login user.
if [ -n "${SUDO_USER:-}" ]; then
  HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  export HOME
fi

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
check "yazi on PATH (pdf preview needs pdftoppm too)" bash -lc 'command -v yazi pdftoppm'
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
check "tailscale connected to tailnet" bash -c 'grep -q "\"BackendState\": *\"Running\"" <<<"$(tailscale status --json 2>/dev/null)"'
# Catches the drift a console rename or a fresh re-auth would cause: the node
# must advertise the name we pinned on the client (see system.sh).
check "tailscale hostname = zuserver" bash -c 'grep -q "\"DNSName\": \"zuserver\." <<<"$(tailscale status --json 2>/dev/null)"'
check "docker: port non-mail ditutup dari publik (ipv4)" iptables -C DOCKER-USER -i eth0 -m comment --comment "os-setup: sisanya tailnet-only" -j DROP
check "docker: port non-mail ditutup dari publik (ipv6)" ip6tables -C DOCKER-USER -i eth0 -m comment --comment "os-setup: sisanya tailnet-only" -j DROP

echo
if [ "$fails" -eq 0 ]; then
  echo "all checks passed"
else
  echo "$fails check(s) failed"
  exit 1
fi
