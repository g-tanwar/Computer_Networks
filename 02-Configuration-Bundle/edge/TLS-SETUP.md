# TLS setup

Team1 Local CA was created on Mac 2 with OpenSSL 3. The CA certificate was then trusted on Mac 1, Mac 2, and Mac 3. nginx uses the server certificate to terminate HTTPS for `app.team1.test` and `api.team1.test`.

Private key files (`teamCA.key` and `app.key`) were written to `~/cn-certs` on Mac 2 with mode `600`. They are not in this repository. The public material is in [ca-public](../../03-Source-Code/edge/ca-public).

## Certificate facts

These fields were read from the certificates on Mac 2.

| | Team1 Local CA | Server certificate |
| --- | --- | --- |
| File | `03-Source-Code/edge/ca-public/team1-root-ca.crt` | `03-Source-Code/edge/ca-public/app.crt` |
| Subject | `CN=Team1 Local CA` | `CN=app.team1.test` |
| Issuer | `CN=Team1 Local CA` | `CN=Team1 Local CA` |
| Public key | RSA 2048 | RSA 2048 |
| Signature | sha256WithRSAEncryption | sha256WithRSAEncryption |
| Not before | 3 Oct 2026 20:07:10 GMT | 3 Oct 2026 20:09:10 GMT |
| Not after | 5 Jan 2029 20:07:10 GMT | 5 Jan 2029 20:09:10 GMT |
| Basic constraints | `CA:TRUE` | `CA:FALSE` |
| Key usage | Certificate Sign, CRL Sign | Digital Signature, Key Encipherment |
| Extended key usage | — | TLS Web Server Authentication |
| SAN | — | `DNS:app.team1.test`, `DNS:api.team1.test` |

`openssl verify -CAfile 03-Source-Code/edge/ca-public/team1-root-ca.crt 03-Source-Code/edge/ca-public/app.crt` succeeds against this bundle. The same CA file is also stored as `02-Configuration-Bundle/edge/team1-root-ca.crt`.

## 1. Create the local CA

The CA is a self-signed root. `basicConstraints=CA:TRUE` and `keyUsage=keyCertSign,cRLSign` mark it as a certificate authority. The lifetime used at creation was 825 days.

```bash
OPENSSL="$(brew --prefix openssl@3)/bin/openssl"
mkdir -p ~/cn-certs
cd ~/cn-certs

$OPENSSL req -x509 -new -newkey rsa:2048 -nodes \
  -keyout teamCA.key \
  -out teamCA.crt \
  -days 825 \
  -sha256 \
  -subj "/CN=Team1 Local CA" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign"
```

`teamCA.key` stays on the machine that signs certificates. Do not copy it into Git.

## 2. Create the server CSR

The CSR subject is the primary hostname. The SAN list is applied later, at signing time, because a CSR subject alone does not carry the second name.

```bash
$OPENSSL req -new -newkey rsa:2048 -nodes \
  -keyout app.key \
  -out app.csr \
  -subj "/CN=app.team1.test"
```

`app.key` is the key nginx loads. It stays in `~/cn-certs` on Mac 2.

## 3. SAN configuration

`03-Source-Code/edge/ca-public/app.ext` is the extension file that was used:

```
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:app.team1.test,DNS:api.team1.test
```

`serverAuth` limits the certificate to TLS server authentication. Both hostnames must appear in `subjectAltName`. Clients check the SAN list, not only the common name.

## 4. Sign the server certificate

```bash
$OPENSSL x509 -req \
  -in app.csr \
  -CA teamCA.crt \
  -CAkey teamCA.key \
  -CAcreateserial \
  -out app.crt \
  -days 825 \
  -sha256 \
  -extfile app.ext
```

`-CAcreateserial` writes `teamCA.srl` beside the CA. That serial file is local signing state and is not included here.

## 5. Trust teamCA.crt

On each of the three Macs the CA was added as a trusted root in the System keychain:

```bash
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  ~/cn-certs/teamCA.crt
```

Confirm it is present:

```bash
security find-certificate -c "Team1 Local CA" /Library/Keychains/System.keychain
```

Distribute `teamCA.crt` only. The CA private key is not required on Mac 1 or Mac 3.

## 6. Certificate verification

nginx on Mac 2 points at the certificate and key:

```
ssl_certificate     /Users/gouravtanwar/cn-certs/app.crt;
ssl_certificate_key /Users/gouravtanwar/cn-certs/app.key;
ssl_protocols       TLSv1.2 TLSv1.3;
```

From a Mac that trusts the CA, and whose resolver is `10.7.17.154`:

```bash
curl -v https://app.team1.test/api/status
openssl x509 -in 03-Source-Code/edge/ca-public/app.crt -noout -subject -issuer -ext subjectAltName
openssl verify -CAfile 03-Source-Code/edge/ca-public/team1-root-ca.crt 03-Source-Code/edge/ca-public/app.crt
```

The lab check succeeded without `curl -k`. The client accepted the chain because Team1 Local CA was in the System keychain and the requested name was in the SAN list.

## 7. TLS 1.2 and TLS 1.3

nginx allows both versions (`ssl_protocols TLSv1.2 TLSv1.3`). HTTP/2 is enabled on the same listener (`http2 on`).

**TLS 1.3** is what a current client negotiates. The visible handshake is ClientHello (with SNI `app.team1.test`) and ServerHello. The Certificate message and the HTTP request are encrypted. The final live test negotiated TLS 1.3 between `10.7.22.54` and `10.7.26.232:443`. The saved Wireshark screenshots are older: they show Application Data between the capture-time addresses `10.7.4.38` and `10.7.18.35`.

**TLS 1.2** leaves the Certificate handshake message in the clear. A forced TLS 1.2 capture was used to read the issuer `Team1 Local CA` and the subject `app.team1.test`. The same certificate and the same CA are used for both versions. The difference is what the capture can display, not which name the certificate covers.

To ask curl for one version during a capture:

```bash
curl -v --tlsv1.2 --tls-max 1.2 https://app.team1.test/api/status
curl -v --tlsv1.3 --tls-max 1.3 https://app.team1.test/api/status
```
