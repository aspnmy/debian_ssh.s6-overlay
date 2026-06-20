# syntax=docker/dockerfile:1
# ============================================================
# sandbox-7777 — Docker Build 沙盒
#
# 定位: Agent 执行 Docker 镜像构建/推送的 disposable 容器
# 特点: 内含 docker-cli + buildx + QEMU 多架构仿真
# 端口: 7777 (SSH)
# 无状态: 每次启动全新环境
# ⚠️  Docker daemon 需挂载宿主 /var/run/docker.sock
# ============================================================

ARG BASE_REGISTRY=ghcr.io/aspnmy
ARG BASE_TAG=base-latest
FROM ${BASE_REGISTRY}/sandbox-base:${BASE_TAG}

LABEL org.aspnmy.sandbox.role="docker-build"
LABEL org.aspnmy.sandbox.variant="7777"
LABEL org.aspnmy.sandbox.type="stateless"

ENV DEBIAN_FRONTEND=noninteractive

# ═══════════════════════════════════════════
# Layer 1: Docker CLI + Buildx
# ═══════════════════════════════════════════
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        docker-ce-cli \
        docker-buildx-plugin \
        docker-compose-plugin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ═══════════════════════════════════════════
# Layer 2: QEMU 多架构仿真
# ═══════════════════════════════════════════
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        qemu-user-static \
        binfmt-support \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ═══════════════════════════════════════════
# Layer 3: OCI 镜像工具
# ═══════════════════════════════════════════
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        skopeo \
        jq \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 crane (Google 官方 OCI 工具)
ARG CRANE_VERSION=0.19.1
RUN ARCH=$(uname -m | sed 's/x86_64/x86_64/;s/aarch64/arm64/') \
    && curl -fsSL "https://github.com/google/go-containerregistry/releases/download/v${CRANE_VERSION}/go-containerregistry_Linux_${ARCH}.tar.gz" \
        -o /tmp/crane.tar.gz \
    && tar -C /usr/local/bin -xzf /tmp/crane.tar.gz crane krane gcrane \
    && chmod +x /usr/local/bin/crane /usr/local/bin/krane /usr/local/bin/gcrane \
    && rm /tmp/crane.tar.gz

# ═══════════════════════════════════════════
# Layer 4: 构建辅助工具
# ═══════════════════════════════════════════
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        python3 \
        python3-pip \
        jq \
        yq \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && pip3 install --no-cache-dir --break-system-packages yq 2>/dev/null || true

# ═══════════════════════════════════════════
# Layer 5: SSH 端口 → 7777
# ═══════════════════════════════════════════
RUN sed -i 's/Port 622/Port 7777/' /etc/ssh/sshd_config \
    && echo "Port 7777" >> /etc/ssh/sshd_config

# 无状态标记
RUN mkdir -p /etc/sandbox.d \
    && echo "7777-docker-build" > /etc/sandbox.d/variant \
    && echo "stateless" > /etc/sandbox.d/mode \
    && echo "requires-docker-socket" > /etc/sandbox.d/requirements

# ═══════════════════════════════════════════
# Docker Buildx 预配置
# ═══════════════════════════════════════════
# 创建默认 buildx builder（运行时若 dockerd 可达则自动激活）
RUN mkdir -p /root/.docker \
    && printf '{"experimental":"enabled"}\n' > /root/.docker/config.json

# 工具链自检脚本
RUN printf '#!/bin/bash\n\
echo "=== sandbox-7777 toolchain check ==="\n\
echo "Docker CLI: $(docker --version 2>/dev/null || echo "NEED DOCKER SOCKET")"\n\
echo "Buildx: $(docker buildx version 2>/dev/null || echo "NEED DOCKER SOCKET")"\n\
echo "QEMU: $(qemu-x86_64-static --version 2>/dev/null || echo "installed")"\n\
echo "Skopeo: $(skopeo --version 2>/dev/null || echo "installed")"\n\
echo "Crane: $(crane version 2>/dev/null || echo "installed")"\n\
echo "=== ready ==="\n\
' > /usr/local/bin/sandbox-check \
    && chmod +x /usr/local/bin/sandbox-check

HEALTHCHECK --interval=30s --timeout=5s CMD pgrep sshd || exit 1
EXPOSE 7777
ENTRYPOINT ["/init"]
