#!bin/bash
URI="docker.io"
AUUSER="aspnmy"
imgNAME="debian-ssh"
ver="s6-overlay-v12.7-sshkey-rc1"
docker build --no-cache -f ./dockerfile/dockerfile-ssh-s6-overlay-addkeys \
        -t $URI/$AUUSER/$imgNAME:$ver .