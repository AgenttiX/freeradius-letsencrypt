#!/usr/bin/env bash
set -e

# Show info on the Let's Encrypt certificate.

if [ "${EUID}" -ne 0 ]; then
   echo "This script should be run as root."
   exit 1
fi

echo "chain.pem"
openssl x509 -in /etc/letsencrypt/live/*/chain.pem -noout -text
echo
echo "fullchain.pem"
openssl x509 -in /etc/letsencrypt/live/*/fullchain.pem -noout -text
