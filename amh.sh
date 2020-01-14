
#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

clear;
echo '================================================================';
echo ' [LNMP/Nginx] Host - AMH 4.5';
echo '================================================================';

# Get public IP address
get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 api.ip.sb/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}
# VAR ***************************************************************************************
AMHDir='/home/amh_install/';
SysName='';
SysBit='';
Cpunum='';
RamTotal='';
RamSwap='';
InstallModel='';
confirm='';
Domain=$(get_ip);
MysqlPass='';
AMHPass='';
StartDate='';
StartDateSecond='';
PHPDisable='';

# Base_url
GetUrl='https://godanger.github.io/fsbus';

# Version
AMHcurl='curl-7.68.0';
AMSVersion='ams-1.5.0107-02';
AMHVersion='amh-4.5';
ConfVersion='conf';
LibiconvVersion='libiconv-1.16';
Mysql55Version='mysql-5.5.62';
Mysql56Version='mysql-5.6.36';
Mysql57Version='mysql-5.7.18';
Mariadb55Version='mariadb-5.5.50';
Mariadb10Version='mariadb-10.1.16';
Php53Version='php-5.3.29';
Php54Version='php-5.4.45';
Php55Version='php-5.5.38';
Php56Version='php-5.6.40';
Php70Version='php-7.4.1';
NginxVersion='nginx-1.16.1';
OpenSSLVersion='openssl-1.1.1d';
NginxCachePurgeVersion='ngx_cache_purge-2.3';
EchoNginxVersion='echo-nginx-module-0.61';
NgxHttpSubstitutionsFilter='ngx_http_substitutions_filter_module-0.6.4';
PureFTPdVersion='pure-ftpd-1.0.42';

# Function List	*****************************************************************************

function CheckSystem()
{
	[ $(id -u) != '0' ] && echo '[Error] Please use root to install AMH.' && exit;
     egrep -i "debian" /etc/issue /proc/version >/dev/null && SysName='Debian';
    egrep -i "ubuntu" /etc/issue /proc/version >/dev/null && SysName='Ubuntu';
    whereis -b yum | grep '/yum' >/dev/null && SysName='CentOS';
	[ "$SysName" == ''  ] && echo '[Error] Your system is not supported install AMH' && exit;

	SysBit='32' && [ `getconf WORD_BIT` == '32' ] && [ `getconf LONG_BIT` == '64' ] && SysBit='64';
	Cpunum=`cat /proc/cpuinfo | grep 'processor' | wc -l`;
        echo "${SysName} ${SysBit}Bit";
	RamTotal=`free -m | grep 'Mem' | awk '{print $2}'`;
	RamSwap=`free -m | grep 'Swap' | awk '{print $2}'`;
	echo "Server ${Domain}";
	echo "${Cpunum}*CPU, ${RamTotal}MB*RAM, ${RamSwap}MB*Swap";
	echo '================================================================';
	
	RamSum=$[$RamTotal+$RamSwap];
	[ "$SysBit" == '32' ] && [ "$RamSum" -lt '250' ] && \
	echo -e "[Error] Not enough memory install AMH. \n(32bit system need memory: ${RamTotal}MB*RAM + ${RamSwap}MB*Swap > 250MB)" && exit;

	if [ "$SysBit" == '64' ] && [ "$RamSum" -lt '480' ];  then
		echo -e "[Error] Not enough memory install AMH. \n(64bit system need memory: ${RamTotal}MB*RAM + ${RamSwap}MB*Swap > 480MB)";
		[ "$RamSum" -gt '250' ] && echo "[Notice] Please use 32bit system.";
		exit;
	fi;
	
	[ "$RamSum" -lt '600' ] && PHPDisable='--disable-fileinfo';
}

function ConfirmInstall()
{
	echo "[Notice] Confirm Install/Uninstall AMH? please select: (1~3)"
	select selected in 'Install AMH 4.5' 'Uninstall AMH 4.5' 'Exit'; do break; done;
	[ "$selected" == 'Exit' ] && echo 'Exit Install.' && exit;
		
	if [ "$selected" == 'Install AMH 4.5' ]; then
		InstallModel='1';
	elif [ "$selected" == 'Uninstall AMH 4.5' ]; then
		Uninstall;
	else
		ConfirmInstall;
		return;
	fi;



	echo "[Notice] Confirm Install Mysql / Mariadb? please select: (1~5)"
	select DBselect in 'Mysql-5.5' 'Mysql-5.6' 'Mysql-5.7' 'Mariadb-5.5' 'Mariadb-10.1' 'Exit'; do break; done;
	[ "$DBselect" == 'Exit' ] && echo 'Exit Install.' && exit;
		
	if [ "$DBselect" == 'Mysql-5.5' ]; then
	confirm='1' && echo '[OK] Mysql-5.5 installed';
	elif [ "$DBselect" == 'Mysql-5.6' ]; then
	confirm='2' && echo '[OK] Mysql-5.6 installed';
  elif [ "$DBselect" == 'Mysql-5.7' ]; then
  confirm='3' && echo '[OK] Mysql-5.7 installed';
	elif [ "$DBselect" == 'Mariadb-5.5' ]; then
	confirm='4' && echo '[OK] Mariadb-5.5 installed';
	elif [ "$DBselect" == 'Mariadb-10.1' ]; then
	confirm='5' && echo '[OK] Mariadb-10.1 installed';
	else
		ConfirmInstall;
		return;
	fi;
	
	echo "[OK] You Selected: ${DBselect}";
	
	read -p '[Notice] Do you want PHP5.3? : (y/n)' confirm53;
	[ "$confirm53" == 'y' ] && echo '[OK] php5.3 will be installed';
	read -p '[Notice] Do you want PHP5.4? : (y/n)' confirm54;
	[ "$confirm54" == 'y' ] && echo '[OK] php5.4 will be installed';
	read -p '[Notice] Do you want PHP5.5? : (y/n)' confirm55;
	[ "$confirm55" == 'y' ] && echo '[OK] php5.5 will be installed';
	read -p '[Notice] Do you want PHP7.0? : (y/n)' confirm70;
	[ "$confirm70" == 'y' ] && echo '[OK] php7.0 will be installed';
	
}

