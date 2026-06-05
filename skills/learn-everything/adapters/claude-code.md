# Claude Code 适配

加载 `prompts/core.md` 的完整教学逻辑。以下为 CC 专用指令。

## 文件操作

- 读文件：`Read` 工具
- 写文件：`Write` 工具（追加 transcript.jsonl 时：先 Read → 末尾 append 一行 JSON → Write 回去）
- transcript.jsonl 每行一条 JSON，`time` 用当前精确时间（ISO 8601 到秒，如 `2026-06-05T14:30:05`）
- 抓网页：`WebFetch`
- 搜索补充：`WebSearch`

## 学习目录结构

`{learning_dir}/{主题名}/`

```
{主题名}/
├── 00-课程概述.md        ← 课程全景（备课产出）
├── 01-{标题}.md          ← 完整教材（备课产出）
├── 02-{标题}.md          ← ...
├── progress.md           ← phase + 图谱状态 + 评分
├── transcript.jsonl      ← 互动记录（实时追加）
└── notes.md              ← 自动总结 + 手动笔记
```

## Phase 流程（详见 core.md）

### onboarding
1. 问：学什么？（链接/路径/文本/名词都行）
2. 展示 6 位老师，用户选
3. 分析内容 → 出知识图谱（标题 + 一句话概要）
4. 用户确认（可指定起点、跳过某些节、要求调整）
5. → phase = preparing

### preparing
一次性写全部教材：
- `00-课程概述.md`：是什么、为什么学、知识图谱、学习范围、信息来源
- `01..N-{标题}.md`：完整中性知识（不管老师风格，写完整版）
- 全部写完 → phase = ready

### ready
展示 00-概述核心内容 → 问"开始第一课吗？" → 确认 → phase = learning

### learning
上课循环。每个节点：
1. Read 本节教材，确认教法（按老师风格决定讲多深）
2. 讲解 → 自评 ⏸ → 费曼 ⏸（提醒可跳过） → 测验 ⏸ → 评分
3. 存档（transcript 实时写，notes 节后总结，有更好类比写回教材）
4. **必须问**"继续下一课？" ⏸

### done
全部 completed，展示总结。

## 中断恢复
重新打开时 Read progress.md → 根据 phase 判断：
- preparing 中断 → 检查空壳文件 → 补写
- ready/learning 中断 → 展示进度 → 问是否继续
- TL;DR skimmed 节点 + 用户切老师 → 重讲

## 切换老师
用户说"换老师" → teacher_history 追加记录（from/to 秒级时间戳） → 从当前节点继续，风格切换但教材不变

## 对话指令

| 用户说 | 动作 |
|--------|------|
| "记个笔记"/`!note xxx` | 追加 notes.md |
| "知识图谱"/`!graph` | 展示图谱（标题 + 状态） |
| "跳过"/`!skip` | 跳过当前费曼或测验 |
| "进度"/`!status` | 显示 phase + 当前节点 + 完成率 |
| "换个老师"/`!teacher xxx` | 切换老师 |
| "复习"/`!review` | 触发间隔复习 |
| "问个问题"/`!ask xxx` | 回答，不扰教学节奏 |
| "结束"/`!done` | 保存进度，phase 保持 learning |
| "换目录"/`!dir xxx` | 更新 config.json |
