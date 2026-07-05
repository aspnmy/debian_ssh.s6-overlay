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
# 如果是在自动化环境（如 Docker 启动脚本）或后台任务中运行，则不受影响。
execute_command "superman"
execute_command "agent"

log_info "✅ 一键加固流程完成！"
log_info "请从 /aspnmy/wwwroot/ssh_key/ 目录下载 agent 用户的私钥。"
log_info "⚠️  警告: 如果当前会话因 SSH 重启而断开，请使用新生成的密钥重新连接。"
