#!/bin/bash
# Piyush - Mac 1 - primary DNS server (dnsmasq) + Backend B (port 3002).
# Usage: ./piyush-mac1.sh <command>     (run with no command to see the list)
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

usage() {
  cat <<EOF
Piyush - Mac 1 (${MAC1_IP}) - DNS server + Backend B

Every lab day
  info            Show this Mac's IP, MAC address, gateway, DNS
  ping            Ping all four Macs
  dns-setup       Write dnsmasq.conf (${APP_HOST} -> ${EDGE_IP}) and start DNS
  dns-test        Ask this DNS server for ${APP_HOST}
  backend         Start Backend B on port ${BACKEND_B_PORT} (keep the window open)
  local-resolver  Let this Mac itself open https://${APP_HOST}
  trust-ca [file] Trust Gourav's teamCA.crt (removes older copies first)

Phase 1 failure test
  record wrong    Point ${APP_HOST} at the unused ${WRONG_IP}  (test 1F.2)
  record edge     Point it back at Mac 2 ${EDGE_IP}

Phase 2
  dns-stop        Extension A demo: switch this DNS server off
  dns-start       Switch it on again
  ttl 30          Extension B: set the TTL to 30 seconds
  record standby  Extension B+E: point ${APP_HOST} at Mac 4 ${STANDBY_EDGE_IP}
  record edge     ...and back to Mac 2
  firewall-on     Extension C: only the edges may reach port ${BACKEND_B_PORT}
  firewall-off    Extension C: undo
EOF
}

cmd="${1:-help}"; shift 2>/dev/null
case "${cmd}" in
  help|-h|--help) usage; exit 0 ;;
  backend) start_backend B ;;
esac

start_log piyush "${cmd}"
{
case "${cmd}" in
  info)           my_info ;;
  ping)           ping_all ;;
  trust-ca)       trust_ca "${1:-}" ;;
  dns-setup)      dns_write "${EDGE_IP}" "${DNS_TTL}"; dns_restart; dns_test 127.0.0.1
                  note "Others test with: dig @${MAC1_IP} ${APP_HOST} +short" ;;
  dns-start)      dns_restart; dns_test 127.0.0.1 ;;
  dns-stop)       dns_stop; note "Alok now runs: ./alok-mac3.sh dns-check   (answer should come from ${BACKUP_DNS_IP})"
                  note "Afterwards: ./piyush-mac1.sh dns-start" ;;
  dns-test)       dns_test 127.0.0.1 ;;
  record)         set_record "${1:-edge}" ;;
  ttl)            set_ttl "${1:-30}" ;;
  local-resolver) step "Send *.${DOMAIN} lookups on this Mac to its own DNS server"
                  run "sudo mkdir -p /etc/resolver && echo 'nameserver 127.0.0.1' | sudo tee /etc/resolver/${DOMAIN}"
                  flush_dns; run "curl -s https://${APP_HOST}/api/status; echo" ;;
  firewall-on)    firewall_on "${BACKEND_B_PORT}"
                  note "Test: Gourav ./gourav-mac2.sh backends (works), Alok ./alok-mac3.sh isolation-test (times out)" ;;
  firewall-off)   firewall_off ;;
  *)              bad "Unknown command: ${cmd}"; usage ;;
esac
} 2>&1 | tee "${LOG_FILE:-/dev/null}"
