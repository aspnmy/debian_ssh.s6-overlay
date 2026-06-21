#!/bin/bash
set -e

# =============================================
# Harbor v2.14.4 一键部署脚本（腾讯云镜像源）
# 适用：阿里云不可达，腾讯云/Quay.io 可达
# =============================================

# ---------- 配置参数 ----------
HARBOR_TAG="v2.14.4"
CHART_VER="1.17.0"

# 源仓库（选一个能用的）
SRC_REG="ccr.ccs.tencentyun.com/goharbor"
# SRC_REG="quay.io/goharbor"       # 备用

# 你的私有 registry
DST_REG="devrom.org"
DST_USER="aspnmy"
DST_PASS="X004252b@="

NS="harbor"
REL="harbor"
SC=""                          # StorageClass 名称，用默认则留空
EXT_URL="http://harbor.local"
ADMIN_PW="Harbor12345"

TRIVY="true"
CHARTMUS="true"
NOTARY="false"

# 颜色
RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
header(){ echo -e "${CYAN}$1${NC}"; }

# ---------- 检查依赖 ----------
check_prereqs() {
    info "检查依赖..."
    for cmd in docker helm kubectl; do
        command -v "$cmd" >/dev/null 2>&1 || error "需要 $cmd"
    done
    docker info >/dev/null 2>&1 || error "docker daemon 未运行"
    kubectl cluster-info >/dev/null 2>&1 || error "k8s 集群不可达"
    curl -s --connect-timeout 5 "http://${DST_REG}/v2/_catalog" >/dev/null 2>&1 && \
        info "私有仓库可达: ${DST_REG}" || warn "私有仓库不可达: ${DST_REG}"
    info "依赖检查通过"
}

# ---------- 登录 ----------
login_dst() {
    if [ -n "$DST_USER" ] && [ -n "$DST_PASS" ]; then
        echo "$DST_PASS" | docker login "$DST_REG" -u "$DST_USER" --password-stdin
    fi
}

# ---------- 镜像列表 ----------
image_list() {
    local base="$SRC_REG" tag="$HARBOR_TAG"
    local imgs=(
        "${base}/harbor-core:${tag}"
        "${base}/harbor-jobservice:${tag}"
        "${base}/harbor-portal:${tag}"
        "${base}/registry-photon:${tag}"
        "${base}/harbor-registryctl:${tag}"
        "${base}/nginx-photon:${tag}"
        "${base}/harbor-db:${tag}"
        "${base}/harbor-redis:${tag}"
        "${base}/harbor-exporter:${tag}"
        "${base}/harbor-migrator:${tag}"
    )
    [ "$TRIVY" = "true" ] && imgs+=("${base}/trivy-adapter-photon:${tag}")
    [ "$CHARTMUS" = "true" ] && imgs+=("${base}/chartmuseum-photon:${tag}")
    [ "$NOTARY" = "true" ] && {
        imgs+=("${base}/notary-server-photon:${tag}")
        imgs+=("${base}/notary-signer-photon:${tag}")
    }
    echo "${imgs[@]}"
}

# ---------- 拉取 + 推送 ----------
pull_push() {
    local imgs=($(image_list))
    local total=${#imgs[@]} idx=0 ok=0 fail=0
    info "拉取 ${total} 个镜像 → 推送至 ${DST_REG}"
    echo "========================================"
    for src in "${imgs[@]}"; do
        idx=$((idx+1))
        local name="${src#${SRC_REG}/}"
        local dst="${DST_REG}/goharbor/${name}"
        echo -n "[${idx}/${total}] ${name} ... "
        if docker pull "$src" >/dev/null 2>&1; then
            echo -n "拉取OK "
        else
            echo "❌ 拉取失败"; fail=$((fail+1)); continue
        fi
        docker tag "$src" "$dst"
        if docker push "$dst" >/dev/null 2>&1; then
            echo "推送OK"; ok=$((ok+1))
        else
            echo "❌ 推送失败"; fail=$((fail+1))
        fi
        docker rmi "$src" "$dst" 2>/dev/null || true
    done
    echo "========================================"
    info "成功: ${ok} 个, 失败: ${fail} 个"
    [ "$fail" -gt 0 ] && warn "部分镜像推送失败"
}

# ---------- 下载 chart ----------
dl_chart() {
    local dir="./charts"
    mkdir -p "$dir"
    if [ -d "${dir}/harbor" ]; then
        warn "Chart 已存在, 跳过"
        return
    fi
    helm repo add harbor https://helm.goharbor.io 2>/dev/null || true
    helm repo update
    helm pull harbor/harbor --version "$CHART_VER" --untar --untardir "$dir"
    [ -d "${dir}/harbor" ] || error