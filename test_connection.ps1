# OpenClaw + AIClient-2-API 连接测试脚本
# 用于验证配置是否正确

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "===== OpenClaw + AIClient-2-API 连接测试 =====" -ForegroundColor Cyan
Write-Host ""

$allPassed = $true

# 测试 1: 检查 Node.js
Write-Host "[测试 1] 检查 Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        $version = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
        if ($version -ge 22) {
            Write-Host "  ✓ Node.js $nodeVersion (符合要求 v22+)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Node.js $nodeVersion (需要 v22+)" -ForegroundColor Red
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
Write-Host "[测试 2] 检查 OpenClaw..." -ForegroundColor Yellow
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
        Write-Host "    运行部署脚本安装: .\deploy_openclaw_with_aiclient.ps1" -ForegroundColor Gray
        $allPassed = $false
    }
} catch {
    Write-Host "  ✗ OpenClaw 检查失败" -ForegroundColor Red
    $allPassed = $false
}

# 测试 3: 检查 AIClient-2-API 服务
Write-Host ""
Write-Host "[测试 3] 检查 AIClient-2-API 服务..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:4000" -Method GET -TimeoutSec 3 -ErrorAction Stop
    Write-Host "  ✓ AIClient-2-API 运行中 (http://127.0.0.1:4000)" -ForegroundColor Green
} catch {
    Write-Host "  ✗ AIClient-2-API 未运行" -ForegroundColor Red
    Write-Host "    启动命令: cd AIClient-2-API && node src/services/api-server.js" -ForegroundColor Gray
    $allPassed = $false
}

# 测试 4: 检查 OpenClaw 配置文件
Write-Host ""
Write-Host "[测试 4] 检查 OpenClaw 配置..." -ForegroundColor Yellow
$configPath = "$env:USERPROFILE\.openclaw\openclaw.json"
if (Test-Path $configPath) {
    Write-Host "  ✓ 配置文件存在: $configPath" -ForegroundColor Green
    
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        
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
            Write-Host "    运行部署脚本配置: .\deploy_openclaw_with_aiclient.ps1" -ForegroundColor Gray
            $allPassed = $false
        }
    } catch {
        Write-Host "  ✗ 配置文件解析失败: $($_.Exception.Message)" -ForegroundColor Red
        $allPassed = $false
    }
} else {
    Write-Host "  ✗ 配置文件不存在" -ForegroundColor Red
    Write-Host "    运行部署脚本创建配置: .\deploy_openclaw_with_aiclient.ps1" -ForegroundColor Gray
    $allPassed = $false
}

# 测试 5: 检查 Kiro 认证
Write-Host ""
Write-Host "[测试 5] 检查 Kiro 认证..." -ForegroundColor Yellow
$kiroTokenPath = "$env:USERPROFILE\.aws\sso\cache\kiro-auth-token.json"
if (Test-Path $kiroTokenPath) {
    Write-Host "  ✓ Kiro token 文件存在" -ForegroundColor Green
    
    try {
        $kiroToken = Get-Content $kiroTokenPath -Raw | ConvertFrom-Json
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
Write-Host "[测试 6] 测试 API 端点..." -ForegroundColor Yellow
try {
    $testUrl = "http://127.0.0.1:4000/v1/models"
    $headers = @{
        "Authorization" = "Bearer hotyi"
    }
    $response = Invoke-WebRequest -Uri $testUrl -Headers $headers -Method GET -TimeoutSec 3 -ErrorAction Stop
    Write-Host "  ✓ API 端点响应正常" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "  ⚠ API 端点返回 404 (可能正常，取决于 AIClient-2-API 版本)" -ForegroundColor Yellow
    } else {
        Write-Host "  ✗ API 端点测试失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 总结
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "         ✓ 所有测试通过！" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "你可以开始使用 OpenClaw 了！" -ForegroundColor Green
    Write-Host ""
    Write-Host "启动命令: openclaw" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "         ✗ 部分测试失败" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "请根据上述提示修复问题后重新测试" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "常见解决方案：" -ForegroundColor Cyan
    Write-Host "1. 运行部署脚本: .\deploy_openclaw_with_aiclient.ps1" -ForegroundColor White
    Write-Host "2. 启动 AIClient-2-API: cd ..\.. && node src/services/api-server.js" -ForegroundColor White
    Write-Host "3. 登录 Kiro IDE 获取认证 token" -ForegroundColor White
    Write-Host ""
}
