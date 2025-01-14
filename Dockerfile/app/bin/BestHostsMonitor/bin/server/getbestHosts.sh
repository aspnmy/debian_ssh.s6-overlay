#! bin/bash

# 监控GIThub加速工具
# gitHUB_wURL="https://github-hosts.tinsfox.com/hosts"

CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd) # 当前脚本所在目录
PARENT_DIR=$(dirname "$CURRENT_DIR") # 当前脚本所在目录的上级目录
ROOT_DIR=$(dirname "$PARENT_DIR") # 当前脚本所在目录的上上上级目录(根目录)


aspnmy_githubHOSTS_tmp="${CURRENT_DIR}/hosts-en.aspnmy"
aspnmy_cfHOSTS_tmp="${CURRENT_DIR}/cfhosts-en.aspnmy"

IP_TXT_PATH="${CURRENT_DIR}/ipdata/china_ip.aspnmy"
gitHUB_wURL="https://github-hosts.tinsfox.com/hosts"

get_latest_gitHUB_BEST_HOSTS() {
    # 获取最新版本下载地址
    local gitHUB_BEST_HOSTS
    gitHUB_BEST_HOSTS=$(curl -l $gitHUB_wURL)
    echo "$gitHUB_BEST_HOSTS"
}

init_hosts(){
    local oldhosts
    oldhosts=$(cat ${aspnmy_HOSTS})
    echo "${oldhosts}" > ${CURRENT_DIR}/hosts-en.aspnmy
  
}

set_github_hosts() {
    # 设置hosts
    local gitHUB_BEST_HOSTS
    gitHUB_BEST_HOSTS=$(get_latest_gitHUB_BEST_HOSTS)
    if [ -z "$gitHUB_BEST_HOSTS" ]; then
        echo "未能获取最新地址"
        exit 1
    fi


    # 删除 # github_BEST_Hosts_Aspnmy 到 # github_BEST_Hosts_Aspnmy之间的数据包括标签本身
    sed -i '/# github_BEST_Hosts_Aspnmy/,/# github_BEST_Hosts_Aspnmy/d' ${CURRENT_DIR}/hosts-en.aspnmy

    # 将远程数据写入hosts文件
    echo "# github_BEST_Hosts_Aspnmy" >> ${CURRENT_DIR}/hosts-en.aspnmy
    echo "$gitHUB_BEST_HOSTS" >> ${CURRENT_DIR}/hosts-en.aspnmy
    echo "# github_BEST_Hosts_Aspnmy" >> ${CURRENT_DIR}/hosts-en.aspnmy
        # 将远程数据写入hosts文件
    echo "# github_BEST_Hosts_Aspnmy" >> ${CURRENT_DIR}/hosts-cn.aspnmy
    echo "$gitHUB_BEST_HOSTS" >> ${CURRENT_DIR}/hosts-cn.aspnmy
    echo "# github_BEST_Hosts_Aspnmy" >> ${CURRENT_DIR}/hosts-cn.aspnmy
}

set_CloudflareBestIP() {
	local cfhosts_files
	local myIPCountry
	myIPCountry=$(get_myIPCountry)
    if [ "$myIPCountry" = "中国" ]; then
   		cfhosts_files="cfhosts-cn.aspnmy"
        
    else
        cfhosts_files="cfhosts-en.aspnmy"
    fi
	local oldcfbestip
    oldcfbestip=$(cat ${CURRENT_DIR}/${cfhosts_files})

    # 删除 # github_BEST_Hosts_Aspnmy 到 # github_BEST_Hosts_Aspnmy之间的数据包括标签本身
    sed -i '/# CF_BESTIP_HOSTS_Aspnmy/,/# CF_BESTIP_HOSTS_Aspnmy/d' ${CURRENT_DIR}/${cfhosts_files}

   
	echo " ${oldcfbestip} " >> ${CURRENT_DIR}/${cfhosts_files}

}

push_en_besthosts(){
    local en_besthosts_dir="${ROOT_DIR}/EN/besthosts.list"
    local en_besthosts
    en_besthosts=$(cat ${CURRENT_DIR}/hosts-en.aspnmy)

    echo "${en_besthosts}" > ${en_besthosts_dir}

}

push_cn_besthosts(){
    local cn_besthosts_dir="${ROOT_DIR}/CN/besthosts.list"
    local cn_besthosts
    cn_besthosts=$(cat ${CURRENT_DIR}/hosts-cn.aspnmy)

    echo "${cn_besthosts}" > ${cn_besthosts_dir}

}

PUSH_BESTHOSTS(){
    local myIPCountry
    myIPCountry=$(get_myIPCountry)
    if [ "$myIPCountry" = "中国" ]; then
   
        push_cn_besthosts
    else
        push_en_besthosts
    fi

}



get_myIPBaiDU(){
# 国内接口获取ip
# 发送请求并提取 IP 地址
local external_ip
external_ip=$(curl -s https://qifu-api.baidubce.com/ip/local/geo/v1/district | jq -r '.ip')
    
    if [ -z "$external_ip" ]; then
        echo "无法获取外网 IP 地址。"
    else
        #echo "外网 IP 地址: $external_ip"
        echo "$external_ip"
    fi

}

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


ck_Ip(){

    local myIP
    myIP=$(get_myIPBaiDU)
    echo "$myIP"
    local Reorg
    Reorg=$(is_china_ip $myIP)
    if [ "$Reorg" = 1 ]; then
        echo "1"
        #echo "IP 地址 ${IP} 在中国"
    else
        echo "0"
        #echo "IP 地址 ${IP} 在国外"
    fi
}

# 检查 IP 地址是否在中国
is_china_ip() {
    local IP="$1"
    while read -r line; do
        if ipcalc -c "$IP" -n "$line" > /dev/null 2>&1; then
            return 0
        fi
    done < "${IP_TXT_PATH}"
    return 1
}


main() {
    
    #init_hosts
    set_github_hosts
    set_CloudflareBestIP

    PUSH_BESTHOSTS

    
}

main