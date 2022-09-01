#!/usr/bin/env sh
set -e

echo "Configuring permissions for FreeRADIUS to access Let's encrypt certificates."
chgrp freerad "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/privkey.pem"
chgrp freerad -R "/etc/letsencrypt/archive/${CERTBOT_DOMAIN}"
chmod 755 "/etc/letsencrypt/archive"
chmod 750 "/etc/letsencrypt/archive/${CERTBOT_DOMAIN}"
chmod 640 "/etc/letsencrypt/archive/${CERTBOT_DOMAIN}"/*
chmod 755 "/etc/letsencrypt/live"
chmod 640 "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/privkey.pem"
