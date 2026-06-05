# Reddit Skills Pack for Kimi Work

一键采集 Reddit 帖子数据并分析用户痛点的 Kimi Work Skill 套装。

包含两个 Skill：
- **reddit-data-collector** — 采集指定 subreddit 的帖子及评论，导出结构化 Excel
- **reddit-painpoint-analyzer** — 读取采集结果，按「刨根问底引导法」分析用户痛点，输出商业洞察报告

---

## 文件结构

```
reddit-skills-pack/
├── README.md                           # 本文件
├── install.ps1                         # Windows 安装脚本 (PowerShell)
├── install.sh                          # macOS/Linux 安装脚本 (Bash)
├── skills/
│   ├── reddit-data-collector/
│   │   └── SKILL.md                    # 数据采集 Skill
│   └── reddit-painpoint-analyzer/
│       └── SKILL.md                    # 痛点分析 Skill
└── .github/
    └── workflows/                      # (可选) GitHub Actions 自动化
```

---

## 快速开始

### 方式一：GitHub 仓库 + 手动复制（推荐）

1. **在当前设备上**，把本仓库 push 到你的 GitHub：
   ```bash
   git init
   git add .
   git commit -m "init: reddit skills pack"
   git remote add origin https://github.com/YOUR_USERNAME/reddit-skills-pack.git
   git push -u origin main
   ```

2. **在目标设备上**，clone 仓库并复制到 Kimi Work skills 目录：

   **Windows (PowerShell):**
   ```powershell
   git clone https://github.com/YOUR_USERNAME/reddit-skills-pack.git
   cd reddit-skills-pack
   # 复制到 Kimi Work skills 目录
   $skillsDir = "$env:APPDATA\kimi-desktop\daimon-share\daimon\skills"
   Copy-Item -Recurse -Force "skills\reddit-data-collector" "$skillsDir\"
   Copy-Item -Recurse -Force "skills\reddit-painpoint-analyzer" "$skillsDir\"
   ```

   **macOS:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/reddit-skills-pack.git
   cd reddit-skills-pack
   SKILLS_DIR="$HOME/Library/Application Support/kimi-desktop/daimon-share/daimon/skills"
   cp -r skills/reddit-data-collector "$SKILLS_DIR/"
   cp -r skills/reddit-painpoint-analyzer "$SKILLS_DIR/"
   ```

   **Linux:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/reddit-skills-pack.git
   cd reddit-skills-pack
   SKILLS_DIR="$HOME/.config/kimi-desktop/daimon-share/daimon/skills"
   cp -r skills/reddit-data-collector "$SKILLS_DIR/"
   cp -r skills/reddit-painpoint-analyzer "$SKILLS_DIR/"
   ```

3. **重启 Kimi Work** 或等待 skill 索引自动刷新（通常几秒到几分钟）。

4. **验证安装**：在 Kimi Work 中发送消息 `采集 r/personaltraining 最近 50 条帖子`，看是否触发 skill。

---

### 方式二：使用安装脚本（一键安装）

**Windows (以管理员身份运行 PowerShell):**
```powershell
# 先 clone 仓库
git clone https://github.com/YOUR_USERNAME/reddit-skills-pack.git
# 运行安装脚本
.\reddit-skills-pack\install.ps1
```

**macOS / Linux:**
```bash
git clone https://github.com/YOUR_USERNAME/reddit-skills-pack.git
bash reddit-skills-pack/install.sh
```

---

### 方式三：通过 Kimi Work 的 SkillManage 工具创建（无需文件操作）

如果你不想手动复制文件，可以直接在目标设备的 Kimi Work 中使用 `SkillManage` 工具创建 skill：

1. 先读取本仓库中的 `skills/reddit-data-collector/SKILL.md` 和 `skills/reddit-painpoint-analyzer/SKILL.md` 内容。
2. 在目标设备的 Kimi Work 中执行：
   ```
   SkillManage(action="create", name="reddit-data-collector", content="<粘贴SKILL.md全文>")
   SkillManage(action="create", name="reddit-painpoint-analyzer", content="<粘贴SKILL.md全文>")
   ```

---

## Kimi Work Skills 目录速查表

| 操作系统 | Skills 目录路径 |
|---------|----------------|
| **Windows** | `%APPDATA%\kimi-desktop\daimon-share\daimon\skills` |
| **macOS** | `~/Library/Application Support/kimi-desktop/daimon-share/daimon/skills` |
| **Linux** | `~/.config/kimi-desktop/daimon-share/daimon/skills` |

> 注意：路径中的 `kimi-desktop` 可能因你使用的 Kimi 客户端名称而略有不同（如 `kimi-work`、`kimi` 等）。如果找不到，可以在 Kimi Work 中问 agent："我的 skills 目录在哪里？"

---

## 使用示例

安装完成后，在 Kimi Work 中直接发送以下消息即可触发：

```
采集 r/personaltraining 最近 100 条帖子
```

采集完成后，再发送：

```
分析一下这些帖子里面的用户痛点
```

或一次性指令：

```
采集 r/fitness 最近 50 条帖子并分析痛点
```

---

## 依赖要求

- **reddit-data-collector** 需要 **Kimi WebBridge** 运行（Kimi Desktop App 已打开且浏览器扩展已启用）
- **reddit-painpoint-analyzer** 需要 reddit-data-collector 导出的 Excel 文件作为输入
- 两个 skill 均依赖 Kimi Work 的 Python 运行时（内置 pandas、openpyxl）

---

## 更新 Skill

当本仓库有更新时，在目标设备上 pull 最新代码并重新复制即可：

```bash
cd reddit-skills-pack
git pull origin main
# 然后重新运行对应系统的复制命令（见方式一）
```

---

## 许可证

MIT License — 自由使用、修改和分发。

---

## 问题反馈

如有问题，请在 GitHub Issues 中提交，或直接在 Kimi Work 中询问 agent。
