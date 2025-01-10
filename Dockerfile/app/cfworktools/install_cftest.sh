download_cfworktools() {
    # 下载CFTest工具
    local wURL
    wURL=$(get_latest_download_url)
    echo "Downloading from $wURL"
	if [ -z "$wURL" ]; then
		echo "未能获取下载地址"
		exit 1
	fi
        # 尝试下载文件，最多重试3次
    local max_retries=3
    local count=0
    local success=0
    while [ $count -lt $max_retries ]; do
        curl -L -o /tmp/CloudflareSpeedTest-linux-amd64.tar.gz $wURL
        if [ $? -eq 0 ]; then
            success=1
            break
        fi
        count=$((count + 1))
        echo "下载失败，重试中... ($count/$max_retries)"
        sleep 2
    done

    if [ $success -ne 1 ]; then
        echo "下载文件失败"
        exit 1
    fi
    mkdir -p /sh/cftest
    tar -xzf /tmp/CloudflareSpeedTest-linux-amd64.tar.gz -C /sh/cftest
    if [ $? -ne 0 ]; then
        echo "解压文件失败"
		if [ ! -f /sh/cftest/version ]; then
			touch /sh/cftest/version
			echo "1.0.0" > /sh/cftest/version
		
		fi        
		exit 1
    fi
	rm -f /tmp/CloudflareSpeedTest-linux-amd64.tar.gz
    chmod +x /sh/cftest/CloudflareST
    chmod +x /sh/cftest/cfst_hosts.sh
    local version=$(get_latest_version)
    if [ ! -f /sh/cftest/version ]; then
        touch /sh/cftest/version
        echo "1.0.0" > /sh/cftest/version
    else
        echo $version > /sh/cftest/version
    fi
}

install_cftest() {
    download_cfworktools
    set_cron
}

set_cron() {
    # 创建一个新的 cron 任务文件
    local cron_file="/etc/cron.d/cfworktools"
    
    # 添加定时任务，每天凌晨 2 点运行 CloudflareSpeedTest
    echo "0 2 * * * root /sh/cftest/CloudflareST > /var/log/cfworktools.log 2>&1" > $cron_file
    
    # 设置权限
    chmod 0644 $cron_file
    
    # 重启 cron 服务以应用更改
    systemctl restart cron
}

ck_version_wURL(){
    if [ -f /sh/cftest/version ]; then
        local old_Version=$(cat /sh/cftest/version)
        local new_Version=$(get_latest_version)
        echo "当前版本：$old_Version"
        echo "最新版本：$new_Version"

        # 去掉版本号中的 'v' 前缀
        local old_Version_num=${old_Version#v}
        local new_Version_num=${new_Version#v}

        
# 比较版本号
        if [ -n "$old_Version_num" ] && [ -n "$new_Version_num" ]; then
            if [ "$(printf '%s\n' "$old_Version_num" "$new_Version_num" | sort -V |tail -n1)" != "$old_Version_num" ]; then
                echo "有新版本可用：$new_Version"
                install_cftest
            else
                echo "当前已经是最新版本。"
            fi
        else
            echo "版本号格式错误或未知。"
            install_cftest
        fi
    else
        echo "版本文件不存在，将安装最新版本。"
        install_cftest
    fi
}

get_latest_version() {
    local latest_release_url="https://api.github.com/repos/XIU2/CloudflareSpeedTest/releases/latest"
    local response=$(curl -s $latest_release_url)
    
    # 输出响应以进行调试
    # echo "GitHub API 响应: $response"
    
    local version=$(echo "$response" | jq -r '.tag_name')
    
    # 检查是否成功获取版本号
    if [ -z "$version" ]; then
        echo "未能获取版本号"
        return 1
    fi
    
    echo "$version"
}

get_latest_download_url() {
    local latest_release_url="https://api.github.com/repos/XIU2/CloudflareSpeedTest/releases/latest"
    local response=$(curl -s $latest_release_url)
    
    # 输出响应以进行调试
     echo "GitHub API 响应: $response"
    
    local download_url=$(echo "$response" | jq -r '.assets[] | select(.name == "CloudflareST_linux_amd64.tar.gz") | .browser_download_url')
    
    # 检查是否成功获取下载地址
    if [ -z "$download_url" ]; then
        echo "未能获取下载地址"
		    if [ ! -f /sh/cftest/version ]; then
				touch /sh/cftest/version
				echo "1.0.0" > /sh/cftest/version
			
			fi
        exit 1
    fi
    
    echo "$download_url"
}

# 主函数 使用参数直接执行业务逻辑
main() {
    ck_version_wURL
}

# 调用主函数
main