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

# SSH 配置 (端口 622；**只保留公钥体系**)
# ⚠️ 2026-09-17 硬化（对应 docs/todoWrite.md 的「默认 root 密码泄露」）：
#   - 不再 chpasswd 设 root 密码，改为 `passwd -l root` 锁死
#   - PasswordAuthentication no / PermitRootLogin prohibit-password（root 仍可公钥登录）
#   - sshd 语义是「首次出现的值生效」，而 sshd_config 顶部有 Include sshd_config.d/*.conf
#     → 必须同时写 00- 前缀 drop-in，否则只 sed 主文件会被 drop-in 抢先
RUN mkdir -p /root/.ssh /run/sshd /var/run/sshd \
    && chmod 700 /root/.ssh /var/run/sshd \
    && chmod 755 /run/sshd \
    && sed -i 's/#Port 22/Port 622/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config \
    && mkdir -p /etc/ssh/sshd_config.d \
    && printf 'PasswordAuthentication no\nPermitRootLogin prohibit-password\nKbdInteractiveAuthentication no\n' \
         > /etc/ssh/sshd_config.d/00-hardening.conf \
    && chmod 600 /etc/ssh/sshd_config.d/00-hardening.conf \
    && passwd -l root \
    && echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config \
    && echo "ClientAliveCountMax 3" >> /etc/ssh/sshd_config

# ⚠️ SSH host key **不烤进镜像**（私钥一律不入镜像）
#   `apt install openssh-server` 时 Debian postinst 会自动 ssh-keygen -A → 3 枚 host 私钥落层，
#   导致所有容器共用同一主机身份、且违反「私钥不入镜像」。删除后由 s6 oneshot 首启生成。
RUN rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub

# host key 首启生成（oneshot；`up` 按 execline 执行 → 只能一行「程序+参数」，不能放脚本体）
#   `ssh-keygen -A` 幂等：只补缺失的 key → 同容器 stop/start 内主机身份稳定，跨容器各不相同
RUN mkdir -p /etc/s6-overlay/s6-rc.d/ssh-host-keys/dependencies.d \
    && echo "oneshot" > /etc/s6-overlay/s6-rc.d/ssh-host-keys/type \
    && printf '/usr/bin/ssh-keygen -A\n' > /etc/s6-overlay/s6-rc.d/ssh-host-keys/up \
    && chmod 755 /etc/s6-overlay/s6-rc.d/ssh-host-keys/up \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/ssh-host-keys \
    && touch /etc/s6-overlay/s6-rc.d/ssh-host-keys/dependencies.d/base \
    && touch /etc/s6-overlay/s6-rc.d/sshd/dependencies.d/ssh-host-keys

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
