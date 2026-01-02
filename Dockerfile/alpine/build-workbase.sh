#!bin/bash
    URI="docker.io"
    AUUSER="aspnmy"
    imgNAME="alpine-ssh"
    s6OverlayVer="3210"
    # aspnmy/alpine-ssh:stable-2026010303-slim_baseimage
    alpineVer="stable-2026010303-slim_baseimage"
    timeBuild=$(TZ=Asia/Shanghai  date +"%Y%m%d%H")
    #ver="${timeBuild}_s6-overlay_v${s6OverlayVer}_${alpineVer}"
    stableVer="workbase_s6-overlay_stable${timeBuild}"

    buildah bud --no-cache -f  ./alpine-ssh-s6-overlay-workbaseimage -t $URI/$AUUSER/$imgNAME:$stableVer /root/git_data/debian_ssh.s6-overlay/Dockerfile/ 
    #buildah tag $URI/$AUUSER/$imgNAME:$ver $URI/$AUUSER/$imgNAME:$stableVer
    #buildah push $URI/$AUUSER/$imgNAME:$ver
    buildah push $URI/$AUUSER/$imgNAME:$stableVer 
