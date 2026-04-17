#!/bin/bash
# Test: コンテキスト退避 → compactサマリー追記 → SessionStart フルフロー
# Usage: bash ~/.claude/scripts/test/hooks/test_compact_hooks.sh

set -uo pipefail
# Note: -e is intentionally omitted. This is a test runner;
# assertion failures should increment FAIL counter, not abort the script.

HOOKS_DIR="$HOME/.claude/scripts/hooks"
PROJECT_INFO_DIR="$HOME/.claude/project_info"

# --- テストヘルパー ---

PASS=0
FAIL=0
TEST_DIRS=()

setup_test_dir() {
  local dir
  dir=$(mktemp -d)
  mkdir -p "$dir/.claude"
  TEST_DIRS+=("$dir")
  echo "$dir"
}

cleanup() {
  for dir in "${TEST_DIRS[@]}"; do
    rm -rf "$dir"
  done
  # テストで作られたold/内のtmpエントリを掃除
  rm -rf "$PROJECT_INFO_DIR/old/tmp."* 2>/dev/null
  # テストで作られたlatest_cacheを掃除（残っていれば）
  rm -f "$PROJECT_INFO_DIR"/latest_cache_test_* 2>/dev/null
}
trap cleanup EXIT

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $label"
    ((PASS++))
  else
    echo "  FAIL: $label (expected='$expected', actual='$actual')"
    ((FAIL++))
  fi
}

assert_file_exists() {
  local label="$1" pattern="$2"
  if ls $pattern >/dev/null 2>&1; then
    echo "  PASS: $label"
    ((PASS++))
  else
    echo "  FAIL: $label (no file matching: $pattern)"
    ((FAIL++))
  fi
}

assert_file_not_exists() {
  local label="$1" pattern="$2"
  if ls $pattern >/dev/null 2>&1; then
    echo "  FAIL: $label (file still exists: $pattern)"
    ((FAIL++))
  else
    echo "  PASS: $label"
    ((PASS++))
  fi
}

assert_output_contains() {
  local label="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo "  PASS: $label"
    ((PASS++))
  else
    echo "  FAIL: $label (output does not contain: '$needle')"
    ((FAIL++))
  fi
}

assert_output_empty() {
  local label="$1" output="$2"
  if [ -z "$output" ]; then
    echo "  PASS: $label"
    ((PASS++))
  else
    echo "  FAIL: $label (expected empty, got: '$output')"
    ((FAIL++))
  fi
}

# --- テストケース ---

echo "=== Test 1: save-context-cache creates cache and marker ==="
TEST_DIR=$(setup_test_dir)
echo "{\"session_id\":\"test-1\",\"cwd\":\"$TEST_DIR\",\"trigger\":\"manual\"}" \
  | bash "$HOOKS_DIR/save-context-cache.sh"
RC=$?
assert_eq "exit code" "0" "$RC"
assert_file_exists "marker created" "$TEST_DIR/.claude/pjcache_marker_*"
assert_file_exists "cache created" "$PROJECT_INFO_DIR/latest_cache_*.log"

# IDを取得して後続で使う
MARKER=$(ls "$TEST_DIR/.claude/pjcache_marker_"* 2>/dev/null | head -1)
CACHE_ID=$(basename "$MARKER" | sed 's/pjcache_marker_//')
CACHE_FILE="$PROJECT_INFO_DIR/latest_cache_${CACHE_ID}.log"

echo ""
echo "=== Test 2: append-compact-summary appends summary to cache ==="
echo "{\"session_id\":\"test-1\",\"cwd\":\"$TEST_DIR\",\"trigger\":\"manual\",\"compact_summary\":\"Test summary content.\"}" \
  | bash "$HOOKS_DIR/append-compact-summary.sh"
RC=$?
assert_eq "exit code" "0" "$RC"
CACHE_CONTENT=$(cat "$CACHE_FILE")
assert_output_contains "summary appended" "Test summary content." "$CACHE_CONTENT"
assert_output_contains "has compact summary section" "## Compact Summary" "$CACHE_CONTENT"

