# Kimi Work Reddit Skills Pack - 安装脚本 (Windows PowerShell)
# 用法: 右键 -> 使用 PowerShell 运行，或在 PowerShell 中执行 .\install.ps1

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillsSource = Join-Path $scriptDir "skills"

# Windows 默认路径
$kimiSkillsDir = Join-Path $env:APPDATA "kimi-desktop\daimon-share\daimon\skills"

Write-Host "🚀 Reddit Skills Pack 安装脚本 (Windows)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 检查源文件
$collectorSource = Join-Path $skillsSource "reddit-data-collector"
$analyzerSource = Join-Path $skillsSource "reddit-painpoint-analyzer"

if (-not (Test-Path $collectorSource) -or -not (Test-Path $analyzerSource)) {
    Write-Host "❌ 错误: 找不到 skill 源文件。" -ForegroundColor Red
    Write-Host "请确保你在 reddit-skills-pack 目录中运行此脚本。" -ForegroundColor Red
    exit 1
}

# 如果默认路径不存在，尝试其他可能的路径
$possiblePaths = @(
    $kimiSkillsDir,
    (Join-Path $env:APPDATA "kimi-work\daimon-share\daimon\skills"),
    (Join-Path $env:APPDATA "kimi\daimon-share\daimon\skills"),
    (Join-Path $env:LOCALAPPDATA "kimi-desktop\daimon-share\daimon\skills"),
    (Join-Path $env:LOCALAPPDATA "kimi-work\daimon-share\daimon\skills")
)

$foundPath = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $foundPath = $path
        break
    }
}

if ($foundPath) {
    $kimiSkillsDir = $foundPath
    Write-Host "✅ 找到 Kimi Work skills 目录: $kimiSkillsDir" -ForegroundColor Green
} else {
    Write-Host "⚠️  未找到 Kimi Work skills 目录，使用默认路径。" -ForegroundColor Yellow
    Write-Host "   默认路径: $kimiSkillsDir" -ForegroundColor Yellow
    
    # 尝试创建目录
    if (-not (Test-Path $kimiSkillsDir)) {
        try {
            New-Item -ItemType Directory -Path $kimiSkillsDir -Force | Out-Null
            Write-Host "   已创建目录。" -ForegroundColor Green
        } catch {
            Write-Host "❌ 无法创建目录。请检查 Kimi Work 是否已安装。" -ForegroundColor Red
            Write-Host "   你也可以手动指定路径，修改本脚本中的 `$kimiSkillsDir 变量。" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host ""
Write-Host "📁 源目录: $skillsSource" -ForegroundColor White
Write-Host "🎯 目标目录: $kimiSkillsDir" -ForegroundColor White
Write-Host ""

# 备份已存在的 skill
$backupDir = Join-Path $kimiSkillsDir ".backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$skillsToInstall = @("reddit-data-collector", "reddit-painpoint-analyzer")

foreach ($skill in $skillsToInstall) {
    $skillPath = Join-Path $kimiSkillsDir $skill
    if (Test-Path $skillPath) {
        Write-Host "📦 备份已存在的 $skill ..." -ForegroundColor Yellow
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        Copy-Item -Path $skillPath -Destination $backupDir -Recurse -Force
    }
}

# 复制 skill 文件
Write-Host "📋 正在安装 skills..." -ForegroundColor White
foreach ($skill in $skillsToInstall) {
    $source = Join-Path $skillsSource $skill
    $dest = Join-Path $kimiSkillsDir $skill
    
    if (Test-Path $source) {
        if (Test-Path $dest) {
            Remove-Item -Path $dest -Recurse -Force
        }
        Copy-Item -Path $source -Destination $dest -Recurse -Force
        Write-Host "   ✅ $skill" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  跳过 $skill (源文件不存在)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🎉 安装完成！" -ForegroundColor Green
Write-Host ""

if (Test-Path $backupDir) {
    Write-Host "📦 旧版本已备份到: $backupDir" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "下一步:" -ForegroundColor White
Write-Host "1. 完全关闭并重新打开 Kimi Work 应用" -ForegroundColor White
Write-Host "2. 在 Kimi Work 中发送: 采集 r/personaltraining 最近 50 条帖子" -ForegroundColor White
Write-Host "3. 验证 skill 是否被正确触发" -ForegroundColor White
Write-Host ""
Write-Host "如果 skill 没有触发，请检查:" -ForegroundColor Yellow
Write-Host "   - Kimi Work 是否已完全重启" -ForegroundColor Yellow
Write-Host "   - skills 目录路径是否正确: $kimiSkillsDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
