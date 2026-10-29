#!/usr/bin/env bash
# Checks the multi-engine configuration from the outside (run after: docker compose up -d --wait).
set -uo pipefail

WEBCLIENT=http://localhost:8080/webapp/services/v1
ENGINE_A=http://localhost:8080/engine-rest
ENGINE_B=http://localhost:8081/engine-rest
# Engine ID of additional engines in the webclient: "<url>|<path>|<engineName>" (url/path from multi-engine.yml)
ENGINE_B_ID='http://engine-b:8080|/engine-rest|default'

fail() { echo "ERROR: $*" >&2; exit 1; }

echo "1) Engines known to the webclient (expected: Engine A and Engine B)"
engines=$(curl -fsS "$WEBCLIENT/engine") || fail "Webclient not reachable"
echo "   $engines"
echo "$engines" | grep -q 'engine-b:8080' \
  || fail "Engine B missing – is the URL in additionalEngineRest unreachable from the webclient server? (docker logs engine-a | grep 'Failed to fetch engines')"

echo "2) Log in to Engine B via the webclient (demo/demo)"
resp=$(curl -fsS -H 'Content-Type: application/json' -H "X-Process-Engine: $ENGINE_B_ID" \
  --data '{"username":"demo","password":"demo","type":"org.cibseven.webapp.auth.rest.StandardLogin"}' \
  "$WEBCLIENT/auth/login") || fail "Login to Engine B failed – does jwtSecret in multi-engine.yml match Engine B's secret?"
token=$(printf '%s' "$resp" | sed -n 's/.*"authToken":"\([^"]*\)".*/\1/p')
[ -n "$token" ] || fail "No authToken in the login response"
case "$token" in Bearer\ *) auth="$token" ;; *) auth="Bearer $token" ;; esac
echo "   ok, token received"

echo "3) Token directly against Engine B: start process 'engineBHello' (expected 200)"
code=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: $auth" -H 'Content-Type: application/json' \
  -d '{}' "$ENGINE_B/process-definition/key/engineBHello/start")
echo "   HTTP $code"
[ "$code" = "200" ] || fail "Engine B does not accept the token"

echo "4) Same token against Engine A (expected 401 – each engine has its own secret)"
code=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: $auth" "$ENGINE_A/process-definition")
echo "   HTTP $code"

echo
echo "Done. In the browser: http://localhost:8080/webapp (demo/demo), select 'Engine B' in the top menu."
