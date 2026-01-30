# 快速测试指南 v1.2.0

## 🎯 新功能测试

### 测试 1：自动配置检测

```powershell
# 1. 运行脚本
.\deploy_openclaw_with_aiclient.ps1

# 2. 选择 "3. 仅配置 AIClient-2-API 连接"

# 3. 输入盘符
盘符 (默认: F): F

# 预期输出：
[*] 自动检测配置...
[✓] 找到 AIClient-2-API 配置: F:\hotyi-dev\AIClient-2-API\configs\config.json
  └─ API Key: hotyi
  └─ Server Port: 4000

自动检测结果：
  API Key: hotyi
  Base URL: http://127.0.0.1:4000/v1
  hotyi-dev 路径: F:\hotyi-dev

# 4. 所有配置项按 Enter（使用自动检测的值）
AIClient-2-API Key (自动检测: hotyi): [Enter]
AIClient-2-API 地址 (自动检测: http://127.0.0.1:4000/v1): [Enter]
选择模型 (1-3, 默认 1): [Enter]

# 5. 验证配置文件
cat ~/.openclaw/openclaw.json

# 应该包含：
# - baseUrl: "http://127.0.0.1:4000/v1"
# - apiKey: "hotyi"
```

**✅ 通过条件：**
- 自动检测到 API Key 和端口
- 配置文件正确生成
- baseUrl 和 apiKey 与 AIClient-2-API 配置一致

---

### 测试 2：卸载功能

```powershell
# 1. 确保 OpenClaw 已安装
openclaw --version

# 2. 运行脚本
.\deploy_openclaw_with_aiclient.ps1

# 3. 选择 "5. 卸载 OpenClaw"

# 4. 确认卸载
确认卸载? (y/n): y

# 预期输出：
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

# 5. 验证卸载结果
openclaw --version  # 应该提示命令不存在
node --version      # 应该正常显示版本
claude --version    # 应该正常显示版本（如果已安装）

# 6. 检查备份
ls ~/.openclaw-backup-*  # 应该存在备份目录
```

**✅ 通过条件：**
- OpenClaw 被完全卸载
- 配置被备份
- Node.js 仍然可用
- AIClient-2-API 未受影响
- Claude Code 未受影响（如果已安装）

---

### 测试 3：完整流程（安装 → 卸载 → 重新安装）

```powershell
# 第一步：完整安装
.\deploy_openclaw_with_aiclient.ps1
# 选择 "1. 完整安装"
# 输入盘符: F
# 所有配置按 Enter

# 验证安装
openclaw --version
cat ~/.openclaw/openclaw.json

# 第二步：卸载
.\deploy_openclaw_with_aiclient.ps1
# 选择 "5. 卸载 OpenClaw"
# 确认: y

# 验证卸载
openclaw --version  # 应该失败
ls ~/.openclaw-backup-*  # 应该有备份

# 第三步：重新安装
.\deploy_openclaw_with_aiclient.ps1
# 选择 "1. 完整安装"
# 输入盘符: F
# 所有配置按 Enter

# 验证重新安装
openclaw --version
cat ~/.openclaw/openclaw.json
```

**✅ 通过条件：**
- 三个步骤都成功完成
- 配置在重新安装后正确生成
- Node.js 始终可用

---

## 🔍 详细验证

### 验证自动配置检测

```powershell
# 1. 检查 AIClient-2-API 配置
cat F:\hotyi-dev\AIClient-2-API\configs\config.json

# 记录以下值：
# - REQUIRED_API_KEY: ___________
# - SERVER_PORT: ___________

# 2. 运行脚本并配置
.\deploy_openclaw_with_aiclient.ps1
# 选择 "3. 仅配置"
# 输入盘符: F

# 3. 检查自动检测结果
# API Key 应该与 REQUIRED_API_KEY 一致
# Base URL 应该包含 SERVER_PORT

# 4. 检查生成的配置
cat ~/.openclaw/openclaw.json

# 验证：
# - models.providers.aiclient-kiro.apiKey 与 REQUIRED_API_KEY 一致
# - models.providers.aiclient-kiro.baseUrl 包含正确的端口
```

### 验证卸载安全性

```powershell
# 卸载前记录
$nodeBefore = node --version
$npmBefore = npm --version

# 执行卸载
.\deploy_openclaw_with_aiclient.ps1
# 选择 "5. 卸载"

# 卸载后验证
$nodeAfter = node --version
$npmAfter = npm --version

# 对比
Write-Host "Node.js 版本: $nodeBefore -> $nodeAfter"
Write-Host "npm 版本: $npmBefore -> $npmAfter"

# 应该完全一致
```

---

## 📋 测试清单

### 功能测试
- [ ] 自动配置检测（F 盘）
- [ ] 自动配置检测（其他盘符）
- [ ] 卸载 OpenClaw
- [ ] 卸载后 Node.js 可用
- [ ] 卸载后 AIClient-2-API 可用
- [ ] 配置备份功能
- [ ] 重新安装功能

### 边界测试
- [ ] AIClient-2-API 配置不存在
- [ ] Claude Code 配置不存在
- [ ] 输入错误的盘符
- [ ] OpenClaw 未安装时卸载
- [ ] 配置文件损坏时处理

### 兼容性测试
- [ ] 与 v1.1.0 配置兼容
- [ ] 与手动配置兼容
- [ ] 多次安装/卸载循环

---

## 🐛 常见问题

### Q1: 自动检测失败？

**症状：** 显示 "[!] 未找到 AIClient-2-API 配置"

**检查：**
```powershell
# 1. 确认盘符正确
ls F:\hotyi-dev\AIClient-2-API

# 2. 确认配置文件存在
ls F:\hotyi-dev\AIClient-2-API\configs\config.json

# 3. 确认配置文件格式
cat F:\hotyi-dev\AIClient-2-API\configs\config.json | ConvertFrom-Json
```

**解决：**
- 输入正确的盘符
- 或手动输入配置值

### Q2: 卸载后 OpenClaw 命令仍存在？

**症状：** 卸载后 `openclaw --version` 仍有输出

**原因：** 环境变量缓存

**解决：**
```powershell
# 刷新环境变量
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 或重启 PowerShell
```

### Q3: 配置备份在哪里？

**位置：**
```powershell
# 卸载时的备份
ls ~/.openclaw-backup-*

# 配置修改时的备份
ls ~/.openclaw/openclaw.json.backup.*
```

---

## 🎉 测试完成

完成所有测试后，请填写：

**测试日期：** _______________  
**测试人员：** _______________  
**测试环境：**
- Windows 版本：_______________
- PowerShell 版本：_______________
- Node.js 版本：_______________
- hotyi-dev 盘符：_______________

**测试结果：**
- [ ] 所有功能测试通过 ✅
- [ ] 部分测试失败 ⚠️（说明）：_______________
- [ ] 需要修复 ❌（说明）：_______________

**备注：**
_______________________________________________
_______________________________________________

---

**版本：** v1.2.0  
**更新日期：** 2025-01-30  
**测试重点：** 自动配置检测 + 卸载功能