function InputDomain()
{
	if [ "$Domain" == '' ]; then
		echo '[Error] empty server ip.';
		read -p '[Notice] Please input server ip:' Domain;
		[ "$Domain" == '' ] && InputDomain;
	fi;
	[ "$Domain" != '' ] && echo '[OK] Your server ip is:' && echo $Domain;
}


function InputMysqlPass()
{
	read -p '[Notice] Please input MySQL password:' MysqlPass;
	if [ "$MysqlPass" == '' ]; then
		echo '[Error] MySQL password is empty.';
		InputMysqlPass;
	else
		echo '[OK] Your MySQL password is:';
		echo $MysqlPass;
	fi;
}


function InputAMHPass()
{
	read -p '[Notice] Please input AMH password:' AMHPass;
	if [ "$AMHPass" == '' ]; then
		echo '[Error] AMH password empty.';
		InputAMHPass;
	else
		echo '[OK] Your AMH password is:';
		echo $AMHPass;
	fi;
}


function Timezone()
{
    rm -rf /etc/localtime;
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime;

    echo '[ntp Installing] ******************************** >>';
    [ "$SysName" == 'CentOS' ] && yum install -y ntp || apt-get install -y ntpdate;
    ntpdate -u pool.ntp.org;
    StartDate=$(date);
    StartDateSecond=$(date +%s);
    echo "Start time: ${StartDate}";
}


