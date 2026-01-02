#!/bin/bash
set -e  # 遇到错误立即退出

# 定义颜色输出（可选，提升可读性）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 重置颜色

# 检查是否为 root 或拥有 sudo 权限
check_permission() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${YELLOW}提示：脚本需要 root 权限，将尝试使用 sudo 执行${NC}"
        if ! command -v sudo &> /dev/null; then
            echo -e "${RED}错误：未安装 sudo，请先执行 apt install sudo 并配置权限${NC}"
            exit 1
        fi
    fi
}

# 系统环境检查
check_system() {
    if [ ! -f /etc/debian_version ]; then
        echo -e "${RED}错误：此脚本仅支持 Debian 系统（当前为非 Debian 环境）${NC}"
        exit 1
    fi
    DEBIAN_VERSION=$(grep -oE '[0-9]+' /etc/debian_version | head -n1)
    if [ "$DEBIAN_VERSION" -ne 13 ]; then
        echo -e "${YELLOW}警告：脚本适配 Debian 13，当前系统版本为 Debian $DEBIAN_VERSION，可能存在兼容性问题${NC}"
        read -p "是否继续安装？(y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# 更新系统并安装基础依赖
install_deps() {
    echo -e "${GREEN}步骤 1/6：更新系统源并安装基础依赖${NC}"
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y curl gnupg2 apt-transport-https ca-certificates slirp4netns uidmap
}

# 安装 Podman（官方仓库）
install_podman() {
    echo -e "${GREEN}步骤 2/6：从官方仓库安装 Podman${NC}"
    if ! command -v podman &> /dev/null; then
        sudo apt install -y podman
    else
        echo -e "${YELLOW}Podman 已安装，跳过安装步骤${NC}"
    fi

    # 验证安装
    echo -e "${GREEN}验证 Podman 安装...${NC}"
    podman --version
    if ! podman run --rm hello-world &> /dev/null; then
        echo -e "${RED}Podman 基础测试失败，请检查环境${NC}"
        exit 1
    fi
    echo -e "${GREEN}Podman 安装验证成功${NC}"
}

# 配置镜像加速（阿里云+网易）
config_mirror() {
    echo -e "${GREEN}步骤 3/6：配置 Podman 镜像加速${NC}"
    REGISTRY_CONF="/etc/containers/registries.conf"
    # 备份原有配置
    sudo cp "$REGISTRY_CONF" "${REGISTRY_CONF}.bak"$(date +%Y%m%d)

    # 写入镜像加速配置
    sudo tee "$REGISTRY_CONF" > /dev/null << EOF
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
insecure = false
location = "docker.io"
mirror = ["https://hub-mirror.c.163.com", "https://mirror.aliyuncs.com"]

[[registry]]
prefix = "ghcr.io"
insecure = false
location = "ghcr.io"
mirror = ["https://ghcr.nju.edu.cn"]

[[registry]]
prefix = "quay.io"
insecure = false
location = "quay.io"
mirror = ["https://quay.mirrors.ustc.edu.cn"]
EOF
    echo -e "${GREEN}镜像加速配置完成${NC}"
}

# 配置 Rootless 模式（非 root 运行）
config_rootless() {
    echo -e "${GREEN}步骤 4/6：配置 Rootless 模式${NC}"
    CURRENT_USER=$(logname)  # 获取登录用户（非 root 执行时的用户）
    # 配置 subuid/subgid
    if ! grep -q "^${CURRENT_USER}:" /etc/subuid; then
        sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$CURRENT_USER"
    fi

    # 切换到当前用户执行 rootless 配置
    sudo -u "$CURRENT_USER" bash -c '
        podman system reset -f
        # 验证 rootless 模式
        if ! podman info | grep -q "rootless: true"; then
            echo -e "${YELLOW}Rootless 模式配置可能未生效，手动执行 podman system reset 重试${NC}"
        fi
    '
    echo -e "${GREEN}Rootless 模式配置完成${NC}"
}

# 启用 Podman systemd 服务
enable_service() {
    echo -e "${GREEN}步骤 5/6：启用 Podman systemd 服务${NC}"
    CURRENT_USER=$(logname)
    # 为当前用户生成并启用 systemd 服务
    sudo -u "$CURRENT_USER" bash -c '
        podman systemd --user --new || true
        systemctl --user enable --now podman.socket
        systemctl --user enable --now podman.service
        loginctl enable-linger "$USER" || true
    '
    echo -e "${GREEN}Podman 服务已启用${NC}"
}

# 输出安装完成信息
print_finish() {
    echo -e "\n${GREEN}=====================================${NC}"
    echo -e "${GREEN}Podman 安装配置完成！${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo -e "常用命令："
    echo -e "  podman --version    # 查看版本"
    echo -e "  podman run hello-world  # 测试运行容器"
    echo -e "  podman ps           # 查看运行中的容器"
    echo -e "  podman system info  # 查看 Rootless 模式状态"
    echo -e "${NC}"
}

# 主执行流程
main() {
    echo -e "${GREEN}开始安装 Podman（Debian 13 适配版）${NC}"
    check_permission
    check_system
    install_deps
    install_podman
    config_mirror
    config_rootless
    enable_service
    print_finish
}

# 启动主流程
main
