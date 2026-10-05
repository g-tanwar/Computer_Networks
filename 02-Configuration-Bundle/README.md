# Configuration bundle

Checked-in configuration for the three-Mac lab. Private keys are not in this directory.

| Path | Role |
| --- | --- |
| [team.env](team.env) | Addresses, ports, and names used by the scripts |
| [dns/dnsmasq.conf](dns/dnsmasq.conf) | Private DNS for Mac 1 (`10.7.17.154`) |
| [dns/etc-resolver-team1.test](dns/etc-resolver-team1.test) | macOS resolver file for `/etc/resolver/team1.test` |
| [edge/nginx-servers-team1.conf](edge/nginx-servers-team1.conf) | nginx site copied from Mac 2 |
| [edge/TLS-SETUP.md](edge/TLS-SETUP.md) | How Team1 Local CA and the server certificate were created |
| [edge/team1-root-ca.crt](edge/team1-root-ca.crt) | Public CA certificate |
| [backend/BACKEND-LAUNCH.md](backend/BACKEND-LAUNCH.md) | How to start Backend A and Backend B |

The server certificate, CSR, and SAN file are in `03-Source-Code/edge/ca-public/`. `app.key` and `teamCA.key` stay in `~/cn-certs` on Mac 2.

## DNS

`dns/dnsmasq.conf` maps both names to the edge server:

- `app.team1.test` → `10.7.18.35`
- `api.team1.test` → `10.7.18.35`

TTL is 60 seconds. Forwarders are `8.8.8.8` and `1.1.1.1`. The live dnsmasq process runs on Mac 1. This file is the configuration that was verified in the lab. The temporary test address `10.7.31.250` is not in it.

## nginx

`edge/nginx-servers-team1.conf` is a byte-for-byte copy of `/opt/homebrew/etc/nginx/servers/team1.conf` from Mac 2 (nginx 1.31.6).

- Backend A: `10.7.4.38:3001`
- Backend B: `10.7.17.154:3002`
- HTTPS port 443
- `server_name app.team1.test api.team1.test`

`ssl_certificate_key` points at `app.key` on Mac 2. That key is gitignored.

## Certificates

```bash
openssl x509 -in edge/team1-root-ca.crt -noout -subject -issuer -dates
openssl x509 -in ../03-Source-Code/edge/ca-public/app.crt -noout -subject -issuer -ext subjectAltName
openssl verify -CAfile edge/team1-root-ca.crt ../03-Source-Code/edge/ca-public/app.crt
```
