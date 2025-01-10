#!/bin/bash
# 启动ssh-server

mkdir -p /aspnmy/wwwroot/ssh_key
echo "重置root-sshkey..."
chmod +x /etc/ssh/setRootKey_Cli
/etc/ssh/setRootKey_Cli usrkey

echo "Starting ssh-server..."
/usr/sbin/sshd -D

if [ $? -ne 0 ]; then
  echo "Failed to start ssh-server"
  exit 1
fi

