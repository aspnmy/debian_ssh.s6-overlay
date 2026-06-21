#!/bin/bash
set -e

# =============================================
# Harbor v2.14.4 一键部署脚本（腾讯云仓库 → 内部私有仓库）
# 适用环境：阿里云不可达，腾讯云/Quay.io 可达
# =============================================

# ---------- 📌 配置参数（按需修改） ----------
HARBOR_VERSION="v2.14.4"
CHART_VERSION="1.17.0"          # 以 helm search repo -l 实际版本为准

# 镜像来源：选择能访问的仓库
# SOURCE_REGISTRY="ccr.ccs.tencentyun.com/goharbor"           # 腾讯云
SOURCE_REGISTRY="quay.io/goharbor"                           # 或者用 quay.io

# 你的私有 registry 地址（必填！从你环境中的 insecure-registries 摘取）
PRIVATE_REGISTRY="devrom.org"      # ← 改成你的私有仓库地址
PRIVATE_REGISTRY_USER="aspnmy"                    # 如有认证，填写用户名
PRIVATE_REGISTRY_PASS="X004252b@="                    # 如有认证，填写密码

NAMESPACE="harbor"
RELEASE_NAME="harbor"
STORAGE_CLASS=""                         # 如使用特定 StorageClass，填写名称，留空用默认
EXTERNAL_URL="http://harbor.local"       # Harbor 访问地址，部署后修改
ADMIN_PASSWORD="Harbor12345"             # 管理员密码

# 组件开关
TRIVY_ENABLED="true"
CHARTMUSEUM_ENABLED="true"
NOTARY_ENABLED="false"

# ------ 以下无需修改 ------
CHARTS_DIR="./charts"

# ---------- 🎨 颜色输出 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
header(){ echo -e "${CYAN}$1${NC}"; }

# ---------- 📋 检查依赖 ----------
check_prereqs() {
    info "检查依赖..."
    command -v docker   >/dev/null 2>&1 || error "需要 docker"
    command -v helm     >/dev/null 2>&1 || error "需要 helm"
    command -v kubectl  >/dev/null 2>&1 || error "需要 kubectl"
    docker info         >/dev/null 2>&1 || error "docker daemon 未运行"
    kubectl cluster-info >/dev/null 2>&1 || error "k8s 集群不可达"
    
    # 检查私有 registry 连通性
    local registry_host=$(echo "$PRIVATE_REGISTRY" | cut -d: -f1)
    local registry_port=$(echo "$PRIVATE_REGISTRY" | cut -d: -f2)
    if curl -s --connect-timeout 5 "http://${PRIVATE_REGISTRY}/v2/_catalog" >/dev/null 2>&1; then
        info "✅ 私有仓库 ${PRIVATE_REGISTRY} 可连通"
    else
        warn "⚠️  私有仓库 ${PRIVATE_REGISTRY} 不可达，请检查网络"
        warn "   后续步骤可能失败，可继续尝试"
    fi
    
    info "✅ 依赖检查通过"
}

# ---------- 🔑 登录私有仓库 ----------
login_private_registry() {
    if [[ -n "$PRIVATE_REGISTRY_USER" && -n "$PRIVATE_REGISTRY_PASS" ]]; then
        info "登录私有仓库 $PRIVATE_REGISTRY ..."
        echo "$PRIVATE_REGISTRY_PASS" | docker login "$PRIVATE_REGISTRY" \
            -u "$PRIVATE_REGISTRY_USER" --password-stdin
    else
        info "🟢 私有仓库无需登录（或在 insecure-registries 中）"
    fi
}

# ---------- 🔍 Harbor 镜像列表 ----------
get_image_list() {
    local base="$SOURCE_REGISTRY"
    local tag="$HARBOR_VERSION"
    
    local images=(
        "$base/harbor-core:$tag"
        "$base/harbor-jobservice:$tag"
        "$base/harbor-portal:$tag"
        "$base/registry-photon:$tag"
        "$base/harbor-registryctl:$tag"
        "$base/nginx-photon:$tag"
        "$base/harbor-db:$tag"
        "$base/harbor-redis:$tag"
        "$base/harbor-exporter:$tag"
        "$base/harbor-migrator:$tag"
    )
    
    if [[ "$TRIVY_ENABLED" == "true" ]]; then
        images+=("$base/trivy-adapter-photon:$tag")
    fi
    if [[ "$CHARTMUSEUM_ENA