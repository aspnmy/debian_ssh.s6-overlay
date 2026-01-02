#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian-ssh"
timeBuild=$(date +"%Y%m%d%H")
debianVer="stable-${timeBuild}-slim"
ver="${debianVer}_baseimage"
buildah bud --no-cache -f ./dockerfile-debian-stable-slim -t $URI/$AUUSER/$imgNAME:$ver 
buildah tag $URI/$AUUSER/$imgNAME:$ver
buildah push $URI/$AUUSER/$imgNAME:$ver
