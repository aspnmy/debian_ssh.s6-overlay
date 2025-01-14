#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian-ssh"
imgNAMEBase="debian"
ver="s6-overlay-v3.2.0.2-v12.7-baseimage-BestHostsMonitor-v1.0.0"

docker build --no-cache -f ./dockerfile-ssh-s6-overlay-baseimage \
        -t $URI/$AUUSER/$imgNAME:$ver .
docker tag $URI/$AUUSER/$imgNAME:$ver $URI/$AUUSER/$imgNAMEBase:$ver
docker push $URI/$AUUSER/$imgNAME:$ver
docker push $URI/$AUUSER/$imgNAMEBase:$ver
