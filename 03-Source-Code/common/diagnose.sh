#!/bin/bash
# Read-only checks: DNS, edge port 443, and both backends.
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"

echo "==== dig @${DNS_IP} ${APP_HOST} ===="
dig @"${DNS_IP}" "${APP_HOST}" +time=2 +tries=1 || true
echo
echo "==== edge ${EDGE_IP}:${HTTPS_PORT} ===="
nc -z -G 2 "${EDGE_IP}" "${HTTPS_PORT}" && echo "open" || echo "closed"
echo "==== backend A ${BACKEND_A_IP}:${BACKEND_A_PORT} ===="
curl -sS -m 3 -D - -o /dev/null "http://${BACKEND_A_IP}:${BACKEND_A_PORT}/api/status" | grep -iE '^(HTTP/|X-Backend:)' || true
echo "==== backend B ${BACKEND_B_IP}:${BACKEND_B_PORT} ===="
curl -sS -m 3 -D - -o /dev/null "http://${BACKEND_B_IP}:${BACKEND_B_PORT}/api/status" | grep -iE '^(HTTP/|X-Backend:)' || true
