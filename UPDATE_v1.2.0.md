# 部署脚本更新 v1.2.0

## 🎉 新功能

### 1. ✅ 卸载功能
- 完整卸载 OpenClaw 及其配置
- 自动备份配置文件
- **不会删除** Node.js、AIClient-2-API、Claude Code
- 验证其他软件未受影响

### 2. ✅ 自动配置检测
- 自动从 AIClient-2-API 配置读取 API Key 和端口
- 自动从 Claude Code 配置读取端口信息
- 询问 hotyi-dev 安装盘符，自动定位配置文件
- 大幅提高自动化程度

### 3. ✅ 更新的菜单
```
1. 完整安装 (推荐)
2. 仅安装 OpenClaw
3. 仅配置 AIClient-2-API 连接
4. 检查安装状态
5. 卸载 OpenClaw          ← 新增
6. 清理配置
7. 退出
```

## 📋 功能详解

### 卸载功能

#### 卸载内容
- ✅ OpenClaw npm 全局包
- ✅ OpenClaw 配置目录 (`~/.openclaw`)
- ✅ npm 缓存中的 OpenClaw

#### 保留内容
- ✅ Node.js（AIClient-2-API 需要）
- ✅ AIClient-2-API
- ✅ Claude Code
- ✅ 其他所有软件

#### 安全措施
- 自动备份配置到 `~/.openclaw-backup-时间戳`
- 卸载前需要用户确认
- 卸载后验证其他软件状态

### 自动配置检测

#### 检测流程
```
1. 询问 hotyi-dev 安装盘符（如: F）
   ↓
2. 读取 AIClient-2-API 配置
   路径: F:\hotyi-dev\AIClient-2-API\configs\config.json
   提取: REQUIRED_API_KEY, SERVER_PORT
   ↓
3. 读取 Claude Code 配置（可选）
   路径: C:\Users\hotyi\.claude\settings.json
   提取: baseUrl 中的端口号
   ↓
4. 构建配置
   API Key: 从 AIClient-2-API 配置
   Base URL: http://127.0.0.1:{端口}/v1
   ↓
5. 显示自动检测结果
   用户可以直接按 Enter 使用
```

#### 配置来源优先级
1. AIClient-2-API config.json（优先）
2. Claude Code settings.json（补充）
3. 默认值（fallback）

## 🚀 使用示例

### 完整安装（自动配置）

```powershell
# 运行脚本
.\deploy_openclaw_with_aiclient.ps1

# 选择 "1. 完整安装"

# 输入 hotyi-dev 盘符
盘符 (默认: F): F

# 自动检测配置
[✓] 找到 AIClient-2-API 配置
  └─ API Key: hotyi
  └─ Server Port: 4000

自动检测结果：
  API Key: hotyi
  Base URL: http://127.0.0.1:4000/v1
  hotyi-dev 路径: F:\hotyi-dev

# 配置参数（直接按 Enter 使用自动检测的值）
AIClient-2-API Key (自动检测: hotyi): [Enter]
AIClient-2-API 地址 (自动检测: http://127.0.0.1:4000/v1): [Enter]

# 选择模型
选择模型 (1-3, 默认 1): [Enter]

# 完成！
```

### 卸载 OpenClaw

```powershell
# 运行脚本
.\deploy_openclaw_with_aiclient.ps1

# 选择 "5. 卸载 OpenClaw"

# 确认卸载
确认卸载? (y/n): y

# 卸载过程
[1/4] 卸载 OpenClaw npm 包...
[✓] OpenClaw npm 包已卸载

[2/4] 处理配置目录...
[✓] 配置已备份到: C:\Users\hotyi\.openclaw-backup-20250130-123456
[✓] 配置目录已删除

[3/4] 清理 npm 缓存...
[✓] npm 缓存已清理

[4/4] 验证卸载...
[✓] OpenClaw 已完全卸载

验证其他软件状态：
[✓] Node.js: v20.11.0 (未受影响)
[✓] Claude Code: 已安装 (未受影响)
[✓] AIClient-2-API: 已安装 (未受影响)

========================================
         卸载完成！
========================================
```

## 🔧 技术实现

### Get-AutoConfig 函数

