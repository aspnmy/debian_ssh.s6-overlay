#!/bin/bash
set -eo pipefail

echo "============================================="
echo " 🚀 RDMA Soft-RoCE 测试工具（容器专用）"
echo "============================================="
echo " 1) 启动 RDMA 服务端 (监听 0.0.0.0)"
echo " 2) 启动 RDMA 客户端 (连接服务端)"
echo "============================================="
read -p "请选择模式 [1/2]: " CHOICE

if [ "$CHOICE" = "1" ]; then
    echo ""
    echo "[服务端] 启动中：ib_write_bw -d rxe0 -b -t 128"
    echo "[服务端] 监听：0.0.0.0:18515"
    echo "[服务端] 等待客户端连接..."
    echo ""
    ib_write_bw -d rxe0 -b -t 128

elif [ "$CHOICE" = "2" ]; then
    echo ""
    read -p "请输入服务端 IP: " IP
    echo ""
    echo "[客户端] 连接中：$IP"
    echo "[客户端] 命令：ib_write_bw -d rxe0 $IP -b -t 128"
    echo ""
    ib_write_bw -d rxe0 "$IP" -b -t 128

else
    echo "[错误] 请输入 1 或 2"
    exit 1
fi
