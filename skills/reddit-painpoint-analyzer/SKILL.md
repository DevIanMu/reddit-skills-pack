---
name: reddit-painpoint-analyzer
description: |
  读取 Reddit 数据采集 Skill 导出的 Excel，按「刨根问底引导法」分析用户痛点，
  输出结构化商业洞察报告。触发方式："分析这个 Excel 的痛点" 或 "帮我分析 r/xxx 的帖子数据"
---

# Reddit 痛点分析 Skill

## Trigger Conditions

Activate this Skill when the user expresses the following intent:
- "Analyze this Excel file"
- "Help me analyze pain points in r/xxx"
- "What business opportunities are in these Reddit posts"
- "Mine pain points from this data"
- "Analyze Reddit user discussions to find pain points"

## Pre-Checks

1. **Confirm Data Source**
   - Ask the user: "Please provide the Excel file path exported from Skill 1, or upload the Excel file."
   - If not provided: Prompt the user to first use the `reddit-data-collector` Skill to collect data

2. **File Validation**
   - Check if file exists
   - Check if required fields are present: post_id, title, selftext, score, num_comments
   - If fields are missing: Inform the user the file format is incorrect

## 语言策略

| 场景 | 报告语言 | 说明 |
|------|----------|------|
| 数据源为英文社区（Reddit 默认） | **英文输出** | 分析、报告、用户原话引用全部用英文，质量最佳 |
| 用户明确要求中文报告 | **中英双语** | 报告主体中文，用户原话保留英文并附中文翻译 |

> **推荐**：分析 Reddit 英文社区时，**默认输出英文报告**。英文分析对俚语、情绪词的理解更精准，且报告可直接用于英文商业场景（pitch deck、Landing Page、投资人演示）。

## 分析工作流（3 步，优化版）

> **核心优化原则**：减少 subagent 串行调用次数，能并行的并行，能合并的合并，所有 subagent 设置 `timeout=3600`。

### Step 1: Data Loading & Preprocessing (PythonRun, executed by main Agent)

**Goal**: Load Excel, filter high-engagement posts, prepare analysis material. **No subagent for this step**.

**Steps**:

1. **Read Excel**
   ```python
   import pandas as pd
   df = pd.read_excel(excel_path)
   ```

2. **Basic Statistics**
   - Total posts
   - Score distribution (min, max, median, average)
   - num_comments distribution
   - Time range

3. **Filter High-Engagement Posts**
   ```python
   median_score = df['score'].median()
   high_engagement = df[(df['score'] > median_score) | (df['num_comments'] > 10)]
   ```
   - Keep `high_engagement` as core analysis target
   - Keep all posts for demand breadth validation

4. **Content Batching (streamlined for LLM input)**
   - Sort posts by `score` descending
   - **20-25 posts per batch** (larger batches reduce total batch count)
   - Only keep streamlined fields per batch: `title`, `selftext` (truncated to 500 chars), `score`, `num_comments`
   - If `selftext` is empty, use `"[no body text]"` as placeholder

5. **Output Batch Files**
   - Save each batch as temporary JSON files (e.g., `batch_01.json`, `batch_02.json`)
   - Record total batch count `total_batches`

### Step 2: Pain Point Extraction + Clustering & Ranking (Parallel Subagents, merged original Step 2+3)

**Goal**: **Complete "extraction → clustering → ranking" in one LLM call**, no longer split into two steps.

**Execution**:
- **Launch multiple subagents in parallel**, each subagent processes one batch
- **Each subagent timeout=3600**
- Keep batch count within **4 batches** (if high-engagement posts > 100, only take Top 100)

**Merge Batch Results**:
- Main agent collects pain point tables returned by all subagents
- Use PythonRun to merge, deduplicate, re-rank by total score, take **Top 15 global pain points**
- Report to user: "Extracted {N} pain points, Top 5 are: ..."

**Subagent Prompt 模板** (English output for English communities):

```
You are a senior market research analyst + product strategy consultant.

Read the following Reddit posts and complete two tasks:

## Task 1: Pain Point Extraction
Extract user-expressed problems, frustrations, and unmet needs from the posts.

For each post, output:
1. **Pain point description** (one sentence, max 30 words)
2. **Pain keywords** (emotionally charged words in quotes)
3. **Source post title**
4. **Engagement data** (score and num_comments)

Focus on: direct complaints, help requests, wishes ("I wish..."), workarounds, comparative dissatisfaction.

## Task 2: Clustering & Ranking
Merge similar pain points by similarity, then score each clustered pain point on three dimensions (1-5 scale):

- **Pain Intensity**: How emotionally charged the user's language is
- **Demand Breadth**: Mentioned in multiple posts = high, single post low engagement = low
- **Market Gap**: User says "no tool / workaround" = high, mature solution exists = low

**Total Score = Pain Intensity × 2 + Demand Breadth × 1.5 + Market Gap × 2**

Output format:
| Rank | Pain Point | Occurrences | Pain Intensity | Demand Breadth | Market Gap | Total Score | Evidence Posts |
|------|------------|-------------|----------------|----------------|------------|-------------|----------------|

Only output pain points found in this batch. No global ranking needed.

Post list:
{batch_posts}
```

