#!/usr/bin/env bash
# Keep Docker's published ports off the public interface.
#
# Why this exists: Docker publishes ports with its own DNAT rules, so inbound
# traffic is forwarded to the container through FORWARD. ufw only filters INPUT,
# so it never sees it -- a published port is internet-reachable even while
# `ufw status` claims everything is denied. DOCKER-USER is the only hook that
# runs before Docker's own accept rules.
#
# Mail stays public; everything else on the public interface is dropped, which
# leaves the tailnet as the only way in (tailnet traffic arrives on tailscale0,
# a different in-interface, so it never matches these rules).
#
# Installed as /usr/local/sbin/docker-tailnet-only.sh by ubuntu/vps/system.sh,
# and re-run by /etc/systemd/system/docker.service.d/tailnet-only.conf after
# every dockerd start -- Docker rebuilds its chains on start, and these rules
# live in one of them.
set -euo pipefail

WHITELIST="${MAIL_PORTS:-25,110,143,465,587,993,995,4190}"
PUBLIC_IF="${PUBLIC_IF:-eth0}"

for cmd in iptables ip6tables; do
  # Fail loudly if dockerd has not created the chain yet: a silently skipped
  # security rule is worse than a noisy one.
  if ! $cmd -nL DOCKER-USER >/dev/null 2>&1; then
    echo "docker-tailnet-only: $cmd has no DOCKER-USER chain (dockerd not started yet?)" >&2
    exit 1
  fi
  # DOCKER-USER is ours alone -- Docker creates it empty and never writes to it --
  # so flushing first is safe, and it keeps RETURN above DROP on every re-run.
  $cmd -F DOCKER-USER
  $cmd -A DOCKER-USER -i "$PUBLIC_IF" -m comment --comment "os-setup: mail tetap publik" \
       -p tcp -m multiport --dports "$WHITELIST" -j RETURN
  $cmd -A DOCKER-USER -i "$PUBLIC_IF" -m comment --comment "os-setup: sisanya tailnet-only" \
       -j DROP
done

echo "docker-tailnet-only: $PUBLIC_IF -> hanya tcp/$WHITELIST publik, sisanya tailnet-only"
