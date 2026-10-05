#!/bin/bash
# Eight HTTPS requests. The lab result was B A B A B A B A.
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"

for i in 1 2 3 4 5 6 7 8; do
  printf '%s ' "${i}"
  curl -sS -D - -o /dev/null "https://${APP_HOST}/api/status" | grep -i '^X-Backend:' || true
done
