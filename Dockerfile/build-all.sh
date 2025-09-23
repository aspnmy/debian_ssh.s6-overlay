#!/bin/bash

build_stable_slim(){
    #构建基础镜像
    URI="docker.io"
    AUUSER="aspnmy"
    imgNAME="debian-ssh"
    timeBuild=$(date +"%Y%m%d%H")
    debianVer="stable-${timeBuild}-slim"
    ver="${debianVer}_baseimage"
    buildah bud --no-cache -f ./dockerfile-debian-stable-slim -t $URI/$AUUSER/$imgNAME:$ver 

    buildah push $URI/$AUUSER/$imgNAME:$ver

    echo "$URI/$AUUSER/$imgNAME:$ver"
}

build_stable_workbase(){    
    #构建基础镜像    # 参数1: 基础镜像标签    
    local base_image_tag=$1    
    URI="docker.io"    
    AUUSER="aspnmy"    
    imgNAME="debian-ssh"    
    s6OverlayVer="3210"    
    timeBuild=$(date +"%Y%m%d%H")    
    #从base_image_tag中提取debianVer    
    debianVer=$(echo "$base_image_tag" | awk -F: '{print $2}' | sed 's/^stable-[0-9]*-//')    
    stableVer="stable_${timeBuild}-s6-overlay_v${s6OverlayVer}_workbase_${debianVer}"    
    # 使用--build-arg参数将基础镜像标签传递给Dockerfile    
    buildah bud --no-cache -f ./dockerfile-ssh-s6-overlay-baseimage --build-arg BASE_IMAGE_TAG="$base_image_tag" -t $URI/$AUUSER/$imgNAME:$stableVer    
    buildah push $URI/$AUUSER/$imgNAME:$stableVer    
    echo "$URI/$AUUSER/$imgNAME:$stableVer"
}



build_stable_BestHostsMonitor(){    
    #构建BestHostsMonitor应用镜像    # 参数1: 工作镜像标签    
    local work_image_tag=$1    
    URI="docker.io"    
    AUUSER="aspnmy"    
    imgNAME="debian-ssh"    
    timeBuild=$(date +"%Y%m%d%H")    
    #从work_image_tag中提取稳定版本信息    
    stableVer_base=$(echo "$work_image_tag" | awk -F: '{print $2}')    
    stableVer="${stableVer_base}_BestHostsMonitor"
    
    # 使用--build-arg参数将工作镜像标签传递给Dockerfile    
    buildah bud --no-cache -f ./dockerfile-ssh-s6-overlay-BestHostsMonitor --build-arg BASE_IMAGE_TAG="$work_image_tag" -t $URI/$AUUSER/$imgNAME:$stableVer    
    buildah push $URI/$AUUSER/$imgNAME:$stableVer    
    echo "$URI/$AUUSER/$imgNAME:$stableVer"
}

main(){    
    # 构建基础镜像 
    build_stable_slim   
    # local base_image=$(build_stable_slim)    
    # echo "基础镜像构建完成: $base_image"
    
    # # 确保基础镜像构建成功才继续    
    # if [ -z "$base_image" ]; then        
    #     echo "错误：基础镜像构建失败，无法继续"        
    #     exit 1    
    # fi    
    # # 构建应用工作镜像，传递基础镜像标签    
    # local work_image=$(build_stable_workbase "$base_image")    
    # echo "应用工作镜像构建完成: $work_image"
    
    # # 确保工作镜像构建成功才继续    
    # if [ -z "$work_image" ]; then        
    #     echo "错误：应用工作镜像构建失败，无法继续"        
    #     exit 1    
    # fi    
    # # 构建BestHostsMonitor应用镜像，传递工作镜像标签    
    # local best_hosts_image=$(build_stable_BestHostsMonitor "$work_image")    
    # echo "BestHostsMonitor应用镜像构建完成: $best_hosts_image"
    
}

main
