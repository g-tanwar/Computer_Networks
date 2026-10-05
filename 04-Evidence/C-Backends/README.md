# C — Backends

Direct requests to the backends, bypassing nginx, were run during the lab:

- `curl http://10.7.4.38:3001/api/status` with `X-Backend: A`
- `curl http://10.7.17.154:3002/api/status` with `X-Backend: B`

**NOT RETAINED.** The original terminal output was not preserved. This folder has no captured file.

The backend program is `03-Source-Code/backend/server.py`. One successful proxied response with `x-backend: B` is in `../E-HTTPS-TLS/E1_mac3_curl_v_TLS_cert_verify.png`.
