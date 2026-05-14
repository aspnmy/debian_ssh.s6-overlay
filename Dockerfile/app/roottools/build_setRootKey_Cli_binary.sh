#!/bin/bash
set -euo pipefail

SCRIPT_PATH="$(dirname "$0")/setRootKey_Cli.sh.s6"
OUTPUT_BIN="$(dirname "$0")/setRootKey_Cli"

if [ ! -f "$SCRIPT_PATH" ]; then
  echo "脚本不存在：$SCRIPT_PATH"
  exit 1
fi

if ! command -v shc >/dev/null 2>&1; then
  echo "shc 未安装，正在安装..."
  apt-get update
  apt-get install -y shc
fi

if ! command -v cc >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1; then
  echo "C 编译器未安装，正在安装 build-essential..."
  apt-get update
  apt-get install -y build-essential
fi

if ! command -v shc >/dev/null 2>&1; then
  echo "错误：shc 安装失败，请手动安装 shc。"
  exit 1
fi

if ! command -v cc >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1; then
  echo "错误：C 编译器安装失败，请手动安装 gcc 或 build-essential。"
  exit 1
fi

echo "正在编译 $SCRIPT_PATH 为二进制文件..."
shc -f "$SCRIPT_PATH" -o "$OUTPUT_BIN"
chmod +x "$OUTPUT_BIN"

echo "编译完成：$OUTPUT_BIN"

echo "开始验证二进制是否可执行..."
"$OUTPUT_BIN" invalid || true

echo "验证完成。请观察上方输出是否为脚本使用提示。"
