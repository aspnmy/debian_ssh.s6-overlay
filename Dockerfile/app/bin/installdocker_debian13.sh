#!/bin/bash
# Docker Bullseye 源强制安装脚本（Debian 13 Trixie 专用）
# 功能：清理旧配置+锁定Bullseye源+安装Docker+验证功能

# 定义颜色输出（可选，便于查看执行状态）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为root用户
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}错误：请使用root权限运行此脚本（sudo ./install-docker.sh）${NC}" >&2
    exit 1
fi

echo -e "${YELLOW}===== 步骤1：清理旧Docker配置与缓存 =====${NC}"
# 删除旧配置文件
rm -rf /etc/apt/sources.list.d/docker.list
rm -rf /etc/apt/preferences.d/docker-pin-bullseye
# 清理apt缓存
apt-get clean
rm -rf /var/lib/apt/lists/*
# 卸载残留Docker组件
apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null 2>&1
apt-get autoremove -y >/dev/null 2>&1

echo -e "${YELLOW}===== 步骤2：配置Docker Bullseye源与GPG密钥 =====${NC}"
# 创建密钥目录
mkdir -p /etc/apt/trusted.gpg.d
# 导入Docker官方GPG密钥
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
if [ $? -ne 0 ]; then
    echo -e "${RED}GPG密钥导入失败，请检查网络连接${NC}" >&2
    exit 1
fi
# 写入Bullseye源配置
tee /etc/apt/sources.list.d/docker.list > /dev/null <<EOF
deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/docker.gpg] https://download.docker.com/linux/debian bullseye stable
EOF

echo -e "${YELLOW}===== 步骤3：锁定源优先级（强制使用Bullseye） =====${NC}"
# 创建apt偏好文件，拒绝Trixie源
tee /etc/apt/preferences.d/docker-pin-bullseye > /dev/null <<EOF
Package: docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
Pin: release n=bullseye
Pin-Priority: 1000

Package: docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
Pin: release n=trixie
Pin-Priority: -10
EOF

echo -e "${YELLOW}===== 步骤4：更新源并安装Docker =====${NC}"
# 更新apt源
apt-get update -y
# 安装Docker套件
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
if [ $? -ne 0 ]; then
    echo -e "${RED}Docker安装失败，请检查源配置或网络${NC}" >&2
    exit 1
fi

echo -e "${YELLOW}===== 步骤5：启动服务并验证安装 =====${NC}"
# 启动并设置开机自启
systemctl enable --now docker containerd >/dev/null 2>&1
# 检查Docker服务状态
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✅ Docker服务启动成功${NC}"
else
    echo -e "${RED}❌ Docker服务启动失败，请执行 systemctl status docker 查看详情${NC}" >&2
    exit 1
fi

# 验证Docker版本
echo -e "${GREEN}===== 安装完成，版本信息如下 =====${NC}"
docker --version
containerd --version

# 可选：运行hello-world测试容器（注释掉则不执行）
echo -e "${YELLOW}===== 运行测试容器（hello-world）=====${NC}"
if docker run --rm hello-world >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker功能验证通过${NC}"
else
    echo -e "${YELLOW}⚠️  测试容器运行失败，可能是网络问题，可手动执行 docker run --rm hello-world 测试${NC}"
fi

echo -e "${GREEN}===== 全部操作完成 =====${NC}"
echo -e "提示：若需免sudo运行Docker，执行：sudo usermod -aG docker \$USER && newgrp docker"
