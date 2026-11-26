#!/bin/bash
# Shared helpers for the four per-person scripts in this folder.
# Each script sources this file, so every command uses the IPs in ../team.env.
# Written for the bash 3.2 that ships with macOS.

TEAM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${TEAM_DIR}/../lib.sh"
set +e  # helpers report failures themselves; one failed check must not stop a demo

REPO_ROOT="$(cd "${TEAM_DIR}/../.." && pwd)"
DNS_CONF="$(brew --prefix 2>/dev/null || echo /opt/homebrew)/etc/dnsmasq.conf"
NGINX_SITE="$(brew --prefix 2>/dev/null || echo /opt/homebrew)/etc/nginx/servers/team1.conf"
NGINX_ERROR_LOG="$(brew --prefix 2>/dev/null || echo /opt/homebrew)/var/log/nginx/error.log"
PF_RULES="${HOME}/team1-pf.conf"

# ---------- output ----------
step()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()    { printf '\033[1;32m OK\033[0m %s\n' "$*"; }
bad()   { printf '\033[1;31m !!\033[0m %s\n' "$*"; }
note()  { printf '    %s\n' "$*"; }
show()  { printf '\033[2m$ %s\033[0m\n' "$*"; }   # print a command before running it
run()   { show "$*"; eval "$@"; }

# Every run is also written to 04-Evidence/_runs/<date>/<who>-<command>.txt
# so the terminal output can be used as evidence later.
start_log() {
  local who="$1" cmd="$2" dir
  dir="${REPO_ROOT}/04-Evidence/_runs/$(date +%Y-%m-%d)"
  mkdir -p "${dir}" 2>/dev/null || return 0
  LOG_FILE="${dir}/${who}-${cmd}-$(date +%H%M%S).txt"
  echo "Saving this run to ${LOG_FILE#"${REPO_ROOT}"/}"
}

# ---------- everyone ----------
my_info() {
  step "This Mac"
  local ip mac mask
  ip="$(ipconfig getifaddr "${IFACE}")"
  mac="$(ifconfig "${IFACE}" | awk '/ether/{print $2}')"
  mask="$(ipconfig getoption "${IFACE}" subnet_mask 2>/dev/null)"
  echo "IP address : ${ip:-none}"
  echo "Subnet mask: ${mask:-?}"
  echo "MAC address: ${mac:-?}"
  echo "Gateway    : $(route -n get default 2>/dev/null | awk '/gateway/{print $2}')"
  echo "Interface  : ${IFACE}"
  echo "DNS servers: $(networksetup -getdnsservers Wi-Fi 2>/dev/null | tr '\n' ' ')"
  if [[ -n "${ip}" ]] && ! grep -q "=${ip}" "${TEAM_DIR}/../team.env"; then
    bad "This IP is not in 03-Source-Code/team.env. Update the *_IP line for this Mac, then tell the team."
  fi
}

ping_all() {
  step "Ping every Mac"
  local ip name
  for pair in "${MAC1_IP}:Mac1-Piyush" "${MAC2_IP}:Mac2-Gourav" "${MAC3_IP}:Mac3-Alok" "${MAC4_IP}:Mac4-Ashar"; do
    ip="${pair%%:*}"; name="${pair#*:}"
    if ping -c 2 -t 3 "${ip}" >/dev/null 2>&1; then ok "${name} ${ip} replies"; else bad "${name} ${ip} does not reply"; fi
  done
  note "No reply? Check that Mac's IP (it may have changed) and turn off stealth mode in its firewall."
}

trust_ca() {
  local file="${1:-}"
  if [[ -z "${file}" ]]; then
    file="$(ls -t "${HOME}"/Downloads/teamCA*.crt 2>/dev/null | head -1)"
    [[ -f "${CERT_DIR}/teamCA.crt" ]] && file="${CERT_DIR}/teamCA.crt"
  fi
  if [[ ! -f "${file}" ]]; then
    bad "No CA file found. Get teamCA.crt from Gourav (AirDrop) and run: $0 trust-ca /path/to/teamCA.crt"
    return 1
  fi
  step "Trust ${file}"
  run "openssl x509 -in '${file}' -noout -subject -startdate -fingerprint -sha256"
  note "This fingerprint must match Gourav's (./gourav-mac2.sh certs). If not, it is an old file: stop and get the new one."
  note "Removing any older '${CA_CN}' certificates first (two with the same name confuse curl)."
  while sudo security delete-certificate -c "${CA_CN}" /Library/Keychains/System.keychain >/dev/null 2>&1; do :; done
  run "sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain '${file}'" && ok "CA trusted"
}

