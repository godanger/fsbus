#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# VAR
IampVersion='imap-2007f';
AMHDir='/home/amh_install';
Ser='';
icuPath='/usr/local/icu';
FreetPath='/usr/local/freetype';
ImapPath='/usr/local/${IampVersion}';
ins='/root';
InstallModel='1';
# Version
Php53Version='php-5.3.29';
Php54Version='php-5.4.45';
Php55Version='php-5.5.38';
Php56Version='php-5.6.30';
Php70Version='php-7.0.17';
Php71Version='php-7.1.3';
Amver='amh4.5';
confver="conf"
function CheckSystem()
{
	[ $(id -u) != '0' ] && echo '[Error] Please use root to install AMH.' && exit;
	if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
	  SysName='centos';
	  Inst='yum';
	elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
	  SysName='RHEL';
	  Inst='yum';
	elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
	  SysName='Aliyun';
	  Inst='yum';
	elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
      SysName='Fedora';
      Inst='yum';
	elif grep -Eqi "Amazon Linux AMI" /etc/issue || grep -Eq "Amazon Linux AMI" /etc/*-release; then
      SysName='Amazon';
      Inst='yum';
	elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
      SysName='debian';
	  Inst='apt';
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
      SysName='Ubuntu';
      Inst='apt';
    elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
      SysName='Raspbian'
      Inst='apt';
	elif grep -Eqi "Deepin" /etc/issue || grep -Eq "Deepin" /etc/*-release; then
      SysName='Deepin';
      Inst='apt';
	else
      SysName='unknow';
    fi;
    if uname -m | grep -Eqi "arm"; then
     Is_ARM='arm';
		else
	 Is_ARM=`uname -m`;
    fi;
	[ "$SysName" == ''  ] && echo '[Error] Your system is not supported install AMH' && exit;
	[ "$SysName" == 'unknow'  ] && echo '[Error] Your system is not supported install AMH' && exit;
	SysBit='32' && [ `getconf WORD_BIT` == '32' ] && [ `getconf LONG_BIT` == '64' ] && SysBit='64';
	Cpunum=`cat /proc/cpuinfo | grep 'processor' | wc -l`;
	RamTotal=`free -m | grep 'Mem' | awk '{print $2}'`;
	RamSwap=`free -m | grep 'Swap' | awk '{print $2}'`;
	echo "Server ${Domain}";
	echo "${SysBit}Bit, ${Cpunum}*CPU, ${RamTotal}MB*RAM, ${RamSwap}MB*Swap";
	echo "${Is_ARM}, Instruction ";
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
function Install()
{
    echo "[Notice] Select Server Area : (1~2)"
	select Serselect in 'localhost' 'Sxsay.com' 'Exit'; do break; done;
	[ "$serselect" == 'Exit' ] && echo 'Exit Install.' && exit;
		
	if [ "$Serselect" == 'localhost' ]; then
	Ser='localhost' && echo '[OK] localhost installed';
	elif [ "$Serselect" == 'Sxsay.com' ]; then
	Ser='http://www.sxsay.com/amh' && echo '[OK] Sxsay.com installed';
	else
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
	read -p '[Notice] Do you want PHP7.1? : (y/n)' confirm71;
	[ "$confirm70" == 'y' ] && echo '[OK] php7.1 will be installed';	
}
function Downloadfile()
{
	if [ "$Ser"  == 'localhost' ]; then
	localhost='${AMHDir}/packages';
	else
   mkdir -p /home/amh_install;
   mkdir -p /home/amh_install/packages;
   mkdir -p /home/amh_install/packages/untar;
   mkdir -p /home/amh_install/packages/untar/$confver;
   chmod +Rw /home/amh_install/packages;
	cd /home/amh_install/packages;
	randstr=$(date +%s);
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
	fi;
	cd /root;
}
function Download()
{
   echo "[+] Downloading files...";
   if [ "$Ser"  == 'localhost' ]; then
    if [ ! -e $ins/$Amver.tar.gz ]; then
	cd /root;
	wget $Ser/$Amver.tar.gz;
	if [ ! -e $ins/$Amver.tar.gz ]; then
	echo '[Error] AMH-V4.5 is empty.' && exit;
	fi;
   tar -zxf /root/$Amver.tar.gz -C /home;
   fi;
  else
   mkdir -p /home/amh_install;
   mkdir -p /home/amh_install/packages;
   mkdir -p /home/amh_install/packages/untar;
   mkdir -p /home/amh_install/packages/untar/$confver;
   chmod +Rw /home/amh_install/packages;
   cd /home/amh_install/packages;
   Downloadfile "${confver}.zip" "${Ser}/${confver}.zip";
   if [ "$confirm53" == 'y' ]; then
   Downloadfile "${Php53Version}.tar.gz" "${Ser}/${Php53Version}.tar.gz";
   fi;
   if [ "$confirm54" == 'y' ]; then
   Downloadfile "${Php54Version}.tar.gz" "${Ser}/${Php54Version}.tar.gz";
   fi;
   if [ "$confirm55" == 'y' ]; then
   Downloadfile "${Php55Version}.tar.gz" "${Ser}/${Php55Version}.tar.gz";
   fi;
   if [ "$confirm70" == 'y' ]; then
   Downloadfile "${Php70Version}.tar.gz" "${Ser}/${Php70Version}.tar.gz";
   fi;
   if [ "$confirm71" == 'y' ]; then
   Downloadfile "${Php71Version}.tar.gz" "${Ser}/${Php71Version}.tar.gz";
   fi;
   fi;
   cd /root;
   echo "[OK] Download Done completed.";
}
function InstallReady()
{
	mkdir -p $AMHDir/packages/untar/$confver;
	mkdir -p $AMHDir/packages/untar;
	chmod +Rw $AMHDir/packages;

	mkdir -p /root/amh/;
	chmod +Rw /root/amh;

	cd $AMHDir/packages;
	if [ ! -e $AMHDir/packages/$confver.zip ]; then
	Downloadfile "${confver}.zip" "${Ser}/${confver}.zip";
	fi;
	unzip $AMHDir/packages/$confver.zip -d $AMHDir/packages/untar/$confver;
}
function InstallPhp()
{
 if [ ! -d /usr/local/php ]; then
  if [ "${Inst}" = 'apt' ]; then
    InstallIcu4c;
	InstallFreet;
    fi;
	if [ "$SysName"=='debian' ]; then
	libc_name=`apt-cache search libc-client.*dev | awk '{print $1}'`;
	#libc_zip=`apt-cache search libzip.*dev | awk '{print $1}'`;
	apt-get install -y $libc_name libzip-dev --force-yes;
	apt-get -f install -y;
	apt-get install -y libzip-dev;
	fi;
	# [dir] /usr/local/php
	echo "[${Php56Version} Installing] ************************************************** >>";
	if [ ! -e $AMHDir/packages/$Php56Version.tar.gz ]; then
	Downloadfile "${Php56Version}.tar.gz" "${Ser}/${Php56Version}.tar.gz";
	 fi;
	echo "tar -zxf ${Php56Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php56Version.tar.gz -C $AMHDir/packages/untar;
	if [ "$SysBit" == '64' ] ; then
		ln -s /usr/lib64/libc-client.so /usr/lib/libc-client.so;
		fi;
 
		cd $AMHDir/packages/untar/$Php56Version;
		groupadd www;
		useradd -m -s /sbin/nologin -g www www;
		if [ "${Inst}" = 'apt' ]; then
		ln -s /usr/lib/libc-client.a /usr/lib/x86_64-linux-gnu/libc-client.a;
		ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h;
		./configure --prefix=/usr/local/php --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=$FreetPath --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-icu-dir=$icuPath --with-curl=/usr/local/curl/ --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-soap --with-gettext --disable-fileinfo --enable-opcache --with-imap=$ImapPath --enable-intl --with-xsl --enable-zip $PHPDisable;
		else
		if [ "$InstallModel" == '1' ]; then
		 if [ "${Is_ARM}" = 'arm' ]; then
		 yum install -y libzip;
		 export CFLAGS="-L/opt/xml2/lib";
		 export LD_LIBRARY_PATH=/usr/local/mysql/lib;
		 ./configure --prefix=/usr/local/php --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl/ --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-opcache --enable-intl --with-xsl $PHPDisable;
		  else
		 ./configure --prefix=/usr/local/php --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --with-openssl --with-zlib --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --enable-sockets --enable-pcntl --with-xmlrpc --with-mhash --enable-soap --with-gettext --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --with-imap=$ImapPath --with-imap-ssl --with-kerberos --without-pear --with-xsl --enable-intl --with-mcrypt $PHPDisable;
		fi;
		fi;
		fi;
		make -j $Cpunum;
		make install;
		#cp $AMHDir/packages/$Php56Version/php.ini-production /etc/php.ini;
		#cp php.ini-production /usr/local/php/etc/php.ini;
		#mv /etc/php.ini /usr/local/php/etc/php.ini.bak;
		cp $AMHDir/packages/untar/$confver/php.ini /etc/php.ini;
		cp $AMHDir/packages/untar/$confver/php /root/amh/php;
		cp $AMHDir/packages/untar/$confver/phpver /root/amh/phpver;
		mkdir -p /root/amh/fpm/sites;
		mkdir -p /root/amh/sitesconf;
		cp $AMHDir/packages/untar/$confver/php-fpm.conf /usr/local/php/etc/php-fpm.conf;
		cp $AMHDir/packages/untar/$confver/php-fpm-template.conf /root/amh/fpm/php-fpm-template.conf;
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
        sed -i 's/post_max_size =.*/post_max_size = 150M/g' /etc/php.ini;
        sed -i 's/upload_max_filesize =.*/upload_max_filesize = 150M/g' /etc/php.ini;
        sed -i 's/;date.timezone =.*/date.timezone = PRC/g' /etc/php.ini;
        sed -i 's/short_open_tag =.*/short_open_tag = On/g' /etc/php.ini;
        sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' /etc/php.ini;
        sed -i 's/max_execution_time =.*/max_execution_time = 300/g' /etc/php.ini;
# Extension **********************************
#cat > /etc/php.ini<<EOF
#extension=openssl.so
#EOF
# Extension***********************************		
		echo "[OK] ${Php56Version} install completed.";
	else
		echo '[OK] PHP is installed.';
	fi;
}

