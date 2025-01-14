#! bin/bash

# 监控GIThub加速工具
# gitHUB_wURL="https://github-hosts.tinsfox.com/hosts"

CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd) # 当前脚本所在目录
PARENT_DIR=$(dirname "$CURRENT_DIR") # 当前脚本所在目录的上级目录


gitHUB_wURL="https://github-hosts.tinsfox.com/hosts"
get_latest_gitHUB_BEST_HOSTS() {
    # 获取最新版本下载地址
    local gitHUB_BEST_HOSTS
    gitHUB_BEST_HOSTS=$(curl -l $gitHUB_wURL)
    echo "$gitHUB_BEST_HOSTS"
}

set_github_hosts() {
    # 设置hosts
    local gitHUB_BEST_HOSTS
    gitHUB_BEST_HOSTS=$(get_latest_gitHUB_BEST_HOSTS)
    if [ -z "$gitHUB_BEST_HOSTS" ]; then
        echo "未能获取最新地址"
        exit 1
    fi
    cp ${PARENT_DIR}/hosts ${PARENT_DIR}/backup/hosts_aspnmy_github

    # 删除 # github_BEST_Hosts_Aspnmy 到 # github_BEST_Hosts_Aspnmy之间的数据包括标签本身
    sed -i '/# github_BEST_Hosts_Aspnmy/,/# github_BEST_Hosts_Aspnmy/d' ${PARENT_DIR}/hosts

    # 将远程数据写入hosts文件
    echo "# github_BEST_Hosts_Aspnmy" >> ${PARENT_DIR}/hosts
    echo "$gitHUB_BEST_HOSTS" >> ${PARENT_DIR}/hosts
    echo "# github_BEST_Hosts_Aspnmy" >> ${PARENT_DIR}/hosts
}



main() {
    set_github_hosts
}

main