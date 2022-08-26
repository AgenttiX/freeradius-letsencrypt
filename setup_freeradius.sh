#!/usr/bin/env bash
set -e

if [ "${EUID}" -ne 0 ]; then
   echo "This script should be run as root."
   exit 1
fi

apt-get update
apt-get install freeradius

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
$CONF_DIR="/etc/freeradius/3.0"
$CLIENTS_CONF="${CONF_DIR}/clients.conf"
$MODS_AVAILABLE="${CONF_DIR}/mods-available"

if [ ! -f "${CLIENTS_CONF}.bak" ]; then
  cp "${CLIENTS_CONF}" "${CLIENTS_CONF}.bak"
fi

echo "Copying clients.conf"
cp "${SCRIPT_DIR}/clients.conf" "${CONF_DIR}"
chown root:root "${CLIENTS_CONF}"
chmod 600 "${CLIENTS_CONF}"

echo "Copying module configs"
if [ ! -f "${CLIENTS_CONF}/eap.bak" ]; then
  cp "${CLIENTS_CONF}/eap" "${CLIENTS_CONF}/eap.bak"
fi
if [ ! -f "${CLIENTS_CONF}/mschap.bak" ]; then
  cp "${CLIENTS_CONF}/mschap" "${CLIENTS_CONF}/mschap.bak"
fi
cp "${SCRIPT_DIR}/mods-available/*" "${MODS_AVAILABLE}"
chown root:root -R "${MODS_AVAILABLE}"
chmod 600 "${MODS_AVAILABLE}/*"

freeradius -C -X

ufw allow ssh
ufw allow radius
ufw enable
