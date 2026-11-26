#!/bin/bash
# Ashar Shaikh - Mac 4 (joined in Phase 2) - backup DNS server + standby edge nginx + second client.
# Usage: ./ashar-mac4.sh <command>     (run with no command to see the list)
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

usage() {
  cat <<EOF
Ashar - Mac 4 (${MAC4_IP}) - backup DNS + standby edge + client

Every lab day
  info              Show this Mac's IP, MAC address, gateway, DNS
  ping              Ping all four Macs
  trust-ca [file]   Trust Gourav's teamCA.crt (removes older copies first)
  use-dns both      Use Mac 1, then Mac 4, for DNS   (also: team | google | auto)
  https             Open the site from this Mac (second client)

Extension A - backup DNS
  dns-setup         Write dnsmasq.conf (same records as Mac 1) and start DNS
  dns-test          Ask this DNS server for ${APP_HOST}
  dns-start / dns-stop

Extension E - standby edge
  receive-certs     Get ready for Gourav's send-certs (folder + checks)
  nginx-setup       Write the nginx site (X-Edge: mac4) and restart nginx
  nginx-restart     Full stop + start
  test              HTTPS test against this standby edge

Extension B + E - DNS switch (run on Mac 1 too)
  ttl 30            Set the TTL to 30 seconds
  record standby    Point ${APP_HOST} at this Mac (${MAC4_IP})
  record edge       Point it back at Mac 2 (${EDGE_IP})

After the project
  cleanup           Delete the copied private key app.key from this Mac
EOF
}

cmd="${1:-help}"; shift 2>/dev/null
case "${cmd}" in help|-h|--help) usage; exit 0 ;; esac

start_log ashar "${cmd}"
{
case "${cmd}" in
  info)          my_info ;;
  ping)          ping_all ;;
  trust-ca)      trust_ca "${1:-}" ;;
  use-dns)       use_dns "${1:-both}" ;;
  https)         run "curl -s -D - -o /dev/null https://${APP_HOST}/api/status | grep -iE 'HTTP/|x-edge|x-backend'" ;;
  dns-setup)     dns_write "${EDGE_IP}" "${DNS_TTL}"; dns_restart; dns_test 127.0.0.1
                 note "Others test with: dig @${MAC4_IP} ${APP_HOST} +short" ;;
  dns-start)     dns_restart; dns_test 127.0.0.1 ;;
  dns-stop)      dns_stop ;;
  dns-test)      dns_test 127.0.0.1 ;;
  receive-certs) step "Prepare to receive app.crt + app.key from Gourav"
                 mkdir -p "${CERT_DIR}"; echo "Login name for Gourav's command: $(whoami)"
                 note "Turn ON: System Settings > General > Sharing > Remote Login"
                 note "Gourav runs: ./gourav-mac2.sh send-certs $(whoami)   (you type YOUR password there)"
                 note "Then run: ./ashar-mac4.sh nginx-setup   and turn Remote Login OFF again." ;;
  nginx-setup)   [[ -f "${CERT_DIR}/app.key" ]] && chmod 600 "${CERT_DIR}/app.key"
                 nginx_write mac4; nginx_restart; test_edge 127.0.0.1 ;;
  nginx-restart) nginx_restart; test_edge 127.0.0.1 ;;
  test)          test_edge 127.0.0.1 ;;
  ttl)           set_ttl "${1:-30}" ;;
  record)        set_record "${1:-edge}" ;;
  cleanup)       step "Remove the private key copy"; run "rm -P '${CERT_DIR}/app.key'"; brew services stop nginx ;;
  *)             bad "Unknown command: ${cmd}"; usage ;;
esac
} 2>&1 | tee "${LOG_FILE:-/dev/null}"
