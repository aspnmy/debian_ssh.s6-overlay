# syntax=docker/dockerfile:1
# ============================================================
# sandbox-base — 无状态沙盒共享基座
# 
# 定位: 所有变体沙盒(622/7777/...)的最小公共层
# 原则: 极简——仅 s6-overlay + SSH + 基础工具。工具链由变体追加。
# 无状态: 容器销毁后无残留，每次启动即全新环境。
# ============================================================

ARG BASEIMAGE=debian:bookworm-slim
ARG S6_VER=3.2.3.0

# ── Stage 1: s6-overlay 提取 ──
FROM ${BASEIMAGE} AS s6-extractor
ARG S6_VER
COPY s6-downloads/ /tmp/s6-downloads/
RUN apt-get update && apt-get install -y --no-install-recommends xz-utils \
    && mkdir -p /tmp/s6 \
    && cp /tmp/s6-downloads/s6-overlay-noarch.tar.xz /tmp/s6-noarch.tar.xz \
    && ARCH=$(uname -m | sed 's/aarch64/aarch64/;s/x86_64/x86_64/') \
    && cp /tmp/s6-downloads/s6-overlay-${ARCH}.tar.xz /tmp/s6-arch.tar.xz \
    && tar -C /tmp/s6 -Jxpf /tmp/s6-noarch.tar.xz \
    && tar -C /tmp/s6 -Jxpf /tmp/s6-arch.tar.xz \
    && rm -f /tmp/s6-noarch.tar.xz /tmp/s6-arch.tar.xz \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Stage 2: 极简基座 ──
FROM ${BASEIMAGE}
ENV DEBIAN_FRONTEND=noninteractive

LABEL org.aspnmy.sandbox.role="base"
LABEL org.aspnmy.sandbox.type="stateless"
LABEL org.aspnmy.sandbox.version="${S6_VER}"

# 基础系统工具（保持最小——变体各自追加工具链）
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openssh-server \
        netcat-openbsd \
        python3 \
        python3-pip \
        curl \
        ca-certificates \
        git \
        jq \
        unzip \
        xz-utils \
        wget \
        gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# s6-overlay
COPY --from=s6-extractor /tmp/s6/ /

# 时区 → Asia/Shanghai
RUN rm -f /etc/localtime \
    && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

# SSH 配置 (端口 622, 允许 root 密码登录)
RUN mkdir -p /root/.ssh /run/sshd /var/run/sshd \
    && chmod 700 /root/.ssh /var/run/sshd \
    && chmod 755 /run/sshd \
    && echo 'root:root@#1314' | chpasswd \
    && sed -i 's/#Port 22/Port 622/' /etc/ssh/sshd_config \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config \
    && echo "ClientAliveCountMax 3" >> /etc/ssh/sshd_config

# s6-overlay sshd 服务定义
RUN mkdir -p /etc/s6-overlay/s6-rc.d/sshd/dependencies.d \
    /etc/s6-overlay/s6-rc.d/sshd/log \
    /var/log/sshd \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/sshd \
    && touch /etc/s6-overlay/s6-rc.d/sshd/dependencies.d/base \
    && echo "longrun" > /etc/s6-overlay/s6-rc.d/sshd/type \
    && printf '#!/bin/sh\n/usr/sbin/sshd -D\n' > /etc/s6-overlay/s6-rc.d/sshd/run \
    && chmod +x /etc/s6-overlay/s6-rc.d/sshd/run \
    && printf '#!/bin/sh\nexec s6-log -b -- n20 s1000000 /var/log/sshd\n' > /etc/s6-overlay/s6-rc.d/sshd/log/run \
    && chmod +x /etc/s6-overlay/s6-rc.d/sshd/log/run

# 无状态标记
RUN mkdir -p /etc/sandbox.d \
    && echo "stateless" > /etc/sandbox.d/mode \
    && echo "base" > /etc/sandbox.d/variant \
    && echo "ephemeral" > /etc/sandbox.d/lifecycle

# Agent 自检脚本 — 验证容器可用性
RUN printf '#!/bin/bash\necho "sandbox-base ready"\nsshd -T 2>/dev/null | head -3\ngit --version\npython3 --version\n' > /usr/local/bin/sandbox-check \
    && chmod +x /usr/local/bin/sandbox-check

HEALTHCHECK --interval=30s --timeout=5s CMD pgrep sshd || exit 1
EXPOSE 622
ENTRYPOINT ["/init"]
