#!/bin/bash
# Trust Team1 Local CA in the System keychain on this Mac.
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"

CRT="${1:-${CA_PUBLIC}/team1-root-ca.crt}"
if [[ ! -f "${CRT}" ]]; then
  echo "CA certificate not found: ${CRT}" >&2
  exit 1
fi

sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  "${CRT}"

security find-certificate -c "${CA_CN}" /Library/Keychains/System.keychain
