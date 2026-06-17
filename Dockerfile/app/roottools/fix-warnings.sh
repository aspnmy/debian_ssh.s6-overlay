#!/bin/bash
# ==============================================================
# fix-warnings.sh
# 修复容器中常见的：
#   ① useradd: Warning: missing or non-executable shell '/usr/sbin/nologin'
#   ② invoke-rc.d: WARNING: No init system and policy-rc.d missing!
# 按需使用，不影响不需要的容器
# ==============================================================

set -e

echo "========================================"
echo "  Docker 容器警告修复脚本"
echo "========================================"

# --------------------------------------------------
# 修复 1: missing or non-executable shell '/usr/sbin/nologin'
# --------------------------------------------------
fix_nologin() {
    echo ""
    echo "[1/2] 修复 nologin shell..."

    if [ -f /sbin/nologin ]; then
        ln -sf /sbin/nologin /usr/sbin/nologin 2>/dev/null && \
            echo "  ✓ 已创建符号链接: /sbin/nologin -> /usr/sbin/nologin" && return 0
    fi

    for src in /bin/nologin /usr/bin/nologin; do
        if [ -f "$src" ]; then
            ln -sf "$src" /usr/sbin/nologin 2>/dev/null && \
                echo "  ✓ 已创建符号链接: $src -> /usr/sbin/nologin" && return 0
        fi
    done

    if [ ! -f /usr/sbin/nologin ]; then
        touch /usr/sbin/nologin 2>/dev/null
        chmod 755 /usr/sbin/nologin 2>/dev/null
        echo "  ✓ 已创建空文件: /usr/sbin/nologin"
    else
        chmod 755 /usr/sbin/nologin 2>/dev/null
        echo "  ✓ 已设置权限: /usr/sbin/nologin"
    fi
}

# --------------------------------------------------
# 修复 2: invoke-rc.d warning - policy-rc.d missing
# --------------------------------------------------
fix_policy_rc_d() {
    echo ""
    echo "[2/2] 修复 invoke-rc.d 警告 (policy-rc.d)..."

    if [ ! -f /usr/sbin/policy-rc.d ]; then
        cat > /usr/sbin/policy-rc.d << 'EOF'
#!/bin/sh
exit 101
EOF
        chmod 755 /usr/sbin/policy-rc.d
        echo "  ✓ 已创建 /usr/sbin/policy-rc.d (所有服务操作返回 101，阻止自动启动)"
    else
        echo "  - /usr/sbin/policy-rc.d 已存在，跳过创建"
    fi
}

# --------------------------------------------------
# 执行
# --------------------------------------------------
fix_nologin
fix_policy_rc_d

echo ""
echo "========================================"
echo "  修复完成！"
echo "========================================"
