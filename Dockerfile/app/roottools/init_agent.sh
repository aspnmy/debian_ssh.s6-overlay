#!/bin/bash

# --- 配置 ---
SH_URL="https://raw.githubusercontent.com/aspnmy/debian_ssh.s6-overlay/refs/heads/baseimage/Dockerfile/app/roottools/setRootKey_Cli.sh.s6"
SCRIPT_NAME="setRootKey_Cli.sh.s6"

# --- 函数定义 ---
log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1"; }

download_script() {
    log_info "正在下载脚本: $SH_URL"
    cd /home || { log_error "无法切换到 /home 目录"; exit 1; }
    # 使用 --tries 重试，--timeout 控制单次连接超时
    if ! wget --tries=3 --timeout=30 "$SH_URL" -O "$SCRIPT_NAME"; then
        log_error "下载脚本失败: $SH_URL"
        exit 1
    fi
    log_info "脚本下载成功: $SCRIPT_NAME"
}

make_executable() {
    log_info "设置脚本执行权限: $SCRIPT_NAME"
    if ! chmod +x "$SCRIPT_NAME"; then
        log_error "设置执行权限失败: $SCRIPT_NAME"
        exit 1
    fi
    log_info "执行权限设置成功"
}

execute_command() {
    local cmd="$1"
    log_info "执行命令: ./$SCRIPT_NAME $cmd"
    if ! ./"$SCRIPT_NAME" "$cmd"; then
        log_error "命令执行失败: ./$SCRIPT_NAME $cmd"
        exit 1 # 如果任何一个步骤失败，立即停止
    fi
    log_info "命令执行成功: ./$SCRIPT_NAME $cmd"
}

# --- 主流程 ---
log_info "开始执行一键加固流程..."

download_script
make_executable

# 注意：执行 superman 会重启 SSH 服务，这可能中断当前的 SSH 会话。
# 如果是在终端直接执行，且当前连接是唯一的，那么后续命令可能无法执行。
# 强烈建议在非交互式环境（如 Docker 启动脚本）或后台任务中运行此脚本。
# 确保 WEBHOOK_URL 环境变量已设置，以便接收生成的 agent 私钥。
if [ -z "$WEBHOOK_URL" ]; then
    log_error "环境变量 WEBHOOK_URL 未设置。无法发送 agent 用户私钥。"
    log_error "请先设置 WEBHOOK_URL，例如: export WEBHOOK_URL='https://your-webhook.com'"
    exit 1
fi

log_info "检测到 WEBHOOK_URL 已设置，将尝试发送生成的密钥。"

execute_command "superman"
execute_command "agent"

# 尝试触发 webhook 发送，如果失败，需要在外部手动触发
log_info "尝试发送 agent 用户私钥到 Webhook..."
if ./"$SCRIPT_NAME" "webhook"; then
    log_info "✅ Webhook 发送尝试完成。"
else
    log_error "❌ Webhook 发送尝试失败。请稍后手动运行: ./$SCRIPT_NAME webhook"
    log_error "    (需要确保 WEBHOOK_URL 环境变量已正确设置)"
fi

log_info "✅ 一键加固流程主体部分完成！"
log_info "⚠️  警告: 如果当前会话因 SSH 重启而断开，请使用新生成的 superman 密钥重新连接。"
log_info "🔑 agent 用户的私钥已尝试通过 Webhook 发送。请检查 Webhook 接收端。"
log_info "   如果 Webhook 发送失败，请手动从 /aspnmy/wwwroot/ssh_key/ 目录获取。"
