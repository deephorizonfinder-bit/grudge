#!/usr/bin/env bash
# 每次 Claude Code 会话结束时,评估有没有产生值得跨会话复用的经验(正向/负向)。
# 没有 → 什么都不做;有 → 写一张经验卡到 Obsidian。正向同类满3张自动判为可复用。

# ↓↓↓ 只改这一行:你的 Obsidian vault 绝对路径 ↓↓↓
VAULT="D:/Vs code/Obsidian-Vault"
# ↑↑↑ ─────────────────────────────────────── ↑↑↑

[ -n "${EXPERIENCE_HOOK_RUNNING:-}" ] && exit 0          # 防递归
command -v jq >/dev/null 2>&1 || exit 0                  # 没装 jq 就安静退出
CLAUDE_BIN=$(command -v claude || echo "")               # 找不到 claude 就退出(可改成绝对路径)
[ -z "$CLAUDE_BIN" ] && exit 0

INPUT=$(cat)
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty')
# 调试:首跑若没生成卡片,取消下一行,跑一次后看这个文件里的真实字段名
# printf '%s' "$INPUT" > /tmp/cc-sessionend.json
[ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || exit 0

PROJECT=$(basename "${CLAUDE_PROJECT_DIR:-$PWD}")
DIR="$VAULT/经验/$PROJECT"
mkdir -p "$DIR" || exit 0

CONVO=$(tail -c 60000 "$TRANSCRIPT")                     # 取会话尾部,避免过长
read -r -d '' PROMPT <<EOF || true
下面是一次 Claude Code 会话记录。判断它是否产生了【值得跨会话复用的经验】。
经验的核心是"重复性技能的标准化":遇到X场景,执行Y动作,不是抽象建议。
经验分两类:正向(有效做法/可复用模式)、负向(踩过的坑/应避免的做法)。
正向经验中,若本次会话产生了可复用的脚本、工具或配置文件,请在files字段填写具体路径——这类经验视为"工具类",下次遇到同类需求直接复用,禁止重写。
若没有值得留存的经验,只输出一个词:NONE
否则只输出一个 JSON(无多余文字、无 markdown 围栏):
{"polarity":"positive 或 negative","tag":"稳定的短标签,用连字符,例如 上下文交接","title":"一句话标题","gist":"一句话说清这条经验","detail":"2-4句:什么情况下、怎么做或别怎么做、为什么","files":"若是工具类,填具体文件路径;知识类留空"}

会话记录:
$CONVO
EOF

OUT=$(EXPERIENCE_HOOK_RUNNING=1 "$CLAUDE_BIN" -p "$PROMPT" 2>/dev/null) || exit 0
[ -z "$OUT" ] && exit 0
printf '%s' "$OUT" | grep -qx "NONE" && exit 0           # 评估认为没有经验 → 收工

POL=$(printf '%s' "$OUT" | jq -r '.polarity // empty' 2>/dev/null)
TAG=$(printf '%s' "$OUT" | jq -r '.tag // empty' 2>/dev/null)
[ -n "$POL" ] && [ -n "$TAG" ] || exit 0                 # 解析失败 → 不写脏数据

TITLE=$(printf '%s' "$OUT" | jq -r '.title // ""')
GIST=$(printf '%s'  "$OUT" | jq -r '.gist // ""')
DETAIL=$(printf '%s' "$OUT" | jq -r '.detail // ""')
FILES=$(printf '%s' "$OUT" | jq -r '.files // ""')
NOW=$(date +%Y-%m-%d); ID=$(date +%Y%m%d-%H%M%S)
SAFE_TAG=$(printf '%s' "$TAG" | sed 's/[\/\\:*?"<>| ]/-/g')
[ -n "$FILES" ] && TYPE="tool" || TYPE="knowledge"

cat > "$DIR/${SAFE_TAG}-${ID}.md" <<EOF
---
title: "$TITLE"
project: $PROJECT
polarity: $POL
tag: $TAG
type: $TYPE
status: candidate
created: $NOW
source: auto
---
> $GIST

$DETAIL

相关:$FILES
EOF

# 正向经验:同 tag 满3张 → 自动判为 reusable 并写入手册(我已选:满3次自动)
if [ "$POL" = "positive" ]; then
  MATCHES=$(grep -rl "^tag: $TAG$" "$DIR" 2>/dev/null | while read -r f; do
    grep -q "^polarity: positive$" "$f" && echo "$f"; done)
  N=$(printf '%s\n' "$MATCHES" | grep -c .)
  if [ "$N" -ge 3 ]; then
    printf '%s\n' "$MATCHES" | while read -r f; do
      [ -n "$f" ] && sed -i.bak 's/^status: .*/status: reusable/' "$f" && rm -f "$f.bak"
    done
    PB="$DIR/_playbook.md"
    [ -f "$PB" ] || printf '# %s · 可复用经验手册\n' "$PROJECT" > "$PB"
    if ! grep -q "<!--tag:$TAG-->" "$PB" 2>/dev/null; then
      if [ -n "$FILES" ]; then
        cat >> "$PB" <<EOF

## [TOOL] $TITLE <!--tag:$TAG-->
**触发条件**: $GIST
**已有资产**: $FILES
**强制操作**: $DETAIL
EOF
      else
        cat >> "$PB" <<EOF

## $TITLE <!--tag:$TAG-->
$GIST
$DETAIL
EOF
      fi
    fi
  fi
fi
exit 0
