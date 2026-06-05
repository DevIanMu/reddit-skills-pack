---
name: reddit-data-collector
description: |
  一键采集指定 Reddit subreddit 的帖子及评论，导出结构化 Excel。
  使用 WebBridge 控制真实浏览器访问 Reddit 公开 JSON 端点，绕过反爬限制。
  触发方式："采集 r/{subreddit} 最近 {N} 条帖子" 或 "帮我抓取 Reddit {subreddit} 的数据"
---

# Reddit 数据采集 Skill

## 触发条件

用户表达以下意图时激活本 Skill：
- "采集 r/xxx 的帖子"
- "抓取 Reddit xxx 社区的数据"
- "导出 r/xxx 最近 N 条帖子到 Excel"
- "帮我收集 Reddit xxx 的用户讨论"

## 参数提取

从用户输入中提取以下参数：

| 参数 | 必填 | 默认值 | 提取规则 |
|------|------|--------|----------|
| subreddit | 是 | — | 用户提到的社区名称，去掉 r/ 前缀 |
| posts | 否 | 100 | 用户提到的数量，如"最近 50 条" → 50 |
| comments | 否 | 20 | 用户提到的评论数，如"每条采 10 条评论" → 10 |
| sort | 否 | hot | 用户提到的排序：hot/new/top/rising |
| output | 否 | `data/{subreddit}_{posts}.xlsx` | 用户指定的输出路径 |

## 前置检查

1. **WebBridge 健康检查**
   ```bash
   curl -s http://127.0.0.1:10086/status
   ```
   - 如果 `running: false` 或 `extension_connected: false`：
     - 提示用户："请确保 Kimi Desktop App 已打开，且浏览器扩展已启用。"
     - 终止执行

2. **参数校验**
   - `posts` 范围：1-100（Reddit JSON 端点单页 25 条，超过 100 需多次翻页，当前限制为 100）
   - `comments` 范围：0-50
   - `subreddit` 不能为空

## 核心采集流程

### Phase 1: 帖子列表采集

**目标**: 采集指定数量的帖子（默认 100 条，分 4 页，每页 25 条）

**步骤**:

1. **初始化变量**
   ```
   collected_posts = []      # 已采集的帖子列表
   after_token = None        # 翻页 token
   page = 0                  # 当前页码
   max_pages = ceil(posts / 25)   # 总页数
   ```

2. **循环翻页采集**（while page < max_pages）

   a. **构造 URL**
      ```
      url = f"https://www.reddit.com/r/{subreddit}.json?limit=25&sort={sort}"
      if after_token:
          url += f"&after={after_token}"
      ```

   b. **WebBridge 导航**
      ```bash
      curl -s -X POST http://127.0.0.1:10086/command \
        -H 'Content-Type: application/json' \
        -d '{"action":"navigate","args":{"url":"{url}","newTab":true},"session":"reddit-collect"}'
      ```

   c. **等待加载**（等待 1.5 秒确保页面完全加载）

   d. **Evaluate 提取 JSON 数据**
      ```bash
      curl -s -X POST http://127.0.0.1:10086/command \
        -H 'Content-Type: application/json' \
        -d '{
          "action": "evaluate",
          "args": {
            "code": "(() => { try { const data = JSON.parse(document.body.textContent); const posts = data.data.children.map(p => ({id: p.data.id, title: p.data.title, author: p.data.author, score: p.data.score, num_comments: p.data.num_comments, upvote_ratio: p.data.upvote_ratio, created_utc: p.data.created_utc, selftext: p.data.selftext, permalink: p.data.permalink, url: p.data.url, subreddit: p.data.subreddit})); return {success: true, posts: posts, after: data.data.after, total: data.data.children.length}; } catch(e) { return {success: false, error: e.message}; } })()"
          },
          "session": "reddit-collect"
        }'
      ```

   e. **解析结果**
      - 如果 `success: false`：记录错误，重试当前页（最多 2 次），仍失败则跳过该页
      - 将 `posts` 追加到 `collected_posts`
      - 更新 `after_token = result.after`
      - `page += 1`

   f. **翻页间隔**：等待 1.5 秒再请求下一页

3. **截断到目标数量**
   ```
   collected_posts = collected_posts[:posts]
   ```

