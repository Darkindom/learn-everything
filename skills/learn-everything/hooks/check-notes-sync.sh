#!/bin/bash
# Stop hook — 学习会话的安全网。在 Claude 停止响应后检查笔记是否跟上。
# 如果 transcript.jsonl 更新了但 notes.md 落后，注入强力提醒到下一轮。

MARKER=$(ls /tmp/learn-everything-* 2>/dev/null | head -1)
[ -z "$MARKER" ] && exit 0

TOPIC=$(basename "$MARKER" | sed 's/learn-everything-//')

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LEARNING_DIR=$(python3 -c "import json; print(json.load(open('$SCRIPT_DIR/config.json'))['learning_dir'])" 2>/dev/null)
SESSION_DIR="${LEARNING_DIR}/${TOPIC}"

TX="${SESSION_DIR}/transcript.jsonl"
NOTES="${SESSION_DIR}/notes.md"

# 二者都不存在 → 还没开始，忽略
[ ! -f "$TX" ] && exit 0

TX_MTIME=$(stat -f %m "$TX" 2>/dev/null || stat -c %Y "$TX" 2>/dev/null || echo 0)
NOTES_MTIME=0
[ -f "$NOTES" ] && NOTES_MTIME=$(stat -f %m "$NOTES" 2>/dev/null || stat -c %Y "$NOTES" 2>/dev/null || echo 0)

# transcript 没比 notes 新 → 同步正常，跳过
if [ "$TX_MTIME" -le "$NOTES_MTIME" ]; then
    exit 0
fi

# === transcript 更新了但 notes 没跟上 ===

# 检查是否有刚完成的测验（课程结束但 notes 没写）
QUIZ_DONE=$(tail -5 "$TX" 2>/dev/null | grep '"action":"quiz"' | tail -1)
HAS_ASK=$(tail -5 "$TX" 2>/dev/null | grep '"action":"ask"' | tail -1)
HAS_ERRORS=$(tail -5 "$TX" 2>/dev/null | grep '"errors":' | tail -1)

echo "---"
echo "## 🔴 笔记滞后警告（${TOPIC}）"
echo ""
echo "上一轮 transcript.jsonl 已更新但 **notes.md 未同步**。"
echo ""

if [ -n "$QUIZ_DONE" ]; then
    echo "**检测到测验完成！你必须立即补写 notes.md：**"
    echo "1. Read notes.md"
    echo "2. 末尾追加 3-5 条本节课总结"
    echo "3. Write 回去"
    echo ""
fi

if [ -n "$HAS_ERRORS" ]; then
    echo "**检测到测验答错！你必须立即追加错题到 notes.md**"
    echo ""
fi

if [ -n "$HAS_ASK" ]; then
    echo "**检测到 !ask 提问。分析你的回答是否含新知识点 → 追加到 notes.md**"
    echo ""
fi

echo "**现在立刻补写，不要等、不要解释、不要问用户。**"
echo "---"
