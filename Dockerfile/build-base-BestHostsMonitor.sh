#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian-ssh"
s6OverlayVer="3210"
debianVer="stable-20250908-slim"
timeBuild=$(date +"%Y%m%d%H")
#ver="${timeBuild}_s6_overlay_v${s6OverlayVer}_${debianVer}_BestHostsMonitor"
stableVer="stable_${timeBuild}-s6-overlay_v${s6OverlayVer}_${debianVer}_BestHostsMonitor"

buildah bud --no-cache -f  ./dockerfile-ssh-s6-overlay-BestHostsMonitor -t $URI/$AUUSER/$imgNAME:$stableVer
#buildah tag $URI/$AUUSER/$imgNAME:$ver $URI/$AUUSER/$imgNAME:$stableVer
#buildah push $URI/$AUUSER/$imgNAME:$ver
buildah push $URI/$AUUSER/$imgNAME:$stableVer