function CloseSelinux()
{
    [ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config;
    setenforce 0 >/dev/null 2>&1;
}

function DeletePackages()
{
    if [ "$SysName" == 'CentOS' ]; then
        yum -y remove httpd;
        yum -y remove php;
        yum -y remove mysql-server mysql;
        yum -y remove php-mysql;
    else
        apt-get --purge remove nginx
        apt-get --purge remove mysql-server;
        apt-get --purge remove mysql-common;
        apt-get --purge remove php;
    fi;
}

function InstallBasePackages()
{
    if [ "$SysName" == 'CentOS' ]; then
        echo '[yum-fastestmirror Installing] ************************************************** >>';
        yum -y install yum-fastestmirror;

        cp /etc/yum.conf /etc/yum.conf.lnmp
        sed -i 's:exclude=.*:exclude=:g' /etc/yum.conf
        for packages in gcc gcc-c++ ncurses-devel libxml2-devel openssl-devel libjpeg-devel libpng-devel autoconf pcre-devel libtool-libs freetype-devel gd zlib-devel zip unzip wget crontabs iptables file bison cmake patch mlocate flex diffutils automake make  readline-devel git glibc-devel glibc-static glib2-devel  bzip2-devel gettext-devel libcap-devel logrotate ftp openssl expect; do 
            echo "[${packages} Installing] ************************************************** >>";
            yum -y install $packages; 
        done;
        mv -f /etc/yum.conf.lnmp /etc/yum.conf;
    else
        apt-get remove -y apache2 apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-doc apache2-mpm-worker mysql-client mysql-server mysql-common php;
        killall apache2;
        apt-get update;
        for packages in build-essential gcc g++ git git-core cmake make ntp logrotate automake patch autoconf autoconf2.13 re2c wget flex cron libzip-dev libc6-dev rcconf bison cpp binutils unzip tar bzip2 libncurses5-dev libncurses5 libtool libevent-dev libpcre3 libpcre3-dev libpcrecpp0 libssl-dev zlibc openssl libsasl2-dev libxml2 libxml2-dev libltdl3-dev libltdl-dev zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libglib2.0-0 libglib2.0-dev libpng3 libfreetype6 libfreetype6-dev libjpeg62 libjpeg62-dev libjpeg-dev libpng-dev libpng12-0 libpng12-dev libcurl3 libpq-dev libpq5 gettext libcurl4-gnutls-dev  libcurl4-openssl-dev libcap-dev ftp openssl expect; do
            echo "[${packages} Installing] ************************************************** >>";
            apt-get install -y $packages --force-yes;apt-get -fy install;apt-get -y autoremove; 
        done;
    fi;
}

function Installcurl()
{
if [ "$SysName" == 'CentOS' ]; then
echo "[${Installcurl} Installing] ************************************************** >>";
   yum -y install gcc gcc-c++;
   mkdir -p $AMHDir/conf;
   mkdir -p $AMHDir/packages;
   mkdir -p $AMHDir/packages/untar;
   chmod +Rw $AMHDir/packages;
   cd $AMHDir/packages;
   Downloadfile "${AMHcurl}.tar.gz" "https://curl.haxx.se/download/${AMHcurl}.tar.gz";
   tar -zxf $AMHDir/packages/$AMHcurl.tar.gz -C $AMHDir/packages/untar;
   cd $AMHDir/packages/untar/$AMHcurl;
   ./configure --prefix=/usr/local/curl;
   make -j $Cpunum;
   make install;
   cd /root;
   rm -rf $AMHDir/packages/untar/$AMHcurl.tar.gz;
   rm -rf $AMHDir/packages/untar/$AMHcurl;
else
   echo "[${Installcurl} Installing] ************************************************** >>";
   apt-get install -y gcc g++ cmake make;
   Downloadfile "${AMHcurl}.tar.gz" "https://curl.haxx.se/download/${AMHcurl}.tar.gz";
   tar -zxf $AMHDir/packages/$AMHcurl.tar.gz -C $AMHDir/packages/untar;
   cd $AMHDir/packages/untar/$AMHcurl;
   ./configure --prefix=/usr/local/curl;
    make -j $Cpunum;
    make install;
    #rm -rf $AMHDir/packages/untar/$AMHcurl.tar.gz;
	#rm -rf $AMHDir/packages/untar/$AMHcurl;
 fi;
}

function Downloadfile()
{
	randstr=$(date +%s);
	cd $AMHDir/packages;

	if [ -s $1 ]; then
		echo "[OK] $1 found.";
	else
		echo "[Notice] $1 not found, download now......";
		if ! wget -c --tries=3 ${2}?${randstr} ; then
			echo "[Error] Download Failed : $1, please check $2 ";
			exit;
		else
			mv ${1}?${randstr} $1;
		fi;
	fi;
}

function InstallReady()
{
	mkdir -p $AMHDir/conf;
	mkdir -p $AMHDir/packages/untar;
	chmod +Rw $AMHDir/packages;

	mkdir -p /root/amh/;
	chmod +Rw /root/amh;

	groupadd www;
  useradd www -g www -M -s /sbin/nologin;

  groupadd mysql;
	useradd -s /sbin/nologin -g mysql mysql;
    
	cd $AMHDir/packages;
	wget ${GetUrl}/${ConfVersion}.zip;
	unzip ${ConfVersion}.zip -d $AMHDir/conf;
}


# Install Function  *********************************************************

function Uninstall()
{
	amh host list 2>/dev/null;
	echo -e "\033[41m\033[37m[Warning] Please backup your data first. Uninstall will delete all the data!!! \033[0m ";
	read -p '[Notice] Backup the data now? : (y/n)' confirmBD;
	[ "$confirmBD" != 'y' -a "$confirmBD" != 'n' ] && exit;
	[ "$confirmBD" == 'y' ] && amh backup;
	echo '=============================================================';

	read -p '[Notice] Confirm Uninstall(Delete All Data)? : (y/n)' confirmUN;
	[ "$confirmUN" != 'y' ] && exit;
	amh mysql stop 2>/dev/null;
	amh php stop 2>/dev/null;
	amh nginx stop 2>/dev/null;

	killall nginx;
	killall mysqld;
	killall pure-ftpd;
	killall php-cgi;
	killall php-fpm;

	[ "$SysName" == 'CentOS' ] && chkconfig amh-start off || update-rc.d -f amh-start remove;
	rm -rf /etc/init.d/amh-start;
	rm -rf /usr/local/curl/;
	rm -rf /usr/local/libiconv;
	rm -rf /usr/local/src/$OpenSSLVersion;
	rm -rf /usr/local/src/$NginxCachePurgeVersion;
	rm -rf /usr/local/src/$EchoNginxVersion;
	rm -rf /usr/local/src/$NgxHttpSubstitutionsFilter;
	rm -rf /usr/local/nginx/ ;
	#rm -rf /usr/local/include/boost/;
	for line in `ls /root/amh/modules`; do
		amh module $line uninstall;
	done;
	rm -rf /usr/local/mysql/ /etc/my.cnf  /etc/ld.so.conf.d/mysql.conf /usr/bin/mysql /var/lock/subsys/mysql /var/spool/mail/mysql;
	rm -rf /home/mysqldata;
	rm -rf /usr/local/php/ /usr/local/php5.3/ /usr/local/php5.4/ /usr/local/php5.5/ /usr/local/php7.0/ /usr/lib/php /etc/php.ini /etc/php.d /usr/local/zend;
	rm -rf /home/wwwroot/;
	rm -rf /home/proxyroot/;
	rm -rf /etc/pure-ftpd.conf /etc/pam.d/ftp /usr/local/sbin/pure-ftpd /etc/pureftpd.passwd /etc/amh-iptables;
	rm -rf /etc/logrotate.d/nginx /root/.mysqlroot;
	rm -rf /root/amh /bin/amh;
	rm -rf $AMHDir;
	rm -f /usr/bin/{mysqld_safe,myisamchk,mysqldump,mysqladmin,mysql,nginx,php-fpm,phpize,php};

	echo '[OK] Successfully uninstall AMH.';
	exit;
}

function InstallLibiconv()
{
	echo "[${LibiconvVersion} Installing] ************************************************** >>";
	Downloadfile "${LibiconvVersion}.tar.gz" "http://ftp.gnu.org/pub/gnu/libiconv/${LibiconvVersion}.tar.gz";
	rm -rf $AMHDir/packages/untar/$LibiconvVersion;
	echo "tar -zxf ${LibiconvVersion}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$LibiconvVersion.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /usr/local/libiconv ]; then
		cd $AMHDir/packages/untar/$LibiconvVersion;
    sed -i 's@_GL_WARN_ON_USE (gets@//_GL_WARN_ON_USE (gets@' ./srclib/stdio.in.h;
    sed -i 's@gets is a security@@' ./srclib/stdio.in.h;
		./configure --prefix=/usr/local/libiconv;
		make;
		make install;
		echo "[OK] ${LibiconvVersion} install completed.";
	else
		echo '[OK] libiconv is installed!';
	fi;
}



function InstallOpenSSL()
{
	echo "[${OpenSSLVersion} Installing] ************************************************** >>";
	Downloadfile "${OpenSSLVersion}.tar.gz" "https://www.openssl.org/source/${OpenSSLVersion}.tar.gz";
	rm -rf $AMHDir/packages/untar/$OpenSSLVersion;
	echo "tar -zxf ${OpenSSLVersion}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$OpenSSLVersion.tar.gz -C /usr/local/src;
	echo "[OK] ${OpenSSLVersion} tar completed.";
}

function InstallMysql55()
{
if [ "$confirm"  == '1' ]; then
	# [dir] /usr/local/mysql/
	echo "[${Mysql55Version} Installing] ************************************************** >>";
	Downloadfile "${Mysql55Version}.tar.gz" "http://mirror.csclub.uwaterloo.ca/mysql/Downloads/MySQL-5.5/${Mysql55Version}.tar.gz";
	rm -rf $AMHDir/packages/untar/$Mysql55Version;
	echo "tar -zxf ${Mysql55Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Mysql55Version.tar.gz -C $AMHDir/packages/untar;
     if [ ! -f /usr/local/mysql/bin/mysql ]; then
		cd $AMHDir/packages/untar/$Mysql55Version;
		
		
		cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql  -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=complex -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1;
		
		make -j $Cpunum;
		make install;
		chmod +w /usr/local/mysql;
		chown -R mysql:mysql /usr/local/mysql;
		mkdir -p /home/mysqldata;
		chown -R mysql:mysql /home/mysqldata;

		rm -f /etc/mysql/my.cnf /usr/local/mysql/etc/my.cnf;
		cp $AMHDir/conf/my.cnf /etc/my.cnf;
		cp $AMHDir/conf/mysql /root/amh/mysql;
		chmod +x /root/amh/mysql;
		/usr/local/mysql/scripts/mysql_install_db --user=mysql --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=/home/mysqldata;
		

# EOF **********************************
cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib/mysql
/usr/local/lib
EOF
# **************************************

		ldconfig;
		if [ "$SysBit" == '64' ] ; then
			ln -s /usr/local/mysql/lib/mysql /usr/lib64/mysql;
		else
			ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql;
		fi;
		chmod 775 /usr/local/mysql/support-files/mysql.server;
		/usr/local/mysql/support-files/mysql.server start;
		ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql;
		ln -s /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin;
		ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump;
		ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk;
		ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe;

		/usr/local/mysql/bin/mysqladmin password $MysqlPass;
		rm -rf /home/mysqldata/test;

# EOF **********************************
mysql -hlocalhost -uroot -p$MysqlPass <<EOF
USE mysql;
DELETE FROM user WHERE User!='root' OR (User = 'root' AND Host != 'localhost');
UPDATE user set password=password('$MysqlPass') WHERE User='root';
DROP USER ''@'%';
FLUSH PRIVILEGES;
EOF
# **************************************
		echo "[OK] ${Mysql55Version} install completed.";
	else
		echo '[OK] MySQL is installed.';
	fi;
 else
 InstallMysql56;
 fi;
}

function InstallMysql56()
{
if [ "$confirm"  == '2' ]; then
	# [dir] /usr/local/mysql/
	echo "[${Mysql56Version} Installing] ************************************************** >>";
	Downloadfile "${Mysql56Version}.tar.gz" "http://mirror.csclub.uwaterloo.ca/mysql/Downloads/MySQL-5.6/${Mysql56Version}.tar.gz";
	rm -rf $AMHDir/packages/untar/$Mysql56Version;
	echo "tar -zxf ${Mysql56Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Mysql56Version.tar.gz -C $AMHDir/packages/untar;

	if [ ! -f /usr/local/mysql/bin/mysql ]; then
		cd $AMHDir/packages/untar/$Mysql56Version;
		
		 cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql  -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=complex -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1;
		
		
		make -j $Cpunum;
		make install;
		chmod +w /usr/local/mysql;
		chown -R mysql:mysql /usr/local/mysql;
		mkdir -p /home/mysqldata;
		chown -R mysql:mysql /home/mysqldata;

		rm -f /etc/mysql/my.cnf /usr/local/mysql/etc/my.cnf;
		cp $AMHDir/conf/my56.cnf /etc/my.cnf;
		cp $AMHDir/conf/mysql /root/amh/mysql;
		chmod +x /root/amh/mysql;
		/usr/local/mysql/scripts/mysql_install_db --user=mysql --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=/home/mysqldata;
		

# EOF **********************************
cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib/mysql
/usr/local/lib
EOF
# **************************************

		ldconfig;
		if [ "$SysBit" == '64' ] ; then
			ln -s /usr/local/mysql/lib/mysql /usr/lib64/mysql;
		else
			ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql;
		fi;
		chmod 775 /usr/local/mysql/support-files/mysql.server;
		/usr/local/mysql/support-files/mysql.server start;
		ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql;
		ln -s /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin;
		ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump;
		ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk;
		ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe;

		/usr/local/mysql/bin/mysqladmin password $MysqlPass;
		rm -rf /home/mysqldata/test;

# EOF **********************************
mysql -hlocalhost -uroot -p$MysqlPass <<EOF
USE mysql;
DELETE FROM user WHERE User!='root' OR (User = 'root' AND Host != 'localhost');
UPDATE user set password=password('$MysqlPass') WHERE User='root';
DROP USER ''@'%';
FLUSH PRIVILEGES;
EOF
# **************************************
		echo "[OK] ${Mysql56Version} install completed.";
	else
		echo '[OK] MySQL is installed.';
	fi;
 else
 InstallMysql57;
 fi;
}

function InstallMysql57()
{
if [ "$confirm"  == '3' ]; then
    #cd $AMHDir/packages;
	     echo "[ boost_1_59_0 Installing] ************************************************** >>";
       Downloadfile "boost_1_59_0.tar.gz" "http://downloads.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz";	
	     tar -xzvf $AMHDir/packages/boost_1_59_0.tar.gz -C $AMHDir/packages/untar;	
	    cd $AMHDir/packages/untar/boost_1_59_0;
	   ./bootstrap.sh;
    ./b2 install;


	cd $AMHDir/packages;
	# [dir] /usr/local/mysql/
	echo "[${Mysql57Version} Installing] ************************************************** >>";
	Downloadfile "${Mysql57Version}.tar.gz" "http://mirror.csclub.uwaterloo.ca/mysql/Downloads/MySQL-5.7/${Mysql57Version}.tar.gz";
	rm -rf $AMHDir/packages/untar/$Mysql57Version;
	echo "tar -zxf ${Mysql57Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Mysql57Version.tar.gz -C $AMHDir/packages/untar;

	
    if [ ! -f /usr/local/mysql/bin/mysql ]; then
		cd $AMHDir/packages/untar/$Mysql57Version;
		
		cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/home/mysqldata -DMYSQL_UNIX_ADDR=/tmp/mysql.sock  -DWITH_MYISAM_STORAGE_ENGINE=1 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=complex -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1;
	
		make -j $Cpunum;
		make install;
		chmod +w /usr/local/mysql;
		chown -R mysql:mysql /usr/local/mysql;
		mkdir -p /home/mysqldata;
		chown -R mysql:mysql /home/mysqldata;

		rm -f /etc/mysql/my.cnf /usr/local/mysql/etc/my.cnf;
		cp $AMHDir/conf/my57.cnf /etc/my.cnf;
		cp $AMHDir/conf/mysql /root/amh/mysql;
		chmod +x /root/amh/mysql;
		/usr/local/mysql/bin/mysql_install_db  --user=mysql  --basedir=/usr/local/mysql --datadir=/home/mysqldata;
		#/usr/local/mysql/bin/mysqld --initialize  --user=mysql  --basedir=/usr/local/mysql --datadir=/home/mysqldata;

# EOF **********************************
cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib/mysql
/usr/local/lib
EOF
# **************************************

		ldconfig;
		if [ "$SysBit" == '64' ] ; then
			ln -s /usr/local/mysql/lib/mysql /usr/lib64/mysql;
		else
			ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql;
		fi;
		chmod 775 /usr/local/mysql/support-files/mysql.server;
		/usr/local/mysql/support-files/mysql.server start;
		ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql;
		ln -s /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin;
		ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump;
		ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk;
		ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe;

		#获取密码
		psw=$(sed '/^$/!h;$!d;g' /root/.mysql_secret);
		#更改mysql密码
		/usr/local/mysql/bin/mysqladmin  -h localhost -u root password $MysqlPass -p${psw};
		rm -rf /home/mysqldata/test;
		rm -rf  /root/.mysql_secret;

# EOF **********************************
mysql -hlocalhost -uroot -p$MysqlPass <<EOF
USE mysql;
update user set authentication_string = PASSWORD('$MysqlPass') where user = 'root';
FLUSH PRIVILEGES;
EOF

# **************************************
		echo "[OK] ${Mysql57Version} install completed.";
	else
		echo '[OK] MySQL is installed.';
	fi;
 else
 InstallMariadb55;
 fi;
}

function InstallMariadb55()
{
if [ "$confirm"  == '4' ]; then
	# [dir] /usr/local/mysql/
	echo "[${Mariadb55Version} Installing] ************************************************** >>";
	Downloadfile "${Mariadb55Version}.tar.gz" "https://downloads.mariadb.com/files/MariaDB/${Mariadb55Version}/source/${Mariadb55Version}.tar.gz";
	rm -rf $AMHDir/packages/untar/$Mariadb55Version;
		echo "tar -zxf ${Mariadb55Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Mariadb55Version.tar.gz -C $AMHDir/packages/untar;

	if [ ! -f /usr/local/mysql/bin/mysql ]; then
		cd $AMHDir/packages/untar/$Mariadb55Version;
		
		cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql  -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=complex -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1;
		
		make -j $Cpunum;
		make install;
		chmod +w /usr/local/mysql;
		chown -R mysql:mysql /usr/local/mysql;
		mkdir -p /home/mysqldata;
		chown -R mysql:mysql /home/mysqldata;

		rm -f /etc/mysql/my.cnf /usr/local/mysql/etc/my.cnf;
		cp $AMHDir/conf/my.cnf /etc/my.cnf;
		cp $AMHDir/conf/mysql /root/amh/mysql;
		chmod +x /root/amh/mysql;
		/usr/local/mysql/scripts/mysql_install_db --user=mysql --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=/home/mysqldata;
		

# EOF **********************************
cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib/mysql
/usr/local/lib
EOF
# **************************************

		ldconfig;
		if [ "$SysBit" == '64' ] ; then
			ln -s /usr/local/mysql/lib/mysql /usr/lib64/mysql;
		else
			ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql;
		fi;
		chmod 775 /usr/local/mysql/support-files/mysql.server;
		/usr/local/mysql/support-files/mysql.server start;
		ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql;
		ln -s /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin;
		ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump;
		ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk;
		ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe;

		/usr/local/mysql/bin/mysqladmin password $MysqlPass;
		rm -rf /home/mysqldata/test;

# EOF **********************************
mysql -hlocalhost -uroot -p$MysqlPass <<EOF
USE mysql;
DELETE FROM user WHERE User!='root' OR (User = 'root' AND Host != 'localhost');
UPDATE user set password=password('$MysqlPass') WHERE User='root';
DROP USER ''@'%';
FLUSH PRIVILEGES;
EOF
# **************************************
		echo "[OK] ${Mariadb55Version} install completed.";
	else
		echo '[OK] MySQL is installed.';
	fi;
 else
 InstallMariadb10;
 fi;
}

function InstallMariadb10()
{
if [ "$confirm"  == '5' ]; then
	# [dir] /usr/local/mysql/
	echo "[${Mariadb10Version} Installing] ************************************************** >>";
	Downloadfile "${Mariadb10Version}.tar.gz" "https://downloads.mariadb.com/files/MariaDB/${Mariadb10Version}/source/${Mariadb10Version}.tar.gz";
	rm -rf $AMHDir/packages/untar/$Mariadb10Version;
	echo "tar -zxf ${Mariadb10Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Mariadb10Version.tar.gz -C $AMHDir/packages/untar;

	if [ ! -f /usr/local/mysql/bin/mysql ]; then
		cd $AMHDir/packages/untar/$Mariadb10Version;
		
		cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql  -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=complex -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1;
		
		make -j $Cpunum;
		make install;
		chmod +w /usr/local/mysql;
		chown -R mysql:mysql /usr/local/mysql;
		mkdir -p /home/mysqldata;
		chown -R mysql:mysql /home/mysqldata;

		rm -f /etc/mysql/my.cnf /usr/local/mysql/etc/my.cnf;
		cp $AMHDir/conf/my.cnf /etc/my.cnf;
		cp $AMHDir/conf/mysql /root/amh/mysql;
		chmod +x /root/amh/mysql;
		/usr/local/mysql/scripts/mysql_install_db --user=mysql --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=/home/mysqldata;
		

# EOF **********************************
cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib/mysql
/usr/local/lib
EOF
# **************************************

		ldconfig;
		if [ "$SysBit" == '64' ] ; then
			ln -s /usr/local/mysql/lib/mysql /usr/lib64/mysql;
		else
			ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql;
		fi;
		chmod 775 /usr/local/mysql/support-files/mysql.server;
		/usr/local/mysql/support-files/mysql.server start;
		ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql;
		ln -s /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin;
		ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump;
		ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk;
		ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe;

		/usr/local/mysql/bin/mysqladmin password $MysqlPass;
		rm -rf /home/mysqldata/test;

# EOF **********************************
mysql -hlocalhost -uroot -p$MysqlPass <<EOF
USE mysql;
DELETE FROM user WHERE User!='root' OR (User = 'root' AND Host != 'localhost');
UPDATE user set password=password('$MysqlPass') WHERE User='root';
DROP USER ''@'%';
FLUSH PRIVILEGES;
EOF
# **************************************
		echo "[OK] ${Mariadb10Version} install completed.";
	else
		echo '[OK] MySQL is installed.';
	fi;
 else
 InstallPhp;
fi;
}

function InstallPhp()
{
	# [dir] /usr/local/php
	echo "[${Php56Version} Installing] ************************************************** >>";
	Downloadfile "${Php56Version}.tar.gz" "http://php.net/distributions/${Php56Version}.tar.gz";
	rm -rf $AMHDir/packages/untar/$Php56Version;
	echo "tar -zxf ${Php56Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php56Version.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /usr/local/php ]; then
		cd $AMHDir/packages/untar/$Php56Version;

		if [ "$InstallModel" == '1' ]; then
		    ./configure --prefix=/usr/local/php --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --with-openssl --with-zlib --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --without-pear $PHPDisable;
		fi;
		make -j $Cpunum;
		make install;
		
		cp $AMHDir/conf/php.ini /etc/php.ini;
		cp $AMHDir/conf/php /root/amh/php;
		cp $AMHDir/conf/phpver /root/amh/phpver;
		mkdir -p /root/amh/fpm/sites;
		mkdir -p /root/amh/sitesconf;
		cp $AMHDir/conf/php-fpm.conf /usr/local/php/etc/php-fpm.conf;
		cp $AMHDir/conf/php-fpm-template.conf /root/amh/fpm/php-fpm-template.conf;
		chmod +x /root/amh/php;
		chmod +x /root/amh/phpver;
		mkdir /etc/php.d;
		mkdir /usr/local/php/etc/fpm;
		mkdir /usr/local/php/var/run/pid;
		#mkdir -p /var/run/pid;
		touch /usr/local/php/etc/fpm/amh.conf;
		/usr/local/php/sbin/php-fpm;

		ln -s /usr/local/php/bin/php /usr/bin/php;
		ln -s /usr/local/php/bin/phpize /usr/bin/phpize;
		ln -s /usr/local/php/sbin/php-fpm /usr/bin/php-fpm;

		echo "[OK] ${Php56Version} install completed.";
	else
		echo '[OK] PHP is installed.';
	fi;
}

function InstallPhp53()
{
	# [dir] /usr/local/php5.3
	echo "[${Php53Version} Installing] ************************************************** >>";
	Downloadfile "${Php53Version}.tar.gz" "http://php.net/distributions/${Php53Version}.tar.gz";
	rm -rf $AMHDir/packages/untar/$Php53Version;
	echo "tar -zxf ${Php53Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php53Version.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /usr/local/php5.3 ]; then
		cd $AMHDir/packages/untar/$Php53Version;
		if [ "$InstallModel" == '1' ]; then
			./configure --prefix=/usr/local/php5.3 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php5.3/etc --with-config-file-scan-dir=/etc/php.d/5.3 --with-openssl --with-zlib --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --without-pear $PHPDisable;
		fi;
		make -j $Cpunum;
		make install;
		
		cp $AMHDir/conf/php53.ini /usr/local/php5.3/etc/php.ini;
		mkdir -p /etc/php.d/5.3;

		echo "[OK] ${Php53Version} install completed.";
	else
		echo '[OK] PHP5.3 is installed.';
	fi;
}

function InstallPhp54()
{
	# [dir] /usr/local/php5.4
	echo "[${Php54Version} Installing] ************************************************** >>";
	Downloadfile "${Php54Version}.tar.gz" "http://php.net/distributions/${Php54Version}.tar.gz";
	rm -rf $AMHDir/packages/untar/$Php54Version;
	echo "tar -zxf ${Php54Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php54Version.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /usr/local/php5.4 ]; then
		cd $AMHDir/packages/untar/$Php54Version;
		if [ "$InstallModel" == '1' ]; then
			./configure --prefix=/usr/local/php5.4 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php5.4/etc --with-config-file-scan-dir=/etc/php.d/5.4 --with-openssl --with-zlib --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --without-pear $PHPDisable;
		fi;
		make -j $Cpunum;
		make install;
		
		cp $AMHDir/conf/php54.ini /usr/local/php5.4/etc/php.ini;
		mkdir -p /etc/php.d/5.4;

		echo "[OK] ${Php54Version} install completed.";
	else
		echo '[OK] PHP5.4 is installed.';
	fi;
}

function InstallPhp55()
{
	# [dir] /usr/local/php5.5
	echo "[${Php55Version} Installing] ************************************************** >>";
	Downloadfile "${Php55Version}.tar.gz" "http://php.net/distributions/${Php55Version}.tar.gz";
	rm -rf $AMHDir/packages/untar/$Php55Version;
	echo "tar -zxf ${Php55Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php55Version.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /usr/local/php5.5 ]; then
		cd $AMHDir/packages/untar/$Php55Version;
		if [ "$InstallModel" == '1' ]; then
			./configure --prefix=/usr/local/php5.5 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php5.5/etc --with-config-file-scan-dir=/etc/php.d/5.5 --with-openssl --with-zlib --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --without-pear $PHPDisable;
		fi;
		make -j $Cpunum;
		make install;
		
		cp $AMHDir/conf/php55.ini /usr/local/php5.5/etc/php.ini;
		mkdir -p /etc/php.d/5.5;

		echo "[OK] ${Php55Version} install completed.";
	else
		echo '[OK] PHP5.5 is installed.';
	fi;
}

function InstallPhp70()
{
	# [dir] /usr/local/php7.0
	echo "[${Php70Version} Installing] ************************************************** >>";
	Downloadfile "${Php70Version}.tar.gz" "http://php.net/distributions/${Php70Version}.tar.gz";
	rm -rf $AMHDir/packages/untar/$Php70Version;
	echo "tar -zxf ${Php70Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php70Version.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /usr/local/php7.0 ]; then
		cd $AMHDir/packages/untar/$Php70Version;
		if [ "$InstallModel" == '1' ]; then
			./configure --prefix=/usr/local/php7.0 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php7.0/etc --with-config-file-scan-dir=/etc/php.d/7.0 --with-openssl --with-zlib --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --without-pear --disable-fileinfo $PHPDisable;
		fi;
		make -j $Cpunum;
		make install;
		
		cp $AMHDir/conf/php70.ini /usr/local/php7.0/etc/php.ini;
		mkdir -p /etc/php.d/7.0;



		echo "[OK] ${Php70Version} install completed.";
	else
		echo '[OK] PHP7.0 is installed.';
	fi;
}




function InstallNginx()
{
	# [dir] /usr/local/nginx
	echo "[${NginxVersion} Installing] ************************************************** >>";
	Downloadfile "${NginxVersion}.tar.gz" "http://nginx.org/download/${NginxVersion}.tar.gz";	
	rm -rf $AMHDir/packages/untar/$NginxVersion;
	echo "tar -zxf ${NginxVersion}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$NginxVersion.tar.gz -C $AMHDir/packages/untar;

	#NginxCachePurgeVersion
	Downloadfile "${NginxCachePurgeVersion}.tar.gz" "http://labs.frickle.com/files/${NginxCachePurgeVersion}.tar.gz";
	echo "tar -zxf ${NginxCachePurgeVersion}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$NginxCachePurgeVersion.tar.gz -C /usr/local/src;

	#echo-nginx-module-0.59  
	Downloadfile "${EchoNginxVersion}.tar.gz" "${GetUrl}/${EchoNginxVersion}.tar.gz";
    rm -rf /usr/local/src/$EchoNginxVersion;
    echo "tar -zxf ${EchoNginxVersion}.tar.gz ing...";
    tar -zxf $AMHDir/packages/$EchoNginxVersion.tar.gz -C /usr/local/src;

    #ngx_http_substitutions_filter_module-0.6.4
	Downloadfile "${NgxHttpSubstitutionsFilter}.tar.gz" "${GetUrl}/${NgxHttpSubstitutionsFilter}.tar.gz";
    rm -rf /usr/local/src/$NgxHttpSubstitutionsFilter;
    echo "tar -zxf ${NgxHttpSubstitutionsFilter}.tar.gz ing...";
    tar -zxf $AMHDir/packages/$NgxHttpSubstitutionsFilter.tar.gz -C /usr/local/src;

	if [ ! -d /usr/local/nginx ]; then
		cd $AMHDir/packages/untar/$NginxVersion;
		./configure --prefix=/usr/local/nginx --user=www --group=www --with-http_ssl_module --with-http_gzip_static_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --with-mail --with-mail_ssl_module --without-http_uwsgi_module --without-http_scgi_module --with-pcre --with-http_v2_module --with-openssl=/usr/local/src/$OpenSSLVersion --add-module=/usr/local/src/$NginxCachePurgeVersion  --add-module=/usr/local/src/$EchoNginxVersion --add-module=/usr/local/src/$NgxHttpSubstitutionsFilter;
		
		make -j $Cpunum;
		make install;
		
		mkdir -p /home/proxyroot/proxy_temp_dir;
		mkdir -p /home/proxyroot/proxy_cache_dir;
		chown www:www -R  /home/proxyroot/proxy_temp_dir  /home/proxyroot/proxy_cache_dir;
		chmod -R 644  /home/proxyroot/proxy_temp_dir  /home/proxyroot/proxy_cache_dir;

		mkdir -p /home/wwwroot/index /home/backup /usr/local/nginx/conf/vhost/  /usr/local/nginx/conf/vhost_stop/  /usr/local/nginx/conf/rewrite/;
		chown +w /home/wwwroot/index;
		touch /usr/local/nginx/conf/rewrite/amh.conf;

		cp $AMHDir/conf/proxy.conf /usr/local/nginx/conf/proxy.conf;
		cp $AMHDir/conf/nginx.conf /usr/local/nginx/conf/nginx.conf;
		cp $AMHDir/conf/nginx-host.conf /usr/local/nginx/conf/nginx-host.conf;
		cp $AMHDir/conf/fcgi.conf /usr/local/nginx/conf/fcgi.conf;
		cp $AMHDir/conf/fcgi-host.conf /usr/local/nginx/conf/fcgi-host.conf;
		cp $AMHDir/conf/nginx /root/amh/nginx;
		cp $AMHDir/conf/host /root/amh/host;
		chmod +x /root/amh/nginx;
		chmod +x /root/amh/host;
		sed -i 's/www.amysql.com/'$Domain'/g' /usr/local/nginx/conf/nginx.conf;

		cd /home/wwwroot/index;
		mkdir -p tmp etc/rsa bin usr/sbin log;
		touch etc/upgrade.conf;
		chown mysql:mysql etc/rsa;
		chmod 777 tmp;
		[ "$SysBit" == '64' ] && mkdir lib64 || mkdir lib;
		/usr/local/nginx/sbin/nginx;
		/usr/local/php/sbin/php-fpm;
		ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx;

		echo "[OK] ${NginxVersion} install completed.";
	else
		echo '[OK] Nginx is installed.';
	fi;
}

function InstallPureFTPd()
{
	# [dir] /etc/	/usr/local/bin	/usr/local/sbin
	echo "[${PureFTPdVersion} Installing] ************************************************** >>";
	Downloadfile "${PureFTPdVersion}.tar.gz" "${GetUrl}/${PureFTPdVersion}.tar.gz";
	rm -rf $AMHDir/packages/untar/$PureFTPdVersion;
	echo "tar -zxf ${PureFTPdVersion}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$PureFTPdVersion.tar.gz -C $AMHDir/packages/untar;

	if [ ! -f /etc/pure-ftpd.conf ]; then
		cd $AMHDir/packages/untar/$PureFTPdVersion;
		./configure --with-puredb --with-quotas --with-throttling --with-ratios --with-peruserlimits;
		make -j $Cpunum;
		make install;
		cp contrib/redhat.init /usr/local/sbin/redhat.init;
		chmod 755 /usr/local/sbin/redhat.init;

		cp $AMHDir/conf/pure-ftpd.conf /etc;
		cp configuration-file/pure-config.pl /usr/local/sbin/pure-config.pl;
		chmod 744 /etc/pure-ftpd.conf;
		chmod 755 /usr/local/sbin/pure-config.pl;
		/usr/local/sbin/redhat.init start;

		groupadd ftpgroup;
		useradd -d /home/wwwroot/ -s /sbin/nologin -g ftpgroup ftpuser;

		cp $AMHDir/conf/ftp /root/amh/ftp;
		chmod +x /root/amh/ftp;

		/sbin/iptables-save > /etc/amh-iptables;
		sed -i '/--dport 21 -j ACCEPT/d' /etc/amh-iptables;
		sed -i '/--dport 80 -j ACCEPT/d' /etc/amh-iptables;
		sed -i '/--dport 8888 -j ACCEPT/d' /etc/amh-iptables;
		sed -i '/--dport 10100:10110 -j ACCEPT/d' /etc/amh-iptables;
		/sbin/iptables-restore < /etc/amh-iptables;
		/sbin/iptables -I INPUT -p tcp --dport 21 -j ACCEPT;
		/sbin/iptables -I INPUT -p tcp --dport 80 -j ACCEPT;
		/sbin/iptables -I INPUT -p tcp --dport 8888 -j ACCEPT;
		/sbin/iptables -I INPUT -p tcp --dport 10100:10110 -j ACCEPT;
		/sbin/iptables-save > /etc/amh-iptables;
		echo 'IPTABLES_MODULES="ip_conntrack_ftp"' >>/etc/sysconfig/iptables-config;

		touch /etc/pureftpd.passwd;
		chmod 774 /etc/pureftpd.passwd;
		echo "[OK] ${PureFTPdVersion} install completed.";
	else
		echo '[OK] PureFTPd is installed.';
	fi;
}

function InstallAMH()
{
	# [dir] /home/wwwroot/index/web
	echo "[${AMHVersion} Installing] ************************************************** >>";
	Downloadfile "${AMHVersion}.tar.gz" "${GetUrl}/${AMHVersion}.tar.gz";
	rm -rf $AMHDir/packages/untar/$AMHVersion;
	echo "tar -xf ${AMHVersion}.tar.gz ing...";
	tar -xf $AMHDir/packages/$AMHVersion.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /home/wwwroot/index/web ]; then
		cp -r $AMHDir/packages/untar/$AMHVersion /home/wwwroot/index/web;

		gcc -o /bin/amh -Wall $AMHDir/conf/amh.c;
		chmod 4775 /bin/amh;
		cp -a $AMHDir/conf/amh-backup.conf /home/wwwroot/index/etc;
		cp -a $AMHDir/conf/html /home/wwwroot/index/etc;
		cp $AMHDir/conf/{all,backup,revert,BRssh,BRftp,info,SetParam,module,crontab,upgrade} /root/amh;
		cp -a $AMHDir/conf/modules /root/amh;
		chmod +x /root/amh/all /root/amh/backup /root/amh/revert /root/amh/BRssh /root/amh/BRftp /root/amh/info /root/amh/SetParam /root/amh/module /root/amh/crontab /root/amh/upgrade;

		SedMysqlPass=${MysqlPass//&/\\\&};
		SedMysqlPass=${SedMysqlPass//\'/\\\\\'};
		sed -i "s/'MysqlPass'/'${SedMysqlPass}'/g" /home/wwwroot/index/web/Amysql/Config.php;
		chown www:www /home/wwwroot/index/web/Amysql/Config.php;

		SedAMHPass=${AMHPass//&/\\\&};
		SedAMHPass=${SedAMHPass//\'/\\\\\\\\\'\'};
		sed -i "s/'AMHPass_amysql-amh'/'${SedAMHPass}_amysql-amh'/g" $AMHDir/conf/amh.sql;
		/usr/local/mysql/bin/mysql -u root -p$MysqlPass < $AMHDir/conf/amh.sql;

		echo "[OK] ${AMHVersion} install completed.";
	else
		echo '[OK] AMH is installed.';
	fi;
}

function InstallAMS()
{
	# [dir] /home/wwwroot/index/web/ams
	echo "[${AMSVersion} Installing] ************************************************** >>";
	Downloadfile "${AMSVersion}.tar.gz" "${GetUrl}/${AMSVersion}.tar.gz";
	rm -rf $AMHDir/packages/untar/$AMSVersion;
	echo "tar -xf ${AMSVersion}.tar.gz ing...";
	tar -xf $AMHDir/packages/$AMSVersion.tar.gz -C $AMHDir/packages/untar;

	if [ ! -d /home/wwwroot/index/web/ams ]; then
		cp -r $AMHDir/packages/untar/$AMSVersion /home/wwwroot/index/web/ams;
		chown www:www -R /home/wwwroot/index/web/ams/View/DataFile;
		echo "[OK] ${AMSVersion} install completed.";
	else
		echo '[OK] AMS is installed.';
	fi;
}


# AMH Installing ****************************************************************************
CheckSystem;
ConfirmInstall;
InputDomain;
InputMysqlPass;
InputAMHPass;
Timezone;
CloseSelinux;
DeletePackages;
InstallBasePackages;
InstallReady;
Installcurl;
InstallLibiconv;
InstallMysql55;
InstallPhp;
[ "$confirm53" == 'y' ] && InstallPhp53;
[ "$confirm54" == 'y' ] && InstallPhp54;
[ "$confirm55" == 'y' ] && InstallPhp55;
[ "$confirm70" == 'y' ] && InstallPhp70;
InstallOpenSSL;
InstallNginx;
InstallPureFTPd;
InstallAMH;
InstallAMS;


if [ -s /usr/local/nginx ] && [ -s /usr/local/php ] && [ -s /usr/local/mysql ]; then

cp $AMHDir/conf/amh-start /etc/init.d/amh-start;
chmod 775 /etc/init.d/amh-start;
if [ "$SysName" == 'CentOS' ]; then
	chkconfig --add amh-start;
	chkconfig amh-start on;
else
	update-rc.d -f amh-start defaults;
fi;

/etc/init.d/amh-start;
rm -rf $AMHDir;

echo '================================================================';
	echo '[AMH] Congratulations, AMH 4.5 install completed.';
	echo "AMH Management: http://${Domain}:8888";
	echo 'User:admin';
	echo "Password:${AMHPass}";
	echo "MySQL Password:${MysqlPass}";
	echo '';
	echo '******* SSH Management *******';
	echo 'Host: amh host';
	echo 'PHP: amh php';
	echo 'Nginx: amh nginx';
	echo 'MySQL: amh mysql';
	echo 'FTP: amh ftp';
	echo 'Backup: amh backup';
	echo 'Revert: amh revert';
	echo 'SetParam: amh SetParam';
	echo 'Module : amh module';
	echo 'Crontab : amh crontab';
	echo 'Upgrade : amh upgrade';
	echo 'Info: amh info';
	echo '';
	echo '******* SSH Dirs *******';
	echo 'WebSite: /home/wwwroot';
	echo 'Nginx: /usr/local/nginx';
	echo 'PHP: /usr/local/php';
	echo 'MySQL: /usr/local/mysql';
	echo 'MySQL-Data: /home/mysqldata';
	echo '';
	echo "Start time: ${StartDate}";
	echo "Completion time: $(date) (Use: $[($(date +%s)-StartDateSecond)/60] minute)";
echo '================================================================';
else
	echo 'Sorry, Failed to install AMH';
fi;
