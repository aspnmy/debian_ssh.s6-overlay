#!/bin/bash

# 两个方案解决，第一在构建镜像时处理编码问题，优点是一次性解决，缺点是增加容器体积，所以我们选第二种
# 第二、把本脚本复制到需要进行编码修复的脚本文件处，先执行一次修改编码后，再进行容器构建，可以减小容器大小
apt-get install -y dos2unix chown


for file in ./*/*; do \
    dos2unix $file; \
    chmod a+xwr $file; \
done