# Team 1 — Private DNS, HTTPS/TLS, Reverse Proxy, Load Balancing, HTTP Caching and Packet Analysis

## Overview

Team 1 built a private web service across three physical Macs on one Wi-Fi LAN. A private DNS server publishes two hostnames. An edge Mac terminates HTTPS, speaks HTTP/2, and reverse-proxies requests to two backends with round-robin load balancing and failover. The backends support HTTP caching with `Cache-Control` and `ETag` validation. Packet captures on the client Mac show DNS, the TCP handshake, and TLS.

This repository holds the architecture notes, the configuration that was used, the backend program, and the lab evidence that was retained. The index is [04-Evidence/EVIDENCE-INDEX.md](04-Evidence/EVIDENCE-INDEX.md). A file is marked available only when it is in the tree. Tests whose original screenshots were not kept are marked not retained. The written report in `docs/` is not packet evidence.

## Team members and roles

| Person | Machine | Combined roles |
| --- | --- | --- |
| Piyush | Mac 1 | Private DNS server and Backend B |
| Gourav | Mac 2 | Edge server, nginx reverse proxy, round-robin load balancer, TLS/HTTPS termination |
| Alok | Mac 3 | Backend A, test client, Wireshark packet capture |

## Submission type

**Type 2 — 2 or 3 Macs with combined roles.**

Three physical Macs share the work. Mac 1 runs DNS and Backend B. Mac 3 runs Backend A, the test client, and Wireshark. Mac 2 is only the edge.

## Architecture

```mermaid
flowchart TD
    C["Client Mac 3<br/>Alok · 10.7.4.38"]
    D["Mac 1 DNS<br/>Piyush · dnsmasq :53<br/>10.7.17.154"]
    C2["Client Mac 3<br/>Alok · 10.7.4.38"]
    N["Mac 2 nginx<br/>Gourav · HTTPS :443<br/>10.7.18.35"]
    A["Backend A<br/>Mac 3 :3001<br/>10.7.4.38"]
    B["Backend B<br/>Mac 1 :3002<br/>10.7.17.154"]

    C -->|"DNS query app.team1.test"| D
    D -->|"10.7.18.35 · TTL 60"| C2
    C2 -->|"HTTPS / TLS TCP 443"| N
    N --> A
    N --> B
```

The client never opens HTTP directly to ports 3001 or 3002 for the public names. Those ports are the upstream targets used by nginx on the LAN.

Full addressing, interface, and MAC details are in [01-Architecture-Document/README.md](01-Architecture-Document/README.md).

## Machine and IP table

Network: `10.7.0.0/19`  
Gateway: `10.7.0.1`  
Subnet mask on every Mac: `255.255.224.0`  
Interface on every Mac: `en0`

| Machine | Person | IP address | MAC address | Services |
| --- | --- | --- | --- | --- |
| Mac 1 | Piyush | 10.7.17.154 | 10:9f:41:c0:9e:e5 | dnsmasq UDP/TCP 53, Backend B TCP 3002 |
| Mac 2 | Gourav | 10.7.18.35 | e6:09:91:27:22:3b | nginx HTTPS 443, TLS 1.2 and TLS 1.3, HTTP/2 |
| Mac 3 | Alok | 10.7.4.38 | 72:36:67:c5:54:98 | Backend A TCP 3001, curl/dig, Wireshark on en0 |

## Request flow

1. Mac 3 asks Mac 1 (`10.7.17.154`) for `app.team1.test`.
2. dnsmasq answers with `10.7.18.35` and a TTL of 60 seconds. `api.team1.test` uses the same address.
3. Mac 3 opens TCP port 443 on Mac 2. The handshake is SYN, SYN-ACK, ACK.
4. Mac 2 presents the server certificate for `app.team1.test`, issued by Team1 Local CA. The certificate also lists `api.team1.test` as a subject alternative name.
5. nginx terminates TLS and proxies the request over plain HTTP to Backend A (`10.7.4.38:3001`) or Backend B (`10.7.17.154:3002`).
6. The chosen backend sets `X-Backend: A` or `X-Backend: B`. nginx returns that response on the existing HTTPS connection.

## DNS architecture

Mac 1 is the only resolver that knows the team names. The client Macs use `10.7.17.154` as their DNS server.

| Name | Type | Address | TTL |
| --- | --- | --- | --- |
| app.team1.test | A | 10.7.18.35 | 60 |
| api.team1.test | A | 10.7.18.35 | 60 |

dnsmasq is configured with `domain-needed`, `bogus-priv`, and `no-resolv`. Unknown names are forwarded to `8.8.8.8` and `1.1.1.1`. Queries are logged to `/tmp/dnsmasq.log`. The file is [02-Configuration-Bundle/dns/dnsmasq.conf](02-Configuration-Bundle/dns/dnsmasq.conf).

