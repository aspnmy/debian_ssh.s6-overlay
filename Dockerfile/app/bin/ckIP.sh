#!/bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd) # 当前脚本所在目录
PARENT_DIR=$(dirname "$CURRENT_DIR") # 当前脚本所在目录的上级目录
# 定义变量
IP_TXT_PATH="${CURRENT_DIR}/ipdata/china_ip.txt"
IP_URL="https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"


down_CNip(){
# 下载前备份旧文件
    if [ -f "${IP_TXT_PATH}" ]; then
        mv "${IP_TXT_PATH}" "${IP_TXT_PATH}_$(date +"%Y%m%d%H%M%S")"
    fi

    # 使用 curl 下载并解析中国 IP 地址段
    curl "${IP_URL}" | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > "${IP_TXT_PATH}"

}

ck_Ip(){
    if is_china_ip; then
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



main(){
    down_CNip
    ck_Ip

}

main