function InstallPhp53()
{
 if [ ! -d /usr/local/php5.3 ]; then
	# [dir] /usr/local/php5.3
	echo "[${Php53Version} Installing] ************************************************** >>";
	if [ ! -e $AMHDir/packages/$Php53Version.tar.gz ]; then
	Downloadfile "${Php53Version}.tar.gz" "${Ser}/${Php53Version}.tar.gz";
	fi;
	echo "tar -zxf ${Php53Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php53Version.tar.gz -C $AMHDir/packages/untar;
     
		cd $AMHDir/packages/untar/$Php53Version;
		if [ "${Inst}" = 'apt' ]; then
		LD_LIBRARY_PATH=/usr/local/mysql/lib:/lib/:/usr/lib/:/usr/local/lib ./configure --prefix=/usr/local/php5.3 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php5.3/etc --with-config-file-scan-dir=/etc/php.d/5.3 --with-openssl --with-zlib --with-icu-dir=$icuPath --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir=$FreetPath --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-sockets --enable-pcntl --with-xmlrpc --with-mhash --enable-soap --with-gettext --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --with-kerberos --without-pear --with-xsl --enable-intl --with-mcrypt --enable-opcache $PHPDisable;
		sed -i '/^BUILD_/ s/\$(CC)/\$(CXX)/g' Makefile;
		else
		if [ "$InstallModel" == '1' ]; then
		 if [ "${Is_ARM}" = 'arm' ]; then
		 LD_LIBRARY_PATH=/usr/local/mysql/lib:/lib/:/usr/lib/:/usr/local/lib ./configure --prefix=/usr/local/php5.3 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php5.3/etc --with-config-file-scan-dir=/etc/php.d/5.3 --with-openssl --with-zlib --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-sockets --enable-pcntl --with-xmlrpc --with-mhash --enable-soap --with-gettext --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --with-kerberos --without-pear --with-xsl --enable-intl --with-mcrypt $PHPDisable;
		 else
		 LD_LIBRARY_PATH=/usr/local/mysql/lib:/lib/:/usr/lib/:/usr/local/lib ./configure --prefix=/usr/local/php5.3 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php5.3/etc --with-config-file-scan-dir=/etc/php.d/5.3 --with-openssl --with-zlib --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-sockets --enable-pcntl --with-xmlrpc --with-mhash --enable-soap --with-gettext --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --with-imap=$ImapPath --with-imap-ssl --with-kerberos --without-pear --with-xsl --enable-intl --with-mcrypt $PHPDisable;
		fi;
		fi;
		fi;
	  if [ "$SysName"=='CentOS' ]; then
       if [ "$RHEL_Ver"=='7' ]; then	
		sed -i '/^BUILD_/ s/\$(CC)/\$(CXX)/g' Makefile;
		else
		echo '[No SED] System No is Centos 7.';
		fi;
		make -j $Cpunum ZEND_EXTRA_LIBS='-liconv';
		make install;
		#cp $AMHDir/packages/$Php53Version/php.ini-production /usr/local/php5.3/etc/php.ini;
		#mv /usr/local/php5.3/etc/php.ini /usr/local/php5.3/etc/php.ini.bak;
		cp $AMHDir/packages/untar/$confver/php53.ini /usr/local/php5.3/etc/php.ini;
		mkdir -p /etc/php.d/5.3;
        sed -i 's/post_max_size =.*/post_max_size = 50M/g' /usr/local/php5.3/etc/php.ini;
        sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' /usr/local/php5.3/etc/php.ini;
        sed -i 's/;date.timezone =.*/date.timezone = PRC/g' /usr/local/php5.3/etc/php.ini;
        sed -i 's/short_open_tag =.*/short_open_tag = On/g' /usr/local/php5.3/etc/php.ini;
        sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' /usr/local/php5.3/etc/php.ini;
        sed -i 's/max_execution_time =.*/max_execution_time = 300/g' /usr/local/php5.3/etc/php.ini;
        sed -i 's/register_long_arrays =.*/;register_long_arrays = On/g' /usr/local/php5.3/etc/php.ini;
        sed -i 's/magic_quotes_gpc =.*/;magic_quotes_gpc = On/g' /usr/local/php5.3/etc/php.ini;
# Extension **********************************
#cat > /usr/local/php5.3/etc/php.ini<<EOF
#extension=openssl.so
#EOF
# Extension***********************************
		echo "[OK] ${Php53Version} install completed.";
	else
		echo '[OK] PHP5.3 is installed.';
	fi;
fi;
}

