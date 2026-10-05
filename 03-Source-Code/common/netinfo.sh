#!/bin/bash
# Print the Wi-Fi address, mask, gateway, and MAC for this Mac.
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"

echo "interface ${IFACE}"
ifconfig "${IFACE}" | grep -E "inet |ether" || true
echo
networksetup -getinfo Wi-Fi || true
echo
route -n get default | grep -E "gateway|interface" || true
