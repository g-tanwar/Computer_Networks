# Source code

Scripts and the backend for the three-Mac lab. Addresses come from [team.env](team.env). Role notes:

- [PERSON1-MAC1-DNS.md](PERSON1-MAC1-DNS.md) — Piyush, DNS and Backend B
- [PERSON2-MAC2-EDGE.md](PERSON2-MAC2-EDGE.md) — Gourav, nginx and TLS
- [PERSON3-MAC3-BACKEND-A.md](PERSON3-MAC3-BACKEND-A.md) — Alok, Backend A, client, and Wireshark
- [DEMO-AND-FAILURES.md](DEMO-AND-FAILURES.md) — the checks that were completed

| Path | Purpose |
| --- | --- |
| [backend/server.py](backend/server.py) | HTTP backend. `--id A` or `--id B` |
| [backend/start-backend.sh](backend/start-backend.sh) | Starts A on 3001 or B on 3002 |
| [lib.sh](lib.sh) | Loads `team.env` for the other scripts |
| `common/` | DNS switch, CA trust, ping, load-balance, cache, diagnose, capture |
| `dns/` | Install dnsmasq, and the temporary wrong-record test |
| `edge/` | Create certificates, install nginx, copy the public CA |
| [edge/ca-public](edge/ca-public) | `team1-root-ca.crt`, `app.crt`, `app.csr`, `app.ext` |

`server.py` uses only the Python 3 standard library. No backend source file was on this Mac; Backend A and Backend B ran on Mac 3 and Mac 1. This program implements the routes those servers answered: `/`, `/api/status`, and `/api/cached`.

Private keys are created in `~/cn-certs` by `edge/make-certs.sh`. They are not in `ca-public`.
