#!/usr/bin/env bash
# Kimi Work Reddit Skills Pack - 安装脚本 (macOS / Linux)
# 用法: bash install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SOURCE="$SCRIPT_DIR/skills"

# 检测操作系统并设置目标目录
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    KIMI_SKILLS_DIR="$HOME/Library/Application Support/kimi-desktop/daimon-share/daimon/skills"
    OS_NAME="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    KIMI_SKILLS_DIR="$HOME/.config/kimi-desktop/daimon-share/daimon/skills"
    OS_NAME="Linux"
else
    echo "❌ 不支持的操作系统: $OSTYPE"
    echo "请手动复制 skills/ 目录到 Kimi Work 的 skills 文件夹。"
    exit 1
fi

echo "🚀 Reddit Skills Pack 安装脚本 ($OS_NAME)"
echo "=========================================="
echo ""

# 检查源文件是否存在
if [ ! -d "$SKILLS_SOURCE/reddit-data-collector" ] || [ ! -d "$SKILLS_SOURCE/reddit-painpoint-analyzer" ]; then
    echo "❌ 错误: 找不到 skill 源文件。"
    echo "请确保你在 reddit-skills-pack 目录中运行此脚本。"
    exit 1
fi

# 检查目标目录是否存在，如果不存在则尝试创建
if [ ! -d "$KIMI_SKILLS_DIR" ]; then
    echo "⚠️  Kimi Work skills 目录不存在: $KIMI_SKILLS_DIR"
    echo "尝试创建..."
    mkdir -p "$KIMI_SKILLS_DIR"
    if [ ! -d "$KIMI_SKILLS_DIR" ]; then
        echo "❌ 无法创建目录。请检查 Kimi Work 是否已安装，或手动创建目录。"
        echo "预期路径: $KIMI_SKILLS_DIR"
        exit 1
    fi
fi

echo "📁 源目录: $SKILLS_SOURCE"
echo "🎯 目标目录: $KIMI_SKILLS_DIR"
echo ""

# 备份已存在的 skill（如果存在）
BACKUP_DIR="$KIMI_SKILLS_DIR/.backup-$(date +%Y%m%d-%H%M%S)"
for skill in reddit-data-collector reddit-painpoint-analyzer; do
    if [ -d "$KIMI_SKILLS_DIR/$skill" ]; then
        echo "📦 备份已存在的 $skill ..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$KIMI_SKILLS_DIR/$skill" "$BACKUP_DIR/"
    fi
done

# 复制 skill 文件
echo "📋 正在安装 skills..."
for skill in reddit-data-collector reddit-painpoint-analyzer; do
    if [ -d "$SKILLS_SOURCE/$skill" ]; then
        rm -rf "$KIMI_SKILLS_DIR/$skill"
        cp -r "$SKILLS_SOURCE/$skill" "$KIMI_SKILLS_DIR/"
        echo "   ✅ $skill"
    else
        echo "   ⚠️  跳过 $skill (源文件不存在)"
    fi
done

echo ""
echo "=========================================="
echo "🎉 安装完成！"
echo ""

if [ -d "$BACKUP_DIR" ]; then
    echo "📦 旧版本已备份到: $BACKUP_DIR"
fi

echo ""
echo "下一步:"
echo "1. 重启 Kimi Work 应用（或等待几分钟让 skill 索引刷新）"
echo "2. 在 Kimi Work 中发送: 采集 r/personaltraining 最近 50 条帖子"
echo "3. 验证 skill 是否被正确触发"
echo ""
echo "如果 skill 没有触发，请检查:"
echo "   - Kimi Work 是否已完全重启"
echo "   - skills 目录路径是否正确: $KIMI_SKILLS_DIR"
echo ""
