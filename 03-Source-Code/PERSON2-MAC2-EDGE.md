# Mac 2 — Gourav — edge, nginx, TLS

Address `10.7.18.35`, mask `255.255.224.0`, gateway `10.7.0.1`, interface `en0`, MAC `e6:09:91:27:22:3b`.

nginx 1.31.6 listens on TCP 443 with TLS 1.2, TLS 1.3, and HTTP/2. The site file is `02-Configuration-Bundle/edge/nginx-servers-team1.conf`. It is the file that was running at `/opt/homebrew/etc/nginx/servers/team1.conf`.

## Certificates

Keys stay in `~/cn-certs` on this Mac. Recreate them only if they are missing:

```bash
cd 03-Source-Code/edge
./make-certs.sh
./share-ca.sh
```

`make-certs.sh` writes `teamCA.key` and `app.key` into `~/cn-certs`. Those files are gitignored.

Public copies already in the repository:

- `edge/ca-public/team1-root-ca.crt`
- `edge/ca-public/app.crt`
- `edge/ca-public/app.csr`
- `edge/ca-public/app.ext`

## nginx

```bash
cd 03-Source-Code/edge
./setup-nginx.sh
brew services start nginx
```

The config expects:

- `/Users/gouravtanwar/cn-certs/app.crt`
- `/Users/gouravtanwar/cn-certs/app.key`

Upstreams are `10.7.4.38:3001` and `10.7.17.154:3002`.

## Trust the CA on this Mac

```bash
cd 03-Source-Code/common
./trust-ca.sh
```
