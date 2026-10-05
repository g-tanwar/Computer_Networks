# Evidence index

Type 2 submission. Three physical Macs. Lab-session addresses only.

`docs/Team1_Computer_Networks_Project_Report.docx` is the written report. It is not packet or test evidence.

Status values:

- **AVAILABLE** — a real file from the lab session is in this repository.
- **NOT RETAINED** — the test was performed, and the original screenshot or terminal output was not preserved.
- **OPTIONAL** — not required for this bundle.

| Area | Test | Status | Evidence | What it proves |
| --- | --- | --- | --- | --- |
| DNS | Query and response for `app.team1.test` | AVAILABLE | [G-Packet-Capture/phase1_full_flow.pcapng](G-Packet-Capture/phase1_full_flow.pcapng), [G2_wireshark_dns_query_and_response.png](G-Packet-Capture/G2_wireshark_dns_query_and_response.png) | Mac 3 `10.7.4.38` queries Mac 1 `10.7.17.154`. The answer is `A 10.7.18.35` |
| DNS | `dig` terminal transcript | NOT RETAINED | — | The lookup was performed. No `dig` screenshot was kept. The packet capture is the retained proof |
| DNS | dnsmasq query log | NOT RETAINED | — | Queries were logged on Mac 1 during the session. `/tmp/dnsmasq.log` was not copied |
| TCP | Three-way handshake | AVAILABLE | [G3_wireshark_tcp_SYN_SYNACK_ACK.png](G-Packet-Capture/G3_wireshark_tcp_SYN_SYNACK_ACK.png) | Packets 1027 SYN, 1029 SYN-ACK, 1030 ACK between `10.7.4.38` and `10.7.18.35:443` |
| TLS | ClientHello and SNI | AVAILABLE | [G4a_wireshark_clienthello_SNI.png](G-Packet-Capture/G4a_wireshark_clienthello_SNI.png) | Packet 1031 Client Hello, `SNI=app.team1.test` |
| TLS | Certificate and Team1 Local CA | AVAILABLE | [G4b_wireshark_certificate_Team1_CA.png](G-Packet-Capture/G4b_wireshark_certificate_Team1_CA.png), [G4c_tls12_certificate_packet_1105.png](G-Packet-Capture/G4c_tls12_certificate_packet_1105.png) | Issuer `Team1 Local CA`, subject `app.team1.test`. Packet 1105 is the TLS 1.2 certificate flight |
| TLS | Encrypted application data | AVAILABLE | [G5_wireshark_encrypted_application_data.png](G-Packet-Capture/G5_wireshark_encrypted_application_data.png) | Application Data both ways on the port 59059 connection |
| TLS | Packet list of the same capture | AVAILABLE | [G6_full_packet_list_tcpdump.txt](G-Packet-Capture/G6_full_packet_list_tcpdump.txt) | `tcpdump -n -r` of the real pcap, 2937 packets |
| TLS | Separate `curl --tlsv1.2` transcript | OPTIONAL | — | The TLS 1.2 handshake is already in G4c and the pcap |
| HTTPS | Certificate verification, HTTP/2, one backend header | AVAILABLE | [E-HTTPS-TLS/E1_mac3_curl_v_TLS_cert_verify.png](E-HTTPS-TLS/E1_mac3_curl_v_TLS_cert_verify.png) | SAN matched `app.team1.test`, issuer `CN=Team1 Local CA`, `SSL certificate verify ok`, HTTP/2 200, `x-backend: B` |
| Load balancing | Two-backend upstream configuration | AVAILABLE | [nginx-servers-team1.conf](../02-Configuration-Bundle/edge/nginx-servers-team1.conf) | Upstream pool `10.7.4.38:3001` and `10.7.17.154:3002`, `max_fails=1`, `fail_timeout=10s` |
| Load balancing | Eight-request `X-Backend` series | NOT RETAINED | — | Round-robin was tested with eight consecutive HTTPS requests and produced alternating Backend A/B responses. The original terminal screenshot was not retained |
| Caching | `GET /api/cached` 200 then 304 | AVAILABLE | [F-HTTP-Caching/mac2_nginx_access.log](F-HTTP-Caching/mac2_nginx_access.log) | 4 Oct 2026 01:58:33 HTTP/2.0 `200`, then 01:59:10 HTTP/2.0 `304` from client `10.7.4.38` |
| Caching | `Cache-Control` and `ETag` headers | NOT RETAINED | — | The surviving nginx log proves the 304 response. The original terminal output containing the Cache-Control and ETag headers was not retained |
| Failover | One backend unavailable | AVAILABLE | [H-Failure-Scenarios/mac2_nginx_error.log](H-Failure-Scenarios/mac2_nginx_error.log), [mac2_nginx_access.log](H-Failure-Scenarios/mac2_nginx_access.log) | At 01:52:30 nginx failed to connect to `10.7.4.38:3001` and the access log recorded HTTP/2.0 `200`. This provides server-side evidence that Backend A was unavailable while nginx continued serving the request successfully through the upstream pool. The log does not contain `X-Backend` |
| Failure | Both backends unavailable | AVAILABLE | [mac2_nginx_error.log](H-Failure-Scenarios/mac2_nginx_error.log), [mac2_nginx_access.log](H-Failure-Scenarios/mac2_nginx_access.log) | Around 01:56, connection refused to `10.7.17.154:3002` and `10.7.4.38:3001`, then HTTP/2.0 `502` |
| Failure | Wrong DNS server `8.8.8.8` / NXDOMAIN | NOT RETAINED | — | The test was performed. The original screenshot was not retained |
| Failure | Wrong record `10.7.31.250` / timeout | NOT RETAINED | — | The test was performed and the record was restored. The original screenshot was not retained |
| Failure | Wrong port 4443 / connection refused | NOT RETAINED | — | The test was performed. The original screenshot was not retained |
| Backends | Direct curl to `:3001` and `:3002` | NOT RETAINED | — | The direct backend checks were performed. The original output was not retained |
| LAN | Ping and netinfo | OPTIONAL | [A-LAN-Setup](A-LAN-Setup) | No ping or interface transcript was kept |
| Notes | Troubleshooting write-up | OPTIONAL | [I-Troubleshooting-Notes](I-Troubleshooting-Notes) | No separate incident note |
| Capture | Extra Wireshark views | AVAILABLE | [_raw-extra](_raw-extra) | Real screenshots from the same session. Weaker or repeated views, not primary evidence |
| Capture | Alternate pcap filenames G0 and G1 | OPTIONAL | — | `phase1_full_flow.pcapng` is the lab capture |
