#!/bin/bash
set -eo pipefail

DEVICE="rxe0"
SESSION_NAME="rdma_roce"

clear
echo "============================================="
echo "   🚀 RDMA 专用多窗口会话工具（tmux）"
echo "============================================="
echo " 1) 新建窗口 → 启动 RDMA 服务端"
echo " 2) 新建窗口 → 启动 RDMA 客户端"
echo " 3) 切回 RDMA 窗口（查看连接状态）"
echo " 4) 退出窗口（保持后台运行）"
echo " 5) 关闭所有 RDMA 窗口"
echo "============================================="
read -p "请选择 [1/2/3/4/5]: " CHOICE

# 检查是否存在 tmux
if ! command -v tmux &> /dev/null; then
    echo -e "\n[错误] 请先安装 tmux: yum install -y tmux 或 apt install -y tmux"
    exit 1
fi

case $CHOICE in
    1)
        echo -e "\n创建服务端窗口并启动监听..."
        tmux new-session -d -s $SESSION_NAME
        tmux send-keys -t $SESSION_NAME "while true; do ib_write_bw -d $DEVICE -b -t 128; echo '重启中...'; sleep 1; done" C-m
        echo "服务端已在独立窗口启动！"
        echo "使用 3 可切回查看"
        ;;

    2)
        echo ""
        read -p "输入服务端 IP: " IP
        tmux new-session -d -s $SESSION_NAME
        tmux send-keys -t $SESSION_NAME "while true; do ib_write_bw -d $DEVICE $IP -b -t 128 -n 99999999; echo '重连中...'; sleep 1; done" C-m
        echo "客户端已启动！使用 3 切回查看"
        ;;

    3)
        tmux attach -t $SESSION_NAME
        ;;

    4)
        tmux detach-client
        ;;

    5)
        tmux kill-session -t $SESSION_NAME 2>/dev/null || true
        echo "已关闭所有 RDMA 窗口"
        ;;

    *)
        echo "输入 1-5"
        exit 1
        ;;
esac