A resolver that does not have these records, such as `8.8.8.8`, returns NXDOMAIN for `app.team1.test`.

## Backend architecture

Both backends run [03-Source-Code/backend/server.py](03-Source-Code/backend/server.py).

| Backend | Host | Listen address |
| --- | --- | --- |
| A | Mac 3 (Alok) | 10.7.4.38:3001 |
| B | Mac 1 (Piyush) | 10.7.17.154:3002 |

| Method and path | Behavior |
| --- | --- |
| `GET /` | Short JSON greeting that names the backend |
| `GET /api/status` | JSON identity and status, plus `X-Backend: A` or `X-Backend: B` |
| `GET /api/cached` | JSON body with `Cache-Control: max-age=60` and an `ETag` |

The cached document is the same on A and B, so the `ETag` does not change when the load balancer switches backends. `X-Backend` still identifies which process answered.

## nginx reverse proxy

Mac 2 runs nginx 1.31.6. The site file copied from `/opt/homebrew/etc/nginx/servers/team1.conf` is [02-Configuration-Bundle/edge/nginx-servers-team1.conf](02-Configuration-Bundle/edge/nginx-servers-team1.conf).

- `listen 443 ssl` and `http2 on`
- `server_name app.team1.test api.team1.test`
- TLS certificate and private key paths point at the files on Mac 2
- `ssl_protocols TLSv1.2 TLSv1.3`
- `proxy_pass http://backends` for `/`
- `Host`, `X-Real-IP`, and `X-Forwarded-For` are forwarded
- `proxy_connect_timeout 2s` and `proxy_next_upstream error timeout http_502`

nginx decrypts the client request and opens a new HTTP connection to the selected backend. Clients do not see ports 3001 and 3002.

## Round-robin load balancing

The upstream block lists Backend A first and Backend B second, with no explicit weights, so nginx uses its default round-robin policy:

```
10.7.4.38:3001
10.7.17.154:3002
```

Each upstream has `max_fails=1` and `fail_timeout=10s`. If a backend does not accept a connection, nginx marks it unavailable and sends the request to the other one.

Round-robin load balancing was tested during the lab session using eight consecutive HTTPS requests and produced alternating Backend A/B responses. The original terminal screenshot/output was not retained in the final evidence bundle. The nginx configuration is the retained record of the two-backend upstream pool.

## TLS and HTTPS

Team1 Local CA is a local root created on Mac 2. It signed a server certificate whose subject is `app.team1.test` and whose subject alternative names are:

- `DNS:app.team1.test`
- `DNS:api.team1.test`

The CA certificate was added to the System keychain on all three Macs, so `curl` verifies the chain without `-k`. Public certificates are in [03-Source-Code/edge/ca-public](03-Source-Code/edge/ca-public). The setup steps are in [02-Configuration-Bundle/edge/TLS-SETUP.md](02-Configuration-Bundle/edge/TLS-SETUP.md).

`teamCA.key` and `app.key` stay on Mac 2. They are not part of this repository.

## HTTP/2

nginx advertises HTTP/2 on port 443 (`http2 on`). Successful HTTPS requests to `https://app.team1.test/api/status` were completed with HTTP/2.

## HTTP caching

`GET /api/cached` returns:

- `Cache-Control: max-age=60`
- an `ETag` for the cached JSON document

A follow-up request that sends that value in `If-None-Match` receives `304 Not Modified` and an empty body.

The surviving nginx log proves the 304 response. The original terminal output containing the Cache-Control and ETag headers was not retained. On 4 Oct 2026 the Mac 2 access log records `GET /api/cached HTTP/2.0` status `200` at 01:58:33 and status `304` at 01:59:10, from client `10.7.4.38`. That log does not store `Cache-Control` or `ETag`. The file is [04-Evidence/F-HTTP-Caching/mac2_nginx_access.log](04-Evidence/F-HTTP-Caching/mac2_nginx_access.log).

## Wireshark packet analysis

Capture was taken on Mac 3, interface `en0`, and saved as `phase1_full_flow.pcapng`. That file and the Wireshark screenshots are in [04-Evidence/G-Packet-Capture](04-Evidence/G-Packet-Capture). The capture shows:

1. DNS query from Mac 3 to Mac 1 for `app.team1.test`.
2. DNS response from Mac 1 to Mac 3: `app.team1.test` → `10.7.18.35`.
3. TCP three-way handshake (SYN, SYN-ACK, ACK) between `10.7.4.38` and `10.7.18.35:443`.
4. TLS ClientHello with SNI `app.team1.test`.
5. TLS ServerHello.
6. A TLS 1.2 Certificate handshake. Issuer: Team1 Local CA. Subject: `app.team1.test`.
7. TLS 1.3 encrypted handshake traffic.
8. TLS Application Data between `10.7.4.38` and `10.7.18.35`.

