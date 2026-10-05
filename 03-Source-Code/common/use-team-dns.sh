#!/bin/bash
# Point this Mac's Wi-Fi DNS at Mac 1, or at an address you pass.
#   ./use-team-dns.sh              # 10.7.17.154
#   ./use-team-dns.sh 8.8.8.8      # failure test: public resolver
#   ./use-team-dns.sh empty        # restore DHCP DNS
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"

TARGET="${1:-${DNS_IP}}"
echo "Setting Wi-Fi DNS to ${TARGET}"
sudo networksetup -setdnsservers Wi-Fi "${TARGET}"
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder || true
networksetup -getdnsservers Wi-Fi
