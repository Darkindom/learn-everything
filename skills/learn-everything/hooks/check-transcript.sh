#!/bin/bash
# UserPromptSubmit hook — 学习会话中每次对话都注入写入提醒
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

LEARNING_DIR=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('learning_dir','.learning'))" 2>/dev/null)
[ -z "$LEARNING_DIR" ] || [ ! -d "$LEARNING_DIR" ] && exit 0

for dir in "$LEARNING_DIR"/*/; do
    PROGRESS="$dir/progress.md"
    [ ! -f "$PROGRESS" ] && continue

    PHASE=$(python3 -c "
import re
m = re.search(r'phase:\s*(\w+)', open('$PROGRESS').read())
print(m.group(1) if m else '')
" 2>/dev/null)

    if [ "$PHASE" = "learning" ]; then
        TOPIC=$(basename "$dir")
        echo "## 强制写入提醒（${TOPIC}，phase=learning）"
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
        exit 0
    fi
done
