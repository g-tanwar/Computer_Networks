# Demo and failure tests

Run the client commands on Mac 3 after DNS is `10.7.17.154` and Team1 Local CA is trusted. Do not pass `curl -k`.

| # | Check | Command | Result that was observed |
| --- | --- | --- | --- |
| 1 | DNS | `dig app.team1.test` | `10.7.18.35`, TTL 60, server `10.7.17.154` |
| 2 | HTTPS | `curl -v https://app.team1.test/api/status` | certificate verification succeeded |
| 3 | HTTP/2 | same curl | response used HTTP/2 |
| 4 | Load balancing | `common/lb-test.sh` | `X-Backend` order B, A, B, A, B, A, B, A |
| 5 | One backend down | stop Backend A, repeat curl | requests continue with `X-Backend: B` |
| 6 | Both backends down | stop A and B | `HTTP/2 502 Bad Gateway` |
| 7 | Caching | `common/cache-test.sh` | `Cache-Control: max-age=60`, then `304 Not Modified` |
| 8 | Wrong port | `curl -v https://app.team1.test:4443` | DNS returns `10.7.18.35`, TCP `Connection refused` |
| 9 | Wrong DNS server | `common/use-team-dns.sh 8.8.8.8` then `dig app.team1.test` | NXDOMAIN, `ANSWER: 0`, `SERVER: 8.8.8.8#53` |
| 10 | Wrong DNS record | `dns/point-record.sh wrong` on the live Mac 1 config | `dig` returns `10.7.31.250`, curl times out on port 443 |

Restore after 9 and 10:

```bash
./use-team-dns.sh
./point-record.sh restore /opt/homebrew/etc/dnsmasq.conf
```

The repository copy of `dnsmasq.conf` stays on `10.7.18.35`. `point-record.sh` refuses to edit any file inside this repository.

Screenshots of these runs belong in `04-Evidence`. They are not stored in the repo yet.