4. **关闭 WebBridge session**
   ```bash
   curl -s -X POST http://127.0.0.1:10086/command \
     -H 'Content-Type: application/json' \
     -d '{"action":"close_session","session":"reddit-collect"}'
   ```

### Phase 2: 高互动帖子筛选

**目标**: 从采集的帖子中筛选出高互动帖子，用于后续评论采集

**步骤**:

1. 使用 `reddit_json_parser.filter_high_engagement_posts(collected_posts, min_comments=10)`
2. 得到 `high_engagement_posts` 列表
3. 向用户报告："已采集 {len(collected_posts)} 条帖子，其中 {len(high_engagement_posts)} 条为高互动帖子，将采集这些帖子的评论。"

### Phase 3: 评论采集（可选）

**触发条件**: `comments > 0` 且 `high_engagement_posts` 非空

**步骤**:

1. **初始化**
   ```
   comments_map = {}   # {post_id: [comment, ...]}
   ```

2. **遍历高互动帖子**

   a. **构造评论 URL**
      ```
      url = f"https://www.reddit.com/comments/{post_id}.json?limit={comments}"
      ```

   b. **WebBridge 导航**（复用或新建 session，建议新建 `reddit-comments` session）

   c. **Evaluate 提取评论 JSON**
      ```bash
      curl -s -X POST http://127.0.0.1:10086/command \
        -H 'Content-Type: application/json' \
        -d '{
          "action": "evaluate",
          "args": {
            "code": "(() => { try { const data = JSON.parse(document.body.textContent); const comments = data[1].data.children.map(c => ({author: c.data.author, body: c.data.body, score: c.data.score, created_utc: c.data.created_utc, replies: c.data.replies && typeof c.data.replies === object ? c.data.replies.data.children.length : 0})).filter(c => c.body); return {success: true, comments: comments, total: comments.length}; } catch(e) { return {success: false, error: e.message}; } })()"
          },
          "session": "reddit-comments"
        }'
      ```

   d. **解析结果**
      - 如果成功：将评论存入 `comments_map[post_id]`
      - 如果失败：记录警告，继续下一个帖子

   e. **间隔**：每条帖子评论采集后等待 1.0 秒

3. **关闭 WebBridge session**

### Phase 4: 数据组装与 Excel 导出

**步骤**:

1. **合并评论到帖子**
   ```python
   import sys
   import os
   sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))
   from skills.reddit_data_collector.reddit_json_parser import merge_comments_into_posts
   posts_with_comments = merge_comments_into_posts(collected_posts, comments_map)
   ```

2. **导出 Excel**
   ```python
   from skills.reddit_data_collector.reddit_json_parser import posts_to_excel
   output_path = posts_to_excel(posts_with_comments, output_path)
   ```

3. **向用户报告结果**
   ```
   "✅ 采集完成！
   - 社区: r/{subreddit}
   - 帖子数: {len(collected_posts)}
   - 高互动帖子: {len(high_engagement_posts)}
   - 评论采集: {len(comments_map)} 个帖子
   - 输出文件: {output_path}"
   ```

## 错误处理

| 场景 | 处理 |
|------|------|
| WebBridge daemon 未运行 | 提示用户启动 Kimi Desktop App，终止 |
| 导航后页面非 JSON | 重试 2 次，仍失败则跳过该页 |
| 某页帖子提取失败 | 记录警告，继续翻页 |
| 高互动帖子评论采集失败 | 记录警告，该帖子跳过评论采集 |
| 采集 0 条帖子 | 提示用户检查 subreddit 名称是否正确 |

## 性能预估

| 阶段 | 预估耗时 |
|------|----------|
| 100 条帖子（4 页） | 30-60 秒 |
| 20 条高互动帖子评论 | 30-60 秒 |
| Excel 导出 | < 5 秒 |
| **总计** | **1-2 分钟** |

## 输出示例

用户输入："采集 r/parenting 最近 100 条帖子，导出到 data/parenting.xlsx"

Agent 执行后输出：
```
✅ 采集完成！
- 社区: r/parenting
- 帖子数: 100
- 高互动帖子: 28
- 评论采集: 28 个帖子
- 输出文件: D:\Projects\reddit\data\parenting_100.xlsx
```
