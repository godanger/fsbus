echo "========================================================================="
echo "Thanks for using Transmission 2.92 for CentOS Auto-Install Script"
echo "========================================================================="

echo "Preparing....."
rpm -ivh http://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm;
yum -y install transmission transmission-daemon

cd /root
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
wget -c https://godanger.github.io/fsbus/Transmission/src.zip
rm -f index.html
unzip -o src.zip
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