#!/bin/bash

# 内存不足的时候可以停止所有进程
CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd) # 当前脚本所在目录
PARENT_DIR=$(dirname "$CURRENT_DIR") # 当前脚本所在目录的上级目录
ROOT_DIR=$(dirname "$PARENT_DIR") # 当前脚本所在目录的上上上级目录(根目录)


main(){
   sudo pkill -f ${CURRENT_DIR}/cfst_hosts.sh
   sudo pkill -f ${CURRENT_DIR}/ck_bestIP_12htask.sh   
   sudo pkill -f ${CURRENT_DIR}/ck_bestHost_24htask.sh
   sudo pkill -f ${CURRENT_DIR}/down_CNip.sh

   sudo pkill -f ${ROOT_DIR}/git-hooks/pre-commit
}

main