TLS 1.3 encrypts the Certificate message, so the issuer and subject were read from a TLS 1.2 handshake. Application data after the handshake is encrypted on the path from the client to nginx.

## Failure scenarios

Each failure was temporary. DNS and both backends were restored afterward. Retained server logs are in [04-Evidence/H-Failure-Scenarios](04-Evidence/H-Failure-Scenarios).

| Scenario | What changed | What happened | Retained file |
| --- | --- | --- | --- |
| Wrong DNS server | Mac 3 resolver set to `8.8.8.8` | `dig app.team1.test` returned NXDOMAIN, `ANSWER: 0`, `SERVER: 8.8.8.8#53` | Not retained |
| Wrong DNS record | `app.team1.test` temporarily answered `10.7.31.250` | `dig` returned `app.team1.test 60 IN A 10.7.31.250`. `curl` to `https://app.team1.test/api/status` timed out connecting to `10.7.31.250:443` | Not retained |
| One backend down | Backend A stopped | At 01:52:30 nginx could not connect to `10.7.4.38:3001` and the access log recorded HTTP/2.0 `200`. This provides server-side evidence that Backend A was unavailable while nginx continued serving the request successfully through the upstream pool. The log does not contain `X-Backend` | `mac2_nginx_error.log`, `mac2_nginx_access.log` |
| Both backends down | Backend A and Backend B stopped | Around 01:56 both `10.7.4.38:3001` and `10.7.17.154:3002` refused connections, then the access log recorded HTTP/2.0 `502` | same logs |
| Wrong port | `curl -v https://app.team1.test:4443` | DNS still returned `10.7.18.35`. TCP to port 4443 returned `Connection refused` | Not retained |

The restored DNS record is `app.team1.test` → `10.7.18.35`. That is the address in `dnsmasq.conf`.

## Test results

These checks were completed on the lab LAN.

| # | Test | Result | Evidence in this repo |
| --- | --- | --- | --- |
| 1 | DNS resolution | `app.team1.test` resolved to `10.7.18.35` from server `10.7.17.154` with TTL 60 | Available: pcap and G2. The `dig` screenshot was not retained |
| 2 | HTTPS/TLS | Certificate verification succeeded. `curl -k` was not used | Available: E1 |
| 3 | HTTP/2 | The HTTPS response used HTTP/2 | Available: E1, and HTTP/2.0 lines in the nginx access log |
| 4 | Load balancing | Eight requests returned `X-Backend` in this order: B, A, B, A, B, A, B, A | Configuration available. The eight-line screenshot was not retained |
| 5 | One backend failure | Backend A was unreachable and nginx still returned HTTP/2.0 `200` | Available: nginx logs at 01:52:30. The log does not name `X-Backend` |
| 6 | Both backends failure | nginx recorded HTTP/2.0 `502` after both upstreams refused the connection | Available: nginx logs around 01:56 |
| 7 | HTTP caching | `/api/cached` sent `Cache-Control: max-age=60` and an `ETag`. The same `ETag` in `If-None-Match` produced `304 Not Modified` | The `304` is in the access log. The header text was not retained |
| 8 | Wrong port | Name resolution succeeded and TCP port 4443 returned `Connection refused` | Not retained |
| 9 | Wrong DNS server | `8.8.8.8` returned NXDOMAIN with `ANSWER: 0` | Not retained |
| 10 | Wrong DNS record | The temporary address `10.7.31.250` resolved, then the HTTPS connection timed out. The record was restored to `10.7.18.35` | Not retained |

## Repository structure

```
.
├── README.md
├── .gitignore
├── 01-Architecture-Document/
│   ├── README.md
│   ├── Architecture-Document.pdf
│   ├── network-architecture.png
│   └── diagrams/
│       ├── topology.svg
│       ├── topology.png
│       ├── request-flow.svg
│       └── request-flow.png
├── 02-Configuration-Bundle/
│   ├── README.md
│   ├── team.env
│   ├── backend/BACKEND-LAUNCH.md
│   ├── dns/dnsmasq.conf
│   ├── dns/etc-resolver-team1.test
│   └── edge/
│       ├── TLS-SETUP.md
│       ├── nginx-servers-team1.conf
│       └── team1-root-ca.crt
├── 03-Source-Code/
│   ├── README.md
│   ├── team.env
│   ├── lib.sh
│   ├── backend/server.py
│   ├── common/
│   ├── dns/
│   └── edge/ca-public/
├── docs/
│   └── Team1_Computer_Networks_Project_Report.docx
└── 04-Evidence/
    ├── EVIDENCE-INDEX.md
    ├── A-LAN-Setup/
    ├── B-Private-DNS/
    ├── C-Backends/
    ├── D-Load-Balancing/
    ├── E-HTTPS-TLS/
    ├── F-HTTP-Caching/
    ├── G-Packet-Capture/
    ├── H-Failure-Scenarios/
    ├── I-Troubleshooting-Notes/
    └── _raw-extra/
```

