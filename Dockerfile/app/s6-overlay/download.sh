#! /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd) # 当前脚本所在目录
S6_OVERLAY_VERSION="3.2.0.2"
S6_OVERLAY_UPDATE_URL="https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}"

download_xzbin(){
    wget -P ${CURRENT_DIR}/tmp ${S6_OVERLAY_UPDATE_URL}/s6-overlay-noarch.tar.xz
    wget -P ${CURRENT_DIR}/tmp ${S6_OVERLAY_UPDATE_URL}/s6-overlay-x86_64.tar.xz
}

unzip_xzbin(){
    mkdir -p ${CURRENT_DIR}/tmp/s6-overlay-noarch && mkdir -p ${CURRENT_DIR}/tmp/s6-overlay-x86_64 \
    && tar -C ${CURRENT_DIR}/tmp/s6-overlay-noarch/ -Jxpf ${CURRENT_DIR}/tmp/s6-overlay-noarch.tar.xz \
    && tar -C ${CURRENT_DIR}/tmp/s6-overlay-x86_64/ -Jxpf ${CURRENT_DIR}/tmp/s6-overlay-x86_64.tar.xz
    
    
}

zip_gzbin(){
    tar -czvf ${CURRENT_DIR}/tmp/s6-overlay-noarch.tar.gz ${CURRENT_DIR}/tmp/s6-overlay-noarch \
    && tar -czvf ${CURRENT_DIR}/tmp/s6-overlay-x86_64.tar.gz ${CURRENT_DIR}/tmp/s6-overlay-x86_64
    
}

clean(){
    rm -rf ${CURRENT_DIR}/tmp/*.tar.xz
}


main(){
    download_xzbin
    unzip_xzbin
    zip_gzbin
    clean
    
}

main