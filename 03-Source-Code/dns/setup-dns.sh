#!/bin/bash
# Install the repository dnsmasq.conf onto the DNS Mac.
#   ./setup-dns.sh /opt/homebrew/etc/dnsmasq.conf
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"

DEST="${1:-/opt/homebrew/etc/dnsmasq.conf}"
refuse_repo_edit "${DEST}"

if [[ ! -f "${REPO_DNS_CONF}" ]]; then
  echo "Missing ${REPO_DNS_CONF}" >&2
  exit 1
fi

echo "Installing ${REPO_DNS_CONF}"
echo "       to ${DEST}"
sudo mkdir -p "$(dirname "${DEST}")"
sudo cp "${REPO_DNS_CONF}" "${DEST}"
echo
echo "Start dnsmasq on Mac 1 (${DNS_IP}):"
echo "  sudo dnsmasq -C ${DEST}"
echo
echo "Records:"
echo "  ${APP_HOST} -> ${EDGE_IP}"
echo "  ${API_HOST} -> ${EDGE_IP}"
echo "  TTL 60"
