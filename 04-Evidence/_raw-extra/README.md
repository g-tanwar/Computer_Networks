# Raw extra

These are real screenshots from the same Wireshark session. They are weaker or repeated views, so they are not the primary evidence files.

| File | Why it is here |
| --- | --- |
| `unfiltered-packet-list-end-of-capture.png` | End of the capture with ARP, mDNS, and other traffic. The lab DNS and TLS rows are not in this view |
| `dns-packet-1020-answers-collapsed.png` | DNS response packet 1020 with the answer section closed |
| `dns-packet-1020-answer-expanded.png` | Same packet with `A 10.7.18.35` expanded. The packet list in `G2` already shows that answer |
| `syn-synack-only-ack-hidden-by-filter.png` | SYN and SYN-ACK only. The filter hides the third ACK. `G3` shows all three |
| `packet-1105-certificate-fields-closed.png` | Packet 1105 frame with the certificate fields closed. `G4b` shows the issuer and subject |
