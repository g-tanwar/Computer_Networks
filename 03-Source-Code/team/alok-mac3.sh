#!/bin/bash
# Alok - Mac 3 - Backend A (port 3001), test client, Wireshark / packet capture.
# Usage: ./alok-mac3.sh <command>     (run with no command to see the list)
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

URL="https://${APP_HOST}/api/status"
TSHARK=/Applications/Wireshark.app/Contents/MacOS/tshark

usage() {
  cat <<EOF
Alok - Mac 3 (${MAC3_IP}) - Backend A + test client + Wireshark

Every lab day
  info              Show this Mac's IP, MAC address, gateway, DNS
  ping              Ping all four Macs
  backend           Start Backend A on port ${BACKEND_A_PORT} (keep the window open)
  use-dns team      Use Mac 1 for DNS          (also: both | google | auto)
  trust-ca [file]   Trust Gourav's teamCA.crt (removes older copies first)

Phase 1 tests (demo steps 3-7)
  dns-check         dig ${APP_HOST}: which IP, which server answered
  https             curl -v ${URL}  (certificate check, HTTP/2)
  lb [n]            n requests (default 6), print X-Backend each time
  cache             Cache-Control + ETag, then If-None-Match -> 304
  capture           Record DNS + TCP + TLS for one request into a .pcap (needs sudo)
  analyze [file]    Show DNS / handshake / SNI / certificate / encrypted data from the .pcap

Phase 1 failure tests
  fail-dns          Use 8.8.8.8 -> NXDOMAIN, ping still works, then restore Mac 1
  fail-port         Wrong port 4443 -> connection refused
  status-code       Print only the HTTP status (shows 502 when both backends are down)

Phase 2
  firewall-on       Extension C: only the edges may reach port ${BACKEND_A_PORT}
  firewall-off      Extension C: undo
  isolation-test    Extension C: direct curl to Backend B must time out, the site must still work
  test-standby      Extension E: HTTPS straight to Mac 4's nginx
  watch [seconds]   Extension B+E: every 2 s print resolved IP, X-Edge, X-Backend (default 60 s)
  diagnose          Extension F: check DNS -> IP -> TCP -> TLS -> HTTP -> backends in order
EOF
}

lb() {
  local n="${1:-6}" i out=""
  step "${n} requests to ${URL}"
  for ((i = 1; i <= n; i++)); do
    b="$(curl -s -m 5 -D - -o /dev/null "${URL}" | awk -F': ' 'tolower($1)=="x-backend"{print $2}' | tr -d '\r')"
    echo "request ${i}: x-backend ${b:-NONE}"; out="${out}${b:--} "
  done
  ok "Order: ${out}"
}

cache_test() {
  local u="https://${APP_HOST}/api/cached" etag
  step "First request: look for cache-control and etag"
  run "curl -s -D - -o /dev/null ${u} | grep -iE 'HTTP/|cache-control|etag|x-backend'"
  etag="$(curl -s -D - -o /dev/null "${u}" | awk -F': ' 'tolower($1)=="etag"{print $2}' | tr -d '\r')"
  step "Repeat with If-None-Match: ${etag}  (expect 304, empty body)"
  run "curl -s -D - -o /dev/null -H 'If-None-Match: ${etag}' ${u} | grep -iE 'HTTP/|etag|x-backend'"
  note "Fresh hit = reuse within max-age without asking. Conditional = ask with ETag, get 304. Full = 200 with body."
}

capture() {
  local f="${HOME}/Desktop/team1-flow-$(date +%H%M%S).pcap" pid
  sudo -v || return 1
  step "Recording to ${f}"
  flush_dns
  sudo tcpdump -i "${IFACE}" -w "${f}" 'port 53 or port 443' >/dev/null 2>&1 &
  pid=$!; sleep 2
  run "curl -s ${URL}; echo"
  run "curl -s --tlsv1.2 --tls-max 1.2 ${URL}; echo"
  sleep 2; sudo kill -INT "${pid}" 2>/dev/null; sleep 1
  cp "${f}" "${REPO_ROOT}/04-Evidence/G-Packet-Capture/" && ok "Saved ${f} and copied it to 04-Evidence/G-Packet-Capture/"
  analyze "${f}"
  note "Open in Wireshark for screenshots: open -a Wireshark '${f}'"
}

analyze() {
  local f="${1:-$(ls -t "${HOME}"/Desktop/team1-flow*.pcap 2>/dev/null | head -1)}"
  [[ -x "${TSHARK}" ]] || { bad "tshark not found. Install Wireshark: brew install --cask wireshark"; return 1; }
  [[ -f "${f}" ]] || { bad "No capture file. Run: $0 capture"; return 1; }
  step "1. DNS question and answer (UDP 53)";      "${TSHARK}" -r "${f}" -Y dns 2>/dev/null
  step "2. TCP three-way handshake (port 443)";    "${TSHARK}" -r "${f}" -Y "tcp.port==443" 2>/dev/null | head -3
  step "3. ClientHello: client port, server, SNI"; "${TSHARK}" -r "${f}" -Y "tls.handshake.type==1" -T fields -e ip.src -e tcp.srcport -e ip.dst -e tcp.dstport -e tls.handshake.extensions_server_name 2>/dev/null
  step "4. Certificate (TLS 1.2 request)";         "${TSHARK}" -r "${f}" -Y "tls.handshake.type==11" -V 2>/dev/null | grep -oE "Team1 Local CA|app\.team1\.test" | sort -u
  step "5. Encrypted application data";            "${TSHARK}" -r "${f}" -Y "tls.app_data" 2>/dev/null | head -4
  note "Wireshark filters for screenshots: dns | tcp.flags.syn == 1 | tls.handshake.type == 1 | tls.handshake.type == 11 | tls.app_data"
}

