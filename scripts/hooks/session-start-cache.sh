#!/bin/bash
# SessionStart Hook: latest_cacheの鮮度判定と注入
# stdin: JSON { session_id, transcript_path, cwd, ... }
#
# 1. $(pwd)/.claude/pjcache_marker_* を探す
# 2. IDを抽出し latest_cache_{id}.log を確認
# 3. VISION.md/DECISIONS.md/PROGRESS.md の更新日と比較
# 4. cacheの方が新しければ stdout に出力（Claudeのコンテキストに注入）
# 5. old/ に移動し、マーカー削除

set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')

MARKER_DIR="$CWD/.claude"
PROJECT_INFO_DIR="$HOME/.claude/project_info"
OLD_DIR="$PROJECT_INFO_DIR/old"

# マーカー探索（set -eの下でもls失敗で落ちないようにする）
MARKER=$(ls "$MARKER_DIR"/pjcache_marker_* 2>/dev/null | head -1 || true)
if [ -z "$MARKER" ]; then
  exit 0
fi

CACHE_ID=$(basename "$MARKER" | sed 's/pjcache_marker_//')
CACHE_FILE="$PROJECT_INFO_DIR/latest_cache_${CACHE_ID}.log"

if [ ! -f "$CACHE_FILE" ]; then
  # cacheファイルが無い: マーカーだけ掃除して終了
  rm -f "$MARKER"
  exit 0
fi

# 鮮度判定: pj管理3ファイルの最大更新日 vs latest_cacheの更新日
# stat -c %Y でUNIXタイムスタンプを取得（Git Bash対応）
get_mtime() {
  if [ -f "$1" ]; then
    stat -c %Y "$1" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

CACHE_MTIME=$(get_mtime "$CACHE_FILE")
VISION_MTIME=$(get_mtime "$CWD/VISION.md")
DECISIONS_MTIME=$(get_mtime "$CWD/DECISIONS.md")
PROGRESS_MTIME=$(get_mtime "$CWD/PROGRESS.md")

# 3ファイルの最大値
MAX_DEV_MTIME=$VISION_MTIME
[ "$DECISIONS_MTIME" -gt "$MAX_DEV_MTIME" ] && MAX_DEV_MTIME=$DECISIONS_MTIME
[ "$PROGRESS_MTIME" -gt "$MAX_DEV_MTIME" ] && MAX_DEV_MTIME=$PROGRESS_MTIME

# 注入判定
if [ "$CACHE_MTIME" -ge "$MAX_DEV_MTIME" ]; then
  # cacheの方が新しい or 同時 → 内容を stdout に出力（Claudeに注入）
  echo "=== Previous session context (latest_cache) ==="
  cat "$CACHE_FILE"
  echo "=== End of latest_cache ==="
fi

# old/ に移動
# プロジェクト名をcwdの末尾ディレクトリ名から取得
PJ_NAME=$(basename "$CWD")
mkdir -p "$OLD_DIR/$PJ_NAME"
TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
mv "$CACHE_FILE" "$OLD_DIR/$PJ_NAME/latest_cache_${CACHE_ID}_${TIMESTAMP}.log"

# マーカー削除
rm -f "$MARKER"

exit 0
