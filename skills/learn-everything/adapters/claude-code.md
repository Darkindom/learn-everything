# Claude Code 适配

加载 `prompts/core.md` 的教学逻辑。以下为 CC 专用指令。

## 文件操作

- 读文件：`Read` 工具
- 写文件：`Write` 工具（追加 transcript.jsonl 时：先 Read → 末尾 append 一行 JSON → Write 回去）
- transcript.jsonl 每行一条 JSON，`time` 用当前精确时间（ISO 8601 到秒，如 `2026-06-05T14:30:05`）
- 抓网页：`WebFetch`
- 搜索补充：`WebSearch`

## 学习目录

`{learning_dir}/{主题名}/`

```
{主题名}/
├── progress.md          ← frontmatter JSON（状态、图谱、评分）
├── notes.md             ← 自动总结 + 手动笔记
├── transcript.jsonl        ← 互动记录（实时追加）
├── 01-{标题}.md         ← 第 1 节课教材
├── 02-{标题}.md         ← 第 2 节课教材
└── ...
```

## 会话启动

### 新主题
1. 问：学什么？（链接/路径/文本/名词都行）
2. 展示老师选项，让用户选
3. 分析内容，推荐图谱策略，让用户确认
4. 创建目录 + progress.md/notes.md/transcript.jsonl + 预建空课程文件

### 已有主题
1. 读 progress.md，展示进度 + 上次在哪
2. 快速回顾上一节内容（≤3 句话）
3. 问：继续上次的？还是重新来？

### TL;DR 特殊情况
- 用户之前用摘要员扫过，现在回来 → 检测 graph 中全是 skimmed
- 按内容类型推荐深入老师：
  - 代码项目 → 结对编程
  - 技术工具/框架 → 实战派
  - 论文/理论 → 教授
  - 官方文档 → 文档向导

## 对话指令

| 用户说 | 动作 |
|--------|------|
| "记个笔记"/`!note xxx` | 追加 notes.md |
| "知识图谱"/`!graph` | ASCII 树 + 提示可用 Excalidraw |
| "跳过"/`!skip` | 跳过当前费曼或测验 |
| "进度"/`!status` | 显示摘要 |
| "换个老师"/`!teacher xxx` | 切换老师，teacher_history 追加 `{"teacher":"xxx","from":"2026-06-05T14:30:05","to":null}`，旧老师 to 填当前时间 |
| "复习"/`!review` | 触发间隔复习 |
| "问个问题"/`!ask xxx` | 回答，不扰教学节奏 |
| "结束"/`!done` | 保存进度 |
| "换目录"/`!dir xxx` | 更新 config.json |