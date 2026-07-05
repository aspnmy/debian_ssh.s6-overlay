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

# 确保 agent 公钥存放目录存在并设置正确的权限
ensure_agent_keys_directory() {
    log_info "检查 agent 公钥存放目录: $AGENT_KEYS_DIR"
    if [ ! -d "$AGENT_KEYS_DIR" ]; then
        log_info "目录 $AGENT_KEYS_DIR 不存在，正在创建..."
        # 创建目录
        if ! mkdir -p "$AGENT_KEYS_DIR"; then
            log_error "❌ 创建目录 $AGENT_KEYS_DIR 失败。"
            exit 1
        fi
        # 设置正确的权限和所有者 (由 init 脚本负责)
        local AGENT_GROUP="agentgroup"
        # 检查组是否存在（应该是存在的，因为 create_agent_group 先调用了）
        if ! getent group "$AGENT_GROUP" > /dev/null; then
            log_error "❌ 预期的用户组 $AGENT_GROUP 不存在，无法设置目录 $AGENT_KEYS_DIR 的组权限。"
            exit 1
        fi
        # 设置目录权限为 750，所有者为 root，组为 agentgroup
        chmod 750 "$AGENT_KEYS_DIR" # owner: rwx, group: rx, others: -
        chown root:"$AGENT_GROUP" "$AGENT_KEYS_DIR" # 将组设置为 agentgroup
        log_info "✅ 目录 $AGENT_KEYS_DIR 创建成功，权限设置为 750，所有者为 root:$AGENT_GROUP。"
    else
        log_info "✅ 目录 $AGENT_KEYS_DIR 已存在。"
        # 检查权限和所有者，如有必要则修正（确保在容器启动时或多次运行时，权限始终正确）
        local AGENT_GROUP="agentgroup"
        if ! getent group "$AGENT_GROUP" > /dev/null; then
            log_error "❌ 预期的用户组 $AGENT_GROUP 不存在，无法校验/修正目录 $AGENT_KEYS_DIR 的组权限。"
            exit 1
        fi
        
        local current_perms=$(stat -c "%a" "$AGENT_KEYS_DIR")
        local current_owner=$(stat -c "%U:%G" "$AGENT_KEYS_DIR")
        local expected_perms="750"
        local expected_owner="root:$AGENT_GROUP"
        
        if [ "$current_perms" != "$expected_perms" ] || [ "$current_owner" != "$expected_owner" ]; then
            log_info "   修正目录权限和所有者为 $expected_perms, $expected_owner ..."
            chmod "$expected_perms" "$AGENT_KEYS_DIR"
            chown "$expected_owner" "$AGENT_KEYS_DIR"
            log_info "✅ 目录 $AGENT_KEYS_DIR 权限和所有者已修正。"
        else
            log_info "✅ 目录 $AGENT_KEYS_DIR 权限和所有者已正确。"
        fi
    fi
}

download_script() {
    log_info "正在下载配置脚本: $SH_URL"

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
ensure_agent_keys_directory # 确保 agent 公钥目录存在且权限正确（由 init 脚本设置）
download_script
make_executable

log_info ""
log_info "==========================================="
log_info "✅ 一键加固准备流程完成！"
log_info ""
log_info "📝 已完成以下准备工作："
log_info "   1. 创建了用户组 'agentgroup'"
log_info "   2. 创建并确保了 agent 公钥存放目录 '/etc/ssh/authorized_keys_agentuser' 存在且权限正确 (root:agentgroup 750)"
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
log_info "     该目录已预先创建并设置好权限 (root:agentgroup 750)，保证了可靠性。"
log_info "   - 配置脚本 (check_and_create_dir) 也会验证此目录权限，若不一致会尝试修正。"
log_info "==========================================="
