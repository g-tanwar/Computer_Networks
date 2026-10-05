#!/bin/bash
# Print the capture command used on Mac 3 (en0).
# Add --run to start tcpdump. The file is written under /tmp, not into git.
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"

OUT="${TMPDIR:-/tmp}/phase1_full_flow.pcapng"
CMD=(tcpdump -i "${IFACE}" -w "${OUT}" "host ${DNS_IP} or host ${EDGE_IP}")

echo "Capture on ${IFACE}. Stop with Ctrl-C, then copy the file to:"
echo "  04-Evidence/G-Packet-Capture/phase1_full_flow.pcapng"
echo
printf 'Command:'
printf ' %q' "${CMD[@]}"
echo

if [[ "${1:-}" == "--run" ]]; then
  echo "Writing ${OUT}"
  sudo "${CMD[@]}"
fi
