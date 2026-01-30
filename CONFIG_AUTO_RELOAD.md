# OpenClaw 配置自动重载说明

## 🎯 重要发现

根据 OpenClaw 官方文档，**配置文件会自动重载**，不需要手动运行配置命令！

## ✅ 自动重载机制

### 官方文档说明

```
gateway.reload (Config hot reload)
The Gateway watches ~/.openclaw/openclaw.json (or OPENCLAW_CONFIG_PATH) 
and applies changes automatically.
```

### 这意味着什么？

1. **✅ 自动监控**
   - OpenClaw 会持续监控 `~/.openclaw/openclaw.json`
   - 文件修改后自动检测

2. **✅ 自动重载**
   - 大部分配置修改后立即生效
   - 无需手动运行命令
   - 无需重启服务

3. **✅ 热更新支持**
   - 模型配置（`models`）
   - Agent 配置（`agents`）
   - 通讯平台配置（`telegram`, `discord`, `signal`）
   - Webhook 配置（`hooks`）
   - 浏览器配置（`browser`）
   - 定时任务（`cron`）

## ❌ 不需要的命令

### 1. `openclaw configure`
- ❌ **不需要运行**
- 我们的脚本直接生成配置文件
- OpenClaw 启动时自动读取

### 2. `openclaw daemon restart`
- ❌ **不需要运行**
- 配置修改后自动重载
- 只有极少数配置需要重启

## 🚀 正确的使用流程

### 初次安装

```powershell
# 1. 运行部署脚本
.\deploy_openclaw_with_aiclient.ps1
# 选择 "1. 完整安装"
# 配置自动生成到 ~/.openclaw/openclaw.json

# 2. 启动 AIClient-2-API
cd ..\..
node src/services/api-server.js

# 3. 直接启动 OpenClaw
openclaw

# 就这么简单！
# ✅ 配置已自动生成
# ✅ OpenClaw 自动读取配置
# ✅ 默认使用 AIClient-2-API
```

### 修改配置

```powershell
# 1. 编辑配置文件
notepad ~/.openclaw/openclaw.json

# 2. 保存文件

# 3. OpenClaw 自动检测并重载
# ✅ 无需任何命令
# ✅ 配置立即生效（大部分情况）
```

## 📋 配置更新类型

### 热更新（立即生效）

以下配置修改后**自动生效**，无需重启：

| 配置项 | 说明 | 示例 |
|--------|------|------|
| `models` | 模型配置 | 添加/修改模型 |
| `agents` | Agent 配置 | 修改默认模型 |
| `hooks` | Webhook 配置 | 添加 webhook |
| `browser` | 浏览器配置 | 修改浏览器设置 |
| `cron` | 定时任务 | 添加定时任务 |
| `telegram` | Telegram 配置 | 修改 bot token |
| `discord` | Discord 配置 | 修改 bot token |
| `signal` | Signal 配置 | 修改配置 |
| `imessage` | iMessage 配置 | 修改配置 |
| `whatsapp` | WhatsApp 配置 | 修改配置 |

### 需要重启（极少数）

只有极少数配置需要重启 Gateway：
- Gateway 核心配置
- 网络绑定配置
- 某些底层系统配置

## 🎯 我们的脚本优势

### 1. 直接生成配置
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "aiclient-kiro/claude-sonnet-4-5"
      }
    }
  },
  "models": {
    "providers": {
      "aiclient-kiro": {
        "baseUrl": "http://127.0.0.1:4000/v1",
        "apiKey": "hotyi",
        "api": "openai-completions"
      }
    }
  }
}
```

### 2. 自动生效
- ✅ 配置文件生成后
- ✅ OpenClaw 启动时自动读取
- ✅ 默认使用 AIClient-2-API
- ✅ 无需额外配置命令

### 3. 支持热更新
- ✅ 修改配置文件
- ✅ 保存即生效
- ✅ 无需重启

## 📝 实际测试

### 测试 1：初次安装

```powershell
# 1. 运行脚本生成配置
.\deploy_openclaw_with_aiclient.ps1

# 2. 查看生成的配置
cat ~/.openclaw/openclaw.json

# 3. 启动 OpenClaw
openclaw

# 4. 验证配置
# OpenClaw 应该自动使用 aiclient-kiro provider
# 发送消息测试 AI 响应
```

**预期结果：**
- ✅ OpenClaw 启动成功
- ✅ 自动读取配置
- ✅ 使用 AIClient-2-API
- ✅ AI 响应正常

### 测试 2：修改配置

```powershell
# 1. OpenClaw 正在运行

# 2. 修改配置文件
notepad ~/.openclaw/openclaw.json
# 例如：修改模型为 claude-haiku-4-5

# 3. 保存文件

# 4. 观察 OpenClaw 日志
# 应该看到配置重载的提示

# 5. 测试新配置
# 发送消息，应该使用新模型
```

**预期结果：**
- ✅ 配置自动重载
- ✅ 无需重启
- ✅ 新配置立即生效

## 🔍 常见问题

### Q1: 配置修改后没有生效？

**检查：**
```powershell
# 1. 确认配置文件格式正确
cat ~/.openclaw/openclaw.json | ConvertFrom-Json

# 2. 查看 OpenClaw 日志
# 应该有配置重载的提示

# 3. 如果仍未生效，尝试重启
# Ctrl+C 停止 OpenClaw
openclaw
```

### Q2: 需要重启 OpenClaw 吗？

**答案：**
- ❌ 大部分情况不需要
- ✅ 配置会自动重载
- ⚠️ 只有极少数底层配置需要重启

### Q3: 如何确认配置已生效？

**方法：**
```powershell
# 1. 查看 OpenClaw 日志
# 应该显示当前使用的模型

# 2. 发送测试消息
# 观察 AI 响应

# 3. 查看 AIClient-2-API 日志
# 应该看到请求记录
```

## 📚 相关文档

- [OpenClaw 官方配置文档](https://docs.openclaw.ai/configuration)
- [部署脚本说明](README.md)
- [快速测试指南](QUICK_TEST_v1.2.0.md)

## 🎉 总结

### 关键要点

1. **✅ 不需要 `openclaw configure`**
   - 我们的脚本直接生成配置文件
   - OpenClaw 自动读取

2. **✅ 不需要 `openclaw daemon restart`**
   - 配置修改后自动重载
   - 大部分配置热更新

3. **✅ 使用流程简单**
   - 运行脚本 → 启动 OpenClaw
   - 就这么简单！

4. **✅ 默认使用 AIClient-2-API**
   - 配置文件已正确生成
   - OpenClaw 启动即可使用

---

**版本：** v1.2.0  
**更新日期：** 2025-01-30  
**关键发现：** OpenClaw 支持配置自动重载  
**结论：** 我们的脚本已经是最佳实践 ✅
