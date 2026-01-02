#!/usr/bin/env bash
#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Set git global configuration
git config --global user.name "aspnmy"
git config --global user.email "support@e2bank.cn"

git clone -b devbox https://github.com/aspnmy/BestHostsMonitor.git