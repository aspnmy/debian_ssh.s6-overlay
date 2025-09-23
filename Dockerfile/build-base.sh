#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian-ssh"
s6OverlayVer="3210"
debianVer="stable-20250908-slim"
timeBuild=$(date +"%Y%m%d")

ver="${timeBuild}_s6-overlay_v${s6OverlayVer}_${debianVer}"
stableVer="test-stable_s6-overlay_v${s6OverlayVer}_${debianVer}"

buildah bud --no-cache -f  ./dockerfile-ssh-s6-overlay-baseimage -t $URI/$AUUSER/$imgNAME:$ver 
buildah tag $URI/$AUUSER/$imgNAME:$ver $URI/$AUUSER/$imgNAME:$stableVer
buildah push $URI/$AUUSER/$imgNAME:$ver
buildah push $URI/$AUUSER/$imgNAME:$stableVer
