#!/bin/bash

MyDir=$(cd `dirname $0`; pwd)

# 安装WEB服务程序
yum -y install zip unzip
mkdir /httx
unzip ./LinuxInstall.zip -d /httx/
rm ./LinuxInstall.zip -f
cd /httx/run
chmod +x install.sh
./install.sh

cd /httx
# 安装字体
yum install -y fontconfig mkfontscale
mv ./fonts/*.ttf /usr/share/fonts/
mkfontscale
mkfontdir
fc-cache -fv

# 安装反弹代理对应程序
chmod +x ./rcsocks/*
crontab < ./rcsocks/crontab.txt
rm ./rcsocks/crontab.txt -f
mv ./rcsocks/* /usr/bin/
rm ./rcsocks -rf
echo "/usr/bin/daemonRcsocks.sh" >> /etc/rc.local

# 安装流量分析程序
cd /httx/FlowAnalysis
python ./Install.py
chmod +x /.ygprog/FlowAnalysis/prepare_before_run.sh

yum install epel-release -y
yum install python36 -y
# 安装终端判断程序
cd /httx/UserAgentAnalysis
mysql -uroot -pYG@root#safe < ./UserAgentAnalysis.sql
python36 ./install.py

# 安装翻墙判断程序
cd /httx/VpnFlowAnalysis
mysql -uroot -pYG@root#safe < ./VpnFlowAnalysis.sql
python36 ./install.py

rm -rf /httx/FlowAnalysis /httx/fonts /httx/rcsocks /httx/UserAgentAnalysis /httx/VpnFlowAnalysis

# 进行一系列善后工作，包括防火墙、权限、删除无用webapps
mv /httx/linux-security /httx/run/jdk/jre
firewall-cmd --add-port=10043/tcp --permanent
firewall-cmd --add-port=1243/tcp --permanent 
firewall-cmd --add-port=1080/tcp --permanent
firewall-cmd --add-port=9998/tcp --permanent
firewall-cmd --reload
chmod -R 777 /httx/count
rm -rf /httx/run/server/users/webapps/docs 
rm -rf /httx/run/server/users/webapps/examples  
rm -rf /httx/run/server/users/webapps/host-manager  
rm -rf /httx/run/server/users/webapps/manager  
rm -rf /httx/run/server/users/webapps/ROOT
rm -rf /httx/run/server/wifilz/webapps/docs  
rm -rf /httx/run/server/wifilz/webapps/examples  
rm -rf /httx/run/server/wifilz/webapps/host-manager  
rm -rf /httx/run/server/wifilz/webapps/manager  
rm -rf /httx/run/server/wifilz/webapps/ROOT
