#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian-ssh"
debianVer="stable-20250908-slim"
ver="${timeBuild}_${debianVer}_baseimage"
timeBuild=$(date +"%Y%m%d")
buildah bud --no-cache -f ./dockerfile-debian-stable-slim -t $URI/$AUUSER/$imgNAME:$ver 
buildah tag $URI/$AUUSER/$imgNAME:$ver
buildah push $URI/$AUUSER/$imgNAME:$ver
