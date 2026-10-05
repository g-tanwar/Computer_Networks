# Demo and failure tests

Run the client commands on Mac 3 after DNS is `10.7.17.154` and Team1 Local CA is trusted. Do not pass `curl -k`.

These are the final live results. No new screenshot or packet file was saved for this session. Older files under `04-Evidence/` use the capture-time addresses `10.7.18.35` and `10.7.4.38`.

| # | Check | Result |
| --- | --- | --- |
| 1 | `dig app.team1.test` | `10.7.26.232` from server `10.7.17.154` |
| 2 | `dig @8.8.8.8 app.team1.test` | NXDOMAIN |
| 3 | `curl https://app.team1.test/api/status` | Certificate verification succeeded without `-k`. CN/SAN is `app.team1.test`. Issuer is Team1 Local CA. TLS 1.3. HTTP/2 200 |
| 4 | Six HTTPS requests | `X-Backend` order A, B, A, B, A, B |
| 5 | `https://app.team1.test/api/cached` | Live result: HTTP/2 200, `server: nginx/1.31.6`, `content-type: application/json`, `content-length: 51`, `x-backend: B`, `cache-control: max-age=60`, `etag: "a8975e0e7afcd001cfc2938f7a0feecb"`. The checked-in `server.py` supports the same headers and 304 behavior, with a different cached body and therefore a different ETag |

## Failure Demonstration — Backend A Failover

Before failure, six requests returned:

```
x-backend: A
x-backend: B
x-backend: A
x-backend: B
x-backend: A
x-backend: B
```

Backend A on Mac 3 (`10.7.22.54:3001`) was stopped. During the failure, six requests returned:

```
x-backend: B
x-backend: B
x-backend: B
x-backend: B
x-backend: B
x-backend: B
```

Backend A was restarted. After restoration, six requests returned:

```
x-backend: B
x-backend: B
x-backend: A
x-backend: B
x-backend: A
x-backend: B
```

Both backends were available again. nginx failover sent the failed period to the healthy backend.

The wrong-record helper still uses the temporary address `10.7.31.250` and then restores `app.team1.test` to the address in `team.env` (`10.7.26.232`). `point-record.sh` refuses to edit any file inside this repository.
