#!/bin/bash
set -e

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)/skills/learn-everything"
CLAUDE_SKILLS="$HOME/.claude/skills"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
HOOK_SCRIPT="$SKILL_DIR/hooks/check-transcript.sh"

echo "==> Learn Everything — 安装 =="
echo ""

# 1. 软链接技能
echo "[1/4] 链接技能到 $CLAUDE_SKILLS"
mkdir -p "$CLAUDE_SKILLS"
if [ -L "$CLAUDE_SKILLS/learn-everything" ] || [ -d "$CLAUDE_SKILLS/learn-everything" ]; then
    echo "  已存在，跳过"
else
    ln -s "$SKILL_DIR" "$CLAUDE_SKILLS/learn-everything"
    echo "  完成"
fi

# 2. 处理 config.json
echo "[2/4] 检查 config.json"
if [ ! -f "$SKILL_DIR/config.json" ]; then
    cp "$SKILL_DIR/config.sample.json" "$SKILL_DIR/config.json"
    echo "  已从 config.sample.json 创建，请编辑 learning_dir"
else
    echo "  已存在，跳过"
fi

# 3. 注入 hooks 到 settings.json
echo "[3/4] 注入 hooks 到 $CLAUDE_SETTINGS"
if [ ! -f "$CLAUDE_SETTINGS" ]; then
    echo '{}' > "$CLAUDE_SETTINGS"
fi

# 用 python 安全合并
python3 - "$HOOK_SCRIPT" "$CLAUDE_SETTINGS" << 'PYEOF'
import json, sys

hook_script = sys.argv[1]
settings_path = sys.argv[2]

with open(settings_path) as f:
    settings = json.load(f)

hooks = settings.setdefault("hooks", {})

# --- UserPromptSubmit hook ---
us = hooks.setdefault("UserPromptSubmit", [])

already = any(
    h2.get("command", "").endswith("check-transcript.sh")
    for entry in us
    for h2 in entry.get("hooks", [])
)

if not already:
    us.append({
        "matcher": "",
        "hooks": [
            {
                "type": "command",
                "command": f"bash {hook_script}"
            }
        ]
    })
    print("  UserPromptSubmit hook 已注册")
else:
    print("  UserPromptSubmit hook 已存在，跳过")

# --- Stop hook (安全网) ---
stop_script = hook_script.replace("check-transcript.sh", "check-notes-sync.sh")
st = hooks.setdefault("Stop", [])

already_stop = any(
    h2.get("command", "").endswith("check-notes-sync.sh")
    for entry in st
    for h2 in entry.get("hooks", [])
)

if not already_stop:
    st.append({
        "matcher": "",
        "hooks": [
            {
                "type": "command",
                "command": f"bash {stop_script}"
            }
        ]
    })
    print("  Stop hook 已注册")
else:
    print("  Stop hook 已存在，跳过")

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PYEOF

echo ""
echo "==> 安装完成！"
echo "  配置文件:  $SKILL_DIR/config.json"
echo "  技能目录:  $CLAUDE_SKILLS/learn-everything"
echo "  Hook 注册: $CLAUDE_SETTINGS"
echo ""
echo "  如果还没有设置学习目录，编辑 config.json 中的 learning_dir。"
