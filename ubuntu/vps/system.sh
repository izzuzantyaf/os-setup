#!/usr/bin/env bash
# Root-only system layer for the Ubuntu VPS: the parts home-manager cannot
# manage (apt, /etc/ssh, ufw, fail2ban, timezone, optional Tailscale).
# Idempotent: safe to re-run. bootstrap.sh calls it; run it by hand after edits.
#
# WARNING: this closes every port except SSH and switches sshd to key-only.
# Run it from the Hetzner console (or over IPv6) the first time, with your SSH
# key already in the login user's authorized_keys. Hetzner rescue mode is the
# way back in if you lock yourself out.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "system.sh must run as root" >&2
  exit 1
fi

SSH_PORT="${SSH_PORT:-22}"

echo "==> apt: base packages and security upgrades"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get -y -qq full-upgrade
# openssh-server is listed so a box that somehow lacks sshd still has one to
# harden below (Hetzner images ship it already).
apt-get -y -qq install openssh-server unattended-upgrades ufw fail2ban ca-certificates curl
# Written directly instead of dpkg-reconfigure so this stays non-interactive.
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'CONF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONF
systemctl enable --now unattended-upgrades

echo "==> sshd: key-only, no password login"
# 00- prefix, not 99-: sshd uses the FIRST value it obtains, and the main
# sshd_config includes this directory at the top, so a drop-in that cloud
# images ship (50-cloud-init.conf sets PasswordAuthentication yes on some
# providers) would otherwise win. /etc/ssh/sshd_config.d/*.conf is read in
# alphabetical order, so 00- is the one that sticks.
rm -f /etc/ssh/sshd_config.d/99-os-setup.conf
cat > /etc/ssh/sshd_config.d/00-os-setup.conf <<CONF
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
CONF
# Validate before reloading: a broken config plus a reload means no way back in.
# sshd -t wants the privilege separation dir, which only exists once ssh has
# started (Debian creates it from the unit's RuntimeDirectory).
mkdir -p /run/sshd
sshd -t
# reload-or-restart: on a fresh box sshd may not be running yet.
systemctl reload-or-restart ssh

echo "==> ufw: deny everything except ssh"
ufw --force default deny incoming
ufw --force default allow outgoing
ufw allow "$SSH_PORT"/tcp
# Docker-published ports reach FORWARD via DNAT and skip INPUT, but host nginx
# serves 80/443 for the vhosts, so they must be allowed here too.
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "==> docker: hanya port mail yang publik, sisanya tailnet"
# Docker publishes ports through its own DNAT rules, so the traffic is forwarded
# to the container via FORWARD and ufw's INPUT rules never see it -- a published
# port stays internet-reachable even though ufw denies everything. DOCKER-USER is
# the only hook that runs before Docker's accept rules.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install -m755 "$SCRIPT_DIR/docker-tailnet-only.sh" /usr/local/sbin/docker-tailnet-only.sh
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/tailnet-only.conf <<'CONF'
[Service]
# Docker rebuilds its iptables chains on every start, so re-apply ours right
# after. The "-" keeps a failure here from marking docker.service failed.
ExecStartPost=-/usr/local/sbin/docker-tailnet-only.sh
CONF
systemctl daemon-reload
# Apply now without restarting docker: a restart would bounce every container,
# including the mail server, for a rule set that does not need it.
if systemctl is-active --quiet docker; then
  /usr/local/sbin/docker-tailnet-only.sh
else
  echo "    docker belum jalan, rule dipasang saat dockerd start"
fi

echo "==> fail2ban: ban ssh brute force"
systemctl enable --now fail2ban

echo "==> clock: UTC"
timedatectl set-timezone UTC

echo "==> hermes-agent"
# No nixpkgs package, and its 28 core Python deps are exactly pinned, so use the
# vendor installer: uv + venv under /usr/local/lib/hermes-agent, command at
# /usr/local/bin/hermes, data in /root/.hermes (FHS layout when run as root).
# --skip-setup skips the interactive onboarding.
if command -v hermes >/dev/null 2>&1; then
  echo "    already installed, skipping"
else
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup
fi

# Everything else stays private. Tailscale is the way to reach services on this
# box without opening ports. The reusable auth key is read from a root-only env
# file (never in git):
#   echo 'TAILSCALE_AUTHKEY=tskey-auth-...' | sudo install -m600 /dev/stdin /etc/os-setup.tailscale.env
# A key in the environment still wins, for one-off runs.
if [ -z "${TAILSCALE_AUTHKEY:-}" ] && [ -f /etc/os-setup.tailscale.env ]; then
  . /etc/os-setup.tailscale.env
fi
# An already-connected node is left alone, so this block is safe to re-run.
# grep reads a here-string instead of a pipe on purpose: -q exits at the first
# match, and pipefail would then turn tailscale's SIGPIPE into a failure.
#
# The name is pinned on the client, not just in the admin console: a console
# rename does not survive a fresh re-auth (a re-register re-advertises the OS
# hostname, which here is still the provider's "vmi2359060").
TAILSCALE_HOSTNAME="${TAILSCALE_HOSTNAME:-zuserver}"
if [ -z "${TAILSCALE_AUTHKEY:-}" ]; then
  echo "==> tailscale skipped (no TAILSCALE_AUTHKEY env or /etc/os-setup.tailscale.env)"
elif grep -q '"BackendState": *"Running"' <<<"$(tailscale status --json 2>/dev/null)"; then
  # Keep the advertised name in sync even on an already-running node, so a
  # console rename or an OS hostname change cannot silently take over.
  tailscale set --hostname "$TAILSCALE_HOSTNAME" >/dev/null
  echo "==> tailscale already connected (hostname: $TAILSCALE_HOSTNAME)"
else
  echo "==> tailscale"
  command -v tailscale >/dev/null || curl -fsSL https://tailscale.com/install.sh | sh
  tailscale up --authkey "$TAILSCALE_AUTHKEY" --ssh --hostname="$TAILSCALE_HOSTNAME"
fi
