#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian-ssh"
debianVer="stable-20250908-slim"
ver="${debianVer}_baseimage"

buildah bud --no-cache -f ./dockerfile-debian-stable-slim -t $URI/$AUUSER/$imgNAME:$ver 
buildah tag $URI/$AUUSER/$imgNAME:$ver
buildah push $URI/$AUUSER/$imgNAME:$ver
