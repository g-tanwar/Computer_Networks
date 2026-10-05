#!/bin/bash
# Show Cache-Control, ETag, then 304 Not Modified for the same ETag.
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"

URL="https://${APP_HOST}/api/cached"
echo "==== first response ===="
curl -sS -D - -o /dev/null "${URL}" | grep -iE '^(HTTP/|cache-control:|etag:)'
ETAG="$(curl -sS -D - -o /dev/null "${URL}" | awk 'BEGIN{IGNORECASE=1} /^ETag:/{sub(/\r/,""); print $2}')"
echo "==== If-None-Match: ${ETAG} ===="
curl -sS -D - -o /dev/null -H "If-None-Match: ${ETAG}" "${URL}" | grep -iE '^(HTTP/|cache-control:|etag:)'
