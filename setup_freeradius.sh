#!/usr/bin/env bash
set -eu

if [ "${EUID}" -ne 0 ]; then
   echo "This script should be run as root."
   exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONF_DIR="/etc/freeradius/3.0"
CERTS_DIR="${CONF_DIR}/certs"
CLIENTS_CONF="${CONF_DIR}/clients.conf"
SETTINGS_CONF="${SCRIPT_DIR}/settings.env"
MODS_AVAILABLE="${CONF_DIR}/mods-available"
# SITES_AVAILABLE="${CONF_DIR}/sites-available"

if [ ! -f "${SETTINGS_CONF}" ]; then
  echo "Please create a copy of settings-template.env as settings.env and modify it to match your setup."
  echo "Then run this script again."
  exit 1
fi

if [ ! -f "${CLIENTS_CONF}" ]; then
  echo "Please create a copy of clients-template.conf as clients.conf and modify it to match your setup."
  echo "Then run this script again."
  exit 1
fi

echo "Loading settings from settings.env."
. "${SETTINGS_CONF}"

echo "Installing the required packages."
apt-get update
apt-get remove certbot
apt-get install freeradius snapd wget

# From Certbot installation instructions
# https://certbot.eff.org/instructions?ws=other&os=ubuntufocal&tab=wildcard
echo "Installing Certbot"
snap install --classic certbot
ln -f -s /snap/bin/certbot /usr/bin/certbot
snap set certbot trust-plugin-with-root=ok
# snap install certbot-dns-<PLUGIN>

# Create certbot configuration folder
set +e
certbot
set -e

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
chown freerad:freerad -R "${CERTS_DIR}"
chmod 640 "${MODS_AVAILABLE}"/*

echo "Updating settings to FreeRADIUS configs."
# sed -i "s@RADIUS_IP_RANGE@${RADIUS_IP_RANGE}@g" "${CLIENTS_CONF}"
# sed -i "s@RADIUS_SECRET@${RADIUS_SECRET}@g" "${CLIENTS_CONF}"
sed -i "s@CERTBOT_DOMAIN@${CERTBOT_DOMAIN}@g" "${MODS_AVAILABLE}/eap"
sed -i "s@CA_NAME@${CA_NAME}@g" "${MODS_AVAILABLE}/eap"

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

echo "Reloading system certificates"
update-ca-certificates

echo "Configuring ufw firewall."
ufw allow ssh
ufw allow radius
ufw enable

"${SCRIPT_DIR}/show_certs.sh"

if [ "$(grep -c "^\s*check_crl = yes" "${MODS_AVAILABLE}/eap")" -ge 1 ]; then
  echo "CRL seems to be enabled in the eap config. Configuring cron job for CRL updates."
  if [ "$#" -eq 1 ]; then
    UPDATER="/etc/cron.daily/update_freeradius_crl.sh"
    cp "${SCRIPT_DIR}/update_freeradius_crl.sh" "${UPDATER}"
    sed -i "s@REPLACE_THIS_VALUE@${1}@g" "${UPDATER}"
  else
    echo "The CRL URL was not given. Cannot configure CRL updates. Please give the CRL URL as the first argument."
    echo "The CRL url can be of the form https://ca.yourcompany.com/CertEnroll/Your-Company-CA.crl"
  fi
else
  echo "CRL is not enabled in the eap config. Skipping cron job setup."
fi

systemctl enable freeradius.service
systemctl restart freeradius.service
systemctl status freeradius.service