function InstallPhp54()
{
	if [ ! -d /usr/local/php5.4 ]; then
	# [dir] /usr/local/php5.4
	echo "[${Php54Version} Installing] ************************************************** >>";
	if [ ! -e $AMHDir/packages/$Php54Version.tar.gz ]; then
	Downloadfile "${Php54Version}.tar.gz" "${Ser}/${Php54Version}.tar.gz";
	fi;
	echo "tar -zxf ${Php54Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php54Version.tar.gz -C $AMHDir/packages/untar;

	
		cd $AMHDir/packages/untar/$Php54Version;
		if [ "${Inst}" = 'apt' ]; then
		./configure --prefix=/usr/local/php5.4 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php5.4/etc --with-config-file-scan-dir=/etc/php.d/5.4 --with-openssl --with-zlib --with-icu-dir=$icuPath --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir=$FreetPath --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --with-imap=$ImapPath --enable-sockets --enable-pcntl --with-xmlrpc --with-mhash --enable-soap --with-gettext --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --with-kerberos --without-pear --with-xsl --enable-intl --with-mcrypt $PHPDisable;
		else
		if [ "$InstallModel" == '1' ]; then
		 if [ "${Is_ARM}" = 'arm' ]; then
		    ./configure --prefix=/usr/local/php5.4 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php5.4/etc --with-config-file-scan-dir=/etc/php.d/5.4 --with-openssl --with-zlib --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --enable-sockets --enable-pcntl --with-xmlrpc --with-mhash --enable-soap --with-gettext --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --with-kerberos --without-pear --with-xsl --enable-intl --with-mcrypt $PHPDisable;
		 else
			./configure --prefix=/usr/local/php5.4 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php5.4/etc --with-config-file-scan-dir=/etc/php.d/5.4 --with-openssl --with-zlib --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --enable-sockets --enable-pcntl --with-xmlrpc --with-mhash --enable-soap --with-gettext --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --with-imap=$ImapPath --with-imap-ssl --with-kerberos --without-pear --with-xsl --enable-intl --with-mcrypt $PHPDisable;
		fi;
		fi;
		fi;
		make -j $Cpunum;
		make install;
		#cp $AMHDir/packages/$Php54Version/php.ini-production /usr/local/php5.4/etc/php.ini;
		#mv /usr/local/php5.4/etc/php.ini /usr/local/php5.4/etc/php.ini.bak;
		cp $AMHDir/packages/untar/$confver/php54.ini /usr/local/php5.4/etc/php.ini;
		mkdir -p /etc/php.d/5.4;
        sed -i 's/post_max_size =.*/post_max_size = 50M/g' /usr/local/php5.4/etc/php.ini;
        sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' /usr/local/php5.4/etc/php.ini;
        sed -i 's/;date.timezone =.*/date.timezone = PRC/g' /usr/local/php5.4/etc/php.ini;
        sed -i 's/short_open_tag =.*/short_open_tag = On/g' /usr/local/php5.4/etc/php.ini;
        sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' /usr/local/php5.4/etc/php.ini;
        sed -i 's/max_execution_time =.*/max_execution_time = 300/g' /usr/local/php5.4/etc/php.ini;
# Extension **********************************
#cat > /usr/local/php5.4/etc/php.ini<<EOF
#extension=openssl.so
#EOF
# Extension***********************************
		echo "[OK] ${Php54Version} install completed.";
	else
		echo '[OK] PHP5.4 is installed.';
	fi;
}

