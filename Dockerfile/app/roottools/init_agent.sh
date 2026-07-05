#!/bin/bash

# --- 配置 ---
SH_URL="https://raw.githubusercontent.com/aspnmy/debian_ssh.s6-overlay/refs/heads/baseimage/Dockerfile/app/roottools/setRootKey_Cli.sh.s6"
SCRIPT_NAME="setRootKey_Cli.sh.s6"
# 预设 agent 公钥存放目录
AGENT_KEYS_DIR="/etc/ssh/authorized_keys_agentuser"

# --- 函数定义 ---
log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1"; }

create_agent_group() {
    local agent_group="agentgroup"
    log_info "检查用户组: $agent_group"
    if ! getent group "$agent_group" > /dev/null; then
        log_info "创建用户组: $agent_group"
        groupadd "$agent_group"
        if [ $? -eq 0 ]; then
            log_info "✅ 用户组 $agent_group 创建成功"
        else
            log_error "❌ 创建用户组 $agent_group 失败"
            exit 1
        fi
    else
        log_info "ℹ️  用户组 $agent_group 已存在"
    fi
}

# 确保 agent 公钥存放目录存在
ensure_agent_keys_directory() {
    log_info "检查 agent 公钥存放目录: $AGENT_KEYS_DIR"
    if [ ! -d "$AGENT_KEYS_DIR" ]; then
        log_info "目录 $AGENT_KEYS_DIR 不存在，正在创建..."
        # 创建目录
        if ! mkdir -p "$AGENT_KEYS_DIR"; then
            log_error "❌ 创建目录 $AGENT_KEYS_DIR 失败。"
            exit 1
        fi
        # 设置权限和所有者
        chmod 755 "$AGENT_KEYS_DIR" # 目录需要执行权限才能进入
        chown root:root "$AGENT_KEYS_DIR"
        log_info "✅ 目录 $AGENT_KEYS_DIR 创建成功，权限设置为 755，所有者为 root:root。"
    else
        log_info "✅ 目录 $AGENT_KEYS_DIR 已存在。"
        # 检查权限和所有者，如有必要则修正
        local current_perms=$(stat -c "%a" "$AGENT_KEYS_DIR")
        local current_owner=$(stat -c "%U:%G" "$AGENT_KEYS_DIR")
        if [ "$current_perms" != "755" ] || [ "$current_owner" != "root:root" ]; then
            log_info "   修正目录权限和所有者..."
            chmod 755 "$AGENT_KEYS_DIR"
            chown root:root "$AGENT_KEYS_DIR"
            log_info "✅ 目录 $AGENT_KEYS_DIR 权限和所有者已修正。"
        fi
    fi
}

download_script() {
    log_info "正在下载配置脚本: $SH_URL"
    cd /home || { log_error "无法切换到 /home 目录"; exit 1; }

    # 检查并删除已存在的旧脚本文件
    if [ -f "$SCRIPT_NAME" ]; then
        log_info "发现旧脚本文件 $SCRIPT_NAME，正在删除..."
        rm -f "$SCRIPT_NAME"
        if [ $? -eq 0 ]; then
            log_info "旧脚本文件 $SCRIPT_NAME 已删除。"
        else
            log_error "删除旧脚本文件 $SCRIPT_NAME 失败。"
            exit 1
        fi
    else
        log_info "未发现旧脚本文件 $SCRIPT_NAME，跳过删除步骤。"
    fi

    # 使用 --tries 重试，--timeout 控制单次连接超时
    if ! wget --tries=3 --timeout=30 "$SH_URL" -O "$SCRIPT_NAME"; then
        log_error "下载脚本失败: $SH_URL"
        exit 1
    fi
    log_info "✅ 脚本下载成功: $SCRIPT_NAME"
}

make_executable() {
    log_info "设置脚本执行权限: $SCRIPT_NAME"
    if ! chmod +x "$SCRIPT_NAME"; then
        log_error "设置执行权限失败: $SCRIPT_NAME"
        exit 1
    fi
    log_info "✅ 执行权限设置成功"
}

# --- 主流程 ---
log_info "开始执行一键加固准备流程..."

create_agent_group
ensure_agent_keys_directory # 确保 agent 公钥目录存在且可靠
download_script
make_executable

log_info ""
log_info "==========================================="
log_info "✅ 一键加固准备流程完成！"
log_info ""
log_info "📝 已完成以下准备工作："
log_info "   1. 创建了用户组 'agentgroup'"
log_info "   2. 创建并确保了 agent 公钥存放目录 '/etc/ssh/authorized_keys_agentuser' 存在且权限正确"
log_info "   3. 从 $SH_URL 下载了配置脚本 $SCRIPT_NAME 到 /home 目录"
log_info "   4. 设置了脚本的执行权限 (+x)"
log_info ""
log_info "🚀 现在您可以手动运行配置脚本来完成后续操作："
log_info "   cd /home"
log_info "   ./$SCRIPT_NAME [选项]"
log_info ""
log_info "📋 可用选项:"
log_info "   ./$SCRIPT_NAME superman    # 配置 superman 用户 (需要手动重启 SSH)"
log_info "   ./$SCRIPT_NAME agent       # 创建 agent 用户 (会将其公钥写入 $AGENT_KEYS_DIR 下的特定文件，需要手动重启 SSH)"
log_info "   ./$SCRIPT_NAME sshd        # 重启 SSH 服务"
log_info "   ./$SCRIPT_NAME webhook     # 通过 Webhook 发送私钥 (需要 WEBHOOK_URL 环境变量)"
log_info ""
log_info "⚠️  重要提示："
log_info "   - 请务必在运行 'superman' 或 'agent' 之前设置 WEBHOOK_URL 环境变量"
log_info "   - 'superman' 和 'agent' 命令会修改 SSH 配置，但不会自动重启服务"
log_info "   - 修改配置后，请手动运行 './$SCRIPT_NAME sshd' 来重启 SSH 服务"
log_info "   - 重启 SSH 服务可能会中断当前会话，请谨慎操作"
log_info "   - agent 用户的公钥将被写入 $AGENT_KEYS_DIR 目录下的特定文件 (如 authorized_keys_agentuser1.pub)，"
log_info "     该目录已预先创建，保证了可靠性。"
log_info "==========================================="
