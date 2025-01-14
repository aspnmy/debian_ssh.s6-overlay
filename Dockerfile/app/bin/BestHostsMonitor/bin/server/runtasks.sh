#!/bin/bash

# 内存不足的时候可以停止所有进程

CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd) # 当前脚本所在目录
PARENT_DIR=$(dirname "$CURRENT_DIR") # 当前脚本所在目录的上级目录
ROOT_DIR=$(dirname "$PARENT_DIR") # 当前脚本所在目录的上上上级目录(根目录)


main(){
   bash ${CURRENT_DIR}/ck_bestIP_12htask.sh   
   bash ${CURRENT_DIR}/ck_bestHost_24htask.sh
   #bash ${CURRENT_DIR}/down_CNip_24htask.sh
   bash ${ROOT_DIR}/git-hooks/pre-commit
}

main