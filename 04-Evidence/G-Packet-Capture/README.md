# G — Packet capture

Capture machine: Mac 3, interface `en0`. The file `phase1_full_flow.pcapng` is the original lab capture. It was copied here unchanged.

These files are historical. The DHCP addresses inside them are capture-time values: client and Backend A `10.7.4.38`, edge `10.7.18.35`, DNS `10.7.17.154`. The final live addresses are `10.7.22.54`, `10.7.26.232`, and `10.7.17.154`. No capture of the final session is in this folder.

| Status | File | What it proves |
| --- | --- | --- |
| AVAILABLE | `phase1_full_flow.pcapng` | 2937-packet capture from the lab session |
| AVAILABLE | `G2_wireshark_dns_query_and_response.png` | `10.7.4.38` asks `10.7.17.154` for `app.team1.test`. Answer is `A 10.7.18.35` |
| AVAILABLE | `G3_wireshark_tcp_SYN_SYNACK_ACK.png` | Packets 1027 SYN, 1029 SYN-ACK, 1030 ACK to `10.7.18.35:443` |
| AVAILABLE | `G4a_wireshark_clienthello_SNI.png` | Client Hello with `SNI=app.team1.test` |
| AVAILABLE | `G4b_wireshark_certificate_Team1_CA.png` | Issuer `Team1 Local CA`, subject `app.team1.test` |
| AVAILABLE | `G4c_tls12_certificate_packet_1105.png` | TLS 1.2 packet 1105: Server Hello, Certificate, Server Key Exchange, Server Hello Done |
| AVAILABLE | `G5_wireshark_encrypted_application_data.png` | TLS Application Data between `10.7.4.38` and `10.7.18.35` |
| AVAILABLE | `G6_full_packet_list_tcpdump.txt` | Packet list read from this pcap with tcpdump |
| OPTIONAL | `G7_mac3_curl_verbose_tls12.txt` | No separate TLS 1.2 curl transcript. Packet 1105 in G4c is the retained TLS 1.2 certificate view |
| OPTIONAL | `G0_mac3_capture_taskG-flow.pcapng` | Not supplied. The capture above is the lab file |
| OPTIONAL | `G1_mac3_capture_run_TLS1.2.pcapng` | No separate TLS 1.2 capture was supplied |

Weaker views of the same capture are in `../_raw-extra/`.
