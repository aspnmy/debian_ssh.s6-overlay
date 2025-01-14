#!/bin/bash
CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd) # 当前脚本所在目录
PARENT_DIR=$(dirname "$CURRENT_DIR") # 当前脚本所在目录的上级目录
ROOT_DIR=$(dirname "$PARENT_DIR") # 当前脚本所在目录的上上上级目录(根目录)



# 定义变量
IP_TXT_PATH="${CURRENT_DIR}/ipdata/china_ip.aspnmy"
IP_URL="https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"


down_CNip(){



    # 使用 curl 下载并解析中国 IP 地址段
    curl "${IP_URL}" | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > "${IP_TXT_PATH}"

}





main(){
    
    # 24小时执行一次地址下载
    while true; do
    down_CNip > /dev/null 2>&1
    #sleep 43200  # 43200 秒 = 12 小时
    sleep 86400
    done
}

main &