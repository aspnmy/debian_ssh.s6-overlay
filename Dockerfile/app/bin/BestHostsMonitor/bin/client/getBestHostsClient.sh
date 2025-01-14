#! bin/bash

# 监控定时工具12小时执行一次

CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd) # 当前脚本所在目录
PARENT_DIR=$(dirname "$CURRENT_DIR") # 当前脚本所在目录的上级目录
# https://raw.githubusercontent.com/aspnmy/BestHostsMonitor/refs/heads/main/EN/besthosts.list
# 公共入口
wURL_EN="https://raw.githubusercontent.com/aspnmy/BestHostsMonitor/refs/heads/main"
wURL_CN="https://git.t2be.cn/aspnmy/BestHostsMonitor/raw/branch/CN/CN"

# # Cn区
# Cn_hosts="${wURL}/CN/hosts.list"
# Cn_sources="${wURL}/CN/sources.list"
# Cn_docker="${wURL}/CN/docker.list"

# # En区
# En_hosts="${wURL}/EN/hosts.list"
# En_sources="${wURL}/EN/sources.list"
# En_docker="${wURL}/EN/docker.list"

# 客户端

get_myIPCountry(){
# 国内接口获取ip
# 发送请求并提取 IP 地址
local truecountry
truecountry=$(curl -s  https://qifu-api.baidubce.com/ip/local/geo/v1/district | jq -r '.data.country')
    if [ -z "$truecountry" ]; then
        echo "未知地区。"
    else
        #echo "外网 IP 地址: $external_ip"
        echo "$truecountry"
    fi

}

update_hosts_sources_docker(){
	local myIPCountry
	myIPCountry=$(get_myIPCountry)
    if [ "$myIPCountry" = "中国" ]; then
        hosts="${wURL_CN}/CN/hosts.list"
        sources="${wURL_CN}/CN/sources.list"
        docker="${wURL_CN}/CN/docker.list"
        
    else
        hosts="${wURL_EN}/EN/hosts.list"
        sources="${wURL_EN}/EN/sources.list"
        docker="${wURL_EN}/EN/docker.list"
    fi

    local updateH
    updateH=$(curl -s $hosts)
    echo "${updateH}" > /etc/hosts

    local updateS
    updateS=$(curl -s $sources)
    echo "${updateS}" > /etc/apt/sources.list

    local updateD
    updateD=$(curl -s $docker) 
    echo "${updateD}" > /etc/docker/daemon.json


}


main() {
    while true; do
        update_hosts_sources_docker > /dev/null 2>&1
        #sleep 43200  # 86400 秒 = 24 小时
        sleep 86400
    done
    
}

main