### Step 3: Solution Brainstorm (Parallel Subagents, merged 3 rounds into 1)

**Goal**: Deep dive into Top 5 pain points, **one Prompt completes "solution ideation → refinement → MVP"**, no longer 3 serial rounds.

**Execution**:
- **Launch 5 subagents in parallel**, each processing 1 pain point
- **Each subagent timeout=3600**
- 5 pain points analyzed simultaneously, total time ≈ time for 1 pain point

**Merge Results**:
- Main agent collects results from 5 subagents
- Organize by total score into Chapter 3 of the report

**Subagent Prompt 模板** (English output):

```
You are a product strategy consultant. Perform a deep analysis of the following pain point and output a complete solution directly.

## Pain Point
{pain_point}

## Background
- What scenario does the user encounter this problem in?
- How do they currently solve it?
- Why are existing solutions inadequate?

## Please output the following

### 1. Solution Recommendations (select best 1-2 from 5-10 directions)
For each recommended solution, specify:
- Technical feasibility (High / Medium / Low)
- Implementation cost (High / Medium / Low)
- Whether similar products already exist (Yes / No / Partial)
- Potential market size (Large / Medium / Small)
- Pain point match score (1-5)

### 2. MVP Design (for the best solution)
- Core features (3-5 feature points)
- Target user persona (age, profession, scenario, willingness to pay)
- Validation methods (3 specific methods, e.g., Reddit post, Landing Page, user interviews)
- Monetization methods (subscription / one-time / ads / B2B)
- Estimated development timeline

### 3. Product Form Recommendation
- Product form (Web App / Browser Extension / Mobile App / Desktop / Service)
- Tech stack suggestions
- Seed user acquisition strategy (3 channels)
- Competitive analysis (2-3 closest products + differentiation advantage)

### 4. Risk Warnings
- 1-2 potential risks
```

### Step 4: Report Output (Assembled by main Agent)

**Goal**: Organize analysis results into a structured Markdown report

**Execution**:
- **Main agent assembles report directly using PythonRun or Write tool**, no subagent call
- Data sources: Step 1 statistics + Step 2 Top 15 pain point table + Step 3 deep analysis of 5 pain points

**报告模板** (English output for English communities):

```markdown
# Reddit Pain Point Analysis Report: r/{subreddit}

> Analysis Time: {datetime.now().isoformat()}
> Data Source: {excel_path}
> Posts Analyzed: {total_posts}
> High-Engagement Posts: {high_engagement_count}

---

## 1. Data Overview

### 1.1 Basic Statistics
- **Total Posts**: {total_posts}
- **Time Range**: {min_date} ~ {max_date}
- **Score Distribution**: Min={min_score}, Max={max_score}, Median={median_score}, Avg={avg_score}
- **Comments Distribution**: Min={min_comments}, Max={max_comments}, Median={median_comments}

### 1.2 Top 10 High-Engagement Posts
| Rank | Title | Score | Comments | Link |
|------|-------|-------|----------|------|
| 1 | ... | ... | ... | ... |
| ... | ... | ... | ... | ... |

---

## 2. Top 15 Pain Points Ranking

| Rank | Pain Point | Occurrences | Pain Intensity | Demand Breadth | Market Gap | Total Score | Evidence Posts |
|------|------------|-------------|----------------|----------------|------------|-------------|----------------|
| 1 | ... | ... | ... | ... | ... | ... | ... |
| ... | ... | ... | ... | ... | ... | ... | ... |

---

## 3. Top 5 Pain Points Deep Dive

### 3.1 Pain Point 1: {title} (Total Score: {score})

**Pain Point Description**: ...

**User Quotes** (from Reddit posts):
- "..."
- "..."

**Recommended Solution**: ...

**MVP Suggestions**:
- Core Features: ...
- Target User: ...
- Validation Methods: ...
- Monetization: ...
- Estimated Timeline: ...

**Product Form**: ...

**Competitive Analysis**: ...

**Risk Warnings**: ...

---

(Pain points 2-5 follow the same format)

## 4. Action Recommendations

### 4.1 Highest Priority Pain Point to Develop
**Recommendation**: Pain Point X — "{title}"

**Rationale**:
1. Highest pain intensity, users are emotionally charged
2. Broad demand, mentioned repeatedly across multiple posts
3. High market gap, existing solutions are inadequate
4. MVP implementation cost is controllable, validation cycle is short

### 4.2 Next Steps
1. **Immediate**: Reply in relevant Reddit posts to validate willingness to pay ("Would you pay for a tool that solves this?")
2. **This Week**: Build a Landing Page or prototype, collect emails
3. **Within Two Weeks**: Finalize product form based on feedback, start MVP development

### 4.3 Risk Warnings
- Potential risk 1: ...
- Potential risk 2: ...
```

