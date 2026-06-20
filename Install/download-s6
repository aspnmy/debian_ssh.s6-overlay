#!/bin/bash
# ==============================================================
# 功能：自动从 GitHub 获取 s6-overlay 最新版本号并下载
# ==============================================================

set -e

DOWNLOAD_DIR="./s6-downloads"
mkdir -p "$DOWNLOAD_DIR"

echo "🔍 正在获取 s6-overlay 最新版本..."

# ----- 方式1：通过 GitHub API 获取最新 release 版本号（推荐）-----
S6_OVERLAY_VERSION=$(curl -fsSL \
  "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" \
  | grep '"tag_name":' \
  | sed 's/.*"tag_name": "v\(.*\)",/\1/')

# 如果 API 有频率限制，改用方式2（解析重定向）
if [ -z "$S6_OVERLAY_VERSION" ]; then
  echo "⚠️  API 方式失败，尝试解析重定向..."
  S6_OVERLAY_VERSION=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    "https://github.com/just-containers/s6-overlay/releases/latest" \
    | sed 's|.*/tag/v||')
fi

if [ -z "$S6_OVERLAY_VERSION" ]; then
  echo "❌ 无法获取最新版本号，请检查网络或手动指定版本"
  exit 1
fi

echo "✅ 最新版本: v${S6_OVERLAY_VERSION}"

# ----- 下载三个架构的压缩包 -----
echo "📥 正在下载 s6-overlay v${S6_OVERLAY_VERSION}..."

BASE_URL="https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}"

# noarch（所有架构通用）
curl -fsSL "${BASE_URL}/s6-overlay-noarch.tar.xz" \
  -o "${DOWNLOAD_DIR}/s6-overlay-noarch.tar.xz"
echo "   ✅ noarch 下载完成"

# x86_64
curl -fsSL "${BASE_URL}/s6-overlay-x86_64.tar.xz" \
  -o "${DOWNLOAD_DIR}/s6-overlay-x86_64.tar.xz"
echo "   ✅ x86_64 下载完成"

# aarch64（arm64 用）
curl -fsSL "${BASE_URL}/s6-overlay-aarch64.tar.xz" \
  -o "${DOWNLOAD_DIR}/s6-overlay-aarch64.tar.xz"
echo "   ✅ aarch64 下载完成"

echo ""
echo "========== 下载完成 =========="
echo "版本: v${S6_OVERLAY_VERSION}"
echo "目录: ${DOWNLOAD_DIR}/"
ls -lh "${DOWNLOAD_DIR}/"
