# Sandbox Variants (沙盒变体)

无状态沙盒体系的设计原则：

1. **极简基座** — `base` 层仅含 s6-overlay + SSH + 基础工具（curl/git/python3/jq），不做多余安装
2. **变体追加** — 各变体从 base 继承，按自身定位追加工具链
3. **完全无状态** — 容器销毁后不留任何残留。Agent 每次使用时自行 clone 项目、安装依赖
4. **Agent 自调用** — Agent 可按需 `docker run` 指定变体镜像，生成 disposable 容器执行任务

## 当前变体

| 变体 | 端口 | 用途 | 关键工具链 |
|------|------|------|-----------|
| `sandbox-622` | 622 | 交叉编译 | Rust(4 targets) + Go + GCC-cross + CMake + Node.js |
| `sandbox-7777` | 7777 | Docker 构建 | docker-cli + buildx + QEMU + skopeo + crane |

## 镜像标签

```
ghcr.io/aspnmy/sandbox-base:base-latest    # 共享基座
ghcr.io/aspnmy/sandbox-622:latest          # 622 交叉编译
ghcr.io/aspnmy/sandbox-7777:latest         # 7777 Docker 构建
```

## Agent 使用示例

```bash
# Agent 自主创建一次性交叉编译沙盒
docker run -d --rm --name build-$(uuidgen) \
    -p 622:622 \
    ghcr.io/aspnmy/sandbox-622:latest

# Agent 自主创建 Docker 构建沙盒（需挂载 docker.sock）
docker run -d --rm --name docker-$(uuidgen) \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -p 7777:7777 \
    ghcr.io/aspnmy/sandbox-7777:latest
```

## 构建流程

```
base/Dockerfile 变更 → CI构建base → 推送 ghcr.io
variants/622/* 变更 → CI以base为FROM构建622 → 推送 ghcr.io
variants/7777/* 变更 → CI以base为FROM构建7777 → 推送 ghcr.io
```
