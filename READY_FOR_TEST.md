# ✅ 准备测试 - OpenClaw 部署脚本

## 📋 更新摘要

根据你的要求，我已经完成以下优化：

### 🔧 主要改进

1. **✅ Node.js 智能检测**
   - 如果 Node.js 已安装且版本 ≥ v18，**不会重新安装**
   - 降低最低版本要求到 v18+（兼容 AIClient-2-API 的环境）
   - 版本过低时询问是否升级，而不是强制升级
   - 保护现有环境，避免影响其他应用

2. **✅ 一键完成部署**
   - 选择"完整安装"后自动完成所有步骤
   - 所有配置项提供智能默认值
   - 无需手动输入，直接按 Enter 即可
   - 自动验证每个步骤的结果

3. **✅ 友好的用户界面**
   - 显示"步骤 X/3"进度提示
   - 使用颜色和 emoji 区分信息类型
   - 提供详细的完成提示和下一步操作
   - 模型选择使用菜单而不是手动输入

## 🎯 核心特性

### Node.js 处理逻辑

```
检测 Node.js
    ├─ 已安装 v18+ → ✓ 跳过安装，继续
    ├─ 已安装 < v18 → ⚠ 询问是否升级
    │   ├─ 选择 y → 升级到最新 LTS
    │   └─ 选择 n → 继续使用当前版本
    └─ 未安装 → 安装最新 LTS
```

### 一键部署流程

```
运行脚本
    ↓
选择 "1. 完整安装"
    ↓
步骤 1/3: 检查 Node.js
    ├─ 已安装 v18+ → 跳过
    └─ 未安装/版本低 → 处理
    ↓
步骤 2/3: 安装 OpenClaw
    ├─ 已安装 → 跳过
    └─ 未安装 → 自动安装
    ↓
步骤 3/3: 配置连接
    ├─ 输入配置（或使用默认值）
    └─ 生成配置文件
    ↓
✅ 完成！显示下一步操作
```

## 📁 文件清单

### 核心文件
- ✅ `deploy_openclaw_with_aiclient.ps1` - 主部署脚本（已优化）
- ✅ `test_connection.ps1` - 连接测试脚本
- ✅ `openclaw-config-example.json` - 配置示例

### 文档文件
- ✅ `README.md` - 部署目录说明
- ✅ `CHANGELOG.md` - 更新日志（v1.1.0）
- ✅ `TEST_CHECKLIST.md` - 测试清单
- ✅ `READY_FOR_TEST.md` - 本文档

### 参考文件
- ✅ `install.ps1` - OpenClaw 官方安装脚本（参考）

## 🚀 快速测试

### 测试步骤

```powershell
# 1. 进入部署目录
cd AIClient-2-API/deploy-clawdbot

# 2. 运行部署脚本
.\deploy_openclaw_with_aiclient.ps1

# 3. 选择 "1. 完整安装"

# 4. 所有配置项直接按 Enter（使用默认值）
#    - API Key: hotyi
#    - Base URL: http://127.0.0.1:4000/v1
#    - Model: 1 (claude-sonnet-4-5)

# 5. 等待完成（预计 1-2 分钟）

# 6. 测试连接
.\test_connection.ps1

# 7. 启动 AIClient-2-API（新终端）
cd ..\..
node src/services/api-server.js

# 8. 启动 OpenClaw（新终端）
openclaw
```

### 预期结果

#### 如果 Node.js 已安装（v18+）
```
步骤 1/3: 检查 Node.js...
[✓] Node.js v20.11.0 已安装 (符合要求 v18+)

步骤 2/3: 检查 OpenClaw...
[!] OpenClaw 未安装
[*] 安装 OpenClaw...
[✓] OpenClaw 安装成功

步骤 3/3: 配置 OpenClaw...
[✓] 配置已保存

========================================
         🎉 部署完成！
========================================
```

#### 如果 Node.js 未安装
```
步骤 1/3: 检查 Node.js...
[!] Node.js 未安装
[*] 安装 Node.js...
[✓] Node.js 安装成功

步骤 2/3: 检查 OpenClaw...
[*] 安装 OpenClaw...
[✓] OpenClaw 安装成功

步骤 3/3: 配置 OpenClaw...
[✓] 配置已保存

========================================
         🎉 部署完成！
========================================
```

## ✅ 验证清单

### 安装验证
- [ ] Node.js 已安装且版本 ≥ v18
- [ ] OpenClaw 已安装（`openclaw --version` 有输出）
- [ ] 配置文件已生成（`~/.openclaw/openclaw.json` 存在）

