#!/usr/bin/env bash
set -e

# TODO: this does yet result in a valid cacrl.pem file.

# Use HTTPS instead of HTTP so that nobody can interfere with the CRL.
# The CA for the HTTPS certificate has to be trusted by the system.
CRL_URL="REPLACE_THIS_VALUE"

CONF_DIR="/etc/freeradius/3.0"
CERTS_DIR="${CONF_DIR}/certs"
CRL="${CERTS_DIR}/ca.crl"
CA_FILES=("/usr/local/share/ca-certificates"/*)
CA_FILE="${CA_FILES[0]}"

wget --ca-certificate "${CA_FILE}" "${CRL_URL}" -O "${CRL}"
cat "${CA_FILE}" "${CRL}" > "${CERTS_DIR}/cacrl.pem"

systemctl restart freeradius.service
