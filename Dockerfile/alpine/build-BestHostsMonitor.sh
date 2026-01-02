#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="alpine-ssh"
s6OverlayVer="3210"
alpineVer="stable_2026010304-workbase-s6-overlay_v3210_stable-2026010303-slim_baseimage"
timeBuild=$(TZ=Asia/Shanghai date +"%Y%m%d%H")
#ver="${timeBuild}_s6_overlay_v${s6OverlayVer}_${alpineVer}_BestHostsMonitor"
stableVer="alpine_ssh_s6-overlay_BestHostsMonitor_stable${timeBuild}"

buildah bud --no-cache --network host -f  ./alpine-ssh-s6-overlay-BestHostsMonitor -t $URI/$AUUSER/$imgNAME:$stableVer /root/git_data/debian_ssh.s6-overlay/Dockerfile/
#buildah tag $URI/$AUUSER/$imgNAME:$ver $URI/$AUUSER/$imgNAME:$stableVer
#buildah push $URI/$AUUSER/$imgNAME:$ver
buildah push $URI/$AUUSER/$imgNAME:$stableVer
