# debian_ssh.s6-overlay — A0 Phase 2 精读 v1

## 交叉依赖关系

```
debian-base.md (BASEIMAGE)
       |
build-baseimage --- s6-overlay GitHub Release
       |                |
  baseimage (SSH+s6)    .user_repo (aspnmy/debian_ssh.s6-overlay)
       |
debian_ssh.s6.md (硬编码 tag)
       |
build-rdma --- RDMA 工具层 (libibverbs, perftest, etc.)
       |
  rdma image - docker-compose.yaml (双节点测试)
```

⚠️ **依赖断裂点**: debian_ssh.s6.md 硬编码 baseimage tag，新版本构建后需手动更新。

## 逐文件详细分析

### P0 — 必须修复

| # | 文件 | 问题 | 根因 |
|---|------|------|------|
| 1 | git-hooks/pre-commit | main & 后台无限循环，每10分钟 auto_commit+push | while true 无退出条件；else if 语法错误（应 elif） |

### P1 — 高优先级

| # | 文件 | 问题 | 建议 |
|---|------|------|------|
| 2 | debian_ssh.s6.md | 硬编码 baseimage tag | 改为从 build-baseimage 输出读取或使用 latest |
| 3 | docker-compose.yaml | 镜像 tag 硬编码，与构建版本脱钩 | 使用变量或生成脚本 |
| 4 | build-baseimage | s6-overlay 仅下载 x86_64 架构 | 增加 aarch64 分支（arm64 服务器场景） |

### P2 — 中优先级

| # | 文件 | 问题 | 建议 |
|---|------|------|------|
| 5 | build-baseimage | 无 HEALTHCHECK 指令 | 添加 HEALTHCHECK --interval=30s CMD pgrep sshd |
| 6 | 全部 | 无 CI/CD 自动构建 | 添加 GitHub Actions（matrix: baseimage, rdma） |
| 7 | README.md | 明文默认密码 | 改为占位符或引导用户修改 |

### P3 — 低优先级

| # | 文件 | 问题 | 建议 |
|---|------|------|------|
| 8 | build-baseimage | Dockerfile 模板内嵌在主脚本中 | 提取为独立 Dockerfile 模板文件 |
| 9 | debian-base.md + debian_ssh.s6.md | 两个文件各仅1行 | 合并为 image-refs.conf |
| 10 | quick_install_docker.sh | 仅支持中国大陆镜像源逻辑 | 通用化：自动检测地区选择镜像 |

### P4 — 改进

| # | 文件 | 问题 | 建议 |
|---|------|------|------|
| 11 | 全部 .sh | 无 shellcheck 验证 | 添加 shellcheck 到 pre-commit |
| 12 | build_binary | 依赖 shc 编译（需网络安装） | 预装 shc 到基础镜像或改用编译型语言 |