function InstallPhp55()
{
	if [ ! -d /usr/local/php5.5 ]; then
	# [dir] /usr/local/php5.5
	echo "[${Php55Version} Installing] ************************************************** >>";
	if [ ! -e $AMHDir/packages/$Php55Version.tar.gz ]; then
	Downloadfile "${Php55Version}.tar.gz" "${Ser}/${Php55Version}.tar.gz";
	fi;
	echo "tar -zxf ${Php55Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php55Version.tar.gz -C $AMHDir/packages/untar;

	
		cd $AMHDir/packages/untar/$Php55Version;
		if [ "${Inst}" = 'apt' ]; then
		./configure --prefix=/usr/local/php5.5 --with-config-file-path=/usr/local/php5.5/etc --with-config-file-scan-dir=/etc/php.d/5.5 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=$FreetPath --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-icu-dir=$icuPath --with-curl=/usr/local/curl/ --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-opcache --with-imap=$ImapPath --enable-intl --with-xsl $PHPDisable;
		else
		if [ "$InstallModel" == '1' ]; then
		if [ "${Is_ARM}" = 'arm' ]; then
		    ./configure --prefix=/usr/local/php5.5 --with-config-file-path=/usr/local/php5.5/etc --with-config-file-scan-dir=/etc/php.d/5.5 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl/ --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-opcache --enable-intl --with-xsl $PHPDisable;
		    else
			./configure --prefix=/usr/local/php5.5 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php5.5/etc --with-config-file-scan-dir=/etc/php.d/5.5 --with-openssl --with-zlib  --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --enable-sockets --enable-pcntl --with-xmlrpc --with-mhash --enable-soap --with-gettext --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --with-imap=$ImapPath --with-imap-ssl --with-kerberos --without-pear --with-xsl --enable-intl --with-mcrypt $PHPDisable;
		fi;
		fi;
		fi;
		make -j $Cpunum;
		make install;
		#cp $AMHDir/packages/$Php55Version/php.ini-production /usr/local/php5.5/etc/php.ini;
		#mv /usr/local/php5.5/etc/php.ini /usr/local/php5.5/etc/php.ini.bak;
		cp $AMHDir/packages/untar/$confver/php55.ini /usr/local/php5.5/etc/php.ini;
		mkdir -p /etc/php.d/5.5;
        sed -i 's/post_max_size =.*/post_max_size = 150M/g' /usr/local/php5.5/etc/php.ini;
        sed -i 's/upload_max_filesize =.*/upload_max_filesize = 150M/g' /usr/local/php5.5/etc/php.ini;
        sed -i 's/;date.timezone =.*/date.timezone = PRC/g' /usr/local/php5.5/etc/php.ini;
        sed -i 's/short_open_tag =.*/short_open_tag = On/g' /usr/local/php5.5/etc/php.ini;
        sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' /usr/local/php5.5/etc/php.ini;
        sed -i 's/max_execution_time =.*/max_execution_time = 300/g' /usr/local/php5.5/etc/php.ini;
# Extension **********************************
#cat > /usr/local/php5.5/etc/php.ini<<EOF
#extension=openssl.so
#EOF
# Extension***********************************
		echo "[OK] ${Php55Version} install completed.";
	else
		echo '[OK] PHP5.5 is installed.';
	fi;
}

