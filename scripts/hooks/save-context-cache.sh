#!/bin/bash
# コンテキスト退避フック: コンテキストが失われるタイミングで作業状態をlatest_cacheとして保存
# 呼び出し元: PreCompact, SessionEnd
# stdin: JSON { session_id, cwd, trigger, ... }
#
# 既存マーカーがあればそのIDを再利用し追記。なければ新規作成。
#
# 生成物:
#   ~/.claude/project_info/latest_cache_{ID}.log  — 作業状態スナップショット
#   {cwd}/.claude/pjcache_marker_{ID}             — プロジェクト側マーカー（0B）

set -euo pipefail

START_MS=$(($(date +%s) * 1000 + $(date +%N 2>/dev/null | head -c3 || echo 0)))

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "unknown"')
TIMESTAMP=$(date "+%Y-%m-%dT%H:%M:%S")

PROJECT_INFO_DIR="$HOME/.claude/project_info"
MARKER_DIR="$CWD/.claude"
mkdir -p "$PROJECT_INFO_DIR" "$MARKER_DIR"

# 既存マーカー探索 → あればID再利用、なければ新規生成
EXISTING_MARKER=$(ls "$MARKER_DIR"/pjcache_marker_* 2>/dev/null | head -1 || true)

if [ -n "$EXISTING_MARKER" ]; then
  CACHE_ID=$(basename "$EXISTING_MARKER" | sed 's/pjcache_marker_//')
  CACHE_FILE="$PROJECT_INFO_DIR/latest_cache_${CACHE_ID}.log"
  IS_NEW=false
else
  CACHE_ID=$(head -c 4 /dev/urandom | xxd -p)
  CACHE_FILE="$PROJECT_INFO_DIR/latest_cache_${CACHE_ID}.log"
  MARKER_FILE="$MARKER_DIR/pjcache_marker_${CACHE_ID}"
  touch "$MARKER_FILE"
  IS_NEW=true
fi

GIT_BRANCH=$(cd "$CWD" 2>/dev/null && git branch --show-current 2>/dev/null || echo "(not a git repo)")
GIT_DIFF_STAT=$(cd "$CWD" 2>/dev/null && git diff --stat 2>/dev/null || echo "(not a git repo)")

if [ "$IS_NEW" = true ]; then
  # 新規: フロントマター付きで作成
  cat > "$CACHE_FILE" <<EOF
---
session_id: ${SESSION_ID}
cwd: ${CWD}
trigger: ${TRIGGER}
timestamp: ${TIMESTAMP}
cache_id: ${CACHE_ID}
branch: ${GIT_BRANCH}
---

# Latest Cache (Context Snapshot)

## Context (${TRIGGER} @ ${TIMESTAMP})
- Working Directory: ${CWD}
- Branch: ${GIT_BRANCH}
- Trigger: ${TRIGGER}

## Uncommitted Changes
${GIT_DIFF_STAT}
EOF
else
  # 追記: セパレータ付きで追記
  cat >> "$CACHE_FILE" <<EOF

---

## Context (${TRIGGER} @ ${TIMESTAMP})
- Working Directory: ${CWD}
- Branch: ${GIT_BRANCH}
- Trigger: ${TRIGGER}

## Uncommitted Changes
${GIT_DIFF_STAT}
EOF
fi

# 実行時間を計測してフロントマターに追記（新規時のみ）
END_MS=$(($(date +%s) * 1000 + $(date +%N 2>/dev/null | head -c3 || echo 0)))
DURATION_MS=$((END_MS - START_MS))
if [ "$IS_NEW" = true ]; then
  sed -i "s/^branch: .*/&\nduration_ms: ${DURATION_MS}/" "$CACHE_FILE"
fi

exit 0
