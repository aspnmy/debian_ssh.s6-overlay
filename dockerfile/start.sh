#!/bin/bash
# 启动ssh-server
echo "Starting ssh-server..."
/usr/sbin/sshd -D
if [ $? -ne 0 ]; then
  echo "Failed to start ssh-server"
  exit 1
fi

