#!/bin/bash
# Start Backend A (Mac 3) or Backend B (Mac 1).
#   ./start-backend.sh A
#   ./start-backend.sh B
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"

ID="${1:-A}"
ID="$(printf '%s' "${ID}" | tr '[:lower:]' '[:upper:]')"

case "${ID}" in
  A) PORT="${BACKEND_A_PORT}" ;;
  B) PORT="${BACKEND_B_PORT}" ;;
  *)
    echo "Usage: $0 A|B" >&2
    exit 1
    ;;
esac

echo "Backend ${ID} on 0.0.0.0:${PORT}"
exec python3 "${SERVER_PY}" --id "${ID}" --port "${PORT}"
