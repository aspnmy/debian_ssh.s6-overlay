#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian-ssh"
ver="s6-overlay-v12.7-devwork"
docker build --no-cache -f ./dockerfile-ssh-s6-overlay \
        -t $URI/$AUUSER/$imgNAME:$ver .
docker push $URI/$AUUSER/$imgNAME:$ver