function InstallPhp70()
{
	if [ ! -d /usr/local/php7.0 ]; then
	# [dir] /usr/local/php7.0
	echo "[${Php70Version} Installing] ************************************************** >>";
	if [ ! -e $AMHDir/packages/$Php70Version.tar.gz ]; then
	Downloadfile "${Php70Version}.tar.gz" "${Ser}/${Php70Version}.tar.gz";
	fi;
	echo "tar -zxf ${Php70Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php70Version.tar.gz -C $AMHDir/packages/untar;
     cd $AMHDir/packages/untar/$Php70Version;
		if [ "${Inst}" = 'apt' ]; then
		./configure --prefix=/usr/local/php7.0 --with-config-file-path=/usr/local/php7.0/etc --with-config-file-scan-dir=/etc/php.d/7.0 --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=$FreetPath --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-icu-dir=$icuPath --with-curl=/usr/local/curl/ --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-opcache --with-imap=$ImapPath --with-xsl --enable-zip $PHPDisable;
		else
		if [ "$InstallModel" == '1' ]; then
		if [ "${Is_ARM}" = 'arm' ]; then
		    ./configure --prefix=/usr/local/php7.0 --with-config-file-path=/usr/local/php7.0/etc --with-config-file-scan-dir=/etc/php.d/7.0 --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl/ --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-opcache --with-xsl $PHPDisable;
		else
			./configure --prefix=/usr/local/php7.0 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php7.0/etc --with-config-file-scan-dir=/etc/php.d/7.0 --with-openssl --with-zlib --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --enable-sockets --enable-pcntl --with-xmlrpc --with-mhash --enable-soap --with-gettext --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --with-imap=$ImapPath --with-imap-ssl --with-kerberos --without-pear --with-xsl --enable-intl --with-mcrypt $PHPDisable;
		fi;
		fi;
		fi;
		make -j $Cpunum;
		make install;
		#cp $AMHDir/packages/$Php70Version/php.ini-production /usr/local/php7.0/etc/php.ini;
		#mv /usr/local/php7.0/etc/php.ini /usr/local/php7.0/etc/php.ini.bak;
		cp $AMHDir/packages/untar/$confver/php70.ini /usr/local/php7.0/etc/php.ini;
		mkdir -p /etc/php.d/7.0;
        sed -i 's/post_max_size =.*/post_max_size = 150M/g' /usr/local/php7.0/etc/php.ini;
        sed -i 's/upload_max_filesize =.*/upload_max_filesize = 150M/g' /usr/local/php7.0/etc/php.ini;
        sed -i 's/;date.timezone =.*/date.timezone = PRC/g' /usr/local/php7.0/etc/php.ini;
        sed -i 's/short_open_tag =.*/short_open_tag = On/g' /usr/local/php7.0/etc/php.ini;
        sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' /usr/local/php7.0/etc/php.ini;
        sed -i 's/max_execution_time =.*/max_execution_time = 300/g' /usr/local/php7.0/etc/php.ini;
# Extension **********************************
#cat > /usr/local/php7.0/etc/php.ini<<EOF
#extension=openssl.so
#EOF
# Extension***********************************
		echo "[OK] ${Php70Version} install completed.";
	else
		echo '[OK] PHP7.0 is installed.';
	fi;
}