echo ""
echo "=== Test 3: SessionStart injects cache (cache is newer) ==="
# pj管理ファイルを古い日付で作成
touch -t 202603200000 "$TEST_DIR/VISION.md"
touch -t 202603200000 "$TEST_DIR/DECISIONS.md"
touch -t 202603200000 "$TEST_DIR/PROGRESS.md"

OUTPUT=$(echo "{\"session_id\":\"test-start-1\",\"cwd\":\"$TEST_DIR\"}" \
  | bash "$HOOKS_DIR/session-start.sh")
RC=$?
assert_eq "exit code" "0" "$RC"
assert_output_contains "injects cache content" "Previous session context" "$OUTPUT"
assert_output_contains "contains summary" "Test summary content." "$OUTPUT"
assert_file_not_exists "marker removed" "$TEST_DIR/.claude/pjcache_marker_*"
assert_file_not_exists "cache moved from project_info" "$CACHE_FILE"
assert_file_exists "cache in old/" "$PROJECT_INFO_DIR/old/$(basename $TEST_DIR)/latest_cache_${CACHE_ID}_*.log"

echo ""
echo "=== Test 4: SessionStart skips stale cache (dev files newer) ==="
TEST_DIR2=$(setup_test_dir)
echo "{\"session_id\":\"test-2\",\"cwd\":\"$TEST_DIR2\",\"trigger\":\"auto\"}" \
  | bash "$HOOKS_DIR/save-context-cache.sh"
MARKER2=$(ls "$TEST_DIR2/.claude/pjcache_marker_"* 2>/dev/null | head -1)
CACHE_ID2=$(basename "$MARKER2" | sed 's/pjcache_marker_//')

# pj管理ファイルをcacheより後に作成
sleep 1
touch "$TEST_DIR2/VISION.md"
touch "$TEST_DIR2/DECISIONS.md"
touch "$TEST_DIR2/PROGRESS.md"

OUTPUT2=$(echo "{\"session_id\":\"test-start-2\",\"cwd\":\"$TEST_DIR2\"}" \
  | bash "$HOOKS_DIR/session-start.sh")
RC=$?
assert_eq "exit code" "0" "$RC"
assert_output_empty "no injection (stale cache)" "$OUTPUT2"
assert_file_not_exists "marker removed" "$TEST_DIR2/.claude/pjcache_marker_*"
assert_file_exists "stale cache still moved to old/" "$PROJECT_INFO_DIR/old/$(basename $TEST_DIR2)/latest_cache_${CACHE_ID2}_*.log"

echo ""
echo "=== Test 5: SessionStart with no marker (noop) ==="
TEST_DIR3=$(setup_test_dir)
OUTPUT3=$(echo "{\"session_id\":\"test-start-3\",\"cwd\":\"$TEST_DIR3\"}" \
  | bash "$HOOKS_DIR/session-start.sh")
RC=$?
assert_eq "exit code" "0" "$RC"
assert_output_empty "no output (no marker)" "$OUTPUT3"

echo ""
echo "=== Test 6: append-compact-summary without save-context-cache (fallback) ==="
TEST_DIR4=$(setup_test_dir)
echo "{\"session_id\":\"test-orphan\",\"cwd\":\"$TEST_DIR4\",\"trigger\":\"auto\",\"compact_summary\":\"Orphan summary.\"}" \
  | bash "$HOOKS_DIR/append-compact-summary.sh"
RC=$?
assert_eq "exit code" "0" "$RC"
assert_file_exists "fallback cache created" "$PROJECT_INFO_DIR/latest_cache_*.log"
assert_file_exists "fallback marker created" "$TEST_DIR4/.claude/pjcache_marker_*"

# クリーンアップ: fallbackで作られたcacheも掃除
FALLBACK_MARKER=$(ls "$TEST_DIR4/.claude/pjcache_marker_"* 2>/dev/null | head -1)
if [ -n "$FALLBACK_MARKER" ]; then
  FALLBACK_ID=$(basename "$FALLBACK_MARKER" | sed 's/pjcache_marker_//')
  rm -f "$PROJECT_INFO_DIR/latest_cache_${FALLBACK_ID}.log"
fi

echo ""
echo "=============================="
echo "Results: $PASS passed, $FAIL failed"
echo "=============================="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
