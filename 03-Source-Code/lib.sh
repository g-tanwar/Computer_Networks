#!/bin/bash
# Shared paths and addresses for the Team 1 scripts.
set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${LIB_DIR}/team.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

REPO_DNS_CONF="${LIB_DIR}/../02-Configuration-Bundle/dns/dnsmasq.conf"
REPO_NGINX_CONF="${LIB_DIR}/../02-Configuration-Bundle/edge/nginx-servers-team1.conf"
CA_PUBLIC="${LIB_DIR}/edge/ca-public"
SERVER_PY="${LIB_DIR}/backend/server.py"

refuse_repo_edit() {
  local target="$1"
  local root
  root="$(cd "${LIB_DIR}/.." && pwd)"
  case "${target}" in
    "${root}"/*)
      echo "Refusing to edit a file inside the repository: ${target}" >&2
      exit 1
      ;;
  esac
}
