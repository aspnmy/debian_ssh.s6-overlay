#!bin/bash

# Build the image
# docker build --no-cache -f ./dockerfile-ssh-s6-overlay-devwork-base -t docker.io/aspnmy/debian-ssh:s6-overlay-v12.7-devworker-bash .
# docker push docker.io/aspnmy/debian-ssh:s6-overlay-v12.7-devworker-bash
# 更新支持CF测试工具的镜像
# time="2025-01-11 00:00:00" 
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian-ssh"
imgNAMEBase="debian"
ver="s6-overlay-v3.2.0.2-v12.7-devbase"
docker build --no-cache -f ./dockerfile-ssh-s6-overlay \
        -t $URI/$AUUSER/$imgNAME:$ver .
docker tag $URI/$AUUSER/$imgNAME:$ver $URI/$AUUSER/$imgNAMEBase:$ver
docker push $URI/$AUUSER/$imgNAME:$ver
docker push $URI/$AUUSER/$imgNAMEBase:$ver
