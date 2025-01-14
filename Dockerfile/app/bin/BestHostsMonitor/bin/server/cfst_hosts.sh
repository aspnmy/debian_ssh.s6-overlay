#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd) # 当前脚本所在目录
PARENT_DIR=$(dirname "$CURRENT_DIR") # 当前脚本所在目录的上级目录

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

get_CloudflareBestIP() {
	# 这里可以自己添加、修改 CloudflareST 的运行参数
	./CloudflareST -o "result_hosts.txt" 

	BESTIP=$(sed -n "2,1p" result_hosts.txt | awk -F, '{print $1}')
	if [[ -z "${BESTIP}" ]]; then
		echo "CloudflareST 测速结果 IP 数量为 0，跳过下面步骤..."
		exit 0
	fi
	local cfhosts_files
	local myIPCountry
	#echo $myIPCountry
	myIPCountry=$(get_myIPCountry)
    if [ "$myIPCountry" = "中国" ]; then
   		cfhosts_files="cfhosts-cn.aspnmy"
        
    else
        cfhosts_files="cfhosts-en.aspnmy"
    fi

    # 删除 # CF_BESTIP_HOSTS_Aspnmy 到 # CF_BESTIP_HOSTS_Aspnmy 之间的数据包括标签本身
    sed -i '/# CF_BESTIP_HOSTS_Aspnmy/,/# CF_BESTIP_HOSTS_Aspnmy/d' ${CURRENT_DIR}/${cfhosts_files}
	time=$(date "+%Y-%m-%d %H:%M:%S")
	#echo "${cfhosts_files}" 

    echo "# CF_BESTIP_HOSTS_Aspnmy" >> ${CURRENT_DIR}/${cfhosts_files}
	echo "${BESTIP} *.cloudflare.com" >> ${CURRENT_DIR}/${cfhosts_files}
	echo "# 更新时间：${time}" >> ${CURRENT_DIR}/${cfhosts_files}
    echo "# CF_BESTIP_HOSTS_Aspnmy" >> ${CURRENT_DIR}/${cfhosts_files}
}




main(){
    get_CloudflareBestIP
}

main