#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian-ssh"
s6OverlayVer="3210"
debianVer="stable-20250908-slim"
timeBuild=$(date +"%Y%m%d%H%M%S")
ver="${timeBuild}_s6_overlay_v${s6OverlayVer}_${debianVer}_baseimage"

buildah bud --no-cache -f  ./dockerfile-ssh-s6-overlay-baseimage -t $URI/$AUUSER/$imgNAME:$ver 
buildah push $URI/$AUUSER/$imgNAME:$ver
