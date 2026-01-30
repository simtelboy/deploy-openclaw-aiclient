# OpenClaw + AIClient-2-API 部署指南

本目录包含用于配置 OpenClaw 使用 AIClient-2-API (Kiro) 的部署脚本和配置文件。

## 📁 文件说明

- `deploy_openclaw_with_aiclient.ps1` - 自动部署脚本（Windows PowerShell）
- `openclaw-config-example.json` - OpenClaw 配置示例
- `install.ps1` - OpenClaw 官方安装脚本（参考）
- `README.md` - 本文档

## 🚀 快速开始

### 前置条件

1. **AIClient-2-API 已安装并运行**
   - 服务地址: `http://127.0.0.1:4000`
   - API Key: 在 `AIClient-2-API/configs/config.json` 中配置

2. **Kiro IDE 已登录**
   - 确保 Kiro 认证 token 存在: `~/.aws/sso/cache/kiro-auth-token.json`

### 一键部署

在 PowerShell 中运行：

```powershell
cd AIClient-2-API/deploy-clawdbot
.\deploy_openclaw_with_aiclient.ps1
```

### 部署选项

脚本提供以下选项：

1. **完整安装（推荐）** - 自动安装 OpenClaw 并配置 AIClient-2-API
2. **仅安装 OpenClaw** - 只安装 OpenClaw，不配置
3. **仅配置 AIClient-2-API** - 为已安装的 OpenClaw 添加配置
4. **检查安装状态** - 查看当前安装和配置状态
5. **清理配置** - 删除 OpenClaw 配置（会备份）

## ⚙️ 配置说明

### 自动配置

脚本会自动创建配置文件：`~/.openclaw/openclaw.json`

配置内容包括：
- Provider: `aiclient-kiro`
- Base URL: `http://127.0.0.1:4000/v1`
- API Key: 你在安装时输入的 key（默认 `hotyi`）
- Model: `claude-sonnet-4-5`

### 手动配置

如果需要手动配置，可以参考 `openclaw-config-example.json`：

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "aiclient-kiro/claude-sonnet-4-5"
      },
      "models": {
        "aiclient-kiro/claude-sonnet-4-5": {
          "alias": "Claude Sonnet 4.5 (Kiro)"
        }
      }
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "aiclient-kiro": {
        "baseUrl": "http://127.0.0.1:4000/v1",
        "apiKey": "hotyi",
        "api": "openai-completions",
        "models": [
          {
            "id": "claude-sonnet-4-5",
            "name": "Claude Sonnet 4.5 via Kiro",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": {
              "input": 0,
              "output": 0,
              "cacheRead": 0,
              "cacheWrite": 0
            },
            "contextWindow": 200000,
            "maxTokens": 8192
          }
        ]
      }
    }
  }
}
```

将此配置保存到 `~/.openclaw/openclaw.json`（Windows: `C:\Users\你的用户名\.openclaw\openclaw.json`）

## 🔧 使用步骤

### 1. 启动 AIClient-2-API

```powershell
cd AIClient-2-API
node src/services/api-server.js
```

或使用 Web UI：
```powershell
npm start
```

### 2. 启动 OpenClaw

```powershell
openclaw
```

### 3. 测试连接

在 OpenClaw 中发送消息，测试 AI 响应是否正常。

## 📝 支持的模型

根据 Kiro API 限制，目前支持以下模型：

- ✅ `claude-sonnet-4-5` - Claude Sonnet 4.5（推荐）
- ✅ `claude-sonnet-4` - Claude Sonnet 4
- ✅ `claude-haiku-4-5` - Claude Haiku 4.5
- ❌ `claude-opus-4-5` - **不支持**（Kiro 不支持 Opus）

## 🔍 故障排查

### OpenClaw 无法连接到 AIClient-2-API

1. **检查 AIClient-2-API 是否运行**
   ```powershell
   # 测试连接
   Invoke-WebRequest -Uri "http://127.0.0.1:4000" -Method GET
   ```

2. **检查配置文件**
   - 位置: `~/.openclaw/openclaw.json`
   - 确认 `baseUrl` 和 `apiKey` 正确

3. **查看 AIClient-2-API 日志**
   - 检查是否有请求到达
   - 查看是否有错误信息

### OpenClaw 返回 400 错误

可能原因：
- 使用了不支持的模型（如 `claude-opus-4-5`）
- API Key 不正确
- 请求格式问题

解决方法：
- 确保使用 `claude-sonnet-4-5` 或其他支持的模型
- 检查 `apiKey` 配置是否与 AIClient-2-API 一致

### Node.js 版本问题

OpenClaw 需要 Node.js v22+：

```powershell
# 检查版本
node --version

# 如果版本过低，使用 winget 升级
winget install OpenJS.NodeJS.LTS
```

## 📚 相关文档

- [OpenClaw 官方文档](https://docs.openclaw.ai/)
- [OpenClaw 配置指南](https://docs.openclaw.ai/configuration)
- [AIClient-2-API 文档](../README.md)

## 🆘 获取帮助

- OpenClaw 帮助: `openclaw --help`
- 运行向导: `openclaw onboard`
- 检查配置: `openclaw doctor`

## 📄 许可证

本部署脚本遵循 AIClient-2-API 项目的许可证。
