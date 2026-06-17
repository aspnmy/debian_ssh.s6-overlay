# debian_ssh.s6-overlay — A0 Phase 1 粗读分析

## 项目概览
- **类型**: Docker 基础镜像项目
- **语言**: Bash Shell
- **基础镜像**: ghcr.io/aspnmy/debian-base:bookworm-debian12-dev-fixed-lts
- **核心组件**: OpenSSH + s6-overlay (进程管理) + Soft-RoCE RDMA

## 文件清单 & 职责

### 构建系统 (Dockerfile/debian/)
| 文件 | 职责 | 行数 |
|------|------|------|
| build-baseimage | 主构建脚本：生成 s6-overlay + SSH Dockerfile → 构建 → zstd压缩 → 推送 DH/GHCR | ~150 |
| build-rdma | RDMA 镜像构建：基于 base 镜像叠加 libibverbs + RDMA 工具 → zstd → 推送 | ~50 |
| debian-base.md | BASEIMAGE 配置（1行） | 1 |
| debian_ssh.s6.md | RDMA 镜像 BASEIMAGE 引用（1行） | 1 |

### 应用层 (Dockerfile/app/)
| 文件 | 职责 | 问题 |
|------|------|------|
| roottools/setRootKey_Cli.sh.s6 | SSH 密钥管理 CLI（superman/usrkey/sshd/set_hosts/mailto） | ✅ superman模式（仅公钥，私钥离线）— 必须保留 |
| roottools/build_binary | C 编译脚本（编译 setRootKey_Cli） | ⚪ 依赖 gcc |
| roottools/build/setRootKey_Cli | 预编译二进制 | ⚪ 架构锁定 x86_64 |
| rdma/docker-compose.yaml | 双节点 RDMA 测试编排 | 🟠 镜像 tag 硬编码可能过期 |
| rdma/check_rdma_softroce | Soft-RoCE 设备检测 | ⚪ |
| rdma/rdma_manage | RDMA 设备管理 | ⚪ |
| rdma/install_rust | Rust 工具链安装 | ⚪ |
| rdma/setup_softroce_host | 宿主机 Soft-RoCE 配置 | ⚪ 需特权模式 |

### s6-overlay 服务 (Dockerfile/app/s6-overlay/)
| 文件 | 职责 |
|------|------|
| rdma_daemon_all.sh | RDMA 交互菜单（server/client/attach/kill） |
| rdma_server_daemon.sh | 常驻 ib_write_bw 服务端（无限重连） |
| rdma_client_daemon.sh | 常驻 ib_write_bw 客户端（自动重连） |
| rdma_session.sh | 虚拟会话管理 |
| rdma_test_tool.sh | RDMA 带宽测试 |

### 其他
| 文件 | 职责 | 问题 |
|------|------|------|
| git-hooks/pre-commit | 自动 commit + push 循环 | 🔴 无限循环后台运行 |
| quick_install_docker.sh | Docker 一键安装（从 1panel 提取） | 🟠 依赖中国大陆镜像源 |

## 明显缺口

1. 🔴 **pre-commit hook 无限循环** — while true; do auto_pre_commit; sleep 600; done & 会持续占用资源
2. ✅ superman公钥为设计特性（仅公钥无风险，私钥离线保管）
3. 🟠 **无多架构支持** — s6-overlay 仅下载 x86_64，无 aarch64
4. 🟠 **docker-compose.yaml 镜像 tag 硬编码** — 与构建版本脱钩
5. 🟠 **默认 root 密码泄露** — README 明文 root@#1314
6. 🟡 **无健康检查** — Dockerfile 未定义 HEALTHCHECK
7. 🟡 **无 CI/CD** — 缺少 GitHub Actions / 自动化构建
8. 🟡 **build-baseimage 单文件过长** — ~150行含 Dockerfile 模板内嵌
9. ⚪ **无测试框架** — 无 shellcheck / bats 测试
10. ⚪ **debian-base.md 和 debian_ssh.s6.md 仅1行** — 过度拆分
