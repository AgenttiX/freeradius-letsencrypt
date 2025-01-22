#!/usr/bin/env bash
set -eu

if [ "${EUID}" -ne 0 ]; then
   echo "This script should be run as root."
   exit 1
fi

CONF_DIR="/etc/freeradius/3.0"
CERTS_DIR="${CONF_DIR}/certs"
CERT_FILE="${CERTS_DIR}/cert.pem"
PRIVKEY_FILE="${CERTS_DIR}/privkey.pem"

if [ -f "${CERT_FILE}" ]; then
  echo "Server certificate:"
  openssl x509 -noout -text -in "${CERT_FILE}"
  echo "Server certificate fingerprint: (you can verify this on a Windows client with \"netsh wlan show wlanreport\")"
  openssl x509 -noout -fingerprint -in "${CERT_FILE}"
  echo "Server certificate modulus: (should match that of the private key)"
  openssl x509 -modulus -noout -in "${CERT_FILE}" | openssl md5
else
  echo "The server certificate was not (yet) found."
fi

if [ -f "${PRIVKEY_FILE}" ]; then
  echo "Private key status:"
  openssl rsa -check -noout -in "${PRIVKEY_FILE}"
  echo "Private key modulus (should match that of the server certificate):"
  openssl rsa -modulus -noout -in "${PRIVKEY_FILE}" | openssl md5
else
  echo "The private key was not (yet) found."
fi
