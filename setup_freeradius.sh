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
# SITES_AVAILABLE="${CONF_DIR}/sites-available"

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

# echo "Downloading Let's Encrypt root certificate."
# wget -O "${CONF_DIR}/certs/isrgrootx1.pem" "https://letsencrypt.org/certs/isrgrootx1.pem"
# chown freerad:freerad "${CONF_DIR}/certs/isrgrootx1.pem"
# chmod 644 "${CONF_DIR}/certs/isrgrootx1.pem"

echo "Copying Let's encrypt configs."
cp "${SCRIPT_DIR}/letsencrypt/cli.ini" "/etc/letsencrypt/cli.ini"
chown root:root "/etc/letsencrypt/cli.ini"
chmod 755 "/etc/letsencrypt/cli.ini"
cp "${SCRIPT_DIR}/letsencrypt/freeradius_deploy_hook.sh" "/etc/letsencrypt/renewal-hooks/deploy"
chown root:root "/etc/letsencrypt/renewal-hooks/deploy"
chmod 755 "/etc/letsencrypt/renewal-hooks/deploy/freeradius_deploy_hook.sh"

freeradius -C -X

echo "Fixing winbind permissions"
# https://freeradius-users.freeradius.narkive.com/4ScMBwo8/reading-winbind-reply-failed-0xc0000001
usermod -a -G winbindd_priv freerad

echo "Configuring ufw firewall."
ufw allow ssh
ufw allow radius
ufw enable

systemctl enable freeradius.service
systemctl restart freeradius.service
systemctl status freeradius.service

