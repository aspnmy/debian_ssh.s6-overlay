#!bin/bash
#-------函数定义-------------
stop_sshd(){
    # 停止当前的sshd服务
    if pkill -f sshd; then
        echo "已停止当前的sshd服务"
    else
        echo "没有运行中的sshd服务或停止失败"
    fi
}

start_sshd(){
# 启动sshd服务
    if /usr/sbin/sshd -D; then
        echo "sshd服务已成功启动"
        return 0
    else
        echo "sshd服务启动失败！"
        return 1
    fi
}


restart_sshd(){
# 先停止当前的sshd服务
    if pkill -f sshd; then
        echo "已停止当前的sshd服务"
    else
        echo "没有运行中的sshd服务或停止失败"
    fi
    
    # 启动sshd服务
    if /usr/sbin/sshd -D; then
        echo "sshd服务已成功启动"
        return 0
    else
        echo "sshd服务启动失败！"
        return 1
    fi
}

main(){
     case "$1" in
        "restart")
            restart_sshd
            ;;
        "start")
            start_sshd
            ;;
        "stop")
            stop_sshd
            ;;
        *)
            echo "无效的选择。请使用以下格式运行脚本："
            echo "Int 'restart'"
            echo "Int 'start'"
            echo "Int 'stop'"  
            exit 1
            ;;
    esac
}

main "$@"