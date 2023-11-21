# FreeRADIUS with a Let's Encrypt certificate

## Client settings for Let's Encrypt + PEAP-MSCHAPv2

### Android
- Security: WPA/WPA2/WPA3-Enterprise
- EAP method: PEAP
- Phase 2 authentication: MSCHAPv2
- CA certificate: Use system certificates
- Online certificate status: Request certificate status
  - This means enabling Online Certificate Status Protocol (OCSP)
  - Later when it works you should set it as strict as possible
- Domain: FQDN of the RADIUS server, e.g. wifi.your-domain.com
- Identity: your-username@your-domain.com
- Anonymous identity: anonymous@your-domain.com


### Kubuntu / KDE
- Security: WPA/WPA2 Enterprise
- Authentication: Protected EAP (PEAP)
- Anonymous identity: anonymous@your-domain.com
- Domain: FQDN of the RADIUS server, e.g. wifi.your-domain.com
- CA certificate: Let's Encrypt root certificate from [here](https://letsencrypt.org/certificates/)
- PEAP version: Automatic
- Inner authentication: MSCHAPv2
- Username: your-username@your-domain.com


### Windows
So far I haven't been able to get Windows to properly accept the Let's Encrypt root certificate,
which is required by this configuration.

The group policy folder for Wi-Fi networks is
`Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Wireless Network (IEEE 802.11) Policies`.
Right-click it and select `Create A New Wireless Network Policy for Windows Vista and Later Releases`.
Name the policy as you like, e.g. with your company name, and add profiles for each Wi-Fi network.
Note that edits to the Wi-Fi networks may not be propagated to clients unless you first delete the profile
and then run `gpupdate /force` on all clients before adding it again.
The settings on an individual client are equally painful to manage, as
[Windows does not allow editing an existing connection](https://social.technet.microsoft.com/Forums/en-US/37bc5304-4dcf-4615-a079-a3dbf56a7162/how-do-i-change-a-wpa2enterprise-wireless-networks-saved-password-in-windows-10-without-first).
In the group policy, set these settings:

In the group policy, set these settings:
- For WPA2
  - Authentication: WPA2-Enterprise
  - Encryption: Try first with AES-CCMP if you can't explicily enable AES-GCMP in the settings of your Wi-Fi network.
    AES-GCMP is faster than AES-CCMP but not supported by e.g. UniFi.
- For WPA3
  - Authentication: WPA3-Enterprise 192 Bits
  - Encryption: AES-GCMP-256
- Authentication method: `Microsoft: Protected EAP (PEAP)`
- Properties
  - Verify the server's identity by validating the certificate: yes
  - Connect to these servers: The FQDN of your certificate
  - Trusted Root Certification Authorities: Let's Encrypt root certificate authority from [here](https://letsencrypt.org/certificates/)
  - Notifications before connecting: Don't ask user to authorize new servers or trusted CAs
  - Authentication method: Secured password (EAP-MSCHAP v2)
    - Automatically use my Windows logon name and password (and domain if any): Enable this for domain-joined machines and disable if configuring an individual non-domain-joined machine.
- Authentication mode: User authentication

Windows is
[very strict](https://docs.microsoft.com/en-US/troubleshoot/windows-server/networking/certificate-requirements-eap-tls-peap)
about the certificates it accepts.
If you get other clients working, but not Windows,
then the problem is likely in the certificate or its configuration.
Further details are available in the comments of `/etc/freeradius/3.0/mods-available/eap`
(or .bak if you've already run `setup_freeradius.sh`).

These settings are painful to debug, as any error in the configuration can result in the message
"Can't connect to this network".
However, some helpful information can be found at
`Event Viewer -> Applications and Services Logs -> Microsoft -> Windows -> WLAN-AutoConfig -> Operational`.


## Client settings for EAP-TLS (client certificates)

### Android
Not tested yet, as distributing certificates from Active Directory to non-Windows clients is a pain.

### Kubuntu / KDE
Not tested yet, as distributing certificates from Active Directory to non-Windows clients is a pain.
Theoretically it should be possible with
[Samba Certificate Auto Enrollment](https://wiki.samba.org/index.php/Certificate_Auto_Enrollment), though,
but it's a pain to set up.

### Windows
You can use certificate auto enrollment to deploy the certificates from Active Directory Certificate Services to clients automatically.
The exact settings are beyond the scope of these instructions, but you can use the tutorials below as a reference.
I recommend storing the client certificate on a TPM and enabling TPM key attestation.
- [Tutorial: Deploy Always On VPN - Configure Certificate Authority templates](https://learn.microsoft.com/en-us/windows-server/remote/remote-access/tutorial-aovpn-deploy-create-certificates)
- [Configure the Workstation Authentication Certificate Template](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/configure-the-workstation-authentication-certificate-template)
- [Using certificates in Remote Desktop Services](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/dn781533(v=ws.11))

Set the group policy settings as for the EAP-MSCHAPv2 authentication, but with these different settings for authentication:
- Authentication method: `Microsoft: Smart Card or other certificate`
- Authentication mode: `User or Computer authentication`
  (Or only one of these, depending on whether you are distributing user and/or computer certificates to clients.)
- Properties
  - When connecting
    - Use a certificate on this computer: yes
    - Use simple certificate selection: yes
    - Advanced: select only your own CA
  - Verify the server's identity by validating the certificate: yes
    - Connect these servers: FQDN of the RADIUS server, as in the CN of the server certificate
    - Trusted Root Certification Authorities: Select only your own CA
    - Don't prompt user to authorize new servers or trusted certification authorities: yes
      (unless you're debugging issues)


## Server certificate setup for EAP-TLS
If you're going to use EAP-TLS with domain certificates in addition to the EAP-MSCHAPv2,
you have to create a certificate for the RADIUS server.
Set up a NPS/RADIUS certificate template using these
[NPS server instructions](https://learn.microsoft.com/en-us/windows-server/remote/remote-access/tutorial-aovpn-deploy-create-certificates#create-the-nps-server-authentication-template)
If you can, use Samba Certificate Auto Enrollment to obtain the server certificate from the CA to the RADIUS server.
If not, the certificate has to be deployed manually.
This requires the following exceptions to the Microsoft instructions.
- Subject Name -> Supply in the request
  - With this you can request the certificate on a domain member and then transfer it to the RADIUS server.
- Request Handling -> Allow private key to be exported
  - This is necessary to export the private key from the CA to the RADIUS server.

When you have set up the certificate template,
request a certificate for the RADIUS server.
If you are requesting it on another computer:
- You have to accept the pending request on the CA at
  Certification Authority (Local) -> Pending Requests
- When requesting the certificate, go to the Subject tab and add the FQDN
  (e.g. your-server.your-domain.com) of the RADIUS server as Subject name -> Common name
- Once you have accepted the request, you can find the private key at
  Certificates (Local Computer) -> Certificate Enrollment Requests -> Certificates.
  If this certificate is not signed by the correct CA, you can find the signed public certificate at
  Certification Authority (Local) -> your CA -> Issued Certificates.
- Export the certificate(s) with right-click -> All tasks -> Export...
- When exporting the certificate that has the private key,
  select to export the private key as well.
- (Select "Export all extended properties", just in case.)
- Use AES256-SHA256 encryption with a password.
- Move the certificate file to the RADIUS server.
- Extract the .pfx package with:
  - `openssl pkcs12 -in RADIUS_SERVER.pfx -nocerts -out privkey.pem -nodes`
  - If the pfx package also has the correctly signed public key
    (may not be the case with a manually approved Active Directory certificate):
    `openssl pkcs12 -in RADIUS_SERVER.pfx -nokeys -out cert.pem`
- Place the files in e.g. `/etc/freeradius/3.0/certs/`

If you get the error 2148204809 or 0x800B0109,
ensure that the server certificate is signed by the correct CA.
The Active Directory Certificate Authority can sometimes create certificates
with an invalid issuer that is the CN of the certificate instead fo the correct CA.

When debugging errors with the configuration,
see /var/log/freeradius/radius.log on the server,
and "netsh wlan show wlanreport" on the Windows client.


## Server setup
- Join the server to the domain with Samba as usual
  (see the instructions at [agx.fi](https://agx.fi/it/active_directory.html))
- Copy the public domain CA certificate to `/usr/local/share/ca-certificates/CA_NAME.cer`
- Clone this repo and modify its config files as needed
- Set up the server certificate with the instructions below
- Run `setup_freeradius.sh`
- Get a Let's Encrypt certificate using Certbot


## WPA3
[Both WPA2-personal and WPA2-enterprise](https://security.stackexchange.com/questions/171451/is-wpa2-enterprise-affected-by-the-krack-attack)
are vulnerable to sophisticated attaks such as
[KRACK](https://www.krackattacks.com/).
To mitigate against this, keep all your devices up to date, or simply switch to WPA3.

When deciding whether to use WPA2-enterprise or WPA3-enterprise,
note that the latter is only compatible with new hardware and software.
Due to the amount of bugs the implementations, you should first test that WPA2
works and only after that upgrade the network to WPA3.
- [Android 10 or later](https://source.android.com/docs/core/connect/wifi-wpa3-owe) (with WPA3-enabled hardware)
- [Intel Wireless-AC 9260, AX200 or later](https://www.intel.com/content/www/us/en/support/articles/000054783/wireless.html)
- [How do we make WPA3 work with Intel® Dual Band Wireless-AC 8260?](https://www.reddit.com/r/intel/comments/rpn8od/how_do_we_make_wpa3_work_with_intel_dual_band/)


## Sources
The scripts and configuration in this repo are based on these instructions:
- [Setting up Samba as a Domain Member](https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Domain_Member)
- [FreeRADIUS Active Directory Integration HOWTO](https://wiki.freeradius.org/guide/freeradius-active-directory-integration-howto)
- [Use Let’s Encrypt Certificates with FreeRADIUS](https://framebyframewifi.net/2017/01/29/use-lets-encrypt-certificates-with-freeradius/)
- [Letsencrypt with Apache and Freeradius](https://www.nico-maas.de/?p=1217)
- [FreeRadius EAP-TLS configuration](https://wiki.alpinelinux.org/wiki/FreeRadius_EAP-TLS_configuration)
- [Freeradius affected by Let's Encrypt Certificate Expiry](https://www.reddit.com/r/sysadmin/comments/pyv7sa/freeradius_affected_by_lets_encrypt_certificate/)
- [Android devices with DoT configured; interaction with new default chain](https://community.letsencrypt.org/t/android-devices-with-dot-configured-interaction-with-new-default-chain/161020)