Role guides and the demo checklist are in `03-Source-Code`. Evidence status is only in [04-Evidence/EVIDENCE-INDEX.md](04-Evidence/EVIDENCE-INDEX.md). The report under `docs/` explains the project in prose and is not a substitute for the capture or the logs.

## How to reproduce

Use three Macs on `10.7.0.0/19` with the addresses in the table above. Python 3 is enough for the backends. Mac 2 needs nginx and OpenSSL. Mac 1 needs dnsmasq. Mac 3 needs `dig`, `curl`, and Wireshark.

**Mac 1 — DNS and Backend B**

```bash
cd 03-Source-Code/dns
./setup-dns.sh /opt/homebrew/etc/dnsmasq.conf
sudo dnsmasq -C /opt/homebrew/etc/dnsmasq.conf

cd ../backend
./start-backend.sh B
```

**Mac 3 — Backend A and the client**

```bash
cd 03-Source-Code/backend
./start-backend.sh A

cd ../common
./use-team-dns.sh
```

**Mac 2 — TLS edge**

Keep `app.key` beside `app.crt` on the edge Mac only. The checked-in nginx file expects:

- certificate: `/Users/gouravtanwar/cn-certs/app.crt`
- private key: `/Users/gouravtanwar/cn-certs/app.key`

Trust the CA on each Mac, then start nginx:

```bash
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  /path/to/teamCA.crt

nginx -t
brew services start nginx
```

Point a browser or `curl` at `https://app.team1.test/api/status` from Mac 3. Do not pass `-k`.

## Useful commands

```bash
dig app.team1.test
dig @10.7.17.154 app.team1.test

curl -v https://app.team1.test/api/status

for i in {1..8}; do
  curl -s -D - -o /dev/null https://app.team1.test/api/status | grep -i x-backend
done

curl -s -D - -o /dev/null https://app.team1.test/api/cached | grep -iE 'HTTP/|cache-control|etag'
ETAG=$(curl -s -D - -o /dev/null https://app.team1.test/api/cached | awk -F': ' 'tolower($1)=="etag"{print $2}' | tr -d '\r')
curl -s -D - -o /dev/null -H "If-None-Match: $ETAG" https://app.team1.test/api/cached

curl -v https://app.team1.test:4443
openssl x509 -in 03-Source-Code/edge/ca-public/app.crt -noout -subject -issuer -ext subjectAltName
```

Direct backend checks, bypassing the proxy:

```bash
curl -i http://10.7.4.38:3001/api/status
curl -i http://10.7.17.154:3002/api/status
```

## Security notes

- `*.key`, `teamCA.key`, and `app.key` are listed in [.gitignore](.gitignore).
- The private keys were created on Mac 2 and were not copied into this repository.
- Public files `teamCA.crt`, `app.crt`, `app.csr`, and `app.ext` are included so the certificate chain and SAN list can be inspected.
- nginx references `app.key` by absolute path. That line is a filesystem path, not the key.
- The lab CA is a private root for `*.team1.test` on this LAN. It is not a public certificate authority.
- dnsmasq query logs on Mac 1 go to `/tmp/dnsmasq.log` and are not committed.

## Key learnings

- Name lookup, TCP connection setup, TLS, and the HTTP application are separate stages. A correct DNS answer does not mean the host is listening, and a listening host does not mean the requested port is open.
- A private zone is invisible to public resolvers. `8.8.8.8` returned NXDOMAIN for a name that Mac 1 answers locally.
- The reverse proxy gives clients one hostname and one port. Backend addresses stay on the LAN, and nginx can hide a dead upstream.
- Round-robin spreads requests. `max_fails` and `proxy_next_upstream` keep the site up when one backend stops. When both stop, TLS to nginx still succeeds and the client receives 502.
- Trust comes from the CA installed on the client, not from disabling verification. SAN entries are what allow one certificate to cover `app.team1.test` and `api.team1.test`.
- TLS 1.3 hides the Certificate message. A TLS 1.2 handshake was used to show the issuer and subject on the wire. After the handshake, Application Data is encrypted between the client and the edge.
- `Cache-Control: max-age=60` tells the client how long the response stays fresh. `ETag` plus `If-None-Match` lets the server answer `304 Not Modified` when the body has not changed.
