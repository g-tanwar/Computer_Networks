#!/bin/bash
# Create Team1 Local CA and the server certificate on Mac 2.
# Private keys are written to ~/cn-certs and are not copied into git.
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"

OPENSSL="${OPENSSL:-$(brew --prefix openssl@3)/bin/openssl}"
mkdir -p "${CERT_DIR}"
cd "${CERT_DIR}"

"${OPENSSL}" req -x509 -new -newkey rsa:2048 -nodes \
  -keyout teamCA.key \
  -out teamCA.crt \
  -days 825 \
  -sha256 \
  -subj "/CN=${CA_CN}" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign"

"${OPENSSL}" req -new -newkey rsa:2048 -nodes \
  -keyout app.key \
  -out app.csr \
  -subj "/CN=${APP_HOST}"

cat > app.ext <<EOF
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:${APP_HOST},DNS:${API_HOST}
EOF

"${OPENSSL}" x509 -req \
  -in app.csr \
  -CA teamCA.crt \
  -CAkey teamCA.key \
  -CAcreateserial \
  -out app.crt \
  -days 825 \
  -sha256 \
  -extfile app.ext

chmod 600 teamCA.key app.key
echo "Public certificates:"
ls -l teamCA.crt app.crt app.csr app.ext
echo "Private keys stay in ${CERT_DIR} and must not be committed."
"${OPENSSL}" verify -CAfile teamCA.crt app.crt
