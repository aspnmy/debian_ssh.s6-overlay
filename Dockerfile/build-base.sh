#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian-ssh"
imgNAMEBase="debian"
s6OverlayVer="v3.2.1.0"
debianVer="stable-20250908-slim"
ver="s6_overlay_v${s6OverlayVer}_${debianVer}_baseimage"

docker build --no-cache -f ./dockerfile-ssh-s6-overlay-baseimage \
        -t $URI/$AUUSER/$imgNAME:$ver .
docker tag $URI/$AUUSER/$imgNAME:$ver $URI/$AUUSER/$imgNAMEBase:$ver
docker push $URI/$AUUSER/$imgNAME:$ver
docker push $URI/$AUUSER/$imgNAMEBase:$ver
