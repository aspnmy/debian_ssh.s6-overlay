#!/bin/bash
set -eo pipefail

DEVICE="rxe0"
SOCK_NAME="rdma_roce_daemon"

# 检查 screen 是否安装
if ! command -v screen &> /dev/null; then
    echo "未检测到 screen，正在安装..."
    apt update && apt install -y screen
fi

clear
echo "============================================="
echo "   🚀 RDMA Soft-RoCE 虚拟会话常驻合一脚本"
echo "============================================="
echo " 1) 启动常驻服务端（放入虚拟窗口后台）"
echo " 2) 启动长连接客户端（放入虚拟窗口后台）"
echo " 3) 附着进入已存在的虚拟会话"
echo " 4) 停止并销毁 RDMA 虚拟会话"
echo "============================================="
read -p "请选择模式 [1/2/3/4] : " MODE

case $MODE in
    1)
        # 服务端虚拟会话
        if screen -list | grep -q "$SOCK_NAME"; then
            echo "会话已存在，请勿重复启动"
            exit 0
        fi
        echo -e "\n启动 RDMA 服务端 虚拟常驻会话..."
        screen -dmS $SOCK_NAME bash -c "
        while true; do
            echo '[服务端] 监听 0.0.0.0 设备 $DEVICE'
            ib_write_bw -d $DEVICE -b -t 128
            echo '[服务端] 连接断开，1秒后重启...'
            sleep 1
        done
        "
        echo "已后台启动，可选 3 进入查看"
        ;;

    2)
        # 客户端虚拟会话
        if screen -list | grep -q "$SOCK_NAME"; then
            echo "会话已存在，请勿重复启动"
            exit 0
        fi
        echo -e "\n启动 RDMA 客户端 虚拟常驻会话"
        read -p "请输入服务端 IP: " SERVER_IP
        [ -z "$SERVER_IP" ] && echo "IP 不能为空" && exit 1

        screen -dmS $SOCK_NAME bash -c "
        while true; do
            echo '[客户端] 正在连接 $SERVER_IP'
            ib_write_bw -d $DEVICE $SERVER_IP -b -t 128 -n 99999999
            echo '[客户端] 断开，1秒后自动重连...'
            sleep 1
        done
        "
        echo "已后台启动，可选 3 进入查看"
        ;;

    3)
        # 附着会话
        if screen -list | grep -q "$SOCK_NAME"; then
            screen -r $SOCK_NAME
        else
            echo "暂无 RDMA 后台虚拟会话，请先启动服务端/客户端"
        fi
        ;;

    4)
        # 销毁会话
        if screen -list | grep -q "$SOCK_NAME"; then
            screen -S $SOCK_NAME -X quit
            echo "已停止并销毁 RDMA 虚拟会话"
        else
            echo "没有运行中的会话"
        fi
        ;;

    *)
        echo "请输入 1 2 3 4 有效选项"
        exit 1
        ;;
esac
