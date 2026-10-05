# F — HTTP caching

| Test | Status | Evidence | What it proves |
| --- | --- | --- | --- |
| Conditional caching / 304 | AVAILABLE | `mac2_nginx_access.log` | Verbatim Mac 2 access log from 4 Oct 2026. Client `10.7.4.38`: `GET /api/cached HTTP/2.0` returned `200` at 01:58:33, then `304` at 01:59:10 |
| `Cache-Control` and `ETag` text | NOT RETAINED | — | The original terminal output was not kept |

The surviving nginx log proves the 304 response. The original terminal output containing the Cache-Control and ETag headers was not retained.

The access log does not contain `Cache-Control` or `ETag`.
