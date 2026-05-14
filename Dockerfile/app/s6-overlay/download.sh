#!/bin/bash
# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "此脚本需要以 root 权限运行。"
    exit 1
fi
CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd)
S6_OVERLAY_VERSION=$(curl -sL https://raw.githubusercontent.com/just-containers/s6-overlay/refs/heads/master/conf/defaults.mk | grep '^VERSION' | awk '{print $3}')
S6_OVERLAY_UPDATE_URL="https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}"

mkdir -p "${CURRENT_DIR}/tmp"

check_install_xz() {
    if ! command -v xz &> /dev/null; then
        echo "未检测到 xz 工具，正在自动安装..."

        if command -v opkg &> /dev/null; then
            opkg update
            opkg install xz
        elif command -v apt &> /dev/null || command -v apt-get &> /dev/null; then
            apt update -y
            apt install xz-utils -y
        elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
            yum install xz -y
        else
            echo "错误：无法自动安装 xz，请手动安装后重试"
            exit 1
        fi
    else
        echo "xz 已存在，跳过安装"
    fi
}

download_xzbin(){
    curl -fsSL -o "${CURRENT_DIR}/tmp/s6-overlay-noarch.tar.xz" "${S6_OVERLAY_UPDATE_URL}/s6-overlay-noarch.tar.xz"
    curl -fsSL -o "${CURRENT_DIR}/tmp/s6-overlay-x86_64.tar.xz" "${S6_OVERLAY_UPDATE_URL}/s6-overlay-x86_64.tar.xz"
}

unzip_xzbin(){
    mkdir -p "${CURRENT_DIR}/tmp/s6-overlay-noarch" "${CURRENT_DIR}/tmp/s6-overlay-x86_64"

    if tar -Jxf "${CURRENT_DIR}/tmp/s6-overlay-noarch.tar.xz" -C "${CURRENT_DIR}/tmp/s6-overlay-noarch/"; then
        rm -vf "${CURRENT_DIR}/tmp/s6-overlay-noarch.tar.xz"
    fi

    if tar -Jxf "${CURRENT_DIR}/tmp/s6-overlay-x86_64.tar.xz" -C "${CURRENT_DIR}/tmp/s6-overlay-x86_64/"; then
        rm -vf "${CURRENT_DIR}/tmp/s6-overlay-x86_64.tar.xz"
    fi
}

zip_gzbin(){
    tar -czvf "${CURRENT_DIR}/tmp/s6-overlay-noarch.tar.gz" -C "${CURRENT_DIR}/tmp" s6-overlay-noarch
    tar -czvf "${CURRENT_DIR}/tmp/s6-overlay-x86_64.tar.gz" -C "${CURRENT_DIR}/tmp" s6-overlay-x86_64
}

main(){
    check_install_xz
    download_xzbin
    unzip_xzbin
    zip_gzbin
    echo -e "\n✅ 执行完成，生成的 tar.gz 文件位于：${CURRENT_DIR}/tmp"
}

main