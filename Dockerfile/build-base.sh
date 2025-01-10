#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian"
ver="base-rc1"
docker build --no-cache -f ./dockerfile-ssh-s6-overlay \
        -t $URI/$AUUSER/$imgNAME:$ver .
docker push $URI/$AUUSER/$imgNAME:$ver
