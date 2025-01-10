#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian-ssh"
ver="s6-overlay-v12.7-sshkey-rc2"
docker build --no-cache -f ./dockerfile-ssh-s6-overlay-addkeys \
        -t $URI/$AUUSER/$imgNAME:$ver .