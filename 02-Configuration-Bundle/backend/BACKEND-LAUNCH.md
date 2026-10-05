# Backend launch

Both backends run the same program, `03-Source-Code/backend/server.py`. The `--id` flag sets the `X-Backend` header.

| Backend | Mac | Person | Command | Address |
| --- | --- | --- | --- | --- |
| A | Mac 3 | Alok | `./start-backend.sh A` | 10.7.4.38:3001 |
| B | Mac 1 | Piyush | `./start-backend.sh B` | 10.7.17.154:3002 |

From `03-Source-Code/backend`:

```bash
./start-backend.sh A
./start-backend.sh B
```

Equivalent direct commands:

```bash
python3 server.py --id A --port 3001
python3 server.py --id B --port 3002
```

The process listens on `0.0.0.0`. Stop it with Ctrl-C.

| Request | Result |
| --- | --- |
| `GET /` | JSON greeting |
| `GET /api/status` | identity and `status: ok`, header `X-Backend` |
| `GET /api/cached` | `Cache-Control: max-age=60` and a stable `ETag` |
| `GET /api/cached` with the same `If-None-Match` | `304 Not Modified` |

Check from another Mac:

```bash
curl -i http://10.7.4.38:3001/api/status
curl -i http://10.7.17.154:3002/api/status
```