flush_dns() { sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; }

use_dns() {
  case "${1:-team}" in
    team)   set -- "${DNS_IP}" ;;
    both)   set -- "${DNS_IP}" "${BACKUP_DNS_IP}" ;;
    google) set -- 8.8.8.8 ;;
    auto)   set -- empty ;;
    *)      ;;
  esac
  step "Set Wi-Fi DNS to: $*"
  run "sudo networksetup -setdnsservers Wi-Fi $*"
  flush_dns
  run "networksetup -getdnsservers Wi-Fi"
}

# ---------- DNS server (Mac 1 primary, Mac 4 backup) ----------
live_dns_value() {  # live_dns_value app|ttl
  if [[ "$1" == app ]]; then
    sed -n "s|^address=/${APP_HOST}/||p" "${DNS_CONF}" 2>/dev/null | head -1
  else
    sed -n 's/^local-ttl=//p' "${DNS_CONF}" 2>/dev/null | head -1
  fi
}

dns_write() {  # dns_write <app ip> <ttl>
  local app_ip="${1:-${EDGE_IP}}" ttl="${2:-${DNS_TTL}}"
  step "Write ${DNS_CONF}: ${APP_HOST} -> ${app_ip}, ${API_HOST} -> ${EDGE_IP}, TTL ${ttl}"
  sudo tee "${DNS_CONF}" >/dev/null <<EOF
# Team 1 private DNS. Written by 03-Source-Code/team scripts on $(date '+%d %b %Y %H:%M').
domain-needed
bogus-priv

no-resolv
server=8.8.8.8
server=1.1.1.1

listen-address=0.0.0.0
interface=${IFACE}

address=/${APP_HOST}/${app_ip}
address=/${API_HOST}/${EDGE_IP}

local-ttl=${ttl}

log-queries
log-facility=/tmp/dnsmasq.log
EOF
  grep -E '^(address|local-ttl)' "${DNS_CONF}"
}

dns_restart() {
  step "Restart dnsmasq"
  sudo brew services stop dnsmasq >/dev/null 2>&1
  sudo pkill dnsmasq 2>/dev/null; sleep 1
  run "sudo dnsmasq -C '${DNS_CONF}'" && ok "dnsmasq running"
}

dns_stop() { step "Stop dnsmasq"; run "sudo pkill dnsmasq"; ok "DNS server on this Mac is now OFF"; }

dns_test() {
  local server="${1:-127.0.0.1}"
  step "Ask ${server} for ${APP_HOST}"
  run "dig @${server} ${APP_HOST} +noall +answer +stats | grep -E 'IN[[:space:]]+A|SERVER|Query time'"
}

set_record() {  # set_record edge|standby|wrong|<ip>
  local target
  case "${1:-edge}" in
    edge)    target="${EDGE_IP}" ;;
    standby) target="${STANDBY_EDGE_IP}" ;;
    wrong)   target="${WRONG_IP}" ;;
    *)       target="$1" ;;
  esac
  dns_write "${target}" "$(live_dns_value ttl || true)"
  dns_restart
  dns_test 127.0.0.1
  note "Do the same on the other DNS Mac so both servers give the same answer."
}

set_ttl() {
  local ttl="${1:-30}" app
  app="$(live_dns_value app)"
  dns_write "${app:-${EDGE_IP}}" "${ttl}"
  dns_restart
  dns_test 127.0.0.1
}

