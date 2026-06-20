# syntax=docker/dockerfile:1
# ============================================================
# sandbox-622 — 交叉编译沙盒
#
# 定位: Agent 执行跨平台编译任务的 disposable 容器
# 目标: linux/amd64 + linux/arm64 宿主，工具链覆盖 linux + mac
# 端口: 622 (SSH)
# 无状态: 每次启动全新环境，Agent 自行 git clone 项目
# ============================================================

ARG BASE_REGISTRY=ghcr.io/aspnmy
ARG BASE_TAG=base-latest
FROM ${BASE_REGISTRY}/sandbox-base:${BASE_TAG}

LABEL org.aspnmy.sandbox.role="cross-compile"
LABEL org.aspnmy.sandbox.variant="622"
LABEL org.aspnmy.sandbox.type="stateless"

ENV DEBIAN_FRONTEND=noninteractive
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

# ═══════════════════════════════════════════
# Layer 1: C/C++ 交叉编译工具链
# ═══════════════════════════════════════════
RUN dpkg --add-architecture arm64 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        # 本机构建
        build-essential \
        cmake \
        pkg-config \
        automake \
        autoconf \
        libtool \
        binutils \
        # ARM64 交叉编译
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
        binutils-aarch64-linux-gnu \
        libc6-dev-arm64-cross \
        # 常用开发库 (amd64 + arm64)
        libssl-dev \
        libssl-dev:arm64 \
        zlib1g-dev \
        zlib1g-dev:arm64 \
        # 其他工具
        nasm \
        yasm \
        ninja-build \
        meson \
        patchelf \
        file \
        strace \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ═══════════════════════════════════════════
# Layer 2: Rust 工具链
# ═══════════════════════════════════════════
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
        sh -s -- -y --default-toolchain stable --profile minimal \
    && rustup target add \
        x86_64-unknown-linux-gnu \
        aarch64-unknown-linux-gnu \
        x86_64-apple-darwin \
        aarch64-apple-darwin \
    && rustup component add \
        rustfmt \
        clippy \
        rust-analyzer \
    && cargo install --locked \
        cargo-audit \
        cargo-deny \
        cargo-outdated \
        cross \
    && rm -rf /usr/local/cargo/registry

# Cargo cross-compilation config
RUN mkdir -p /root/.cargo \
    && printf '[target.aarch64-unknown-linux-gnu]\nlinker = "aarch64-linux-gnu-gcc"\n' >> /root/.cargo/config.toml

# ═══════════════════════════════════════════
# Layer 3: Go 工具链
# ═══════════════════════════════════════════
ARG GO_VERSION=1.22.5
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz
ENV PATH=/usr/local/go/bin:$PATH
ENV GOPATH=/go
RUN mkdir -p "$GOPATH" && go version

# ═══════════════════════════════════════════
# Layer 4: Node.js (前端构建 / wasm)
# ═══════════════════════════════════════════
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && npm install -g yarn pnpm 2>/dev/null || true

# ═══════════════════════════════════════════
# Layer 5: Python 工具
# ═══════════════════════════════════════════
RUN pip3 install --no-cache-dir --break-system-packages \
        ruff \
        mypy \
        pytest \
        black \
        build \
        pip-audit \
    && true

# ═══════════════════════════════════════════
# Layer 6: 其他构建辅助
# ═══════════════════════════════════════════
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        musl-tools \
        qemu-user-static \
        binfmt-support \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# macOS 交叉编译说明（osxcross 需 macOS SDK — 见 variants/622-cross-compile/README.md）
# Rust macOS targets 已安装，可编译但不能链接。链接需 osxcross 或 GitHub Actions macOS runner。
RUN mkdir -p /etc/sandbox.d \
    && echo "622-cross-compile" > /etc/sandbox.d/variant \
    && echo "stateless" > /etc/sandbox.d/mode

# 工具链自检脚本
RUN printf '#!/bin/bash\n\
echo "=== sandbox-622 toolchain check ==="\n\
echo "Rust: $(rustc --version)"\n\
echo "Targets:" && rustup target list --installed\n\
echo "Go: $(go version)"\n\
echo "Node: $(node --version)"\n\
echo "GCC-aarch64: $(aarch64-linux-gnu-gcc --version | head -1)"\n\
echo "CMake: $(cmake --version | head -1)"\n\
echo "=== ready ==="\n\
' > /usr/local/bin/sandbox-check \
    && chmod +x /usr/local/bin/sandbox-check

HEALTHCHECK --interval=30s --timeout=5s CMD pgrep sshd || exit 1
EXPOSE 622
ENTRYPOINT ["/init"]
