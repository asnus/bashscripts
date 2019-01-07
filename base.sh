#!/bin/sh
#
#v0.1新建
#
#本脚本用于安装后首次对服务器进行配置
#
#将计算机升级到最新状态
#安装epel-release第三方库
#安装常用软件
#根据服务器还是桌面应用设置防火墙和selinux，如果是桌面类型将关闭防火墙和selinux
#
#
#运行操作系统为centos 6 或 7
#脚本要点：以root身份运行
#
#lzh
#2018-8-30

if [ "$(whoami)" != "root" ]
then
echo "NOT in root, please run IN root."
exit 1
fi

# 变量设置
os_user=guest
os_type=desktop

#操作系统版本
VERSION=` cat /etc/redhat-release |grep -o '[6-7]' |head -n 1 `
#脚本所在目录
DIR="$(cd "$(dirname "$0")"&&pwd)"

yum install -y epel-release
yum clean all
yum makecache
 
yum update -y
yum install -y nano vim git wget python-devel kernel-headers kernel-devel gcc

case $VERSION in
  '6')
     if [ "$os_type" == "desktop" ] ; then
        service iptables stop
        chkconfig iptables off
     fi
     ;;
  '7')
     if [ "$os_type" == "desktop" ] ; then
        systemctl stop firewalld
        systemctl disable firewalld
     fi
     ;;
   *)
    echo 'NOT surpport this platform'
    exit 1
esac

if [ "$os_type" == "desktop" ] ; then
   sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
   setenforce 0
fi

rm -f /etc/vimrc.bak
mv /etc/vimrc /etc/vimrc.bak
cp $DIR/vimrc /etc/

echo 'DONE!'

