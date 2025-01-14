#!/bin/bash

# 内存不足的时候可以停止所有进程

CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd) # 当前脚本所在目录


main(){
   sudo pkill -f ${CURRENT_DIR}/set_cfgithub_hosts.sh

}

main