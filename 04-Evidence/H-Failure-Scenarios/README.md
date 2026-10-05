# H — Failure scenarios

`mac2_nginx_error.log` and `mac2_nginx_access.log` are verbatim copies of Mac 2's nginx logs from 4 Oct 2026. They were not edited.

| Test | Status | Evidence | What it proves |
| --- | --- | --- | --- |
| One-backend failure / failover | AVAILABLE | both logs | At 01:52:30 the error log records connection refused to `10.7.4.38:3001` during `GET /api/status HTTP/2.0`. The access log records HTTP/2.0 `200` at that same second. This provides server-side evidence that Backend A was unavailable while nginx continued serving the request successfully through the upstream pool. The log does not contain `X-Backend: B` |
| Both backends unavailable | AVAILABLE | both logs | Around 01:56 the error log records connection refused to `10.7.17.154:3002` (01:56:44) and `10.7.4.38:3001` (01:56:45). The access log records HTTP/2.0 `502` at 01:56:45 for client `10.7.4.38` |
| Wrong DNS server | NOT RETAINED | — | `8.8.8.8` returned NXDOMAIN. The original screenshot was not kept |
| Wrong DNS record | NOT RETAINED | — | Temporary answer `10.7.31.250`, then a connection timeout. The record was restored. The original screenshot was not kept |
| Wrong destination port | NOT RETAINED | — | `https://app.team1.test:4443` was connection refused after DNS returned `10.7.18.35`. The original screenshot was not kept |
