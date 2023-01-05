#!/bin/bash

set -euo pipefail

# Our openssl cannot find the system CA certs, so we use mkcert to pull
# Mozilla's CA certs
main() {
  mkdir -p /opt/_internal/ssl/
  curl --retry 3 -o "/opt/_internal/ssl/certifi.pem" -sSL https://mkcert.org/generate/
  rm -rf "${0}"
}

main "$@"
