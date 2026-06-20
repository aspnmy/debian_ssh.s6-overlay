# Future Sandbox Platforms (未来沙盒基座)

## 规划中

### Windows Sandbox (windows-sandbox)
- **目标：** Windows Server Core / Windows 容器内编译和测试
- **用途：** .NET 编译、Windows 原生工具链（MSVC）、PowerShell 脚本测试
- **预计镜像：** `ghcr.io/aspnmy/sandbox-win:latest`
- **技术路线：** Windows Server Core LTSC + OpenSSH Server + winget/choco 包管理
- **状态：** 📋 规划中

### macOS Sandbox (macos-sandbox)
- **目标：** macOS 环境的交叉编译验证和 iOS/macOS 构建
- **用途：** Xcode 命令行工具、Swift 编译、iOS 构建签名
- **预计镜像：** Docker-OSX / UTM based（非标准 Docker）
- **技术路线：** GitHub Actions macOS runner 作为主要方案；本地 macOS 作为辅助
- **状态：** 📋 规划中

## 设计原则

所有平台沙盒遵循相同原则：
1. **无状态** — 即用即弃，无状态残留
2. **SSH 可达** — 统一通过 SSH 访问，Agent 透明切换
3. **工具链预装** — Agent 不浪费 token 在 `apt-get install` 上
4. **CI 自动构建** — 推送到对应 registry，Agent 按需拉取
