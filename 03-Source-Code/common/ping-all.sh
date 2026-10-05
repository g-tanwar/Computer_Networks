#!/bin/bash
# Ping the three lab addresses from this Mac.
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"

for host in "${DNS_IP}" "${EDGE_IP}" "${BACKEND_A_IP}"; do
  echo "==== ping ${host} ===="
  ping -c 3 "${host}" || true
done
