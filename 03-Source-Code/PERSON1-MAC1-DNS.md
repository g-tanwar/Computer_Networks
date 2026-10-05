# Mac 1 — Piyush — DNS and Backend B

Address `10.7.17.154`, mask `255.255.224.0`, gateway `10.7.0.1`, interface `en0`, MAC `10:9f:41:c0:9e:e5`.

## DNS

```bash
cd 03-Source-Code/dns
./setup-dns.sh /opt/homebrew/etc/dnsmasq.conf
sudo dnsmasq -C /opt/homebrew/etc/dnsmasq.conf
```

The installed file must keep:

```
listen-address=0.0.0.0
interface=en0
address=/app.team1.test/10.7.26.232
address=/api.team1.test/10.7.26.232
local-ttl=60
```

Query log: `/tmp/dnsmasq.log`.

The wrong-record test is a temporary edit of the live file only:

```bash
./point-record.sh wrong /opt/homebrew/etc/dnsmasq.conf
./point-record.sh restore /opt/homebrew/etc/dnsmasq.conf
```

## Backend B

```bash
cd 03-Source-Code/backend
./start-backend.sh B
```

Listens on port 3002 and sends `X-Backend: B`.

## Trust the CA

Copy `team1-root-ca.crt` from Mac 2, then:

```bash
cd 03-Source-Code/common
./trust-ca.sh /path/to/team1-root-ca.crt
```
