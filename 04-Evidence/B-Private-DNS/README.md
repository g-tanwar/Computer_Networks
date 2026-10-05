# B — Private DNS

The retained proof of name resolution is the packet capture, not a file in this folder.

| Test | Status | Where |
| --- | --- | --- |
| DNS query and answer `app.team1.test` → `10.7.18.35` | AVAILABLE | `../G-Packet-Capture/phase1_full_flow.pcapng` and `G2_wireshark_dns_query_and_response.png` |
| `dig` terminal transcript | NOT RETAINED | The lookup was performed. No terminal screenshot was kept |
| dnsmasq query log | NOT RETAINED | Mac 1 logged queries to `/tmp/dnsmasq.log`. That file was not copied |
| CA trust command output | NOT RETAINED | Trust is shown by the successful verification in `../E-HTTPS-TLS/E1_mac3_curl_v_TLS_cert_verify.png` |

The live records are in `02-Configuration-Bundle/dns/dnsmasq.conf`: `app.team1.test` and `api.team1.test` both answer `10.7.18.35` with TTL 60.
