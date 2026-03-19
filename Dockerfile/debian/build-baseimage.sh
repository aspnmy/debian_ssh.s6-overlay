#!/bin/bash

# 读取s6-overlay版本号
if [ -f "s6-overlay-version.md" ]; then
    S6_OVERLAY_VERSION=$(cat s6-overlay-version.md | grep S6_OVERLAY_VERSION | cut -d'=' -f2)
else
    echo "Error: s6-overlay-version.md file not found"
    exit 1
fi

# 读取基础镜像地址
if [ -f "debian-base.md" ]; then
    BASEIMAGE=$(cat debian-base.md | grep BASEIMAGE | cut -d'=' -f2)
else
    echo "Error: debian-base.md file not found"
    exit 1
fi

# 构建参数
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian-ssh"
timeBuild=$(date +"%Y%m%d%H")
stableVer="v12-baseimage-s6-overlay_v${S6_OVERLAY_VERSION}_${timeBuild}"

# GitHub Container Registry参数
GITHUB_REGISTRY="ghcr.io"
GITHUB_USER="aspnmy"  # 请替换为实际的GitHub用户名

# 构建镜像
echo "Building base image with s6-overlay version: ${S6_OVERLAY_VERSION}"
echo "Using base image: ${BASEIMAGE}"
buildah bud --no-cache --build-arg BASEIMAGE=${BASEIMAGE} --build-arg S6_OVERLAY_VERSION=${S6_OVERLAY_VERSION} -f dockerfile-debian-s6-overlay-baseimage -t $URI/$AUUSER/$imgNAME:$stableVer

# 为GitHub Container Registry添加标签
ghcr_tag="$GITHUB_REGISTRY/$GITHUB_USER/$imgNAME:$stableVer"
buildah tag $URI/$AUUSER/$imgNAME:$stableVer $ghcr_tag

# 推送镜像到Docker Hub
echo "Pushing image to Docker Hub..."
buildah push $URI/$AUUSER/$imgNAME:$stableVer

# 推送镜像到GitHub Container Registry
echo "Pushing image to GitHub Container Registry..."
buildah push $ghcr_tag

echo "Base image build completed successfully!"
echo "Docker Hub image tag: $URI/$AUUSER/$imgNAME:$stableVer"
echo "GitHub Container Registry image tag: $ghcr_tag"