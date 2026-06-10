#!/bin/bash
# UserPromptSubmit hook — 学习会话中强制写入检查
# 依赖会话标记文件 /tmp/learn-everything-* （skill 进入 learning 时创建，!done 时删除）

MARKER=$(ls /tmp/learn-everything-* 2>/dev/null | head -1)
[ -z "$MARKER" ] && exit 0

TOPIC=$(basename "$MARKER" | sed 's/learn-everything-//')

# 尝试读取 config.json 获取 learning_dir
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LEARNING_DIR=$(python3 -c "import json; print(json.load(open('$SCRIPT_DIR/config.json'))['learning_dir'])" 2>/dev/null)
SESSION_DIR="${LEARNING_DIR}/${TOPIC}"

TX="${SESSION_DIR}/transcript.jsonl"
NOTES="${SESSION_DIR}/notes.md"

echo "## 强制写入检查（${TOPIC}，正在上课）"
echo ""

# 检查 transcript.jsonl vs notes.md 的修改时间
NEED_NOTES=0
if [ -f "$TX" ] && [ -f "$NOTES" ]; then
    TX_MTIME=$(stat -f %m "$TX" 2>/dev/null || stat -c %Y "$TX" 2>/dev/null)
    NOTES_MTIME=$(stat -f %m "$NOTES" 2>/dev/null || stat -c %Y "$NOTES" 2>/dev/null)
    if [ "$TX_MTIME" -gt "$NOTES_MTIME" ]; then
        NEED_NOTES=1
    fi
elif [ -f "$TX" ] && [ ! -f "$NOTES" ]; then
    NEED_NOTES=1
fi

# 检查最近 N 行 transcript 中是否有问题(!ask)但未记笔记
HAS_UNANSWERED_Q=0
if [ -f "$TX" ]; then
    # 取最近 10 行中的 ask 类型
    RECENT_ASKS=$(tail -10 "$TX" 2>/dev/null | grep '"action":"ask"' | wc -l | tr -d ' ')
    if [ "$RECENT_ASKS" -gt 0 ] 2>/dev/null; then
        HAS_UNANSWERED_Q=1
    fi
fi

# 检查是否有完整课程结束但 notes 没跟上
HAS_COMPLETED=0
if [ -f "$TX" ]; then
    COMPLETED=$(tail -10 "$TX" 2>/dev/null | grep '"action":"quiz"' | grep '"result":"passed"' | wc -l | tr -d ' ')
    if [ "$COMPLETED" -gt 0 ] 2>/dev/null; then
        HAS_COMPLETED=1
    fi
fi

# === 生成针对性提醒 ===

if [ "$NEED_NOTES" -eq 1 ]; then
    echo "**⚠️ 检测到 transcript.jsonl 已更新但 notes.md 落后！你必须立刻补写：**"
    echo ""
fi

if [ "$HAS_UNANSWERED_Q" -eq 1 ]; then
    echo "**🔴 上一轮回答了学生提问 (!ask)！你必须立即做这两件事：**"
    echo "1. 用 Read 读 transcript.jsonl → 确认问题已追加一行 JSON"
    echo "2. **分析回答是否含新知识点** → 如果有，立即 Read notes.md → 末尾追加知识点 → Write 回去"
    echo ""
fi

if [ "$HAS_COMPLETED" -eq 1 ] && [ "$NEED_NOTES" -eq 1 ]; then
    echo "**🔴 上一轮完成了测验！一堂课结束了！你必须立即：**"
    echo "1. Read notes.md → 末尾追加 3-5 条自动总结 → Write 回去"
    echo "2. **必须问用户"继续下一课？"**"
    echo ""
fi

echo "**本轮输出中，如果你做了以下任何动作，必须用 Write 工具立即落盘：**"
echo ""
echo "| 你做了什么 | 立即 Write | 内容格式 |"
echo "|-----------|-----------|---------|"
echo "| 和学生互动（讲、问、答） | transcript.jsonl | 追加一行 JSON，time=当前时间秒级 |"
echo "| 回答了学生的提问(!ask) | transcript.jsonl + **分析是否需要记 note** | 如果含新知识点→追加 notes.md |"
echo "| 费曼检查 / 批改测验 | transcript.jsonl | 追加结果 JSON |"
echo "| 测验答错 | notes.md | 错题+你的答案+正确答案 |"
echo "| 一节课程结束 | notes.md | 3-5条自动总结 + **必须问继续下一课？** |"
echo ""
echo "**不延迟、不批量、不等'等一下'。上一轮忘了的现在立刻补。**"
