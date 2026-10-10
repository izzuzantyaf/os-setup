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

# The deployed files are home-manager artefacts (nix-store copies, or mkOutOfStoreSymlink
# links back into the repo). Comparing content is the assertion that actually matters:
# the old `readlink -f | grep ~/.os-setup/` could never pass, because readlink resolves the
# repo's own ~/.os-setup symlink away to ~/os-setup before the grep ever sees it.
check "nvim config matches the repo" diff -rq ~/.config/nvim "$HOME/.os-setup/home/.config/nvim"
check "pi settings match the repo" cmp -s ~/.pi/agent/settings.json "$HOME/.os-setup/home/.pi/agent/settings.json"
check "pi extensions match the repo" diff -rq ~/.pi/agent/extensions/guard "$HOME/.os-setup/home/.pi/agent/extensions/guard"
check "AGENTS.md shim for codex matches repo" cmp -s ~/.codex/AGENTS.md "$HOME/.os-setup/home/AGENTS.md"
check "AGENTS.md shim for gemini matches repo" cmp -s ~/.gemini/GEMINI.md "$HOME/.os-setup/home/AGENTS.md"
check "typesafe skill matches the repo" diff -rq ~/.agents/skills/typesafe "$HOME/.os-setup/home/.agents/skills/typesafe"
check "starship config generated" test -f ~/.config/starship.toml
# zsh is a Nix user-profile binary, so root's PATH (sudo's secure_path) cannot see it:
# "command not found". Run it as the login user, which is where it actually has to work.
LOGIN_USER="$(stat -c %U "$HOME" 2>/dev/null || echo root)"
check "zsh starts (as $LOGIN_USER)" runuser -l "$LOGIN_USER" -c 'zsh -lc true'
check "zu on PATH" bash -lc 'command -v zu'
check "herdr runs (prebuilt binary from pkgs/herdr.nix)" bash -lc 'herdr --version'
check "herdr config matches the repo" cmp -s ~/.config/herdr/config.toml "$HOME/.os-setup/home/.config/herdr/config.toml"
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
