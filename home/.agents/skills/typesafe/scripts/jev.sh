#!/usr/bin/env bash
# TypeSafe System One (Jev) caller. Request JSON on stdin, response JSON on stdout, timing on stderr.
#   echo '{"state":"...","model":"jev-latest","questions":{...}}' | jev.sh
# Env: TYPESAFE_API_KEY (optional), TYPESAFE_URL (override endpoint), TYPESAFE_TIMEOUT (seconds, default 15)
set -euo pipefail

# Key lookup stays inside this script on purpose: a bare `security ... -w` prints the key to
# stdout, which pi records in the session transcript. Env wins if set, else the macOS keychain
# item 'typesafe-api'. Expect one prompt per requesting binary - never click "Always Allow".
key=${TYPESAFE_API_KEY:-$(security find-generic-password -s typesafe-api -a "${USER:-$(id -un)}" -w 2>/dev/null || true)}
[ -n "$key" ] || { echo "jev.sh: no key - export TYPESAFE_API_KEY or add the keychain item 'typesafe-api' (see SKILL.md)" >&2; exit 3; }

body=$(cat)
if [ -z "$body" ]; then
  echo "jev.sh: no request JSON on stdin" >&2
  exit 2
fi

# ponytail: exits non-zero on http error and never retries; add a retry only if the API proves flaky.
out=$(mktemp)
trap 'rm -f "$out"' EXIT

timing=$(curl -sS -o "$out" -w '%{http_code} %{time_total}' \
  --max-time "${TYPESAFE_TIMEOUT:-15}" \
  -H "authorization: Bearer $key" \
  -H 'content-type: application/json' \
  --data-binary "$body" \
  "${TYPESAFE_URL:-https://api.typesafe.ai/v1/systemone}")

cat "$out"
printf 'http %s in %ss\n' "${timing%% *}" "${timing##* }" >&2
[ "${timing%% *}" = "200" ] || exit 1