```powershell
function Get-AutoConfig {
    # 1. 询问盘符
    $driveLetter = Read-Host "盘符 (默认: F)"
    $hotyiDevPath = "${driveLetter}:\hotyi-dev"
    
    # 2. 读取 AIClient-2-API 配置
    $aiclientConfigPath = "$hotyiDevPath\AIClient-2-API\configs\config.json"
    if (Test-Path $aiclientConfigPath) {
        $aiclientConfig = Get-Content $aiclientConfigPath | ConvertFrom-Json
        $apiKey = $aiclientConfig.REQUIRED_API_KEY
        $serverPort = $aiclientConfig.SERVER_PORT
    }
    
    # 3. 读取 Claude Code 配置（补充）
    $claudeConfigPath = "$env:USERPROFILE\.claude\settings.json"
    if (Test-Path $claudeConfigPath) {
        $claudeConfig = Get-Content $claudeConfigPath | ConvertFrom-Json
        # 从 baseUrl 提取端口号
        if ($claudeConfig.api.baseUrl -match ':(\d+)') {
            $serverPort = $matches[1]
        }
    }
    
    # 4. 构建配置
    $baseUrl = "http://127.0.0.1:$serverPort/v1"
    
    return @{
        apiKey = $apiKey
        baseUrl = $baseUrl
        serverPort = $serverPort
        hotyiDevPath = $hotyiDevPath
    }
}
```

### Uninstall-OpenClaw 函数

```powershell
function Uninstall-OpenClaw {
    # 1. 确认卸载
    $confirm = Read-Host "确认卸载? (y/n)"
    if ($confirm -ne "y") { return }
    
    # 2. 卸载 npm 包
    npm uninstall -g openclaw
    
    # 3. 备份并删除配置
    $configDir = "$env:USERPROFILE\.openclaw"
    $backupDir = "$env:USERPROFILE\.openclaw-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -Path $configDir -Destination $backupDir -Recurse
    Remove-Item -Path $configDir -Recurse -Force
    
    # 4. 清理缓存
    npm cache clean --force
    
    # 5. 验证其他软件
    # 检查 Node.js, Claude Code, AIClient-2-API
}
```

## 📝 配置文件示例

### 自动生成的配置（使用自动检测）

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
            "name": "Claude Sonnet 4.5 (Kiro)",
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

注意：
- `baseUrl` 和 `apiKey` 自动从 AIClient-2-API 配置读取
- 端口号自动检测（4000 或其他配置的端口）

## ✅ 测试场景

### 场景 1：自动配置检测

**前提：**
- AIClient-2-API 已安装在 F:\hotyi-dev
- config.json 中配置了 API Key 和端口

**步骤：**
1. 运行脚本，选择 "1. 完整安装"
2. 输入盘符 "F"
3. 所有配置项按 Enter

**预期：**
- ✓ 自动检测到 API Key: hotyi
- ✓ 自动检测到端口: 4000
- ✓ 自动构建 Base URL: http://127.0.0.1:4000/v1
- ✓ 配置文件正确生成

### 场景 2：卸载 OpenClaw

**前提：**
- OpenClaw 已安装
- 配置文件存在

**步骤：**
1. 运行脚本，选择 "5. 卸载 OpenClaw"
2. 确认卸载

**预期：**
- ✓ OpenClaw 被卸载
- ✓ 配置被备份
- ✓ Node.js 仍然存在
- ✓ AIClient-2-API 未受影响
- ✓ Claude Code 未受影响

### 场景 3：不同盘符

**前提：**
- hotyi-dev 安装在 D 盘

**步骤：**
1. 运行脚本，选择 "1. 完整安装"
2. 输入盘符 "D"

**预期：**
- ✓ 正确读取 D:\hotyi-dev\AIClient-2-API\configs\config.json
- ✓ 配置正确生成

## 🎯 优势

### 1. 更高的自动化
- 之前：需要手动输入 API Key 和 Base URL
- 现在：自动从配置文件读取，直接按 Enter

### 2. 更安全的卸载
- 自动备份配置
- 验证其他软件未受影响
- 不会删除 Node.js

### 3. 更灵活的配置
- 支持不同盘符
- 支持自定义端口
- 自动适应现有配置

## 📚 相关文档

- [部署指南](README.md)
- [测试清单](TEST_CHECKLIST.md)
- [更新日志](CHANGELOG.md)

---

**版本：** v1.2.0  
**更新日期：** 2025-01-30  
**新增功能：** 卸载功能 + 自动配置检测  
**状态：** ✅ 已完成，准备测试
