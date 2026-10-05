# H — Failure scenarios

`mac2_nginx_error.log` and `mac2_nginx_access.log` are verbatim copies of Mac 2's nginx logs from 4 Oct 2026. They were not edited. Addresses `10.7.4.38` and `10.7.18.35` in those logs are capture-time DHCP values.

| Test | Status | Evidence | What it proves |
| --- | --- | --- | --- |
| Historical one-backend failure | AVAILABLE | both logs | At 01:52:30 the error log records connection refused to capture-time Backend A `10.7.4.38:3001` during `GET /api/status HTTP/2.0`. The access log records HTTP/2.0 `200` at that same second. This provides server-side evidence that Backend A was unavailable while nginx continued serving the request successfully through the upstream pool. The log does not contain `X-Backend: B` |
| Final Backend A failover | NOT RETAINED | — | Backend A `10.7.22.54:3001` was stopped. Six responses were `x-backend: B`. After restart the series was B, B, A, B, A, B. No screenshot was saved |
| Historical both backends unavailable | AVAILABLE | both logs | Capture-time. Around 01:56 the error log records connection refused to `10.7.17.154:3002` (01:56:44) and `10.7.4.38:3001` (01:56:45). The access log records HTTP/2.0 `502` at 01:56:45 for client `10.7.4.38` |
| Wrong DNS server | NOT RETAINED | — | `8.8.8.8` returned NXDOMAIN. The original screenshot was not kept |
| Wrong DNS record | NOT RETAINED | — | Temporary answer `10.7.31.250`, then a connection timeout. The record was restored. The original screenshot was not kept |
| Wrong destination port | NOT RETAINED | — | `https://app.team1.test:4443` was connection refused. The original screenshot was not kept. Notes of that earlier test used the capture-time edge address `10.7.18.35` |
