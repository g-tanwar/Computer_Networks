#!/bin/bash
# Install the Team 1 nginx site on Mac 2 and test the configuration.
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"

DEST="${1:-$(brew --prefix)/etc/nginx/servers/team1.conf}"
refuse_repo_edit "${DEST}"

sudo mkdir -p "$(dirname "${DEST}")"
sudo cp "${REPO_NGINX_CONF}" "${DEST}"
nginx -t
echo "Installed ${DEST}"
echo "Start with: brew services start nginx"
echo "Certificate files expected by that config:"
echo "  ${CERT_DIR}/app.crt"
echo "  ${CERT_DIR}/app.key"
