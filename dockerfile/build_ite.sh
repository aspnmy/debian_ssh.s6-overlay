#!/bin/bash
apt-get install -y openssh-server
# 创建SSH配置文件 创建SSH密钥
mkdir /var/run/sshd && ssh-keygen -A
# 设置root用户密码
echo 'root:rootadmin' | chpasswd
# 配置SSH服务 
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && sed -i 's/#StrictModes yes/StrictModes no/' /etc/ssh/sshd_config