watch_cutover() {
  local secs="${1:-60}" end ip hdr
  step "Watching for ${secs} s. Switch the DNS record now (Piyush + Ashar: record standby)."
  end=$(( $(date +%s) + secs ))
  while [[ $(date +%s) -lt ${end} ]]; do
    ip="$(dscacheutil -q host -a name "${APP_HOST}" | awk '/ip_address/{print $2}' | head -1)"
    hdr="$(curl -s -m 3 -D - -o /dev/null "${URL}" | grep -iE 'x-edge|x-backend' | tr -d '\r' | tr '\n' ' ')"
    echo "$(date +%T)  resolved=${ip:-none}  ${hdr:-no response}"
    sleep 2
  done
  note "Flush to see the change at once: sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
}

diagnose() {
  local ip code
  step "Layer 1 - DNS"
  ip="$(dig +short "${APP_HOST}" | tail -1)"
  if [[ "${ip}" == "${EDGE_IP}" || "${ip}" == "${STANDBY_EDGE_IP}" ]]; then ok "${APP_HOST} -> ${ip}"; else bad "${APP_HOST} -> '${ip:-no answer}' (expected ${EDGE_IP}). Check client DNS and dnsmasq."; fi
  ip="${ip:-${EDGE_IP}}"
  step "Layer 2 - IP reachability"
  if ping -c 2 -t 3 "${ip}" >/dev/null 2>&1; then ok "${ip} replies to ping"; else bad "${ip} does not reply (wrong IP, Mac off, or stealth mode)"; fi
  step "Layer 3 - TCP port ${HTTPS_PORT}"
  if nc -z -G 3 "${ip}" "${HTTPS_PORT}" 2>/dev/null; then ok "port ${HTTPS_PORT} open"; else bad "port ${HTTPS_PORT} closed (nginx stopped or wrong port)"; fi
  step "Layer 4 - TLS certificate"
  openssl s_client -connect "${ip}:${HTTPS_PORT}" -servername "${APP_HOST}" </dev/null 2>/dev/null | grep -E 'subject=|issuer=|Verify return code'
  step "Layer 5 - HTTP"
  code="$(curl -s -m 5 -o /dev/null -w '%{http_code}' "${URL}")"
  case "${code}" in
    200) ok "HTTP 200" ;;
    502|504) bad "HTTP ${code}: nginx is up but cannot reach a backend" ;;
    000) bad "No HTTP response (fails below HTTP - see layers above; curl exit shows why)"; curl -s -m 5 -o /dev/null "${URL}" ;;
    *) bad "HTTP ${code}" ;;
  esac
  step "Layer 6 - backends directly"
  check_backends
  note "Direct backend checks time out from this Mac while the firewall (Extension C) is on. That is expected."
}

cmd="${1:-help}"; shift 2>/dev/null
case "${cmd}" in
  help|-h|--help) usage; exit 0 ;;
  backend) start_backend A ;;
esac

start_log alok "${cmd}"
{
case "${cmd}" in
  info)           my_info ;;
  ping)           ping_all ;;
  trust-ca)       trust_ca "${1:-}" ;;
  use-dns)        use_dns "${1:-team}" ;;
  dns-check)      flush_dns; run "dig ${APP_HOST} | grep -E 'status|IN[[:space:]]+A|SERVER|Query time'" ;;
  https)          run "curl -v ${URL} 2>&1 | grep -E 'Connected|SSL connection|subject:|issuer:|subjectAltName|verify|HTTP/2 |x-backend|x-edge'" ;;
  lb)             lb "${1:-6}" ;;
  cache)          cache_test ;;
  capture)        capture ;;
  analyze)        analyze "${1:-}" ;;
  fail-dns)       use_dns google
                  run "dig ${APP_HOST} | grep -E 'status|SERVER'"
                  run "ping -c 2 ${EDGE_IP}"
                  note "Name lookup fails, IP still works: DNS and IP are separate layers."
                  use_dns team ;;
  fail-port)      run "curl -sv -m 5 https://${APP_HOST}:4443/ 2>&1 | grep -E 'Trying|refused|Failed'"
                  run "nc -vz -G 3 ${EDGE_IP} 443; nc -vz -G 3 ${EDGE_IP} 4443" ;;
  status-code)    run "curl -s -o /dev/null -w 'HTTP %{http_code}\n' ${URL}" ;;
  firewall-on)    firewall_on "${BACKEND_A_PORT}" ;;
  firewall-off)   firewall_off ;;
  isolation-test) step "Direct to Backend B - should TIME OUT while Piyush's firewall is on"
                  run "curl -s -m 3 http://${BACKEND_B_IP}:${BACKEND_B_PORT}/api/status || echo 'blocked (timed out)'"
                  step "Through the edge - should still work"
                  run "curl -s ${URL}; echo" ;;
  test-standby)   test_edge "${STANDBY_EDGE_IP}" ;;
  watch)          watch_cutover "${1:-60}" ;;
  diagnose)       diagnose ;;
  *)              bad "Unknown command: ${cmd}"; usage ;;
esac
} 2>&1 | tee "${LOG_FILE:-/dev/null}"
