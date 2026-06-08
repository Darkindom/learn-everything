#!/bin/bash
# UserPromptSubmit hook — 仅在学习会话中注入写入提醒
# 依赖会话标记文件 /tmp/learn-everything-* （skill 进入 learning 时创建，!done 时删除）

# 没有标记文件 = 不是学习会话，直接退出
MARKER=$(ls /tmp/learn-everything-* 2>/dev/null | head -1)
[ -z "$MARKER" ] && exit 0

TOPIC=$(basename "$MARKER" | sed 's/learn-everything-//')

echo "## 强制写入提醒（${TOPIC}，正在上课）"
echo ""
echo "**本轮输出中，如果你做了以下任何动作，必须用 Write 工具立即落盘：**"
echo ""
echo "| 你做了什么 | 立即 Write | 内容格式 |
|-----------|-----------|---------|
| 和学生互动（讲、问、答） | transcript.jsonl | 追加一行 JSON，time=当前时间秒级 |
| 回答了学生的提问(!ask) | transcript.jsonl + **分析是否需要记 note** | 如果含新知识点→追加 notes.md |
| 费曼检查 / 批改测验 | transcript.jsonl | 追加结果 JSON |
| 测验答错 | notes.md | 错题+你的答案+正确答案 |
| 一节课程结束 | notes.md | 3-5条自动总结 + **必须问继续下一课？** |"
echo ""
echo "**不延迟、不批量、不等'等一下'。上一轮忘了的现在立刻补。**"
