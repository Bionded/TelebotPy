#!/bin/bash
########################################
#dependies: pwgen sshpass
#
#
#
#
############################################
echo "Введите имя"
read FIRSTNAME
echo "Введите Фамилию"
read SECONDNAME
PASS=$(pwgen -n 12 1)
TRANSFN=$(echo ${FIRSTNAME,,} |sed 'y/абвгджзийклмнопрстуфхыэе/abvgdjzijklmnoprstufhyee/'|sed 's/[ьъ]//g; s/ё/yo/g; s/ц/ts/g; s/ч/ch/g; s/ш/sh/g; s/щ/sh/g; s/ю/yu/g; s/я/ya/g')
TRANSSN=$(echo ${SECONDNAME,,} |sed 'y/абвгджзийклмнопрстуфхыэе/abvgdjzijklmnoprstufhyee/'|sed 's/[ьъ]//g; s/ё/yo/g; s/ц/ts/g; s/ч/ch/g; s/ш/sh/g; s/щ/sh/g; s/ю/yu/g; s/я/ya/g')
SHORTNAME=PF${TRANSFN:0:1}$TRANSSN;
FULLNAME="$SECONDNAME $FIRSTNAME";
mkdir $SHORTNAME-config
echo $SHORTNAME > $SHORTNAME-config/pass.txt
echo $PASS >> $SHORTNAME-config/pass.txt
###################ADCREATE
#sshpass -p Bionded1 ssh -o StrictHostKeyChecking=no ykovrigin@172.20.1.100 Dsadd user "\"CN=$FIRSTNAME $SECONDNAME,OU=Remote_Employees,DC=ui,DC=loc\"" -samid $SHORTNAME -upn $SHORTNAME -pwd $PASS -fn $FIRSTNAME -ln $SECONDNAME -display "\"$FIRSTNAME $SECONDNAME\"" -canchpwd no -pwdneverexpires yes -memberof "\"CN=VPN_Users,CN=Users,DC=ui,DC=loc\""  -disabled no
#echo "Create Active Directory username Done!"