# ---------- backend ----------
start_backend() {
  step "Start Backend $1 (leave this window open, Ctrl+C stops it)"
  local port="${BACKEND_A_PORT}"; [[ "$1" == B ]] && port="${BACKEND_B_PORT}"
  if lsof -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1; then
    note "Port ${port} is already in use (an old backend). Stopping it."
    kill "$(lsof -t -iTCP:"${port}" -sTCP:LISTEN)" 2>/dev/null; sleep 1
  fi
  exec python3 "${SERVER_PY}" --id "$1" --port "${port}"
}

# ---------- edge nginx (Mac 2 primary, Mac 4 standby) ----------
nginx_write() {  # nginx_write mac2|mac4
  local edge_name="$1"
  step "Write ${NGINX_SITE} (X-Edge: ${edge_name})"
  mkdir -p "$(dirname "${NGINX_SITE}")"
  cat > "${NGINX_SITE}" <<EOF
# Team 1 edge. Written by 03-Source-Code/team scripts on $(date '+%d %b %Y %H:%M').
upstream backends {
    server ${BACKEND_A_IP}:${BACKEND_A_PORT} max_fails=1 fail_timeout=10s;   # Backend A - Mac 3 Alok
    server ${BACKEND_B_IP}:${BACKEND_B_PORT} max_fails=1 fail_timeout=10s;   # Backend B - Mac 1 Piyush
}

server {
    listen ${HTTPS_PORT} ssl;
    http2 on;
    server_name ${APP_HOST} ${API_HOST};

    ssl_certificate     ${CERT_DIR}/app.crt;
    ssl_certificate_key ${CERT_DIR}/app.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        proxy_pass http://backends;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_connect_timeout 2s;
        proxy_next_upstream error timeout http_502;
        add_header X-Edge ${edge_name} always;
    }
}
EOF
  grep -E 'server [0-9]|ssl_certificate|X-Edge' "${NGINX_SITE}"
}

nginx_restart() {
  step "Restart nginx (full stop, then start, so new certificates are loaded)"
  if [[ ! -f "${CERT_DIR}/app.crt" || ! -f "${CERT_DIR}/app.key" ]]; then
    bad "${CERT_DIR}/app.crt or app.key is missing. Nothing to serve."
    return 1
  fi
  brew services stop nginx >/dev/null 2>&1
  pkill nginx 2>/dev/null; sudo pkill nginx 2>/dev/null; sleep 2
  run "nginx -t" && run "brew services start nginx" && ok "nginx running"
}

check_backends() {
  step "Backends directly (bypassing nginx)"
  run "curl -s -m 3 http://${BACKEND_A_IP}:${BACKEND_A_PORT}/api/status; echo"
  run "curl -s -m 3 http://${BACKEND_B_IP}:${BACKEND_B_PORT}/api/status; echo"
}

test_edge() {  # test_edge <ip>
  step "HTTPS to the edge at $1 (DNS not used)"
  run "curl -s -D - -o /dev/null --resolve ${APP_HOST}:${HTTPS_PORT}:$1 https://${APP_HOST}/api/status | grep -iE 'HTTP/|x-edge|x-backend'"
}

# ---------- firewall (Mac 1 port 3002, Mac 3 port 3001) ----------
firewall_on() {
  local port="$1"
  step "Firewall: only the edges (${EDGE_IP}, ${STANDBY_EDGE_IP}) may reach port ${port}"
  sudo pfctl -sr > "${HOME}/pf-before.txt" 2>&1
  printf 'pass in quick proto tcp from %s to any port %s\npass in quick proto tcp from %s to any port %s\nblock drop in quick proto tcp from any to any port %s\n' \
    "${EDGE_IP}" "${port}" "${STANDBY_EDGE_IP}" "${port}" "${port}" > "${PF_RULES}"
  cat "${PF_RULES}"
  sudo pfctl -f "${PF_RULES}" -e 2>&1 | grep -v -i 'ALTQ' ; ok "Rules loaded. Rollback copy of the old rules: ~/pf-before.txt"
  note "Undo after the demo: $0 firewall-off"
}

firewall_off() {
  step "Firewall: restore the normal macOS rules"
  sudo pfctl -f /etc/pf.conf 2>&1 | grep -v -i 'ALTQ'
  sudo pfctl -d 2>&1; ok "Backend port open again"
}
