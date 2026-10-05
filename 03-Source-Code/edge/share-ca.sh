#!/bin/bash
# Copy the public CA certificate to a path you can move to the other Macs.
#   ./share-ca.sh ~/Desktop/team1-root-ca.crt
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"

SRC="${CA_PUBLIC}/team1-root-ca.crt"
DEST="${1:-${HOME}/Desktop/team1-root-ca.crt}"
cp "${SRC}" "${DEST}"
echo "Copied public CA to ${DEST}"
echo "On each other Mac, run common/trust-ca.sh with that file."
echo "Do not copy teamCA.key or app.key."
