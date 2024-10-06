#!/bin/bash

apt-get install -y dos2unix chown


for file in ./*/*; do \
    dos2unix $file; \
    chmod a+xwr $file; \
done