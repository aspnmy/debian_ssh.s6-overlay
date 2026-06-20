# ==============================================================
# Dockerfile - 使用本地预下载的 s6-overlay + 自定义 SSH 配置
# ==============================================================

# ========== 第一阶段：准备 s6-overlay（从本地 COPY）==========
FROM alpine:latest AS s6-preloader

ARG TARGETARCH
ARG S6_OVERLAY_VERSION=3.1.6.2

# 复制预下载的所有压缩包
COPY s6-downloads/ /tmp/s6-downloads/

RUN echo "🔧 检测到架构: ${TARGETARCH:-amd64}" \
    && mkdir -p /tmp/s6-overlay \
    && case "${TARGETARCH}" in \
         amd64|"") \
           echo "  ➡️ 解压 noarch + x86_64" && \
           tar -C /tmp/s6-overlay -Jxpf /tmp/s6-downloads/s6-overlay-noarch.tar.xz && \
           tar -C /tmp/s6-overlay -Jxpf /tmp/s6-downloads/s6-overlay-x86_64.tar.xz ;; \
         arm64) \
           echo "  ➡️ 解压 noarch + aarch64" && \
           tar -C /tmp/s6-overlay -Jxpf /tmp/s6-downloads/s6-overlay-noarch.tar.xz && \
           tar -C /tmp/s6-overlay -Jxpf /tmp/s6-downloads/s6-overlay-aarch64.tar.xz ;; \
         *) echo "❌ 不支持的架构: ${TARGETARCH}"; exit 1 ;; \
       esac \
    && echo "✅ s6-overlay 解压完成" \
    && rm -rf /tmp/s6-downloads

# ========== 第二阶段：主应用（Debian）==========
FROM debian:bookworm-slim

ARG TARGETARCH

# ===== 1. 复制 s6-overlay 文件到根目录 =====
COPY --from=s6-preloader /tmp/s6-overlay/ /

# ===== 2. 安装必要软件包 =====
RUN apt-get update -qq \
    && apt-get install -y -qq --no-install-recommends \
       ca-certificates \
       curl \
       openssh-server \
       openssh-client \
       tzdata \
       bash \
       sudo \
    && rm -rf /var/lib/apt/lists/*

# ===== 3. 复制 setRootKey_Cli.sh.s6 脚本 =====
# 请确保 /app/roottools/setRootKey_Cli.sh.s6 在构建上下文中存在
COPY /app/roottools/setRootKey_Cli.sh.s6 /aspnmy/bin/
RUN chmod +x /aspnmy/bin/setRootKey_Cli.sh.s6

# ===== 4. 配置时区 =====
RUN rm -f /etc/localtime \
    && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" | tee /etc/timezone

# ===== 5. ⚠️ 关键：以超级管理员 root 权限执行 superman 模式 =====
# Dockerfile 中 RUN 默认以 root 运行，因此这里就是 root 权限执行
RUN /aspnmy/bin/setRootKey_Cli.sh.s6 superman

# ===== 6. 创建 SSH 服务目录结构（s6-rc 格式）=====
RUN mkdir -p /etc/s6-overlay/s6-rc.d/sshd \
    && mkdir -p /etc/s6-overlay/s6-rc.d/sshd/dependencies.d \
    && mkdir -p /etc/s6-overlay/s6-rc.d/sshd/log \
    && mkdir -p /etc/s6-overlay/s6-rc.d/user \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/sshd \
    && touch /
