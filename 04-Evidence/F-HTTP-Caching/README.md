# F — HTTP caching

| Test | Status | Evidence | What it proves |
| --- | --- | --- | --- |
| Historical conditional caching / 304 | AVAILABLE | `mac2_nginx_access.log` | Capture-time Mac 2 access log from 4 Oct 2026. Client `10.7.4.38` is that night's DHCP address. `GET /api/cached HTTP/2.0` returned `200` at 01:58:33, then `304` at 01:59:10 |
| Final `Cache-Control` and `ETag` | NOT RETAINED | — | The final response was HTTP/2 200, `cache-control: max-age=60`, `etag: "a8975e0e7afcd001cfc2938f7a0feecb"`, `x-backend: B`. The transcript was not saved |

The historical nginx log proves the 304 status. It does not contain `Cache-Control` or `ETag`. The final header text was not retained as a file. The live ETag above is the observed response. `03-Source-Code/backend/server.py` implements the same cache behavior with its own body, so its ETag is different.
