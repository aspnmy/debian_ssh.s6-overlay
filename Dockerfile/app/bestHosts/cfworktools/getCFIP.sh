#! bin/bash

# 监控CF加速工具

CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd) # 当前脚本所在目录
PARENT_DIR=$(dirname "$CURRENT_DIR") # 当前脚本所在目录的上级目录

CF_BESTIP="${CURRENT_DIR}/cfbestip_hosts.txt"
get_latest_CF_BESTIP() {

    CF_BESTIP=$(cat $CF_BESTIP)
    echo "$CF_BESTIP"
}

set_CF_BESTIP_hosts() {
    # 设置hosts
    local CF_BESTIP_HOSTS
    CF_BESTIP_HOSTS=$(get_latest_CF_BESTIP)
    if [ -z "$CF_BESTIP_HOSTS" ]; then
        echo "未能获取最新地址"
        exit 1
    fi
    cp ${PARENT_DIR}/hosts ${PARENT_DIR}/backup/hosts_aspnmy_cfip
    # 删除 # github_BEST_Hosts_Aspnmy 到 # github_BEST_Hosts_Aspnmy之间的数据包括标签本身
    sed -i '/# CF_BESTIP_HOSTS_Aspnmy/,/# CF_BESTIP_HOSTS_Aspnmy/d' ${PARENT_DIR}/hosts


    # 将远程数据写入hosts文件
    echo "# CF_BESTIP_HOSTS_Aspnmy" >> ${PARENT_DIR}/hosts
    echo "$CF_BESTIP_HOSTS" >> ${PARENT_DIR}/hosts
    echo "# CF_BESTIP_HOSTS_Aspnmy" >> ${PARENT_DIR}/hosts
}



main() {
    set_CF_BESTIP_hosts
}

main