#!/bin/bash

DEVICE="rxe0"

echo "============================================="
echo " 🚀 RDMA 客户端 - 长连接常驻脚本"
echo " 功能：自动重连 | 保持在线 | 不断开"
echo "============================================="

read -p "请输入服务端 IP 地址: " SERVER_IP

if [ -z "$SERVER_IP" ]; then
    echo "[错误] IP 不能为空"
    exit 1
fi

echo -e "\n============================================="
echo " 已配置：服务端 IP = $SERVER_IP"
echo " 开始建立长连接，并自动保持重连…"
echo "=============================================\n"

# 无限循环保持连接
while true; do
    echo "[客户端] 正在连接：$SERVER_IP"
    ib_write_bw -d $DEVICE $SERVER_IP -b -t 128 -n 99999999
    echo -e "\n[客户端] 连接断开，1 秒后自动重连…\n"
    sleep 1
done
