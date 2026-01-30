# OpenClaw + AIClient-2-API 自动部署脚本
# 作者: hotyi
# 日期: 2025-01-30
# 功能: 自动安装 OpenClaw 并配置使用 AIClient-2-API 的 Kiro API
# 运行: .\deploy_openclaw_with_aiclient.ps1

# 设置控制台编码为 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "Stop"

# 刷新环境变量的函数
function Refresh-Environment {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Host "环境变量已刷新" -ForegroundColor Green
}

# 显示标题
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   OpenClaw + AIClient-2-API 部署工具   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "功能说明：" -ForegroundColor Yellow
Write-Host "- 自动检测并安装 Node.js (v22+)"
Write-Host "- 自动安装 OpenClaw"
Write-Host "- 自动配置 OpenClaw 使用 AIClient-2-API"
Write-Host "- 支持 Kiro API (Claude Sonnet 4.5)"
Write-Host ""

# 自动检测配置函数
function Get-AutoConfig {
    Write-Host ""
    Write-Host "[*] 自动检测配置..." -ForegroundColor Yellow
    
    $autoConfig = @{
        apiKey = $null
        baseUrl = $null
        serverPort = $null
        hotyiDevPath = $null
    }
    
    # 1. 询问 hotyi-dev 安装盘符
    Write-Host ""
    Write-Host "请输入 hotyi-dev 的安装盘符（如: F, C, D）" -ForegroundColor Cyan
    $driveLetter = Read-Host "盘符 (默认: F)"
    if (-not $driveLetter) { $driveLetter = "F" }
    
    $hotyiDevPath = "${driveLetter}:\hotyi-dev"
    
    # 2. 检查 AIClient-2-API 配置
    $aiclientConfigPath = "$hotyiDevPath\AIClient-2-API\configs\config.json"
    if (Test-Path $aiclientConfigPath) {
        Write-Host "[✓] 找到 AIClient-2-API 配置: $aiclientConfigPath" -ForegroundColor Green
        try {
            $aiclientConfig = Get-Content $aiclientConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $autoConfig.apiKey = $aiclientConfig.REQUIRED_API_KEY
            $autoConfig.serverPort = $aiclientConfig.SERVER_PORT
            $autoConfig.hotyiDevPath = $hotyiDevPath
            
            Write-Host "  └─ API Key: $($autoConfig.apiKey)" -ForegroundColor Gray
            Write-Host "  └─ Server Port: $($autoConfig.serverPort)" -ForegroundColor Gray
        } catch {
            Write-Host "[!] 配置文件解析失败，将使用默认值" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[!] 未找到 AIClient-2-API 配置，将使用默认值" -ForegroundColor Yellow
        Write-Host "    路径: $aiclientConfigPath" -ForegroundColor Gray
    }
    
    # 3. 检查 Claude Code 配置
    $claudeConfigPath = "$env:USERPROFILE\.claude\settings.json"
    if (Test-Path $claudeConfigPath) {
        Write-Host "[✓] 找到 Claude Code 配置: $claudeConfigPath" -ForegroundColor Green
        try {
            $claudeConfig = Get-Content $claudeConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($claudeConfig.api.baseUrl) {
                # 从 baseUrl 提取端口号（如果 AIClient-2-API 配置中没有）
                if (-not $autoConfig.serverPort -and $claudeConfig.api.baseUrl -match ':(\d+)') {
                    $autoConfig.serverPort = $matches[1]
                    Write-Host "  └─ 从 Claude 配置提取端口: $($autoConfig.serverPort)" -ForegroundColor Gray
                }
            }
        } catch {
            Write-Host "[!] Claude 配置解析失败" -ForegroundColor Yellow
        }
    }
    
    # 4. 构建 baseUrl
    if ($autoConfig.serverPort) {
        $autoConfig.baseUrl = "http://127.0.0.1:$($autoConfig.serverPort)/v1"
    } else {
        $autoConfig.baseUrl = "http://127.0.0.1:4000/v1"
    }
    
    # 5. 设置默认值
    if (-not $autoConfig.apiKey) {
        $autoConfig.apiKey = "hotyi"
    }
    
    Write-Host ""
    Write-Host "自动检测结果：" -ForegroundColor Cyan
    Write-Host "  API Key: $($autoConfig.apiKey)" -ForegroundColor White
    Write-Host "  Base URL: $($autoConfig.baseUrl)" -ForegroundColor White
    Write-Host "  hotyi-dev 路径: $($autoConfig.hotyiDevPath)" -ForegroundColor White
    Write-Host ""
    
    return $autoConfig
}

# 卸载 OpenClaw 函数
function Uninstall-OpenClaw {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "         OpenClaw 卸载程序             " -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "警告: 此操作将卸载 OpenClaw 及其配置" -ForegroundColor Yellow
    Write-Host "不会影响: Node.js, AIClient-2-API, Claude Code" -ForegroundColor Green
    Write-Host ""
    
    $confirm = Read-Host "确认卸载? (y/n)"
    if ($confirm -ne "y") {
        Write-Host "取消卸载" -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "[*] 开始卸载 OpenClaw..." -ForegroundColor Yellow
    
    # 1. 卸载 OpenClaw npm 包
    Write-Host ""
    Write-Host "[1/4] 卸载 OpenClaw npm 包..." -ForegroundColor Cyan
    if (Get-Command openclaw -ErrorAction SilentlyContinue) {
        try {
            Write-Host "  正在卸载，请稍候（可能需要 10-30 秒）..." -ForegroundColor Gray
            
            # 显示进度的方式卸载
            $uninstallJob = Start-Job -ScriptBlock {
                npm uninstall -g openclaw 2>&1
            }
            
            # 等待任务完成，同时显示进度
            $dots = 0
            while ($uninstallJob.State -eq 'Running') {
                Start-Sleep -Milliseconds 500
                $dots = ($dots + 1) % 4
                Write-Host "`r  卸载中$('.' * $dots)$(' ' * (3 - $dots))   " -NoNewline -ForegroundColor Gray
            }
            
            $result = Receive-Job -Job $uninstallJob
            Remove-Job -Job $uninstallJob
            
            Write-Host "`r  " -NoNewline
            Write-Host "[✓] OpenClaw npm 包已卸载" -ForegroundColor Green
        } catch {
            Write-Host "[!] 卸载失败: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[✓] OpenClaw 未安装，跳过" -ForegroundColor Green
    }
    
    # 2. 备份并删除配置目录
    Write-Host ""
    Write-Host "[2/4] 处理配置目录..." -ForegroundColor Cyan
    $openclawConfigDir = "$env:USERPROFILE\.openclaw"
    if (Test-Path $openclawConfigDir) {
        # 创建备份
        $backupDir = "$env:USERPROFILE\.openclaw-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        try {
            Copy-Item -Path $openclawConfigDir -Destination $backupDir -Recurse -Force
            Write-Host "[✓] 配置已备份到: $backupDir" -ForegroundColor Green
        } catch {
            Write-Host "[!] 备份失败: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # 删除配置目录
        try {
            Remove-Item -Path $openclawConfigDir -Recurse -Force
            Write-Host "[✓] 配置目录已删除" -ForegroundColor Green
        } catch {
            Write-Host "[!] 删除失败: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[✓] 配置目录不存在，跳过" -ForegroundColor Green
    }
    
    # 3. 清理 npm 缓存中的 OpenClaw
    Write-Host ""
    Write-Host "[3/4] 清理 npm 缓存..." -ForegroundColor Cyan
    try {
        npm cache clean --force 2>$null
        Write-Host "[✓] npm 缓存已清理" -ForegroundColor Green
    } catch {
        Write-Host "[!] 清理失败: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # 4. 验证卸载
    Write-Host ""
    Write-Host "[4/4] 验证卸载..." -ForegroundColor Cyan
    if (Get-Command openclaw -ErrorAction SilentlyContinue) {
        Write-Host "[!] OpenClaw 命令仍然存在，可能需要重启终端" -ForegroundColor Yellow
    } else {
        Write-Host "[✓] OpenClaw 已完全卸载" -ForegroundColor Green
    }
    
    # 验证其他软件未受影响
    Write-Host ""
    Write-Host "验证其他软件状态：" -ForegroundColor Cyan
    
    # 检查 Node.js
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $nodeVersion = node --version
        Write-Host "[✓] Node.js: $nodeVersion (未受影响)" -ForegroundColor Green
    } else {
        Write-Host "[!] Node.js: 未检测到" -ForegroundColor Yellow
    }
    
    # 检查 Claude Code
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Write-Host "[✓] Claude Code: 已安装 (未受影响)" -ForegroundColor Green
    } else {
        Write-Host "[!] Claude Code: 未检测到" -ForegroundColor Yellow
    }
    
    # 检查 AIClient-2-API
    $autoConfig = Get-AutoConfig
    if ($autoConfig.hotyiDevPath -and (Test-Path "$($autoConfig.hotyiDevPath)\AIClient-2-API")) {
        Write-Host "[✓] AIClient-2-API: 已安装 (未受影响)" -ForegroundColor Green
    } else {
        Write-Host "[!] AIClient-2-API: 未检测到" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "         卸载完成！                     " -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "已卸载：" -ForegroundColor Cyan
    Write-Host "  ✓ OpenClaw npm 包" -ForegroundColor White
    Write-Host "  ✓ OpenClaw 配置目录" -ForegroundColor White
    Write-Host ""
    Write-Host "已保留：" -ForegroundColor Cyan
    Write-Host "  ✓ Node.js" -ForegroundColor White
    Write-Host "  ✓ AIClient-2-API" -ForegroundColor White
    Write-Host "  ✓ Claude Code" -ForegroundColor White
    Write-Host ""
    if (Test-Path $backupDir) {
        Write-Host "配置备份位置: $backupDir" -ForegroundColor Gray
    }
    Write-Host ""
}

# 主菜单
while ($true) {
    Write-Host "请选择操作：" -ForegroundColor Cyan
    Write-Host "1. 完整安装 (推荐) - 安装 OpenClaw 并配置 AIClient-2-API"
    Write-Host "2. 仅安装 OpenClaw"
    Write-Host "3. 仅配置 AIClient-2-API 连接"
    Write-Host "4. 检查安装状态"
    Write-Host "5. 卸载 OpenClaw"
    Write-Host "6. 清理配置"
    Write-Host "7. 退出"
    $mainChoice = Read-Host "请输入选项 (1-7, 默认 1)"

    if (-not $mainChoice) { $mainChoice = "1" }

    switch ($mainChoice) {
        "1" {
            Write-Host "开始完整安装..." -ForegroundColor Green
            $shouldInstall = $true
            break
        }
        "2" {
            Write-Host "仅安装 OpenClaw..." -ForegroundColor Green
            $installOnly = $true
            $shouldInstall = $true
            break
        }
        "3" {
            Write-Host "仅配置 AIClient-2-API 连接..." -ForegroundColor Green
            $configOnly = $true
            $shouldInstall = $true
            break
        }
        "4" {
            # 检查安装状态
            Write-Host ""
            Write-Host "===== 安装状态检查 =====" -ForegroundColor Cyan
            
            # 检查 Node.js
            if (Get-Command node -ErrorAction SilentlyContinue) {
                $nodeVersion = node --version
                Write-Host "✓ Node.js: $nodeVersion" -ForegroundColor Green
            } else {
                Write-Host "✗ Node.js: 未安装" -ForegroundColor Red
            }
            
            # 检查 OpenClaw
            if (Get-Command openclaw -ErrorAction SilentlyContinue) {
                try {
                    $openclawVersion = openclaw --version 2>$null
                    Write-Host "✓ OpenClaw: $openclawVersion" -ForegroundColor Green
                } catch {
                    Write-Host "✓ OpenClaw: 已安装 (版本未知)" -ForegroundColor Green
                }
            } else {
                Write-Host "✗ OpenClaw: 未安装" -ForegroundColor Red
            }
            
            # 检查配置文件
            $configPath = "$env:USERPROFILE\.openclaw\openclaw.json"
            if (Test-Path $configPath) {
                Write-Host "✓ OpenClaw 配置: $configPath" -ForegroundColor Green
                try {
                    $config = Get-Content $configPath -Raw | ConvertFrom-Json
                    if ($config.models.providers."aiclient-kiro") {
                        Write-Host "  └─ AIClient-2-API 配置: 已配置" -ForegroundColor Green
                    } else {
                        Write-Host "  └─ AIClient-2-API 配置: 未配置" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "  └─ 配置文件解析失败" -ForegroundColor Red
                }
            } else {
                Write-Host "✗ OpenClaw 配置: 未找到" -ForegroundColor Yellow
            }
            
            # 检查 AIClient-2-API
            Write-Host ""
            Write-Host "AIClient-2-API 服务状态:" -ForegroundColor Cyan
            try {
                $response = Invoke-WebRequest -Uri "http://127.0.0.1:4000" -Method GET -TimeoutSec 2 -ErrorAction Stop
                Write-Host "✓ AIClient-2-API: 运行中 (http://127.0.0.1:4000)" -ForegroundColor Green
            } catch {
                Write-Host "✗ AIClient-2-API: 未运行" -ForegroundColor Yellow
                Write-Host "  提示: 请先启动 AIClient-2-API 服务" -ForegroundColor Gray
            }
            
            Write-Host ""
            Write-Host "按任意键返回主菜单..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "5" {
            # 卸载 OpenClaw
            Uninstall-OpenClaw
            Write-Host ""
            Write-Host "按任意键返回主菜单..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "6" {
            # 清理配置
            Write-Host ""
            Write-Host "===== 清理配置 =====" -ForegroundColor Red
            $confirm = Read-Host "警告: 这将删除 OpenClaw 配置文件，是否继续? (y/n)"
            if ($confirm -eq "y") {
                $configPath = "$env:USERPROFILE\.openclaw\openclaw.json"
                if (Test-Path $configPath) {
                    # 备份配置
                    $backupPath = "$configPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                    Copy-Item $configPath $backupPath
                    Write-Host "已备份配置到: $backupPath" -ForegroundColor Yellow
                    
                    Remove-Item $configPath -Force
                    Write-Host "配置文件已删除" -ForegroundColor Green
                } else {
                    Write-Host "配置文件不存在" -ForegroundColor Yellow
                }
            }
            Write-Host ""
            Write-Host "按任意键返回主菜单..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "7" {
            Write-Host "退出脚本..." -ForegroundColor Green
            Exit
        }
        default {
            Write-Host "无效选项，请重新选择。" -ForegroundColor Red
        }
    }
    
    # 只有选择了安装选项才跳出循环
    if ($shouldInstall) {
        break
    }
}

# 检查 Node.js
function Check-Node {
    try {
        $nodeVersion = (node -v 2>$null)
        if ($nodeVersion) {
            $version = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
            if ($version -ge 18) {
                Write-Host "[✓] Node.js $nodeVersion 已安装 (符合要求 v18+)" -ForegroundColor Green
                return $true
            } else {
                Write-Host "[!] Node.js $nodeVersion 版本过低，需要 v18+" -ForegroundColor Yellow
                Write-Host "    OpenClaw 推荐 v22+，但 v18+ 也可以工作" -ForegroundColor Gray
                return $false
            }
        }
    } catch {
        Write-Host "[!] Node.js 未安装" -ForegroundColor Yellow
        return $false
    }
    return $false
}

# 安装或升级 Node.js
function Install-Node {
    param(
        [bool]$IsUpgrade = $false
    )
    
    if ($IsUpgrade) {
        Write-Host "[*] 升级 Node.js 到最新 LTS 版本..." -ForegroundColor Yellow
        Write-Host "    注意: 这可能会影响其他依赖 Node.js 的应用" -ForegroundColor Gray
        $confirm = Read-Host "是否继续升级? (y/n, 默认 n)"
        if ($confirm -ne "y") {
            Write-Host "[!] 跳过 Node.js 升级，使用现有版本" -ForegroundColor Yellow
            return
        }
    } else {
        Write-Host "[*] 安装 Node.js..." -ForegroundColor Yellow
    }

    # 尝试使用 winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "  使用 winget 安装..." -ForegroundColor Gray
        if ($IsUpgrade) {
            winget upgrade OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
        } else {
            winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements --scope user
        }
        
        if ($LASTEXITCODE -eq 0) {
            Refresh-Environment
            Write-Host "[✓] Node.js 安装/升级成功" -ForegroundColor Green
            return
        }
    }

    # 尝试使用 Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "  使用 Chocolatey 安装..." -ForegroundColor Gray
        if ($IsUpgrade) {
            choco upgrade nodejs-lts -y
        } else {
            choco install nodejs-lts -y
        }
        Refresh-Environment
        Write-Host "[✓] Node.js 安装/升级成功" -ForegroundColor Green
        return
    }

    # 手动下载
    Write-Host ""
    Write-Host "错误: 无法自动安装 Node.js" -ForegroundColor Red
    Write-Host "请手动安装 Node.js 18+:" -ForegroundColor Yellow
    Write-Host "  https://nodejs.org/en/download/" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

# 检查 OpenClaw
function Check-OpenClaw {
    try {
        $null = Get-Command openclaw -ErrorAction Stop
        Write-Host "[✓] OpenClaw 已安装" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[!] OpenClaw 未安装" -ForegroundColor Yellow
        return $false
    }
}

# 安装 OpenClaw
function Install-OpenClaw {
    Write-Host "[*] 安装 OpenClaw..." -ForegroundColor Yellow
    
    $prevLogLevel = $env:NPM_CONFIG_LOGLEVEL
    $prevUpdateNotifier = $env:NPM_CONFIG_UPDATE_NOTIFIER
    $prevFund = $env:NPM_CONFIG_FUND
    $prevAudit = $env:NPM_CONFIG_AUDIT
    
    $env:NPM_CONFIG_LOGLEVEL = "error"
    $env:NPM_CONFIG_UPDATE_NOTIFIER = "false"
    $env:NPM_CONFIG_FUND = "false"
    $env:NPM_CONFIG_AUDIT = "false"
    
    try {
        npm install -g openclaw@latest
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[✗] OpenClaw 安装失败" -ForegroundColor Red
            exit 1
        }
        
        # 确保 OpenClaw 在 PATH 中
        $npmPrefix = (npm config get prefix 2>$null).Trim()
        if ($npmPrefix) {
            $npmBin = Join-Path $npmPrefix "bin"
            $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if (-not ($userPath -split ";" | Where-Object { $_ -ieq $npmBin })) {
                [Environment]::SetEnvironmentVariable("Path", "$userPath;$npmBin", "User")
                Refresh-Environment
                Write-Host "[!] 已将 npm bin 目录添加到 PATH" -ForegroundColor Yellow
            }
        }
        
        Write-Host "[✓] OpenClaw 安装成功" -ForegroundColor Green
    } finally {
        $env:NPM_CONFIG_LOGLEVEL = $prevLogLevel
        $env:NPM_CONFIG_UPDATE_NOTIFIER = $prevUpdateNotifier
        $env:NPM_CONFIG_FUND = $prevFund
        $env:NPM_CONFIG_AUDIT = $prevAudit
    }
}

# 配置 OpenClaw 使用 AIClient-2-API
function Configure-OpenClawWithAIClient {
    Write-Host ""
    Write-Host "[*] 配置 OpenClaw 使用 AIClient-2-API..." -ForegroundColor Yellow
    
    # 自动检测配置
    $autoConfig = Get-AutoConfig
    
    # 获取配置参数（提供自动检测的默认值）
    Write-Host ""
    Write-Host "配置参数（直接按 Enter 使用自动检测的值）：" -ForegroundColor Cyan
    
    $apiKey = Read-Host "AIClient-2-API Key (自动检测: $($autoConfig.apiKey))"
    if (-not $apiKey) { $apiKey = $autoConfig.apiKey }
    
    $baseUrl = Read-Host "AIClient-2-API 地址 (自动检测: $($autoConfig.baseUrl))"
    if (-not $baseUrl) { $baseUrl = $autoConfig.baseUrl }
    
    # 自动检测可用模型
    Write-Host ""
    Write-Host "可用模型（Kiro 支持）：" -ForegroundColor Cyan
    Write-Host "1. claude-sonnet-4-5 (推荐，最佳性能)"
    Write-Host "2. claude-sonnet-4"
    Write-Host "3. claude-haiku-4-5 (更快速)"
    $modelChoice = Read-Host "选择模型 (1-3, 默认 1)"
    
    $modelName = switch ($modelChoice) {
        "2" { "claude-sonnet-4" }
        "3" { "claude-haiku-4-5" }
        default { "claude-sonnet-4-5" }
    }
    
    Write-Host ""
    Write-Host "使用配置：" -ForegroundColor Yellow
    Write-Host "  API Key: $apiKey" -ForegroundColor Gray
    Write-Host "  Base URL: $baseUrl" -ForegroundColor Gray
    Write-Host "  Model: $modelName" -ForegroundColor Gray
    Write-Host ""
    
    # 创建配置目录
    $configDir = "$env:USERPROFILE\.openclaw"
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        Write-Host "[✓] 创建配置目录: $configDir" -ForegroundColor Green
    }
    
    $configPath = "$configDir\openclaw.json"
    
    # 读取现有配置或创建新配置
    $config = $null
    $isNewConfig = $false
    
    if (Test-Path $configPath) {
        Write-Host "[*] 检测到现有配置，将合并设置..." -ForegroundColor Yellow
        try {
            $configContent = Get-Content $configPath -Raw -Encoding UTF8
            $config = $configContent | ConvertFrom-Json
            Write-Host "[✓] 成功读取现有配置" -ForegroundColor Green
        } catch {
            Write-Host "[!] 现有配置解析失败，将创建新配置" -ForegroundColor Yellow
            # 备份损坏的配置
            $backupPath = "$configPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item $configPath $backupPath -ErrorAction SilentlyContinue
            Write-Host "[*] 已备份原配置到: $backupPath" -ForegroundColor Gray
            $config = $null
        }
    }
    
    if (-not $config) {
        $isNewConfig = $true
        Write-Host "[*] 创建新配置..." -ForegroundColor Yellow
        $config = [PSCustomObject]@{}
    }
    
    # 构建配置对象（使用 PowerShell 对象而不是哈希表，以便正确序列化）
    if (-not $config.agents) {
        $config | Add-Member -NotePropertyName "agents" -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    if (-not $config.agents.defaults) {
        $config.agents | Add-Member -NotePropertyName "defaults" -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    if (-not $config.agents.defaults.model) {
        $config.agents.defaults | Add-Member -NotePropertyName "model" -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    if (-not $config.agents.defaults.models) {
        $config.agents.defaults | Add-Member -NotePropertyName "models" -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    
    # 设置主模型
    $config.agents.defaults.model | Add-Member -NotePropertyName "primary" -NotePropertyValue "aiclient-kiro/$modelName" -Force
    
    # 添加模型别名
    $modelAlias = switch ($modelName) {
        "claude-sonnet-4-5" { "Claude Sonnet 4.5 (Kiro)" }
        "claude-sonnet-4" { "Claude Sonnet 4 (Kiro)" }
        "claude-haiku-4-5" { "Claude Haiku 4.5 (Kiro)" }
        default { "Claude (Kiro)" }
    }
    
    $config.agents.defaults.models | Add-Member -NotePropertyName "aiclient-kiro/$modelName" -NotePropertyValue ([PSCustomObject]@{
        alias = $modelAlias
    }) -Force
    
    # 配置 models.providers
    if (-not $config.models) {
        $config | Add-Member -NotePropertyName "models" -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    $config.models | Add-Member -NotePropertyName "mode" -NotePropertyValue "merge" -Force
    
    if (-not $config.models.providers) {
        $config.models | Add-Member -NotePropertyName "providers" -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    
    # 配置 aiclient-kiro provider
    $config.models.providers | Add-Member -NotePropertyName "aiclient-kiro" -NotePropertyValue ([PSCustomObject]@{
        baseUrl = $baseUrl
        apiKey = $apiKey
        api = "openai-completions"
        models = @(
            [PSCustomObject]@{
                id = $modelName
                name = $modelAlias
                reasoning = $false
                input = @("text", "image")
                cost = [PSCustomObject]@{
                    input = 0
                    output = 0
                    cacheRead = 0
                    cacheWrite = 0
                }
                contextWindow = 200000
                maxTokens = 8192
            }
        )
    }) -Force
    
    # 配置 gateway.mode 为 local（允许本地运行）
    if (-not $config.gateway) {
        $config | Add-Member -NotePropertyName "gateway" -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    $config.gateway | Add-Member -NotePropertyName "mode" -NotePropertyValue "local" -Force
    
    # 配置 gateway.auth.token（生成随机 token）
    if (-not $config.gateway.auth) {
        $config.gateway | Add-Member -NotePropertyName "auth" -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    # 生成一个随机 token（如果不存在）
    if (-not $config.gateway.auth.token) {
        $randomToken = [System.Guid]::NewGuid().ToString("N").Substring(0, 32)
        $config.gateway.auth | Add-Member -NotePropertyName "token" -NotePropertyValue $randomToken -Force
        Write-Host "[*] 生成 Gateway 认证 Token: $randomToken" -ForegroundColor Yellow
    }
    
    # 询问是否配置 Telegram Bot
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   Telegram Bot 配置（可选）            " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "如果你想让机器人在 Telegram 中工作，需要配置 Telegram Bot Token" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "获取 Telegram Bot Token 的步骤：" -ForegroundColor Cyan
    Write-Host "1. 在 Telegram 中搜索: @BotFather" -ForegroundColor White
    Write-Host "2. 发送命令: /newbot" -ForegroundColor White
    Write-Host "3. 按提示输入机器人名称（如: My OpenClaw Bot）" -ForegroundColor White
    Write-Host "4. 输入机器人用户名（必须以 bot 结尾，如: myopenclaw_bot）" -ForegroundColor White
    Write-Host "5. 复制 BotFather 给你的 Token（格式: 1234567890:ABC...）" -ForegroundColor White
    Write-Host ""
    Write-Host "设置隐私模式（重要）：" -ForegroundColor Cyan
    Write-Host "1. 在与 @BotFather 的对话中发送: /setprivacy" -ForegroundColor White
    Write-Host "2. 选择你的机器人" -ForegroundColor White
    Write-Host "3. 选择 'Disable' - 这样机器人才能接收所有消息" -ForegroundColor White
    Write-Host ""
    
    $configureTelegram = Read-Host "是否现在配置 Telegram Bot? (y/n, 默认 n)"
    
    if ($configureTelegram -eq "y") {
        Write-Host ""
        $telegramToken = Read-Host "请输入 Telegram Bot Token"
        
        if ($telegramToken) {
            # 添加 Telegram 配置到 channels
            if (-not $config.channels) {
                $config | Add-Member -NotePropertyName "channels" -NotePropertyValue ([PSCustomObject]@{}) -Force
            }
            $config.channels | Add-Member -NotePropertyName "telegram" -NotePropertyValue ([PSCustomObject]@{
                token = $telegramToken
                dmPolicy = "pairing"
                allowFrom = @()
            }) -Force
            
            Write-Host "[✓] Telegram Bot 配置已添加" -ForegroundColor Green
            Write-Host "    DM 策略: pairing (需要配对码批准)" -ForegroundColor Gray
            Write-Host "    批准命令: openclaw pairing approve telegram <配对码>" -ForegroundColor Gray
            $telegramConfigured = $true
        } else {
            Write-Host "[!] 未输入 Token，跳过 Telegram 配置" -ForegroundColor Yellow
            Write-Host "    稍后可运行 'openclaw configure' 配置" -ForegroundColor Gray
            $telegramConfigured = $false
        }
    } else {
        Write-Host "[*] 跳过 Telegram 配置" -ForegroundColor Yellow
        Write-Host "    稍后可运行 'openclaw onboard' 或 'openclaw configure' 配置" -ForegroundColor Gray
        $telegramConfigured = $false
    }
    
    # 保存配置
    Write-Host ""
    try {
        $jsonConfig = $config | ConvertTo-Json -Depth 100 -Compress:$false
        $jsonConfig | Set-Content $configPath -Encoding UTF8
        Write-Host "[✓] 配置已保存到: $configPath" -ForegroundColor Green
    } catch {
        Write-Host "[✗] 配置保存失败: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    
    # 显示配置摘要
    Write-Host ""
    Write-Host "===== 配置摘要 =====" -ForegroundColor Cyan
    Write-Host "Provider: aiclient-kiro" -ForegroundColor White
    Write-Host "Base URL: $baseUrl" -ForegroundColor White
    Write-Host "API Key: $apiKey" -ForegroundColor White
    Write-Host "Model: $modelName" -ForegroundColor White
    Write-Host "Alias: $modelAlias" -ForegroundColor White
    Write-Host "Gateway Mode: local" -ForegroundColor White
    Write-Host "Gateway Token: $($config.gateway.auth.token)" -ForegroundColor White
    if ($telegramConfigured) {
        Write-Host "Telegram: 已配置" -ForegroundColor Green
    } else {
        Write-Host "Telegram: 未配置" -ForegroundColor Yellow
    }
    Write-Host "Config: $configPath" -ForegroundColor White
    if ($autoConfig.hotyiDevPath) {
        Write-Host "hotyi-dev: $($autoConfig.hotyiDevPath)" -ForegroundColor White
    }
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host ""
}

# 连接测试函数
function Test-Connection {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "      开始连接测试                      " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $allPassed = $true
    
    # 测试 1: 检查 Node.js
    Write-Host "[测试 1/6] 检查 Node.js..." -ForegroundColor Yellow
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            $version = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
            if ($version -ge 18) {
                Write-Host "  ✓ Node.js $nodeVersion (符合要求)" -ForegroundColor Green
            } else {
                Write-Host "  ✗ Node.js $nodeVersion (需要 v18+)" -ForegroundColor Red
                $allPassed = $false
            }
        } else {
            Write-Host "  ✗ Node.js 未安装" -ForegroundColor Red
            $allPassed = $false
        }
    } catch {
        Write-Host "  ✗ Node.js 检查失败" -ForegroundColor Red
        $allPassed = $false
    }
    
    # 测试 2: 检查 OpenClaw
    Write-Host ""
    Write-Host "[测试 2/6] 检查 OpenClaw..." -ForegroundColor Yellow
    try {
        if (Get-Command openclaw -ErrorAction SilentlyContinue) {
            $openclawVersion = openclaw --version 2>$null
            if ($openclawVersion) {
                Write-Host "  ✓ OpenClaw $openclawVersion" -ForegroundColor Green
            } else {
                Write-Host "  ✓ OpenClaw 已安装" -ForegroundColor Green
            }
        } else {
            Write-Host "  ✗ OpenClaw 未安装" -ForegroundColor Red
            $allPassed = $false
        }
    } catch {
        Write-Host "  ✗ OpenClaw 检查失败" -ForegroundColor Red
        $allPassed = $false
    }
    
    # 测试 3: 检查 AIClient-2-API 服务
    Write-Host ""
    Write-Host "[测试 3/6] 检查 AIClient-2-API 服务..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:4000" -Method GET -TimeoutSec 3 -ErrorAction Stop
        Write-Host "  ✓ AIClient-2-API 运行中 (http://127.0.0.1:4000)" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ AIClient-2-API 未运行" -ForegroundColor Red
        Write-Host "    启动命令: cd ..\.. && node src/services/api-server.js" -ForegroundColor Gray
        $allPassed = $false
    }
    
    # 测试 4: 检查 OpenClaw 配置文件
    Write-Host ""
    Write-Host "[测试 4/6] 检查 OpenClaw 配置..." -ForegroundColor Yellow
    $configPath = "$env:USERPROFILE\.openclaw\openclaw.json"
    if (Test-Path $configPath) {
        Write-Host "  ✓ 配置文件存在: $configPath" -ForegroundColor Green
        
        try {
            $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
            
            # 检查 provider 配置
            if ($config.models.providers."aiclient-kiro") {
                Write-Host "  ✓ aiclient-kiro provider 已配置" -ForegroundColor Green
                
                $provider = $config.models.providers."aiclient-kiro"
                Write-Host "    - Base URL: $($provider.baseUrl)" -ForegroundColor Gray
                Write-Host "    - API Key: $($provider.apiKey)" -ForegroundColor Gray
                Write-Host "    - API Type: $($provider.api)" -ForegroundColor Gray
                
                # 检查模型配置
                if ($config.agents.defaults.model.primary) {
                    $primaryModel = $config.agents.defaults.model.primary
                    Write-Host "  ✓ 主模型: $primaryModel" -ForegroundColor Green
                    
                    # 验证模型名称
                    if ($primaryModel -match "opus") {
                        Write-Host "  ⚠ 警告: 检测到 Opus 模型，Kiro 不支持 Opus！" -ForegroundColor Yellow
                        Write-Host "    建议使用: aiclient-kiro/claude-sonnet-4-5" -ForegroundColor Gray
                    }
                } else {
                    Write-Host "  ✗ 未配置主模型" -ForegroundColor Red
                    $allPassed = $false
                }
            } else {
                Write-Host "  ✗ aiclient-kiro provider 未配置" -ForegroundColor Red
                $allPassed = $false
            }
        } catch {
            Write-Host "  ✗ 配置文件解析失败: $($_.Exception.Message)" -ForegroundColor Red
            $allPassed = $false
        }
    } else {
        Write-Host "  ✗ 配置文件不存在" -ForegroundColor Red
        $allPassed = $false
    }
    
    # 测试 5: 检查 Kiro 认证
    Write-Host ""
    Write-Host "[测试 5/6] 检查 Kiro 认证..." -ForegroundColor Yellow
    $kiroTokenPath = "$env:USERPROFILE\.aws\sso\cache\kiro-auth-token.json"
    if (Test-Path $kiroTokenPath) {
        Write-Host "  ✓ Kiro token 文件存在" -ForegroundColor Green
        
        try {
            $kiroToken = Get-Content $kiroTokenPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($kiroToken.accessToken) {
                Write-Host "  ✓ Access token 存在" -ForegroundColor Green
                
                # 检查 token 是否过期
                if ($kiroToken.expiresAt) {
                    $expiresAt = [DateTime]::Parse($kiroToken.expiresAt)
                    $now = [DateTime]::UtcNow
                    if ($expiresAt -gt $now) {
                        $timeLeft = $expiresAt - $now
                        Write-Host "  ✓ Token 有效 (剩余: $([int]$timeLeft.TotalHours) 小时)" -ForegroundColor Green
                    } else {
                        Write-Host "  ⚠ Token 已过期，需要重新登录 Kiro IDE" -ForegroundColor Yellow
                    }
                }
            } else {
                Write-Host "  ✗ Access token 缺失" -ForegroundColor Red
                $allPassed = $false
            }
        } catch {
            Write-Host "  ✗ Token 文件解析失败" -ForegroundColor Red
            $allPassed = $false
        }
    } else {
        Write-Host "  ✗ Kiro token 文件不存在" -ForegroundColor Red
        Write-Host "    请启动 Kiro IDE 并登录" -ForegroundColor Gray
        $allPassed = $false
    }
    
    # 测试 6: 测试 API 连接
    Write-Host ""
    Write-Host "[测试 6/6] 测试 API 端点..." -ForegroundColor Yellow
    try {
        $testUrl = "http://127.0.0.1:4000/v1/models"
        $headers = @{
            "Authorization" = "Bearer hotyi"
        }
        $response = Invoke-WebRequest -Uri $testUrl -Headers $headers -Method GET -TimeoutSec 3 -ErrorAction Stop
        Write-Host "  ✓ API 端点响应正常" -ForegroundColor Green
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Host "  ⚠ API 端点返回 404 (可能正常)" -ForegroundColor Yellow
        } else {
            Write-Host "  ⚠ API 端点测试失败: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # 总结
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    if ($allPassed) {
        Write-Host "         ✓ 所有测试通过！              " -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "你可以开始使用 OpenClaw 了！" -ForegroundColor Green
        Write-Host ""
        Write-Host "启动命令: openclaw" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "         ⚠ 部分测试失败                " -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "请根据上述提示修复问题" -ForegroundColor Yellow
        Write-Host ""
    }
}

# 主安装流程
function Main {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         开始部署流程                   " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    # 步骤 1: 检查并安装 Node.js
    if (-not $configOnly) {
        Write-Host ""
        Write-Host "步骤 1/3: 检查 Node.js..." -ForegroundColor Cyan
        $nodeOk = Check-Node
        
        if (-not $nodeOk) {
            $nodeVersion = (node -v 2>$null)
            if ($nodeVersion) {
                # Node.js 已安装但版本过低
                Write-Host ""
                Write-Host "检测到 Node.js $nodeVersion，但版本较低" -ForegroundColor Yellow
                Write-Host "OpenClaw 推荐 v22+，但 v18+ 也可以工作" -ForegroundColor Gray
                $upgrade = Read-Host "是否升级 Node.js? (y/n, 默认 n)"
                if ($upgrade -eq "y") {
                    Install-Node -IsUpgrade $true
                    
                    # 验证安装
                    Refresh-Environment
                    if (-not (Check-Node)) {
                        Write-Host ""
                        Write-Host "警告: Node.js 升级可能需要重启终端" -ForegroundColor Yellow
                        Write-Host "建议: 关闭此终端，打开新终端后重新运行此脚本" -ForegroundColor Yellow
                        $continue = Read-Host "是否继续使用当前版本? (y/n)"
                        if ($continue -ne "y") {
                            exit 1
                        }
                    }
                } else {
                    Write-Host "[!] 继续使用当前 Node.js 版本" -ForegroundColor Yellow
                }
            } else {
                # Node.js 未安装
                Install-Node -IsUpgrade $false
                
                # 验证安装
                Refresh-Environment
                if (-not (Check-Node)) {
                    Write-Host ""
                    Write-Host "错误: Node.js 安装可能需要重启终端" -ForegroundColor Red
                    Write-Host "请关闭此终端，打开新终端后重新运行此脚本" -ForegroundColor Yellow
                    exit 1
                }
            }
        }
    }
    
    # 步骤 2: 检查并安装 OpenClaw
    if (-not $configOnly) {
        Write-Host ""
        Write-Host "步骤 2/3: 检查 OpenClaw..." -ForegroundColor Cyan
        if (-not (Check-OpenClaw)) {
            Install-OpenClaw
            
            # 验证安装
            Refresh-Environment
            if (-not (Check-OpenClaw)) {
                Write-Host ""
                Write-Host "错误: OpenClaw 安装可能需要重启终端" -ForegroundColor Red
                Write-Host "请关闭此终端，打开新终端后重新运行此脚本" -ForegroundColor Yellow
                exit 1
            }
        }
        
        if ($installOnly) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "         OpenClaw 安装完成！           " -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "下一步：" -ForegroundColor Yellow
            Write-Host "1. 运行此脚本选择 '3. 仅配置 AIClient-2-API 连接'" -ForegroundColor White
            Write-Host "2. 或运行: openclaw onboard" -ForegroundColor White
            Write-Host ""
            return
        }
    }
    
    # 步骤 3: 配置 OpenClaw
    Write-Host ""
    Write-Host "步骤 3/3: 配置 OpenClaw..." -ForegroundColor Cyan
    Configure-OpenClawWithAIClient
    
    # 完成
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "         🎉 部署完成！                  " -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "配置摘要：" -ForegroundColor Cyan
    Write-Host "✓ Node.js: $(node -v 2>$null)" -ForegroundColor Green
    Write-Host "✓ OpenClaw: 已安装并配置" -ForegroundColor Green
    Write-Host "✓ 配置文件: $env:USERPROFILE\.openclaw\openclaw.json" -ForegroundColor Green
    Write-Host ""
    
    # 询问是否进行连接测试
    Write-Host "是否进行连接测试？" -ForegroundColor Yellow
    Write-Host "注意: 测试前需要确保 AIClient-2-API 服务已启动" -ForegroundColor Gray
    Write-Host ""
    $runTest = Read-Host "运行测试? (y/n, 默认 y)"
    
    if ($runTest -ne "n") {
        # 询问 AIClient-2-API 是否已启动
        Write-Host ""
        $apiRunning = Read-Host "AIClient-2-API 服务是否已启动? (y/n)"
        
        if ($apiRunning -eq "y") {
            # 运行测试
            Test-Connection
        } else {
            Write-Host ""
            Write-Host "请先启动 AIClient-2-API 服务：" -ForegroundColor Yellow
            Write-Host "  命令: cd ..\.. && node src/services/api-server.js" -ForegroundColor White
            Write-Host "  或使用 Web UI: cd ..\.. && npm start" -ForegroundColor White
            Write-Host ""
            Write-Host "启动后可以重新运行此脚本选择 '4. 检查安装状态' 进行测试" -ForegroundColor Gray
            Write-Host ""
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         下一步操作指南                 " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "步骤 1: 启动 AIClient-2-API 服务（如果未启动）" -ForegroundColor Yellow
    Write-Host "  命令: cd ..\.. && node src/services/api-server.js" -ForegroundColor White
    Write-Host "  或使用 Web UI: cd ..\.. && npm start" -ForegroundColor White
    Write-Host ""
    
    Write-Host "步骤 2: 启动 OpenClaw Gateway" -ForegroundColor Yellow
    Write-Host "  启动命令: openclaw gateway" -ForegroundColor White
    Write-Host "  说明: 启动 WebSocket Gateway，监听 ws://127.0.0.1:18789" -ForegroundColor Gray
    Write-Host "  注意: 保持此终端窗口打开，不要关闭" -ForegroundColor Gray
    Write-Host "  提示: Gateway 启动时会自动打开浏览器，但 URL 不带 token" -ForegroundColor Yellow
    Write-Host "        请关闭该窗口，使用 'openclaw dashboard' 打开正确的 URL" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Gateway 管理命令:" -ForegroundColor Cyan
    Write-Host "    启动: openclaw gateway" -ForegroundColor White
    Write-Host "    停止: 在 Gateway 终端按 Ctrl+C" -ForegroundColor White
    Write-Host "    状态: openclaw health" -ForegroundColor White
    Write-Host "    日志: openclaw logs" -ForegroundColor White
    Write-Host ""
    Write-Host "  Windows 服务管理（已安装为计划任务）:" -ForegroundColor Cyan
    Write-Host "    查看任务: 任务计划程序 -> 'OpenClaw Gateway'" -ForegroundColor White
    Write-Host "    启动服务: schtasks /run /tn `"OpenClaw Gateway`"" -ForegroundColor White
    Write-Host "    停止服务: taskkill /F /FI `"WINDOWTITLE eq OpenClaw*`"" -ForegroundColor White
    Write-Host ""
    
    Write-Host "步骤 3: 配置 Telegram 机器人（推荐）" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  3.1 创建 Telegram Bot" -ForegroundColor Cyan
    Write-Host "    1) 在 Telegram 中搜索: @BotFather" -ForegroundColor White
    Write-Host "    2) 点击 'START' 或发送: /newbot" -ForegroundColor White
    Write-Host "    3) 输入机器人名称（如: My OpenClaw Bot）" -ForegroundColor White
    Write-Host "    4) 输入机器人用户名（必须以 bot 结尾，如: myopenclaw_bot）" -ForegroundColor White
    Write-Host "    5) 复制 BotFather 给你的 API Token（格式: 1234567890:ABC...）" -ForegroundColor White
    Write-Host ""
    
    Write-Host "  3.2 设置机器人隐私模式" -ForegroundColor Cyan
    Write-Host "    1) 在与 @BotFather 的对话中发送: /setprivacy" -ForegroundColor White
    Write-Host "    2) 选择你刚创建的机器人" -ForegroundColor White
    Write-Host "    3) 选择 'Disable' 或输入 Disable" -ForegroundColor White
    Write-Host "       说明: 禁用隐私模式，机器人才能接收所有消息" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "  3.3 配置 OpenClaw" -ForegroundColor Cyan
    Write-Host "    1) 在新终端运行: openclaw onboard" -ForegroundColor White
    Write-Host "    2) 按提示操作，选择风险确认 'Yes'" -ForegroundColor White
    Write-Host "    3) 选择 'QuickStart' 模式" -ForegroundColor White
    Write-Host "    4) 选择 'Use existing values' 保持我们的配置" -ForegroundColor White
    Write-Host "    5) 选择 'Skip for now' 跳过 AI 平台配置" -ForegroundColor White
    Write-Host "    6) 选择 'aiclient-kiro' 作为 provider" -ForegroundColor White
    Write-Host "    7) 选择 'Keep current' 保持当前模型" -ForegroundColor White
    Write-Host "    8) 选择 'Telegram (Bot API)'" -ForegroundColor White
    Write-Host "    9) 粘贴你的 Telegram Bot Token" -ForegroundColor White
    Write-Host "   10) 跳过其他配置，完成设置" -ForegroundColor White
    Write-Host ""
    
    Write-Host "  3.4 批准用户配对" -ForegroundColor Cyan
    Write-Host "    1) 在 Telegram 中搜索你的机器人（用户名）" -ForegroundColor White
    Write-Host "    2) 发送 /start 或任何消息" -ForegroundColor White
    Write-Host "    3) 机器人会回复配对信息:" -ForegroundColor White
    Write-Host "       - 配对码（如: EFUL2WEB）" -ForegroundColor Gray
    Write-Host "       - 你的 Telegram User ID（如: 2125609160）" -ForegroundColor Gray
    Write-Host "       - 批准命令示例" -ForegroundColor Gray
    Write-Host "    4) 在终端运行批准命令:" -ForegroundColor White
    Write-Host "       openclaw pairing approve telegram <配对码>" -ForegroundColor Cyan
    Write-Host "       例如: openclaw pairing approve telegram EFUL2WEB" -ForegroundColor DarkGray
    Write-Host "    5) 看到 'Approved telegram sender <User ID>' 表示成功" -ForegroundColor White
    Write-Host "    6) 批准后，在 Telegram 中重新发送消息测试" -ForegroundColor White
    Write-Host ""
    
    Write-Host "步骤 4: 测试机器人" -ForegroundColor Yellow
    Write-Host "  在 Telegram 中向机器人发送消息，例如:" -ForegroundColor White
    Write-Host "  - '你好，你可以说中文吗？'" -ForegroundColor Gray
    Write-Host "  - '介绍一下你自己'" -ForegroundColor Gray
    Write-Host "  - '用中文写一首诗'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  首次使用需要配对批准:" -ForegroundColor Cyan
    Write-Host "  1) 在 Telegram 中搜索你的机器人（用户名）" -ForegroundColor White
    Write-Host "  2) 发送 /start 或任何消息" -ForegroundColor White
    Write-Host "  3) 机器人会回复配对信息，包含:" -ForegroundColor White
    Write-Host "     - 配对码（如: EFUL2WEB）" -ForegroundColor Gray
    Write-Host "     - 你的 Telegram User ID（如: 2125609160）" -ForegroundColor Gray
    Write-Host "  4) 在终端运行批准命令:" -ForegroundColor White
    Write-Host "     openclaw pairing approve telegram <配对码>" -ForegroundColor Cyan
    Write-Host "     例如: openclaw pairing approve telegram EFUL2WEB" -ForegroundColor DarkGray
    Write-Host "  5) 批准成功后，在 Telegram 中重新发送消息测试" -ForegroundColor White
    Write-Host "  6) 机器人应该会通过 AIClient-2-API 调用 Claude Sonnet 4.5 回复" -ForegroundColor White
    Write-Host ""
    Write-Host "  配对管理命令:" -ForegroundColor Cyan
    Write-Host "  - 查看所有配对: openclaw pairing list" -ForegroundColor White
    Write-Host "  - 批准配对: openclaw pairing approve telegram <配对码>" -ForegroundColor White
    Write-Host "  - 撤销配对: openclaw pairing revoke telegram <User ID>" -ForegroundColor White
    Write-Host ""
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         重要提示                       " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "✓ OpenClaw 已配置使用 AIClient-2-API" -ForegroundColor Green
    Write-Host "✓ AI 模型: Claude Sonnet 4.5 (通过 Kiro API)" -ForegroundColor Green
    Write-Host "✓ 配置文件: $env:USERPROFILE\.openclaw\openclaw.json" -ForegroundColor Green
    Write-Host ""
    Write-Host "注意事项:" -ForegroundColor Yellow
    Write-Host "- 确保 AIClient-2-API 服务一直运行" -ForegroundColor White
    Write-Host "- 确保 OpenClaw Gateway 终端窗口保持打开" -ForegroundColor White
    Write-Host "- 中文路径可能有编码问题，建议使用英文路径" -ForegroundColor White
    Write-Host "- 查看帮助: openclaw --help" -ForegroundColor White
    Write-Host ""
    Write-Host "常用管理命令:" -ForegroundColor Cyan
    Write-Host "- 启动 Gateway: openclaw gateway" -ForegroundColor White
    Write-Host "- 停止 Gateway: 在 Gateway 终端按 Ctrl+C" -ForegroundColor White
    Write-Host "- 检查状态: openclaw health" -ForegroundColor White
    Write-Host "- 查看日志: openclaw logs" -ForegroundColor White
    Write-Host "- 配置管理: openclaw configure" -ForegroundColor White
    Write-Host "- 配对管理: openclaw pairing list" -ForegroundColor White
    Write-Host "- 重新配置: openclaw onboard" -ForegroundColor White
    Write-Host "- 打开 Web 管理界面: openclaw dashboard" -ForegroundColor White
    Write-Host ""
    Write-Host "Web 管理界面（Dashboard）:" -ForegroundColor Cyan
    Write-Host "- 命令: openclaw dashboard" -ForegroundColor White
    Write-Host "- 说明: 自动打开浏览器访问 Web 控制面板（带认证 Token）" -ForegroundColor Gray
    Write-Host "- 地址: http://127.0.0.1:18789/?token=<自动生成>" -ForegroundColor Gray
    Write-Host "- 注意: 不要直接访问 http://127.0.0.1:18789/，会提示 token 缺失" -ForegroundColor Yellow
    Write-Host "- 功能: 查看状态、管理会话、配置设置、查看日志等" -ForegroundColor Gray
    Write-Host ""
    Write-Host "获取 Gateway Token:" -ForegroundColor Cyan
    Write-Host "- 命令: openclaw config get gateway.auth.token" -ForegroundColor White
    Write-Host "- 或查看配置文件: $env:USERPROFILE\.openclaw\openclaw.json" -ForegroundColor Gray
    Write-Host ""
    Write-Host "文档链接:" -ForegroundColor Cyan
    Write-Host "- OpenClaw 官方文档: https://docs.openclaw.ai" -ForegroundColor Gray
    Write-Host "- Telegram 配置: https://docs.openclaw.ai/channels/telegram" -ForegroundColor Gray
    Write-Host "- 安全指南: https://docs.openclaw.ai/gateway/security" -ForegroundColor Gray
    Write-Host ""
    Write-Host "高级配置选项:" -ForegroundColor Cyan
    Write-Host "如需配置更多功能，可以使用以下方式：" -ForegroundColor White
    Write-Host ""
    Write-Host "1. 命令行配置工具:" -ForegroundColor Yellow
    Write-Host "   openclaw configure" -ForegroundColor White
    Write-Host "   - 配置其他通讯平台（WhatsApp、Discord、Slack 等）" -ForegroundColor Gray
    Write-Host "   - 修改 Workspace 路径" -ForegroundColor Gray
    Write-Host "   - 切换 AI 模型" -ForegroundColor Gray
    Write-Host "   - 配置 Web 搜索工具（Brave Search API）" -ForegroundColor Gray
    Write-Host "   - 管理 Skills（技能插件）" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Web 管理界面:" -ForegroundColor Yellow
    Write-Host "   openclaw dashboard" -ForegroundColor White
    Write-Host "   - 可视化配置界面" -ForegroundColor Gray
    Write-Host "   - 查看和管理会话" -ForegroundColor Gray
    Write-Host "   - 实时查看日志" -ForegroundColor Gray
    Write-Host "   - 管理配对和权限" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. 完整配置向导:" -ForegroundColor Yellow
    Write-Host "   openclaw onboard" -ForegroundColor White
    Write-Host "   - 交互式完整配置流程" -ForegroundColor Gray
    Write-Host "   - 适合首次设置或重新配置" -ForegroundColor Gray
    Write-Host ""
    Write-Host "提示：" -ForegroundColor Cyan
    Write-Host "- OpenClaw 已配置使用 AIClient-2-API (Claude Sonnet 4.5)" -ForegroundColor Gray
    Write-Host "- 配置文件: $env:USERPROFILE\.openclaw\openclaw.json" -ForegroundColor Gray
    Write-Host "- 查看帮助: openclaw --help" -ForegroundColor Gray
    Write-Host ""
    
    # 生成 Markdown 使用指南到桌面
    Generate-UsageGuide
}

# 生成 Markdown 使用指南到桌面
function Generate-UsageGuide {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "      生成使用指南文档                  " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $guidePath = Join-Path $desktopPath "OpenClaw使用指南.md"
    
    # 读取配置信息
    $configPath = "$env:USERPROFILE\.openclaw\openclaw.json"
    $modelName = "claude-sonnet-4-5"
    $gatewayMode = "local"
    $gatewayToken = ""
    $telegramConfigured = $false
    
    # 获取版本信息（不调用 openclaw 命令，避免配置错误）
    $nodeVersion = "未知"
    $openclawVersion = "已安装"
    
    try {
        $nodeVersion = (node --version 2>$null)
        if (-not $nodeVersion) { $nodeVersion = "未知" }
    } catch {
        $nodeVersion = "未知"
    }
    
    try {
        # 尝试从 package.json 读取版本
        $npmPrefix = (npm config get prefix 2>$null).Trim()
        if ($npmPrefix) {
            $openclawPackageJson = Join-Path $npmPrefix "node_modules\openclaw\package.json"
            if (Test-Path $openclawPackageJson) {
                $packageInfo = Get-Content $openclawPackageJson -Raw -Encoding UTF8 | ConvertFrom-Json
                $openclawVersion = $packageInfo.version
            }
        }
    } catch {
        $openclawVersion = "已安装"
    }
    
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($config.agents.defaults.model.primary) {
                $modelName = $config.agents.defaults.model.primary -replace "aiclient-kiro/", ""
            }
            if ($config.gateway.mode) {
                $gatewayMode = $config.gateway.mode
            }
            if ($config.gateway.auth.token) {
                $gatewayToken = $config.gateway.auth.token
            }
            if ($config.channels.telegram.token) {
                $telegramConfigured = $true
            }
        } catch {
            Write-Host "[!] 无法读取配置文件，使用默认值" -ForegroundColor Yellow
        }
    }
    
    # 生成 Markdown 内容
    $markdownContent = @"
# OpenClaw + AIClient-2-API 使用指南

> 生成时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
> 配置文件: ``$env:USERPROFILE\.openclaw\openclaw.json``

---

## 📋 配置摘要

| 项目 | 配置 |
|------|------|
| **AI 模型** | $modelName (通过 AIClient-2-API) |
| **Gateway 模式** | $gatewayMode |
| **Gateway Token** | $gatewayToken |
| **Telegram Bot** | $(if ($telegramConfigured) { "✓ 已配置" } else { "✗ 未配置" }) |
| **Node.js 版本** | $nodeVersion |
| **OpenClaw 版本** | $openclawVersion |

---

## 🚀 快速启动

### 步骤 1: 启动 AIClient-2-API 服务

AIClient-2-API 是连接 AWS Kiro API 的桥梁，必须先启动。

**方法 1: 命令行启动**
``````powershell
cd F:\hotyi-dev\AIClient-2-API
node src/services/api-server.js
``````

**方法 2: Web UI 启动**
``````powershell
cd F:\hotyi-dev\AIClient-2-API
npm start
``````

> **注意**: 保持此终端窗口打开，不要关闭！

---

### 步骤 2: 启动 OpenClaw Gateway

在**新的终端窗口**中运行：

``````powershell
openclaw gateway
``````

**说明**:
- Gateway 监听地址: ``ws://127.0.0.1:18789``
- 保持此终端窗口打开，不要关闭
- Gateway 启动时会自动打开浏览器，但 URL 不带 token
- **请关闭自动打开的浏览器窗口**，使用下面的命令打开正确的 URL

**打开 Web 管理界面**:
``````powershell
openclaw dashboard
``````

> 此命令会自动打开浏览器并附带认证 Token

---

### 步骤 3: 配置 Telegram Bot（可选）

$(if ($telegramConfigured) {
@"
✓ **Telegram Bot 已配置**

你可以直接在 Telegram 中搜索你的机器人并开始使用。

**首次使用需要配对批准**，请参考下面的「配对批准流程」。
"@
} else {
@"
✗ **Telegram Bot 未配置**

如果你想让机器人在 Telegram 中工作，请按以下步骤配置：

#### 3.1 创建 Telegram Bot

1. 在 Telegram 中搜索: ``@BotFather``
2. 点击 **START** 或发送: ``/newbot``
3. 输入机器人名称（如: ``My OpenClaw Bot``）
4. 输入机器人用户名（必须以 ``bot`` 结尾，如: ``myopenclaw_bot``）
5. 复制 BotFather 给你的 **API Token**（格式: ``1234567890:ABC...``）

#### 3.2 设置机器人隐私模式

1. 在与 @BotFather 的对话中发送: ``/setprivacy``
2. 选择你刚创建的机器人
3. 选择 **Disable** 或输入 ``Disable``

> **说明**: 禁用隐私模式，机器人才能接收所有消息

#### 3.3 配置 OpenClaw

在新终端运行:
``````powershell
openclaw onboard
``````

按提示操作:
1. 选择风险确认 **Yes**
2. 选择 **QuickStart** 模式
3. 选择 **Use existing values** 保持我们的配置
4. 选择 **Skip for now** 跳过 AI 平台配置
5. 选择 **aiclient-kiro** 作为 provider
6. 选择 **Keep current** 保持当前模型
7. 选择 **Telegram (Bot API)**
8. 粘贴你的 Telegram Bot Token
9. 跳过其他配置，完成设置
"@
})

---

### 步骤 4: 配对批准（Telegram）

首次使用 Telegram 机器人时，需要进行配对批准。

#### 4.1 获取配对码

1. 在 Telegram 中搜索你的机器人（用户名）
2. 发送 ``/start`` 或任何消息
3. 机器人会回复配对信息:
   - **配对码**（如: ``EFUL2WEB``）
   - **你的 Telegram User ID**（如: ``2125609160``）
   - **批准命令示例**

#### 4.2 批准配对

在终端运行批准命令:
``````powershell
openclaw pairing approve telegram <配对码>
``````

**示例**:
``````powershell
openclaw pairing approve telegram EFUL2WEB
``````

看到 ``Approved telegram sender <User ID>`` 表示成功。

#### 4.3 测试机器人

批准后，在 Telegram 中重新发送消息测试:
- "你好，你可以说中文吗？"
- "介绍一下你自己"
- "用中文写一首诗"

机器人应该会通过 AIClient-2-API 调用 Claude Sonnet 4.5 回复。

---

## 🛠️ 常用管理命令

### Gateway 管理

| 命令 | 说明 |
|------|------|
| ``openclaw gateway`` | 启动 Gateway |
| ``Ctrl+C`` | 停止 Gateway（在 Gateway 终端） |
| ``openclaw health`` | 检查 Gateway 状态 |
| ``openclaw logs`` | 查看 Gateway 日志 |
| ``openclaw dashboard`` | 打开 Web 管理界面（带 Token） |

### 配对管理

| 命令 | 说明 |
|------|------|
| ``openclaw pairing list`` | 查看所有配对 |
| ``openclaw pairing approve telegram <配对码>`` | 批准 Telegram 配对 |
| ``openclaw pairing revoke telegram <User ID>`` | 撤销 Telegram 配对 |

### 配置管理

| 命令 | 说明 |
|------|------|
| ``openclaw configure`` | 打开配置工具 |
| ``openclaw onboard`` | 重新运行配置向导 |
| ``openclaw config get <key>`` | 获取配置值 |
| ``openclaw config set <key> <value>`` | 设置配置值 |

### 其他命令

| 命令 | 说明 |
|------|------|
| ``openclaw --help`` | 查看帮助 |
| ``openclaw --version`` | 查看版本 |

---

## 🌐 Web 管理界面（Dashboard）

### 访问方式

**推荐方式**（自动附带 Token）:
``````powershell
openclaw dashboard
``````

**手动访问**（需要手动添加 Token）:
``````
http://127.0.0.1:18789/?token=$gatewayToken
``````

> **注意**: 不要直接访问 ``http://127.0.0.1:18789/``，会提示 token 缺失

### 功能介绍

- ✓ 查看 Gateway 状态
- ✓ 管理会话和对话
- ✓ 配置设置
- ✓ 查看实时日志
- ✓ 管理配对和权限
- ✓ 监控资源使用

---

## ⚙️ 高级配置

### 1. 命令行配置工具

``````powershell
openclaw configure
``````

**可配置项**:
- 其他通讯平台（WhatsApp、Discord、Slack 等）
- Workspace 路径
- AI 模型切换
- Web 搜索工具（Brave Search API）
- Skills（技能插件）管理

### 2. Web 管理界面

``````powershell
openclaw dashboard
``````

**功能**:
- 可视化配置界面
- 查看和管理会话
- 实时查看日志
- 管理配对和权限

### 3. 完整配置向导

``````powershell
openclaw onboard
``````

**适用场景**:
- 首次设置
- 重新配置
- 添加新的通讯平台

---

## 📚 文档链接

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [Telegram 配置指南](https://docs.openclaw.ai/channels/telegram)
- [安全指南](https://docs.openclaw.ai/gateway/security)
- [AIClient-2-API GitHub](https://github.com/simtelboy/AIClient-2-API)
- [部署脚本 GitHub](https://github.com/simtelboy/deploy-openclaw-aiclient)

---

## ⚠️ 重要提示

### 必须保持运行的服务

1. **AIClient-2-API 服务** - 必须一直运行
   - 启动命令: ``node src/services/api-server.js``
   - 或: ``npm start``

2. **OpenClaw Gateway** - 必须一直运行
   - 启动命令: ``openclaw gateway``
   - 保持终端窗口打开

### 注意事项

- ✓ 确保 AIClient-2-API 服务一直运行
- ✓ 确保 OpenClaw Gateway 终端窗口保持打开
- ✓ 中文路径可能有编码问题，建议使用英文路径
- ✓ 首次使用 Telegram 需要配对批准
- ✓ Gateway Token 用于 Web 管理界面认证
- ✓ API Key 用于 AIClient-2-API 认证（不同用途）

### 故障排查

**问题 1: Telegram 机器人不回复**
- 检查 AIClient-2-API 是否运行
- 检查 OpenClaw Gateway 是否运行
- 检查是否已完成配对批准
- 查看日志: ``openclaw logs``

**问题 2: Web 管理界面无法访问**
- 使用 ``openclaw dashboard`` 命令打开（自动附带 Token）
- 不要直接访问 ``http://127.0.0.1:18789/``
- 检查 Gateway 是否运行: ``openclaw health``

**问题 3: API 调用失败**
- 检查 Kiro IDE 是否登录
- 检查 Kiro Token 是否过期
- 重启 AIClient-2-API 服务

---

## 🔄 卸载和重新安装

### 卸载 OpenClaw

``````powershell
cd F:\hotyi-dev\AIClient-2-API\deploy-clawdbot
.\deploy_openclaw_with_aiclient.ps1
``````

选择 **5. 卸载 OpenClaw**

### 重新安装

运行相同的脚本，选择 **1. 完整安装**

---

## 📞 获取帮助

- 查看命令帮助: ``openclaw --help``
- 查看配置: ``openclaw config list``
- 查看日志: ``openclaw logs``
- 检查状态: ``openclaw health``

---

**祝你使用愉快！** 🎉
"@

    # 保存文件（UTF-8 with BOM）
    try {
        $utf8Bom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($guidePath, $markdownContent, $utf8Bom)
        
        Write-Host "[✓] 使用指南已保存到桌面" -ForegroundColor Green
        Write-Host "    文件路径: $guidePath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "你可以使用以下方式打开:" -ForegroundColor Cyan
        Write-Host "- Markdown 编辑器（如 Typora、VS Code）" -ForegroundColor White
        Write-Host "- 记事本" -ForegroundColor White
        Write-Host "- 浏览器（安装 Markdown 预览插件）" -ForegroundColor White
        Write-Host ""
    } catch {
        Write-Host "[✗] 保存使用指南失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 执行主流程
Main
