#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="alpine-ssh"
timeBuild=$(TZ=Asia/Shanghai date +"%Y%m%d%H")
alpineVer="stable${timeBuild}"
ver="baseimage_${alpineVer}"
# buildah bud --no-cache -f ./alpine-stable-slim -t docker.io/aspnmy/alpine-ssh:stable-20260103-slim
buildah bud --no-cache --network host -f ./alpine-stable-slim -t $URI/$AUUSER/$imgNAME:$ver
# Optional: Add additional tags if needed
buildah push $URI/$AUUSER/$imgNAME:$ver docker://$URI/$AUUSER/$imgNAME:$ver
