#!/usr/bin/env python3
"""Team 1 HTTP backend used behind the nginx reverse proxy.

The same program runs on both backend Macs. The identity header is selected
with --id so each machine announces itself as A or B.

    python3 server.py --id A --port 3001
    python3 server.py --id B --port 3002

Routes:
    GET /            service greeting
    GET /api/status  identity and health, with X-Backend
    GET /api/cached  Cache-Control: max-age=60 and a stable ETag

A request that repeats that ETag in If-None-Match receives 304 Not Modified.
The cached document is identical on both backends, so ETag validation still
works when nginx alternates between them. X-Backend still names the server
that handled the request.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MAX_AGE = "max-age=60"

CACHED_PAYLOAD = {
    "cacheable": True,
    "message": "This response is cacheable for 60 seconds.",
    "resource": "/api/cached",
}


def canonical_json(payload: dict) -> bytes:
    return json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")


CACHED_BODY = canonical_json(CACHED_PAYLOAD)
CACHED_ETAG = '"' + hashlib.sha256(CACHED_BODY).hexdigest()[:16] + '"'


class BackendHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt: str, *args) -> None:
        backend_id = getattr(self.server, "backend_id", "?")
        super().log_message("[%s] " + fmt, backend_id, *args)

    def do_GET(self) -> None:
        path = self.path.split("?", 1)[0]
        if path == "/":
            self._send_json(
                200,
                {
                    "backend": self.server.backend_id,
                    "message": "Team 1 backend is running",
                    "service": "team1-backend",
                },
            )
            return
        if path == "/api/status":
            self._send_json(
                200,
                {
                    "backend": self.server.backend_id,
                    "port": self.server.server_port,
                    "status": "ok",
                },
            )
            return
        if path == "/api/cached":
            self._send_cached()
            return
        self._send_json(
            404,
            {
                "backend": self.server.backend_id,
                "error": "not found",
                "path": path,
            },
        )

    def _send_cached(self) -> None:
        extra = {"Cache-Control": MAX_AGE, "ETag": CACHED_ETAG}
        if self._if_none_match():
            self._send(304, b"", extra=extra)
            return
        self._send(200, CACHED_BODY, content_type="application/json", extra=extra)

    def _if_none_match(self) -> bool:
        header = self.headers.get("If-None-Match")
        if not header:
            return False
        presented = [part.strip() for part in header.split(",")]
        return CACHED_ETAG in presented

    def _send_json(self, status: int, payload: dict) -> None:
        self._send(status, canonical_json(payload), content_type="application/json")

    def _send(
        self,
        status: int,
        body: bytes,
        content_type: str | None = None,
        extra: dict | None = None,
    ) -> None:
        self.send_response(status)
        self.send_header("X-Backend", self.server.backend_id)
        if content_type and body:
            self.send_header("Content-Type", content_type)
        if extra:
            for key, value in extra.items():
                self.send_header(key, value)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if body:
            self.wfile.write(body)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Team 1 backend (A on port 3001, B on port 3002)"
    )
    parser.add_argument(
        "--id",
        default=os.environ.get("BACKEND_ID", "A"),
        help="Backend identity: A or B",
    )
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=None)
    args = parser.parse_args()
    args.id = str(args.id).strip().upper()
    if args.id not in {"A", "B"}:
        parser.error("--id must be A or B")
    if args.port is None:
        env_port = os.environ.get("PORT")
        if env_port:
            args.port = int(env_port)
        else:
            args.port = 3001 if args.id == "A" else 3002
    return args


def main() -> None:
    args = parse_args()
    server = ThreadingHTTPServer((args.host, args.port), BackendHandler)
    server.backend_id = args.id
    print(f"Backend {args.id} listening on {args.host}:{args.port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping backend", flush=True)
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
