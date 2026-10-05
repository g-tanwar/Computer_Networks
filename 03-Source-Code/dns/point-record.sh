#!/bin/bash
# Temporarily point app.team1.test at the wrong lab address, then restore it.
# This edits a live dnsmasq.conf you name. It will not edit the repository copy.
#
#   ./point-record.sh wrong   /opt/homebrew/etc/dnsmasq.conf
#   ./point-record.sh restore /opt/homebrew/etc/dnsmasq.conf
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"

MODE="${1:-}"
DEST="${2:-}"
WRONG_IP="10.7.31.250"

if [[ "${MODE}" != "wrong" && "${MODE}" != "restore" ]] || [[ -z "${DEST}" ]]; then
  echo "Usage: $0 wrong|restore /path/to/live/dnsmasq.conf" >&2
  exit 1
fi

refuse_repo_edit "${DEST}"

if [[ ! -f "${DEST}" ]]; then
  echo "No such file: ${DEST}" >&2
  exit 1
fi

if [[ "${MODE}" == "wrong" ]]; then
  sudo sed -i '' "s|^address=/${APP_HOST}/.*|address=/${APP_HOST}/${WRONG_IP}|" "${DEST}"
  echo "Live record is now ${APP_HOST} -> ${WRONG_IP}"
  echo "Restore with: $0 restore ${DEST}"
else
  sudo sed -i '' "s|^address=/${APP_HOST}/.*|address=/${APP_HOST}/${EDGE_IP}|" "${DEST}"
  echo "Live record restored: ${APP_HOST} -> ${EDGE_IP}"
fi

echo "Reload dnsmasq, then flush the client cache."