**Output**:
- Save report to `reports/{subreddit}_painpoint_analysis_{timestamp}.md`
- Show report summary to user

## Performance Estimate (Optimized)

| Phase | Execution Method | Estimated Time |
|-------|-----------------|----------------|
| Step 1: Data Preprocessing | PythonRun (main agent) | 5-10 sec |
| Step 2: Pain Point Extraction + Clustering | 4 subagents **parallel** | 60-120 sec |
| Step 3: Solution Deep Dive | 5 subagents **parallel** | 60-120 sec |
| Step 4: Report Assembly | PythonRun / Write (main agent) | 5-10 sec |
| **Total** | | **2-4 minutes** |

> Original version with 27 serial calls could take 10-20 minutes. Optimized version uses at most 9 parallel subagents, keeping total time under 2-4 minutes.

## Subagent Calling Convention

All subagent calls must follow:

```
Agent(
    description="Extract pain points batch X",
    prompt="...",
    timeout=3600,        # Mandatory, prevents timeout
    subagent_type="coder"
)
```

**Parallel Call Example** (Step 2):
```
# Launch 4 subagents simultaneously, one per batch
agent_1 = Agent(description="Batch 1 pain point extraction", prompt=..., timeout=3600)
agent_2 = Agent(description="Batch 2 pain point extraction", prompt=..., timeout=3600)
agent_3 = Agent(description="Batch 3 pain point extraction", prompt=..., timeout=3600)
agent_4 = Agent(description="Batch 4 pain point extraction", prompt=..., timeout=3600)
# Wait for all to complete, then merge results
```

**Parallel Call Example** (Step 3):
```
# Launch 5 subagents simultaneously, one per pain point
agent_1 = Agent(description="Pain point 1 deep dive", prompt=..., timeout=3600)
agent_2 = Agent(description="Pain point 2 deep dive", prompt=..., timeout=3600)
agent_3 = Agent(description="Pain point 3 deep dive", prompt=..., timeout=3600)
agent_4 = Agent(description="Pain point 4 deep dive", prompt=..., timeout=3600)
agent_5 = Agent(description="Pain point 5 deep dive", prompt=..., timeout=3600)
# Wait for all to complete, then merge results
```

## Fallback Strategy (if parallel subagents still time out)

If the user's environment limits the number of parallel subagents, degrade in the following priority order:

1. **Step 2 Fallback**: Reduce batches to 2 (50 posts each), only analyze Top 50 high-engagement posts
2. **Step 3 Fallback**: Only analyze Top 3 pain points (instead of 5), or execute serially with timeout=3600 for each step
3. **Final Fallback**: Skip Step 3 solution deep-dive. Only output Step 2 pain point ranking table + data overview. Inform the user: "Due to large data volume, please perform deep analysis in batches."

## Scoring Criteria Quick Reference

| Dimension | High-Score Signals | Low-Score Signals |
|-----------|-------------------|-------------------|
| **Pain Intensity** | "frustrating", "annoying", "time-consuming", "hate", "drives me crazy", "nightmare", "impossible" | "nice to have", "would be cool", "maybe", "slightly" |
| **Demand Breadth** | Mentioned in multiple posts, high upvotes, many comments, "me too" replies, "same here" | Single post, low engagement, no resonance, 0 replies |
| **Market Gap** | "no tool for this", "I wish there was", "can't find anything", "currently using workaround", "nothing works" | User satisfied with existing solution, or mature solution already exists |

## Important Notes

1. **Avoid fake needs**: If a pain point only appears in 1 post with very low engagement, be cautious about ranking it high priority
2. **Distinguish pain points from nice-to-haves**: "Nice to have" ≠ pain point. A pain point is a problem users feel compelled to solve
3. **Validate before building**: MVP suggestions in the report are hypotheses. User validation is required before development investment
4. **Cultural context**: Reddit users are primarily from US/Europe. Consider cultural background differences in analysis
5. **Context limits**: If there are too many posts, prioritize high-engagement posts. Low-engagement posts serve as supplementary validation