function InstallPhp71()
{
	if [ ! -d /usr/local/php7.1 ]; then
	# [dir] /usr/local/php7.1
	echo "[${Php71Version} Installing] ************************************************** >>";
	if [ ! -e $AMHDir/packages/$Php71Version.tar.gz ]; then
	Downloadfile "${Php71Version}.tar.gz" "${Ser}/${Php71Version}.tar.gz";
	fi;
	echo "tar -zxf ${Php71Version}.tar.gz ing...";
	tar -zxf $AMHDir/packages/$Php71Version.tar.gz -C $AMHDir/packages/untar;

	
		cd $AMHDir/packages/untar/$Php71Version;
		if [ "${Inst}" = 'apt' ]; then
		./configure --prefix=/usr/local/php7.1 --with-config-file-path=/usr/local/php7.1/etc --with-config-file-scan-dir=/etc/php.d/7.1 --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=$FreetPath --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-icu-dir=$icuPath --with-curl=/usr/local/curl/ --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-opcache --with-imap=$ImapPath --with-xsl $PHPDisable;
		else
		if [ "$InstallModel" == '1' ]; then
		 if [ "${Is_ARM}" = 'arm' ]; then
		    ./configure --prefix=/usr/local/php7.1 --with-config-file-path=/usr/local/php7.1/etc --with-config-file-scan-dir=/etc/php.d/7.1 --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl/ --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-opcache --with-xsl $PHPDisable;
		  else
			./configure --prefix=/usr/local/php7.1 --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php7.1/etc --with-config-file-scan-dir=/etc/php.d/7.1 --with-openssl --with-zlib --with-curl=/usr/local/curl/ --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --enable-sockets --enable-pcntl --with-xmlrpc --with-mhash --enable-soap --with-gettext --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --with-imap=$ImapPath --with-imap-ssl --with-kerberos --without-pear --with-xsl --enable-intl --with-mcrypt $PHPDisable;
		fi;
		fi;
		fi;
		make -j $Cpunum;
		make install;
		#cp $AMHDir/packages/$Php71Version/php.ini-production /usr/local/php7.1/etc/php.ini;
		#mv /usr/local/php7.1/etc/php.ini /usr/local/php7.1/etc/php.ini.bak;
		cp $AMHDir/packages/untar/$confver/php71.ini /usr/local/php7.1/etc/php.ini;
		mkdir -p /etc/php.d/7.1;
        sed -i 's/post_max_size =.*/post_max_size = 150M/g' /usr/local/php7.1/etc/php.ini;
        sed -i 's/upload_max_filesize =.*/upload_max_filesize = 150M/g' /usr/local/php7.1/etc/php.ini;
        sed -i 's/;date.timezone =.*/date.timezone = PRC/g' /usr/local/php7.1/etc/php.ini;
        sed -i 's/short_open_tag =.*/short_open_tag = On/g' /usr/local/php7.1/etc/php.ini;
        sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' /usr/local/php7.1/etc/php.ini;
        sed -i 's/max_execution_time =.*/max_execution_time = 300/g' /usr/local/php7.1/etc/php.ini;
# Extension **********************************
#cat > /usr/local/php7.1/etc/php.ini<<EOF
#extension=openssl.so
#EOF
# Extension***********************************
		echo "[OK] ${Php71Version} install completed.";
	else
		echo '[OK] PHP7.1 is installed.';
	fi;
	/etc/init.d/amh-start;
	rm -rf /home/amh_install;
}
CheckSystem;
Install;
Download;
InstallReady;
InstallPhp;
[ "$confirm53" == 'y' ] && InstallPhp53;
[ "$confirm54" == 'y' ] && InstallPhp54;
[ "$confirm55" == 'y' ] && InstallPhp55;
[ "$confirm70" == 'y' ] && InstallPhp70;
[ "$confirm71" == 'y' ] && InstallPhp71;
