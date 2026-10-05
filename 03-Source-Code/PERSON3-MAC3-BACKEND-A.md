# Mac 3 — Alok — Backend A, test client, Wireshark

Address `10.7.22.54`, mask `255.255.224.0`, gateway `10.7.0.1`, interface `en0`, MAC `72:36:67:c5:54:98`.

This Mac is the client. There is no fourth Mac.

## Backend A

```bash
cd 03-Source-Code/backend
./start-backend.sh A
```

Listens on port 3001 and sends `X-Backend: A`.

## DNS and CA

```bash
cd 03-Source-Code/common
./use-team-dns.sh
./trust-ca.sh /path/to/team1-root-ca.crt
```

Optional split DNS, instead of changing all Wi-Fi lookups:

```bash
sudo mkdir -p /etc/resolver
sudo cp 02-Configuration-Bundle/dns/etc-resolver-team1.test /etc/resolver/team1.test
```

## Tests

```bash
cd 03-Source-Code/common
./diagnose.sh
./lb-test.sh
./cache-test.sh
dig app.team1.test
curl -v https://app.team1.test/api/status
```

## Capture

Wireshark or tcpdump on `en0`. The lab capture name is `phase1_full_flow.pcapng`.

```bash
./capture.sh
./capture.sh --run
```

`--run` writes `/tmp/phase1_full_flow.pcapng`. Copy that file into `04-Evidence/G-Packet-Capture/` yourself. The script does not put a capture into the repository.
