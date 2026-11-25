# I — Troubleshooting notes

Problems the team met while rebuilding the lab on 25–26 Nov 2026, before Phase 2. Each one is written as symptom → layer → cause → fix, the same method used for Extension F.

| # | Symptom | Layer | Cause | Fix | Who |
| --- | --- | --- | --- | --- | --- |
| 1 | Ping to the old addresses `10.7.17.154` and `10.7.22.54` failed, even from those Macs themselves | IP | DHCP gave every Mac a new address. `10.7.26.232` still answered, but it now belonged to some other device on the Wi-Fi | Read each Mac's IP with `ipconfig getifaddr en0`, updated `team.env` and every config | Everyone |
| 2 | `Mac 4` was listed as `10.67.245.86` | IP | That address is outside `10.7.0.0/19`, so it was from another network | Re-read on the lab Wi-Fi: `10.7.31.120` | Ashar |
| 3 | `start-backend.sh` → `OSError: [Errno 48] Address already in use` | Transport (port) | A backend from an earlier session was still listening on 3001 / 3002 | `lsof -nP -iTCP:3001 -sTCP:LISTEN`, `kill` it, start again | Alok, Piyush |
| 4 | `curl: Could not resolve host: app.team1.test` | DNS | Client was not yet using Mac 1, and a DNS server had been started on the client by mistake | Stopped dnsmasq on Mac 3; set Mac 3 DNS to `10.7.11.104` | Alok |
| 5 | `dig @10.7.11.104 app.team1.test +short` printed nothing (no timeout) | DNS | Server reachable, but the running dnsmasq still had the old record. dnsmasq reads `address=` only at start-up | Rewrote `dnsmasq.conf` with `10.7.1.118`, full restart → answer `10.7.1.118` | Piyush |
| 6 | `SSL certificate problem: unable to get local issuer certificate` | TLS | Gourav had created a new CA (25 Nov). The CA in the repository and on the clients was the old one | Distributed the new `teamCA.crt`; trusted it on every Mac | Gourav, everyone |
| 7 | Still failing with `--cacert ~/Downloads/teamCA.crt` | TLS | AirDrop saved the new CA as `teamCA 2.crt`; `teamCA.crt` was an old file. Fingerprints showed it: new `C6:54:AD…`, old `06:E8:EB…` | Renamed the files, removed old “Team1 Local CA” keychain entries, trusted the new one → `SSL certificate verify ok`, TLS 1.3, HTTP/2 200 | Alok |
| 8 | Wireshark filters typed into Terminal → `command not found: dns` | Tooling | Display filters belong in Wireshark's filter bar, not the shell | Used the filter bar, or `tshark -r file -Y <filter>` (now `./alok-mac3.sh analyze`) | Alok |
| 9 | Mac 4 nginx: `cannot load certificate "/Users/ashar/cn-certs/app.crt"` | TLS (edge config) | The certificate and key had not been copied to Mac 4 | Gourav copied `app.crt` + `app.key` with `scp` → `nginx -t` successful | Gourav, Ashar |
| 10 | `scp: stat local "/cn-certs/app.crt": No such file or directory` | — (human) | The command was passed on WhatsApp, which removes `~` (strikethrough marker) | Used a command without `~` (`scp app.crt app.key ashar@10.7.31.120:cn-certs/`) | Gourav |

## What this taught us

- Check the layers in order. Each problem above sat at one layer, and the lower layers worked: DNS answered (5) even though the record was wrong, TCP connected (6) even though TLS failed.
- A changed IP silently breaks DNS records, nginx upstreams and test commands. Check addresses first every lab day.
- Two certificates with the same name are easy to confuse. Compare SHA-256 fingerprints, not names.
