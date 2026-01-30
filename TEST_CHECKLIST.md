# 部署脚本测试清单

## 测试前准备

- [ ] 确保 AIClient-2-API 已安装
- [ ] 确保 Kiro IDE 已登录（token 文件存在）
- [ ] 备份现有配置（如果有）

## 测试场景

### ✅ 场景 1：Node.js 已安装（v18+）

**环境：** Node.js v18+ 已安装

**步骤：**
1. 运行脚本：`.\deploy_openclaw_with_aiclient.ps1`
2. 选择 "1. 完整安装"
3. 观察 Node.js 检测结果

**预期结果：**
- ✓ 显示 "[✓] Node.js vX.X.X 已安装 (符合要求 v18+)"
- ✓ 跳过 Node.js 安装步骤
- ✓ 直接进入 OpenClaw 安装

**实际结果：**
- [ ] 通过
- [ ] 失败（说明原因）：_______________

---

### ✅ 场景 2：Node.js 版本过低（< v18）

**环境：** Node.js < v18 已安装

**步骤：**
1. 运行脚本：`.\deploy_openclaw_with_aiclient.ps1`
2. 选择 "1. 完整安装"
3. 当询问是否升级时，选择 "n"

**预期结果：**
- ✓ 显示 "[!] Node.js vX.X.X 版本过低，需要 v18+"
- ✓ 询问 "是否升级 Node.js? (y/n, 默认 n)"
- ✓ 选择 "n" 后继续使用当前版本
- ✓ 显示 "[!] 继续使用当前 Node.js 版本"

**实际结果：**
- [ ] 通过
- [ ] 失败（说明原因）：_______________

---

### ✅ 场景 3：全新安装

**环境：** Node.js 未安装，OpenClaw 未安装

**步骤：**
1. 运行脚本：`.\deploy_openclaw_with_aiclient.ps1`
2. 选择 "1. 完整安装"
3. 所有配置项按 Enter 使用默认值

**预期结果：**
- ✓ 自动安装 Node.js
- ✓ 自动安装 OpenClaw
- ✓ 生成配置文件到 `~/.openclaw/openclaw.json`
- ✓ 显示完成提示和下一步操作

**实际结果：**
- [ ] 通过
- [ ] 失败（说明原因）：_______________

---

### ✅ 场景 4：配置已存在

**环境：** OpenClaw 已安装，配置文件已存在

**步骤：**
1. 备份现有配置：`copy ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.test-backup`
2. 运行脚本：`.\deploy_openclaw_with_aiclient.ps1`
3. 选择 "3. 仅配置 AIClient-2-API 连接"
4. 使用默认配置

**预期结果：**
- ✓ 显示 "[*] 检测到现有配置，将合并设置..."
- ✓ 显示 "[✓] 成功读取现有配置"
- ✓ 配置文件包含新的 aiclient-kiro provider
- ✓ 原有配置保持不变

**实际结果：**
- [ ] 通过
- [ ] 失败（说明原因）：_______________

---

### ✅ 场景 5：模型选择

**环境：** 正常环境

**步骤：**
1. 运行脚本：`.\deploy_openclaw_with_aiclient.ps1`
2. 选择 "3. 仅配置 AIClient-2-API 连接"
3. 在模型选择时选择 "2" (claude-sonnet-4)

**预期结果：**
- ✓ 显示模型选择菜单
- ✓ 配置文件中 model.primary 为 "aiclient-kiro/claude-sonnet-4"
- ✓ 显示正确的模型别名

**实际结果：**
- [ ] 通过
- [ ] 失败（说明原因）：_______________

---

### ✅ 场景 6：检查安装状态

**环境：** 完成安装后

**步骤：**
1. 运行脚本：`.\deploy_openclaw_with_aiclient.ps1`
2. 选择 "4. 检查安装状态"

**预期结果：**
- ✓ 显示 Node.js 版本
- ✓ 显示 OpenClaw 安装状态
- ✓ 显示 AIClient-2-API 服务状态
- ✓ 显示配置文件状态
- ✓ 显示 Kiro 认证状态

**实际结果：**
- [ ] 通过
- [ ] 失败（说明原因）：_______________

---

### ✅ 场景 7：连接测试

**环境：** 完成安装后，AIClient-2-API 正在运行

