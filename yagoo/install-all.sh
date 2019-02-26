#!/bin/sh
echo "亚古科技服务安装程序"
echo "Copyright 2018 yagoosafe.com All right reserved. This software is theconfidential and proprietary information of yagoosafe.com . You shall not disclose such Confidential Information and shalluse it only in accordance with the terms of the license agreement you enteredinto with yagoosafe.com."
echo "版权所有，翻版必究。本软件涉及机密信息，您不得披露该保密信息，应使用它只在许可协议中的条款范围内。"

echo "A：安装    B： 升级   Z：退出"
echo -n "请输出您的选择："
read choice
if [[ $choice = [Aa] ]]
then
	echo "开始执行安装"	
	# 首先安装各类第三方rpm包，包含redis、nginx
	echo "begin to start redis.nginx .."
	rm -f /var/run/yum.pid
	yum install -y --disablerepo=* *.rpm
	
	rm  -f  *.rpm
	# 复制nginx.conf以及443证书
	cd /etc/nginx

	mkdir backup
	#备份原生nginx的配置文件
	cp nginx.conf backup
	
	cd /httx/run/nginx
	
	# 将nginx中的nginx文件移动到nginx中
	mv *.conf /etc/nginx/conf.d/
	
	mv server.* /etc/nginx/
	
	# install jdk
	echo "begin to start jdk..."
	yum -y remove java*
	cd /httx/run/
	tar -zxvf jdk-8u191-linux-x64.tar.gz
	rm -f jdk-8u191-linux-x64.tar.gz
	mv jdk1.8.0_191/ jdk 

	echo '#jdk path config' >> /etc/profile
	echo 'JAVA_HOME=/httx/run/jdk' >> /etc/profile
	echo 'JRE_HOME=/httx/run/jdk' >> /etc/profile
	echo 'CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib:$JAVA_HOME/jre/lib' >> /etc/profile
	echo 'export JAVA_HOME JRE_HOME CLASSPATH' >> /etc/profile
	echo 'export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH' >> /etc/profile
	echo "" >> /etc/profile

	# install mysql
	mysqlpwd='YG@root#safe'
	echo "开始安装MySQL服务..."
	echo "MySQL默认root密码为：'$mysqlpwd' "
	echo "是否修改密码？如修改：请输入 【y-是】；不修改：按任意键继续!"
	read choice1
	if [[ $choice1 = [Yy] ]]
	then
		echo "请输入自定义密码："
		read newpwd
		mysqlpwd=$newpwd
	fi
	find / -name mysql|xargs rm -rf
	find / -name my.cnf|xargs rm -rf
	mv mys.cnf my.cnf
	cd /httx/run
	tar -zxvf mysql-5.7.24-linux-glibc2.12-x86_64.tar.gz 
	rm -f mysql-5.7.24-linux-glibc2.12-x86_64.tar.gz 
	mv mysql-5.7.24-linux-glibc2.12-x86_64/ mysql
	groupadd mysql
	useradd -r -g mysql mysql
	cd /httx/run/mysql
	chown -R mysql:mysql ./
	cp /httx/run/mysql/support-files/mysql.server /etc/init.d/mysql
	sed -i '1,50s|basedir=|basedir=/httx/run/mysql|' /etc/init.d/mysql
	sed -i '1,50s|datadir=|datadir=/httx/run/mysql/data|' /etc/init.d/mysql
	cp /httx/run/my.cnf /etc/my.cnf
	cd /httx/run/mysql/bin/
	./mysqld --initialize --user=mysql --basedir=/httx/run/mysql --datadir=/httx/run/mysql/data
	cd /usr/local/bin
	ln -fs /httx/run/mysql/bin/mysql mysql
	 
	service mysql start
	cd /httx/run/
	mysql -u root < changepw.sql

	sleep 5s
	rm -rf changepw.sql
	sed -i '1,50s|skip-grant-tables=1| |' /etc/my.cnf
	firewall-cmd --zone=public --add-port=3306/tcp --permanent
	firewall-cmd --reload
	chkconfig --add mysql
	service mysql restart	
	
	echo 'MYSQL_HOME=/httx/run/mysql' >> /etc/profile
	echo 'export PATH=$PATH:$MYSQL_HOME/bin' >> /etc/profile
	.  /etc/profile
	mysql  --connect-expired-password  -e "alter user user() identified by '$mysqlpwd';"
	sed -i '1,50s|host=localhost| |' /etc/my.cnf
	sed -i '1,50s|user=root| |' /etc/my.cnf
	sed -i "1,50s|password='123456'| |" /etc/my.cnf
	
	#安装activemq
	echo "begin to start activemq "
	cd /httx/run
	#将文件拷贝到/etx/init.d/下
    mv activemq /etc/init.d/	

	tar -zxvf  apache-activemq-5.15.8-bin.tar.gz
	
	
	cd /httx/run
	rm -rf apache-activemq-5.15.8-bin.tar.gz
	
	##添加软链，任意位置启动ActiveMQ
	#chmod -R  654 apache-activemq-5.14.0
	
	mv apache-activemq-5.15.8/ activemq
	
	ln -s /httx/run/activemq/bin/activemq /etc/init.d/
	#将文件拷贝到/etx/init.d/下
	#mv activemq /etc/init.d/
	#对文件赋予权限：
	chmod 777 /etc/init.d/activemq
	#设置开机自启
	#chkconfig --add  activemq
	
	chkconfig activemq on
	
	echo 'service activemq restart ' >> /etc/rc.d/rc.local
	
	chmod +x /etc/rc.d/rc.local
	# install tomcat
	echo "begin to start tomcat "
	cd /httx/run/
	mkdir server
	echo 'source /etc/profile' >> /etc/rc.local	
	dir=$(ls -l /httx/run/APP|awk '/^d/ {print $NF}')
	for i in $dir
	do
		cd /httx/run/
		tar -zxvf apache-tomcat-8.5.31.tar.gz 
		mv apache-tomcat-8.5.31 server/$i
		cp  server/$i/conf/server.xml  server/$i/conf/server.xml.bak.yagoo
		cp APP/$i/Install/Init/server.xml server/$i/conf/server.xml
		cp -rf APP/$i/Install/War/* server/$i/webapps/
		
		cd server/$i/
		mkdir YGconfig
		cd /httx/run
		cp APP/$i/Install/Init/APP.info server/$i/YGconfig/APP.info
		cp APP/$i/Install/Init/MySQL.properties server/$i/YGconfig/MySQL.properties
		
		echo '/httx/run/server/'$i'/bin/startup.sh' >> /etc/rc.local	
	done   
	rm -f apache-tomcat-8.5.31.tar.gz

	.  /etc/profile
	chmod 777 /etc/rc.local
	
	

	#redis启动
	systemctl start redis.service
	#开机自启
	systemctl enable redis.service
	#启动nginx
	cd /httx/run/
	setenforce 0
	chmod 644 ./selinux
	cp -a -f ./selinux /etc/selinux/config
	
	
	systemctl start nginx.service
	systemctl enable nginx.service
	
	#启动activemq
	#cd /httx/run/apache-activemq-5.14.0/bin/linux-x86-64
	service activemq start
	#./activemq start
	#执行jar文件
	cd /httx/run/
	java -jar LinuxInstaller.jar Install 
	
	#安装过程将静态文件拷贝到html文件中判断并执行init.jar
	dir=$(ls -l /httx/run/APP|awk '/^d/ {print $NF}')
	for i in $dir

	do
	 cp -rf /httx/run/APP/$i/Install/html/.  /usr/share/nginx/html/
		 if [ ! -f "/httx/run/APP/$i/Install/Init/Init.jar" ];
		 then
		  echo "Init.jar文件不存在"
		 else
		  cd /httx/run/APP/$i/Install/Init/
		  java -jar Init.jar 
			if [ $? -eq 0 ]
			then
				echo "执行$i私有化安装成功"
			else
				echo "执行$i私有化安装失败"
			fi
		 fi
	done
	
	# 设置防火墙
	httpPortcount=0
	httpsPortcount=0
	str=""
	if [ $httpPortcount -le 1 ]
	then
			read line
			let httpPortcount++
			echo "$line"
			str=$line
	fi< /httx/run/httpPort.txt
	firewall-cmd --zone=public --add-port=$str/tcp --permanent
	if [ $httpsPortcount -le 1 ]
	then
			read line
			let httpsPortcount++
			echo "$line"
			str=$line
	fi< /httx/run/httpsPort.txt
	firewall-cmd --zone=public --add-port=$str/tcp --permanent
	firewall-cmd --zone=public --add-port=6379/tcp --permanent
	firewall-cmd --zone=public --add-port=80/tcp --permanent
	firewall-cmd --zone=public --add-port=443/tcp --permanent
	firewall-cmd --zone=public --add-port=61616/tcp --permanent
	firewall-cmd --zone=public --add-port=8161/tcp --permanent
	firewall-cmd --reload
	
	#如果在 init.jar中修改了nginx的配置文件应该重新加载
	systemctl reload nginx.service
	cd /httx/run/
	rm -rf http*Port*
	rm -f selinux
	rm -f LinuxInstaller.jar
	rm -rf nginx
	rm -rf APP
	echo "安装完成，部分配置重启后生效"
elif [[ $choice = [Bb] ]]
then
	echo "开始执行升级"
	.  /etc/profile
	cd /httx/run/
	java -jar LinuxInstaller.jar Update 
	
	#升级过程中判断并执行Update.jar
	dir=$(ls -l /httx/run/APP|awk '/^d/ {print $NF}')
	for i in $dir
	do
		if [ ! -f "/httx/run/APP/$i/Update/Update.jar" ];then
		 echo "Update.jar文件不存在"
		else
		cd /httx/run/APP/$i/Update/
		 java -jar Update.jar 
		 if [ $? -eq 0 ]
			then
				echo "执行$i自有升级成功"
			else
				echo "执行$i自有升级失败"
			fi
		fi
	done
	
	cd /httx/run/
	rm -f LinuxInstaller.jar
#	rm -rf APP
	echo "升级完成"
else
	echo "退出"
fi

