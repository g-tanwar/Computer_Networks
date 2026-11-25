#!/bin/bash
# Gourav - Mac 2 - edge: nginx HTTPS termination, HTTP/2, round-robin load balancer, certificates.
# Usage: ./gourav-mac2.sh <command>     (run with no command to see the list)
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

usage() {
  cat <<EOF
Gourav - Mac 2 (${MAC2_IP}) - edge nginx + certificates

Every lab day
  info              Show this Mac's IP, MAC address, gateway, DNS
  ping              Ping all four Macs
  backends          Check Backend A and B directly
  nginx-setup       Write the nginx site with today's backend IPs and restart nginx
  nginx-restart     Full stop + start (use after any certificate change)
  test              HTTPS test against this edge
  errors            Last 20 lines of the nginx error log

Certificates (keys never leave ~/cn-certs except to Mac 4 with send-certs)
  certs             Show the certificate, its CA and fingerprint, and verify them
  share-ca          Serve ONLY teamCA.crt on port 8000 so others can download it
  send-certs [user] Copy app.crt + app.key to Mac 4 (Ashar turns Remote Login on first)
  trust-ca          Trust ~/cn-certs/teamCA.crt on this Mac

Phase 2
  failover-notes    What to say for Extension D (how failover works, single point of failure)
EOF
}

cmd="${1:-help}"; shift 2>/dev/null
case "${cmd}" in
  help|-h|--help) usage; exit 0 ;;
  share-ca)
    mkdir -p "${HOME}/ca-share" && cp "${CERT_DIR}/teamCA.crt" "${HOME}/ca-share/" || exit 1
    echo "Others run:  curl -o ~/Downloads/teamCA.crt http://${MAC2_IP}:8000/teamCA.crt"
    echo "Press Ctrl+C when everyone has it."
    cd "${HOME}/ca-share" && exec python3 -m http.server 8000 ;;
esac

start_log gourav "${cmd}"
{
case "${cmd}" in
  info)          my_info ;;
  ping)          ping_all ;;
  backends)      check_backends ;;
  nginx-setup)   nginx_write mac2; nginx_restart; test_edge 127.0.0.1 ;;
  nginx-restart) nginx_restart; test_edge 127.0.0.1 ;;
  test)          test_edge 127.0.0.1 ;;
  errors)        run "tail -20 '${NGINX_ERROR_LOG}'" ;;
  trust-ca)      trust_ca "${CERT_DIR}/teamCA.crt" ;;
  certs)         step "Certificates in ${CERT_DIR}"
                 run "ls -l '${CERT_DIR}'"
                 run "openssl x509 -in '${CERT_DIR}/app.crt' -noout -subject -issuer -dates -ext subjectAltName"
                 run "openssl x509 -in '${CERT_DIR}/teamCA.crt' -noout -subject -fingerprint -sha256"
                 run "openssl verify -CAfile '${CERT_DIR}/teamCA.crt' '${CERT_DIR}/app.crt'"
                 note "Everyone's teamCA.crt must show this same fingerprint." ;;
  send-certs)    user="${1:-${MAC4_USER}}"
                 step "Copy app.crt and app.key to ${user}@${MAC4_IP}:cn-certs/"
                 note "Ashar first: Remote Login ON + mkdir -p \$HOME/cn-certs. He types his own password here."
                 run "scp '${CERT_DIR}/app.crt' '${CERT_DIR}/app.key' '${user}@${MAC4_IP}:cn-certs/'" ;;
  failover-notes)
    cat <<EOF

Extension D - what to say
  * The upstream block lists Backend A (${BACKEND_A_IP}:${BACKEND_A_PORT}) and B (${BACKEND_B_IP}:${BACKEND_B_PORT}).
  * max_fails=1 fail_timeout=10s: one failed connection marks a backend down for 10 seconds.
  * proxy_next_upstream error timeout http_502: the failed request is retried on the other backend,
    so the user never sees the error.
  * proxy_connect_timeout 2s: a dead backend is detected within 2 seconds.
  * When Backend A returns, nginx tries it again after fail_timeout and round-robin resumes.

Single point of failure
  * nginx on Mac 2 (${EDGE_IP}). If Mac 2 stops, nothing reaches the backends.
  * Our fix: a standby nginx on Mac 4 (${STANDBY_EDGE_IP}) plus a short DNS TTL, so DNS can move
    clients to Mac 4 (Extension E). It is manual and clients wait up to one TTL.
  * Production fix: two load balancers sharing one virtual IP (VRRP / keepalived), or a cloud
    load balancer (AWS ALB, GCP Load Balancer) that is itself redundant.
EOF
    ;;
  *) bad "Unknown command: ${cmd}"; usage ;;
esac
} 2>&1 | tee "${LOG_FILE:-/dev/null}"