**步骤：**
1. 启动 AIClient-2-API：`cd ..\.. && node src/services/api-server.js`
2. 在新终端运行：`.\test_connection.ps1`

**预期结果：**
- ✓ 所有测试项显示 "✓"
- ✓ 显示 "✓ 所有测试通过！"
- ✓ 提供启动命令

**实际结果：**
- [ ] 通过
- [ ] 失败（说明原因）：_______________

---

### ✅ 场景 8：实际使用测试

**环境：** 完成安装和配置

**步骤：**
1. 启动 AIClient-2-API
2. 启动 OpenClaw：`openclaw`
3. 在 OpenClaw 中发送测试消息

**预期结果：**
- ✓ OpenClaw 成功启动
- ✓ 能够连接到 AIClient-2-API
- ✓ 收到 AI 响应
- ✓ 响应内容正常

**实际结果：**
- [ ] 通过
- [ ] 失败（说明原因）：_______________

---

## 配置验证

### 检查配置文件内容

```powershell
# 查看配置文件
cat ~/.openclaw/openclaw.json | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

**必须包含的内容：**
- [ ] `agents.defaults.model.primary` = "aiclient-kiro/claude-sonnet-4-5"
- [ ] `models.providers.aiclient-kiro.baseUrl` = "http://127.0.0.1:4000/v1"
- [ ] `models.providers.aiclient-kiro.apiKey` = "hotyi"
- [ ] `models.providers.aiclient-kiro.api` = "openai-completions"
- [ ] `models.providers.aiclient-kiro.models` 数组包含模型定义

---

## 错误处理测试

### ✅ 场景 9：AIClient-2-API 未运行

**步骤：**
1. 确保 AIClient-2-API 未运行
2. 运行测试脚本：`.\test_connection.ps1`

**预期结果：**
- ✓ 显示 "✗ AIClient-2-API 未运行"
- ✓ 提供启动命令提示

**实际结果：**
- [ ] 通过
- [ ] 失败（说明原因）：_______________

---

### ✅ 场景 10：Kiro Token 不存在

**步骤：**
1. 临时重命名 Kiro token 文件
2. 运行测试脚本：`.\test_connection.ps1`

**预期结果：**
- ✓ 显示 "✗ Kiro token 文件不存在"
- ✓ 提示 "请启动 Kiro IDE 并登录"

**实际结果：**
- [ ] 通过
- [ ] 失败（说明原因）：_______________

---

## 性能测试

### 脚本执行时间

- [ ] 完整安装（Node.js 已安装）：< 2 分钟
- [ ] 仅配置：< 30 秒
- [ ] 检查状态：< 10 秒

---

## 兼容性测试

### Windows 版本
- [ ] Windows 10
- [ ] Windows 11

### PowerShell 版本
- [ ] PowerShell 5.1
- [ ] PowerShell 7+

### Node.js 版本
- [ ] v18.x
- [ ] v20.x
- [ ] v22.x

---

## 清理测试

### ✅ 场景 11：清理配置

**步骤：**
1. 运行脚本：`.\deploy_openclaw_with_aiclient.ps1`
2. 选择 "5. 清理配置"
3. 确认清理

**预期结果：**
- ✓ 创建配置备份
- ✓ 删除配置文件
- ✓ 显示备份路径

**实际结果：**
- [ ] 通过
- [ ] 失败（说明原因）：_______________

---

## 测试总结

**测试日期：** _______________  
**测试人员：** _______________  
**环境信息：**
- Windows 版本：_______________
- PowerShell 版本：_______________
- Node.js 版本：_______________

**总体结果：**
- [ ] 所有测试通过 ✅
- [ ] 部分测试失败 ⚠️
- [ ] 需要修复 ❌

**备注：**
_______________________________________________
_______________________________________________
_______________________________________________

---

## 快速测试命令

```powershell
# 1. 完整安装测试
.\deploy_openclaw_with_aiclient.ps1
# 选择 1，使用默认配置

# 2. 连接测试
.\test_connection.ps1

# 3. 查看配置
cat ~/.openclaw/openclaw.json

# 4. 启动 AIClient-2-API
cd ..\..
node src/services/api-server.js

# 5. 启动 OpenClaw（新终端）
openclaw
```

---

**版本：** v1.1.0  
**更新日期：** 2025-01-30
