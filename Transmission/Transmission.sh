#!/bin/bash
echo "========================================================================="
echo "Thanks for using Transmission 2.93 for CentOS Auto-Install Script"
echo "========================================================================="
yum -y install wget xz gcc gcc-c++ m4 make automake libtool gettext openssl-devel pkgconfig perl-libwww-perl perl-XML-Parser curl curl-devel libidn-devel zlib-devel which libevent
service transmissiond stop
mv -f /home/transmission/Downloads /home
rm -rf /home/transmission
rm -rf /usr/share/transmission
mkdir /home/transmission
mv -f /home/Downloads /home/transmission
cd /root
wget -c https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz -O intltool-0.51.0.tar.gz
tar zxf intltool-0.51.0.tar.gz
cd intltool-0.51.0
./configure --prefix=/usr
make -s
make -s install
cd ..
wget -c https://github.com/libevent/libevent/releases/download/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz -O libevent-2.0.22-stable.tar.gz
tar zxf libevent-2.0.22-stable.tar.gz
cd libevent-2.0.22-stable
./configure
make -s
make -s install
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
ln -s /usr/local/lib/libevent-2.0.so.5 /usr/lib/libevent-2.0.so.5
ln -s /usr/local/lib/libevent-2.0.so.5.1.9 /usr/lib/libevent-2.0.so.5.1.9
ln -s /usr/lib/libevent-2.0.so.5 /usr/local/lib/libevent-2.0.so.5
ln -s /usr/lib/libevent-2.0.so.5.1.9 /usr/local/lib/libevent-2.0.so.5.1.9
echo install Transmisson
cd /root
wget -c https://github.com/transmission/transmission-releases/raw/master/transmission-2.93.tar.xz -O transmission-2.93.tar.xz
tar Jxvf transmission-2.93.tar.xz
cd transmission-2.93
./configure --prefix=/usr
make -s
make -s install
useradd -m transmission
passwd -d transmission
cd /root
wget -c https://godanger.github.io/fsbus/Transmission/initd.sh -O /etc/init.d/transmissiond
chmod 755 /etc/init.d/transmissiond
chkconfig --add transmissiond
chkconfig --level 2345 transmissiond on
mkdir -p /home/transmission/Downloads/
chmod g+w /home/transmission/Downloads/
wget -c https://godanger.github.io/fsbus/Transmission/settings.json
mkdir -p /home/transmission/.config/transmission/
mv -f settings.json /home/transmission/.config/transmission/settings.json
chown -R transmission.transmission /home/transmission/
mkdir -p /usr/share/transmission/web/
cd /usr/share/transmission/web/
wget -c https://raw.githubusercontent.com/ronggang/transmission-web-control/master/release/src.tar.gz
rm -f index.html
tar zxf  src.tar.gz
iptables -t nat -F
iptables -t nat -X
iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P POSTROUTING ACCEPT
iptables -t nat -P OUTPUT ACCEPT
iptables -t mangle -F
iptables -t mangle -X
iptables -t mangle -P PREROUTING ACCEPT
iptables -t mangle -P INPUT ACCEPT
iptables -t mangle -P FORWARD ACCEPT
iptables -t mangle -P OUTPUT ACCEPT
iptables -t mangle -P POSTROUTING ACCEPT
iptables -F
iptables -X
iptables -P FORWARD ACCEPT
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t raw -F
iptables -t raw -X
iptables -t raw -P PREROUTING ACCEPT
iptables -t raw -P OUTPUT ACCEPT
service iptables save

echo "The installation is complete!"
echo "Start the service!"
service transmissiond start
echo "OvO!"