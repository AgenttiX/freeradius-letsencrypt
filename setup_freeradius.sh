#!/usr/bin/env bash
set -e

if [ "${EUID}" -ne 0 ]; then
   echo "This script should be run as root."
   exit 1
fi

apt-get update
apt-get install freeradius

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONF_DIR="/etc/freeradius/3.0"
CLIENTS_CONF="${CONF_DIR}/clients.conf"
MODS_AVAILABLE="${CONF_DIR}/mods-available"

if [ ! -f "${CLIENTS_CONF}.bak" ]; then
  cp "${CLIENTS_CONF}" "${CLIENTS_CONF}.bak"
fi

echo "Copying clients.conf"
if [ ! -f "${CLIENTS_CONF}.bak" ]; then
  cp "${CLIENTS_CONF}" "${CLIENTS_CONF}.bak"
fi
cp "${SCRIPT_DIR}/clients.conf" "${CLIENTS_CONF}"
chown freerad:freerad "${CLIENTS_CONF}"
chmod 640 "${CLIENTS_CONF}"

echo "Copying module configs."
if [ ! -f "${MODS_AVAILABLE}/eap.bak" ]; then
  cp "${MODS_AVAILABLE}/eap" "${MODS_AVAILABLE}/eap.bak"
fi
if [ ! -f "${MODS_AVAILABLE}/mschap.bak" ]; then
  cp "${MODS_AVAILABLE}/mschap" "${MODS_AVAILABLE}/mschap.bak"
fi
cp -r "${SCRIPT_DIR}/mods-available"/* "${MODS_AVAILABLE}/"
chown freerad:freerad -R "${MODS_AVAILABLE}"
chmod 640 "${MODS_AVAILABLE}"/*

freeradius -C -X

echo "Creating Certbot deploy hook."
cp "${SCRIPT_DIR}/freeradius_deploy_hook.sh" "/etc/letsencrypt/renewal-hooks/deploy"
chmod 755 "/etc/letsencrypt/renewal-hooks/deploy/freeradius_deploy_hook.sh"

echo "Configuring ufw firewall."
ufw allow ssh
ufw allow radius
ufw enable
