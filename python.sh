#!/bin/sh
#
#v0.1新建
#
#本脚本用于配置python3.4运行环境 以及 jupyter notebook 服务
#
#
#以 conda 创建 python  虚拟环境
#设置jupyter notebook 服务 服务名称为notebook(centos6) 或notebook.service(centos7)
#
#
#运行操作系统为centos 6 或 7
#运行权限为root管理员
#
# 
#
#lzh
#2018-8-30

if [ "$(whoami)" != "root" ]
then
echo "NOT in root, please run IN root."
exit 1
fi

#变量设置
os_user=guest
os_type=desktop
venv_dir=/opt/venv
venv_version=3.6

#操作系统版本
VERSION=` cat /etc/redhat-release |grep -o '[6-7]' |head -n 1 `
#脚本所在目录
DIR="$(cd "$(dirname "$0")"&&pwd)"

yum install -y  python34 python34-devel python34-tkinter
python3.4 -m ensurepip
python3.4 -m pip install -q conda

[ -e /home/$os_user/.pip ] || mkdir /home/$os_user/.pip
[ -e /home/$os_user/.pip/pip.conf ] || touch /home/$os_user/.pip/pip.conf

(
cat<<EOF
[global]
https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host=pypi.tuna.tsinghua.edu.cn
EOF
)  </home/$os_user/.pip/pip.conf
chown -R $os_user:$os_user /home/$os_user/.pip

[ -e /home/$os_user/.condarc ] || touch /home/$os_user/.condarc

( 
cat<<EOF
channels:
- https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
- https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
- https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
- defaults
show_channel_urls: true
EOF
)  >/home/$os_user/.condarc
chown $os_user:$os_user /home/$os_user/.condarc

[ -e $venv_dir ] || mkdir $venv_dir
origin_user=` ls -al $venv_dir/.. | head -n 2 | tail -n 1 | awk '{print $3}' `
chown $os_user  $venv_dir/..
rm -rf $venv_dir
su - $os_user -c "python3.4 -m conda create -q -y -p $venv_dir python=$venv_version --copy "
chown $origin_user $venv_dir/..

su - $os_user -c "python3.4 -m conda install -q -y -p $venv_dir  jupyter notebook spyder matplotlib"
su - $os_user -c "python3.4 -m conda install -q -y -p $venv_dir numpy scipy pandas basemap"

[ -e /etc/profile.bak ] && mv /etc/profile.bak /etc/profile.origin 
cp /etc/profile /etc/profile.bak
sed -i '/.*PROJ_LIB.*/d' /etc/profile
echo "export PROJ_LIB=$venv_dir/share/proj" >>/etc/profile

rm -f $venv_dir/jupyter_notebook_config.py 
cp $DIR/jupyter_notebook_config.py $venv_dir/
rm -f $venv_dir/lib/python$venv_version/site-packages/matplotlib/mpl-data/matplotlibrc.bak
mv $venv_dir/lib/python$venv_version/site-packages/matplotlib/mpl-data/matplotlibrc $venv_dir/lib/python$venv_version/site-packages/matplotlib/mpl-data/matplotlibrc.bak
cp $DIR/matplotlibrc $venv_dir/lib/python$venv_version/site-packages/matplotlib/mpl-data/
rm -f $venv_dir/lib/python$venv_version/site-packages/matplotlib/mpl-data/fonts/ttf/simhei.ttf
cp $DIR/simhei.ttf $venv_dir/lib/python$venv_version/site-packages/matplotlib/mpl-data/fonts/ttf/
chown $os_user:$os_user $venv_dir/jupyter_notebook_config.py $venv_dir/lib/python$venv_version/site-packages/matplotlib/mpl-data/matplotlibrc $venv_dir/lib/python$venv_version/site-packages/matplotlib/mpl-data/fonts/ttf/simhei.ttf

case $VERSION in
  '6')
     rm -f /etc/rc.d/init.d/notebook
     cp $DIR/notebook /etc/rc.d/init.d/
     service notebook start
     chkconfig notebook on
     if [ "$os_type" == "server" ] ; then
        iptables -A INPUT -p tcp --dport 8888 -j ACCEPT 
        etc/rc.d/init.d/iptables save
        /etc/init.d/iptables restart
     fi
     ;;
  '7')
     rm	-f /usr/lib/systemd/system/notebook.service
     cp	$DIR/notebook.service /usr/lib/systemd/system/
     systemctl start notebook.service
     systemctl enable notebook.service
     if [ "$os_type" == "server" ] ; then
        firewall-cmd --zone=public --add-port=8888/tcp --permanent
        firewall-cmd --reload
        systemctl start notebook.service
        systemctl enable notebook.service
     fi
     ;;
   *)
    echo 'NOT surpport this platform'
    exit 1
esac
