# FreeRADIUS with a Let's Encrypt certificate

Instructions
- Join the server to the domain with Samba as usual
  (see the instructions at [agx.fi](https://agx.fi/it/active_directory.html))
- Modify the config files in this repo as needed
- Run `setup_freeradius.sh`

Android settings for connecting to the network
- Security: WPA/WPA2/WPA3-Enterprise
- EAP method: PEAP
- Phase 2 authentication: MSCHAPV2
- CA certificate: Use system certificates
- Online certificate status: Require certificate status
  - This means enabling Online Certificate Status Protocol (OCSP)
- Domain: FQDN of the RADIUS server, e.g. wifi.your-domain.com
- Identity: your-username@your-domain.com
- Anonymous identity: anonymous@your-domain.com

The scripts and configuration in this repo are based on these instructions:
- [Setting up Samba as a Domain Member](https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Domain_Member)
- [FreeRADIUS Active Directory Integration HOWTO](https://wiki.freeradius.org/guide/freeradius-active-directory-integration-howto)
- [Use Let’s Encrypt Certificates with FreeRADIUS](https://framebyframewifi.net/2017/01/29/use-lets-encrypt-certificates-with-freeradius/)
- [Letsencrypt with Apache and Freeradius](https://www.nico-maas.de/?p=1217)
- [FreeRadius EAP-TLS configuration](https://wiki.alpinelinux.org/wiki/FreeRadius_EAP-TLS_configuration)
