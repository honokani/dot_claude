#!/bin/bash
# 会話サマリー追記フック: compact_summaryまたはtranscriptから会話内容をlatest_cacheに追記
# 呼び出し元: PostCompact, SessionEnd
# stdin: JSON { session_id, transcript_path, cwd, trigger, compact_summary(PostCompactのみ), ... }

set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "unknown"')
COMPACT_SUMMARY=$(echo "$INPUT" | jq -r '.compact_summary // ""')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# サマリー取得: compact_summaryがあればそれを使い、なければtranscriptから抽出
if [ -n "$COMPACT_SUMMARY" ] && [ "$COMPACT_SUMMARY" != "null" ]; then
  SUMMARY="$COMPACT_SUMMARY"
  SUMMARY_TYPE="compact"
elif [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  # transcriptから直近のuser/assistantテキストを抽出
  SUMMARY=$(tail -200 "$TRANSCRIPT_PATH" | jq -r '
    select(.type == "user" or .type == "assistant") |
    if .type == "user" then
      (.message.content |
        if type == "string" then "USER: " + .[:200]
        else [.[] | select(.type == "text") | .text[:200]] | if length > 0 then "USER: " + join(" ") else empty end
        end)
    elif .type == "assistant" then
      ([.message.content[] | select(.type == "text") | .text[:200]] |
        if length > 0 then "ASSISTANT: " + join(" ")
        else empty end)
    else empty end
  ' 2>/dev/null | tail -30)
  SUMMARY_TYPE="transcript-tail"
else
  SUMMARY="(no summary available)"
  SUMMARY_TYPE="none"
fi

PROJECT_INFO_DIR="$HOME/.claude/project_info"

# マーカーからIDを取得して対応するlatest_cacheに追記
MARKER_DIR="$CWD/.claude"
MARKER=$(ls "$MARKER_DIR"/pjcache_marker_* 2>/dev/null | head -1 || true)

if [ -n "$MARKER" ]; then
  CACHE_ID=$(basename "$MARKER" | sed 's/pjcache_marker_//')
  CACHE_FILE="$PROJECT_INFO_DIR/latest_cache_${CACHE_ID}.log"

  if [ -f "$CACHE_FILE" ]; then
    cat >> "$CACHE_FILE" <<EOF

## Session Summary (${SUMMARY_TYPE})
${SUMMARY}
EOF
  fi
else
  # マーカーが無い場合（save-context-cacheが失敗した等）: 単独でcache作成
  CACHE_ID=$(head -c 4 /dev/urandom | xxd -p)
  TIMESTAMP=$(date "+%Y-%m-%dT%H:%M:%S")
  mkdir -p "$PROJECT_INFO_DIR" "$MARKER_DIR"

  cat > "$PROJECT_INFO_DIR/latest_cache_${CACHE_ID}.log" <<EOF
---
session_id: ${SESSION_ID}
cwd: ${CWD}
trigger: ${TRIGGER}
timestamp: ${TIMESTAMP}
cache_id: ${CACHE_ID}
type: ${SUMMARY_TYPE}-only
---

# Latest Cache (${SUMMARY_TYPE})

## Session Summary (${SUMMARY_TYPE})
${SUMMARY}
EOF

  touch "$MARKER_DIR/pjcache_marker_${CACHE_ID}"
fi

exit 0