### 配置验证
```powershell
# 查看配置
cat ~/.openclaw/openclaw.json

# 应该包含：
# - agents.defaults.model.primary: "aiclient-kiro/claude-sonnet-4-5"
# - models.providers.aiclient-kiro.baseUrl: "http://127.0.0.1:4000/v1"
# - models.providers.aiclient-kiro.apiKey: "hotyi"
```

### 连接验证
```powershell
# 运行测试脚本
.\test_connection.ps1

# 应该显示：
# [测试 1] ✓ Node.js
# [测试 2] ✓ OpenClaw
# [测试 3] ✓ AIClient-2-API 服务
# [测试 4] ✓ OpenClaw 配置
# [测试 5] ✓ Kiro 认证
# [测试 6] ✓ API 端点
```

### 功能验证
```powershell
# 1. 启动 AIClient-2-API
cd ..\..
node src/services/api-server.js

# 2. 在新终端启动 OpenClaw
openclaw

# 3. 发送测试消息
# 应该收到 AI 响应
```

## 🔍 关键改进点

### 1. Node.js 检测（已修复）
```powershell
# 之前的问题：
# - 即使已安装也会尝试重新安装
# - 要求 v22+，可能导致不必要的升级

# 现在的行为：
function Check-Node {
    if ($version -ge 18) {  # 降低到 v18+
        Write-Host "[✓] Node.js $nodeVersion 已安装 (符合要求 v18+)"
        return $true  # 跳过安装
    }
}
```

### 2. 智能升级（新增）
```powershell
# 版本过低时询问用户
if ($nodeVersion) {
    $upgrade = Read-Host "是否升级 Node.js? (y/n, 默认 n)"
    if ($upgrade -eq "y") {
        Install-Node -IsUpgrade $true
    } else {
        Write-Host "[!] 继续使用当前 Node.js 版本"
    }
}
```

### 3. 一键部署（优化）
```powershell
# 所有配置项都有默认值
$apiKey = Read-Host "AIClient-2-API Key (默认: hotyi)"
if (-not $apiKey) { $apiKey = "hotyi" }  # 直接按 Enter 使用默认值

# 模型选择使用菜单
Write-Host "1. claude-sonnet-4-5 (推荐，最佳性能)"
Write-Host "2. claude-sonnet-4"
Write-Host "3. claude-haiku-4-5 (更快速)"
$modelChoice = Read-Host "选择模型 (1-3, 默认 1)"
```

## 📝 测试建议

### 测试场景 1：Node.js 已安装（推荐先测试这个）
**环境：** 你的机器（Node.js 已安装用于 AIClient-2-API）

**预期：**
- ✓ 检测到 Node.js，显示版本
- ✓ 跳过 Node.js 安装
- ✓ 直接安装 OpenClaw
- ✓ 生成配置文件
- ✓ 显示完成提示

### 测试场景 2：使用默认配置
**操作：** 所有配置项直接按 Enter

**预期：**
- ✓ API Key: hotyi
- ✓ Base URL: http://127.0.0.1:4000/v1
- ✓ Model: claude-sonnet-4-5
- ✓ 配置文件正确生成

### 测试场景 3：连接测试
**操作：** 运行 `.\test_connection.ps1`

**预期：**
- ✓ 所有测试项通过
- ✓ 显示详细的诊断信息

## 🐛 已知问题

### 无已知问题

所有已知问题已在 v1.1.0 中修复：
- ✅ Node.js 重复安装问题
- ✅ 版本要求过高问题
- ✅ 配置输入繁琐问题
- ✅ JSON 序列化问题

## 📞 如果遇到问题

### 问题 1：Node.js 检测失败
```powershell
# 手动检查
node --version

# 如果显示版本，但脚本检测失败，尝试刷新环境变量
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

### 问题 2：OpenClaw 安装失败
```powershell
# 手动安装
npm install -g openclaw@latest

# 检查安装
openclaw --version
```

### 问题 3：配置文件格式错误
```powershell
# 查看配置
cat ~/.openclaw/openclaw.json

# 如果格式错误，删除后重新生成
rm ~/.openclaw/openclaw.json
.\deploy_openclaw_with_aiclient.ps1
# 选择 "3. 仅配置 AIClient-2-API 连接"
```

## 🎉 准备就绪

脚本已经优化完成，满足你的所有要求：

1. ✅ **不会重复安装 Node.js** - 已安装且版本符合要求时跳过
2. ✅ **一键完成部署** - 选择"完整安装"后自动完成所有步骤
3. ✅ **智能默认配置** - 所有配置项都有默认值，直接按 Enter 即可
4. ✅ **友好的用户界面** - 清晰的进度提示和完成信息

**现在可以开始测试了！** 🚀

---

**版本：** v1.1.0  
**更新日期：** 2025-01-30  
**状态：** ✅ 已优化，准备测试  
**测试人员：** hotyi
