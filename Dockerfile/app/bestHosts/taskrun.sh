#!/bin/bash

# 24小时执行一次

CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd) # 当前脚本所在目录


main(){
    while true; do
        bash ${CURRENT_DIR}/set_cfgithub_hosts.sh &

        #sleep 86400  # 86400 秒 = 24 小时
        sleep 86400
    done

}

main