#######################PFSENSECREATE
wget -qO- --keep-session-cookies --save-cookies cookies.txt --no-check-certificate https://217.12.203.61/diag_backup.php | grep "name='__csrf_magic'" | sed 's/.*value="\(.*\)".*/\1/' > csrf.txt
wget -qO- --keep-session-cookies --load-cookies cookies.txt --save-cookies cookies.txt --no-check-certificate --post-data "login=Login&usernamefld=kyy&passwordfld=Bionded1&__csrf_magic=$(cat csrf.txt)" https://217.12.203.61/diag_backup.php  | grep "name='__csrf_magic'" | sed 's/.*value="\(.*\)".*/\1/' > csrf2.txt
wget -qO- --keep-session-cookies --load-cookies cookies.txt --no-check-certificate --post-data "__csrf_magic=$(head -n 1 csrf2.txt)&usernamefld=$SHORTNAME&passwordfld1=$PASS&passwordfld2=$PASS&descr=$FULLNAME&expires=&webguicss=pfSense.css&webguifixedmenu=&webguihostnamemenu=&dashboardcolumns=2&groups%5B%5D=VPNusers&showcert=yes&name=$SHORTNAME-vpn&caref=57b2c517dbca2&keylen=4096&lifetime=365&authorizedkeys=&ipsecpsk=&act=&userid=&privid=&certid=&utype=user&oldusername=&save=Save" https://217.12.203.61/system_usermanager.php?act=new > source1.txt
wget -qO- --keep-session-cookies --load-cookies cookies.txt --no-check-certificate --post-data "__csrf_magic=$(head -n 1 csrf2.txt)" https://217.12.203.61/system_certmanager.php?act=edit > source.txt
IDVPN=$(cat source.txt | grep "system_certmanager.php?act=exp" |tail -n 1 | cut -d '=' -f4 | cut -d '"' -f1)
wget --keep-session-cookies --load-cookies cookies.txt --no-check-certificate --post-data "__csrf_magic=$(head -n 1 csrf2.txt)" "https://217.12.203.61/system_certmanager.php?act=exp&id=$IDVPN" -O $SHORTNAME-config/$SHORTNAME.crt
wget --keep-session-cookies --load-cookies cookies.txt --no-check-certificate --post-data "__csrf_magic=$(head -n 1 csrf2.txt)" "https://217.12.203.61/system_certmanager.php?act=key&id=$IDVPN" -O $SHORTNAME-config/$SHORTNAME.key
rm cookies.txt
rm csrf.txt 
rm csrf2.txt 
rm source.txt 
rm source1.txt 
echo "Create PFsense Cert Done!"
######################Create ovpnFile
echo "dev tun" > $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "persist-tun" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "persist-key" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "cipher AES-256-CBC" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "ncp-ciphers AES-256-GCM:AES-128-GCM" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "auth SHA256" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "tls-client" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "client" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "resolv-retry infinite" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "remote 217.12.203.61 1196 tcp-client" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo 'verify-x509-name "VPNsrvUsers" name' >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "auth-user-pass pass.txt" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "remote-cert-tls server" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "comp-lzo adaptive" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "keepalive 30 900" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "reneg-sec 86400" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "verb 3" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "<ca>" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "-----BEGIN CERTIFICATE-----" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "MIIGZTCCBE2gAwIBAgIBADANBgkqhkiG9w0BAQsFADB/MQswCQYDVQQGEwJVQTEQ" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "MA4GA1UECBMHS2hhcmtpdjEQMA4GA1UEBxMHS2hhcmtpdjETMBEGA1UEChMKUG9s" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "aW1lbnRvcjEjMCEGCSqGSIb3DQEJARYUYWRtaW5AcG9saW1lbnRvci5jb20xEjAQ" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "BgNVBAMTCVZQTi1VU0VSUzAeFw0xNjA4MTYwNzQ3MzhaFw0yNjA4MTQwNzQ3Mzha" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "MH8xCzAJBgNVBAYTAlVBMRAwDgYDVQQIEwdLaGFya2l2MRAwDgYDVQQHEwdLaGFy" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "a2l2MRMwEQYDVQQKEwpQb2xpbWVudG9yMSMwIQYJKoZIhvcNAQkBFhRhZG1pbkBw" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "b2xpbWVudG9yLmNvbTESMBAGA1UEAxMJVlBOLVVTRVJTMIICIjANBgkqhkiG9w0B" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "AQEFAAOCAg8AMIICCgKCAgEAsopVGApoKK/us/JBnoBHwzcb4f7ASl1e2eBoi1PA" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "eAV1HGc7KIf80C4XMwtdSlPcZDE9lSfVwIh+pR3/6FxjO3n1srwY84AJFjaIUqkt" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "qNYy4iDgtUSNPcUNvO1USwyMtq7rLXbkmI1J29GDFG8PLKDhIUzcP77q9ZGMpW3W" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "/AKXLlL344R7zQ3CmJMLxyYUwnSTRC9DkKQXttuy+KtjZynS5X5UjlJ7oChsCoKw" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "dYixgN7i5Ufem/DJMNCaNe6XvgzZmJZUSf5Ig9xhU0R/4wSlSbWwCiGSSXYvZjiJ" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "qVJyZeYsWr17/WOB6O5OLuq26eGEYgeiDmgeoZzCDtMZWTIuhxYXgiilB2xVd6y9" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "WtIBqTv3dfhPgMVhByja/3ygA2H+Dsxu4npoF3H4Te/ds/KHrFKXgztWQNrAZjIL" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "OznnsluWMfMoUwc9GKp09xpaATD8gFk164kcNFjg8qBQODAIlp0TARp5DK3RNu+Q" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "zrZ0l29kEOohk3x6kBvGx72YX4aXVuzjqtMkLud78eww0XhtYMlvL6BUI51+c9nR" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "MY3FI1HQYr5GI+7QXqv1qt9pk68EPPqFaPADixmoUTdUSTrQ5iHwd4MFjcpGYh4P" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "pTugN4kPc2L3xdd8JRtZQ6QK2b0vuUj1GJZOj4xr9QzVBuQ1kjPxu0D40ztJLj/R" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "TVcCAwEAAaOB6zCB6DAdBgNVHQ4EFgQUeGY7S9yZVd4pactQq6Qfc4343tEwgasG" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "A1UdIwSBozCBoIAUeGY7S9yZVd4pactQq6Qfc4343tGhgYSkgYEwfzELMAkGA1UE" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "BhMCVUExEDAOBgNVBAgTB0toYXJraXYxEDAOBgNVBAcTB0toYXJraXYxEzARBgNV" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "BAoTClBvbGltZW50b3IxIzAhBgkqhkiG9w0BCQEWFGFkbWluQHBvbGltZW50b3Iu" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "Y29tMRIwEAYDVQQDEwlWUE4tVVNFUlOCAQAwDAYDVR0TBAUwAwEB/zALBgNVHQ8E" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "BAMCAQYwDQYJKoZIhvcNAQELBQADggIBAKQgnHUJHu71cUQr6BqnaEmZfQm3cv1Z" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "xkhuDAeaeXKmHG5WVFJ0xYTf7TK0d5MhBoA8s1neS0q8eWTYAigE250+JO5OmrYw" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "Jp4UI88kXvjq+PpSbYcHwCREBFK3b+rqkjU3QrbtNndkRCaX8aE4SqFuYu8+yL/s" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "THRrRYkUglfEaElzm6bK4ifeTRTJQSCsnoTw5LqQJBqXLzhs2EXMmdCVtvjqcSJX" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "1gjc/ahFrdawIP+gmlpRMKBlM6TUaGKessVF8avNoszwwaxUCcrXAXskhoLZZocz" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "oXVx85UAxLGAn6W89KI6yLOV0Zk9WiQoA9czVBa0CrEiZ83SkpeEFM6H9d/ALnMK" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "KmrKinHuF2wpbdcr+oJsYRiBhFxMdCjqiFjDJtEzscIYSMli+xOIJ5HbRv0pkQSy" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "v12KAR5/i4y29rprZEba07Y0oGjSnUvCrPnEGQSJQbKnfgitjzvpVoR/VGfRnf1d" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "MLl6zcrnA6YopWazsDGCdojq1ykxMVvQOSv7ekM0TAVMUqRIhEa9XrEBOk5e8+0v" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "1RfT+TWg//8l2JGdI/6nOpnOZASoWztauqUrK+pd+8znxm+fp7YlcHq8pB7CQxsp" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "TFgYu3bM/1fOYKNJFisfn6ZdY45Hnu/K8FUzq4sVz5upQ37XzHN2tJ/bPOTLXUjk" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "amUxuC6NzAS+" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "-----END CERTIFICATE-----" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "</ca>" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "<cert>" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
cat $SHORTNAME-config/$SHORTNAME.crt >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo '</cert>' >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "<key>" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
cat $SHORTNAME-config/$SHORTNAME.key >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "</key>" >> $SHORTNAME-config/$SHORTNAME-config.ovpn
echo "<tls-auth>" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "#" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "# 2048 bit OpenVPN static key" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "#" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "-----BEGIN OpenVPN Static key V1-----" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "4fe6fc0252ce2fd7a43cd84585659839" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "9aa073b5d50f3803afe96e4db29702fb" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "3cd6d336f86ca104fe86fc603e2f7a4d" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "87e0962c1286512bf62c4e46967a83e3" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "81be9c27a4dadbefacf77e12ec9929fc" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "d8fa01f7c9197b1948c2815319838d85" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "5d40dcffcf23944b6362e92c57c2d204" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "bf79d4cf886c3329e84d7871e37fcf2b" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "01be9e5cb1d8d3f14db603586540f534" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "be45122cc1b74d10479579a66de3e088" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "5fb4331f9d546cd299e6cc22e09baae9" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "9386924cedad7496d1e3f82f5844df45" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "14791a6c12f8665a220a706bfb771703" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "886828356277d5332c3ad7f38683da73" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "c4e40311353dd94e11a3e12f06c23d1c" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "924d18f68f052d9663c5f739d407b615" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "-----END OpenVPN Static key V1-----" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "</tls-auth>" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
echo "key-direction 1" >>$SHORTNAME-config/$SHORTNAME-config.ovpn
rm $SHORTNAME-config/$SHORTNAME.key
rm $SHORTNAME-config/$SHORTNAME.crt
echo "Create .ovpn file Done!"