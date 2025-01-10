#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian-ssh"
ver="s6-overlay-v12.7-devworker-cn"
docker build --no-cache -f ./dockerfile-ssh-s6-overlay-devwork-cn \
        -t $URI/$AUUSER/$imgNAME:$ver .

docker push $URI/$AUUSER/$imgNAME:$ver
