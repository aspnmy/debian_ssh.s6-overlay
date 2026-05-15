#!/bin/bash
echo "============================================="
echo " 🚀 RDMA Soft-RoCE 常驻服务端（保持运行）"
echo " 设备：rxe0"
echo " 监听：0.0.0.0"
echo " 用途：保持容器不退出，允许客户端无限连接"
echo "============================================="

while true; do
    echo "[常驻] 启动 RDMA 服务端..."
    ib_write_bw -d rxe0 -b -t 128
    echo "[常驻] 连接断开，1秒后自动重启服务端…"
    sleep 1
done
