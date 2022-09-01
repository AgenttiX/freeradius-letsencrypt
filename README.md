# FreeRADIUS with a Let's Encrypt certificate

TODO: Android and Linux clients work,
but Windows doesn't when using the log-in credentials,
unless certificate validation is disabled.
Therefore, there is probably an issue with the certificate.

## Instructions
- Join the server to the domain with Samba as usual
  (see the instructions at [agx.fi](https://agx.fi/it/active_directory.html))
- Modify the config files in this repo as needed
- Run `setup_freeradius.sh`

## Client settings

### Android
- Security: WPA/WPA2/WPA3-Enterprise
- EAP method: PEAP
- Phase 2 authentication: MSCHAPV2
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
The group policy folder for Wi-Fi networks is
`Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Wireless Network (IEEE 802.11) Policies`.
Right-click it and select `Create A New Wireless Network Policy for Windows Vista and Later Releases`.
Name the policy as you like, e.g. with your company name, and add profiles for each Wi-Fi network.
Note that edits to the Wi-Fi networks may not be propagated to clients unless you first delete the profile
and then run `gpupdate /force` on all clients before adding it again.
The settings on an individual client are equally painful to manage, as
[Windows does not allow editing an existing connection](https://social.technet.microsoft.com/Forums/en-US/37bc5304-4dcf-4615-a079-a3dbf56a7162/how-do-i-change-a-wpa2enterprise-wireless-networks-saved-password-in-windows-10-without-first).
In the profile, set these settings:
- For WPA2
  - Authentication: WPA2-Enterprise
  - Encryption: Try first with AES-CCMP if you can't explicily enable AES-GCMP in the settings of your Wi-Fi network.
    AES-GCMP is faster than AES-CCMP but not supported by e.g. UniFi.
- For WPA3
  - Authentication: WPA3-Enterprise 192 Bits
  - Encryption: AES-GCMP-256
- Authentication method: Microsoft: Protected EAP (PEAP)
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
