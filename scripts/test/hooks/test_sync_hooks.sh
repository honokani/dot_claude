#!/bin/bash
# Test: session-start-pull.sh / session-end-push.sh の 通常モード と read-only モード
# Usage: bash ~/.claude/scripts/test/hooks/test_sync_hooks.sh
#
# サンドボックス構成（ケースごとに独立）:
#   $sb/origin.git                 bare remote
#   $sb/other                      別環境役の clone（remote を進めるために使う）
#   $sb/home/git_clone/dot_claude  テスト対象 clone。HOME=$sb/home で hook を実行し、
#                                  ~/.claude/CLAUDE.md symlink が無いため hook の fallback パス解決を通す

set -uo pipefail
# Note: -e は意図的に外す（アサート失敗は FAIL カウント、スクリプトは継続）

HOOKS_DIR="$(cd "$(dirname "$0")/../../hooks" && pwd)"
# 実行環境の system/global git config（Git for Windows の autocrlf 等）に左右されないよう、テスト中は無効化
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null
PASS=0
FAIL=0
SANDBOXES=()

cleanup() {
  for d in "${SANDBOXES[@]}"; do
    rm -rf "$d"
  done
}
trap cleanup EXIT

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $label"; PASS=$((PASS + 1))
  else
    echo "  FAIL: $label (expected='$expected' actual='$actual')"; FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF -- "$needle"; then
    echo "  PASS: $label"; PASS=$((PASS + 1))
  else
    echo "  FAIL: $label (missing '$needle' in: $(echo "$haystack" | head -3 | tr '\n' ' '))"; FAIL=$((FAIL + 1))
  fi
}

# --- サンドボックス ---
GITID=(-c user.name=t -c user.email=t@example.com)

make_sandbox() {
  local sb
  sb=$(mktemp -d)
  SANDBOXES+=("$sb")
  git init -q --bare "$sb/origin.git"
  git clone -q "$sb/origin.git" "$sb/other" 2>/dev/null
  git -C "$sb/other" checkout -q -b master
  echo "v1" > "$sb/other/CLAUDE.md"
  git -C "$sb/other" add CLAUDE.md
  git -C "$sb/other" "${GITID[@]}" commit -q -m init
  git -C "$sb/other" push -q -u origin master 2>/dev/null
  mkdir -p "$sb/home/git_clone"
  git clone -q "$sb/origin.git" "$sb/home/git_clone/dot_claude" 2>/dev/null
  git -C "$sb/home/git_clone/dot_claude" config user.name t
  git -C "$sb/home/git_clone/dot_claude" config user.email t@example.com
  echo "$sb"
}

clone_dir()      { echo "$1/home/git_clone/dot_claude"; }
set_readonly()   { git -C "$(clone_dir "$1")" config dot-claude.readonly true; }
remote_head()    { git -C "$1/origin.git" rev-parse master; }
local_head()     { git -C "$(clone_dir "$1")" rev-parse HEAD; }
remote_advance() {
  echo "remote $2" >> "$1/other/CLAUDE.md"
  git -C "$1/other" "${GITID[@]}" commit -q -am "remote-$2"
  git -C "$1/other" push -q 2>/dev/null
}
local_commit() {
  echo "local $2" > "$(clone_dir "$1")/local-$2.md"
  git -C "$(clone_dir "$1")" add "local-$2.md"
  git -C "$(clone_dir "$1")" commit -q -m "local-$2"
}
rebase_in_progress() {
  local d; d="$(clone_dir "$1")/.git"
  if [ -d "$d/rebase-merge" ] || [ -d "$d/rebase-apply" ]; then echo yes; else echo no; fi
}
run_pull() { HOME="$1/home" bash "$HOOKS_DIR/session-start-pull.sh" 2>&1; }
run_push() { HOME="$1/home" bash "$HOOKS_DIR/session-end-push.sh" 2>&1; }

# --- テストケース ---

echo "Test 1: 通常モード / remote が先行 → pull で取り込む"
sb=$(make_sandbox); remote_advance "$sb" 1
out=$(run_pull "$sb"); st=$?
assert_eq "exit 0" 0 "$st"
assert_contains "INFO 出力" "INFO: dot_claude: pull 成功" "$out"
assert_eq "HEAD が remote に一致" "$(remote_head "$sb")" "$(local_head "$sb")"

echo "Test 2: 通常モード / ローカル commit + remote 先行 → rebase で両立（既存挙動）"
sb=$(make_sandbox); local_commit "$sb" a; remote_advance "$sb" 1
before=$(local_head "$sb")
out=$(run_pull "$sb"); st=$?
assert_eq "exit 0" 0 "$st"
assert_eq "HEAD が変わる（rebase 実行）" "no" "$([ "$before" = "$(local_head "$sb")" ] && echo yes || echo no)"
assert_eq "remote commit を含む" 1 "$(git -C "$(clone_dir "$sb")" log --oneline | grep -c remote-1)"
assert_eq "rebase 途中で止まっていない" no "$(rebase_in_progress "$sb")"

echo "Test 3: read-only / remote 先行・ローカル clean → ff-only で取り込む"
sb=$(make_sandbox); set_readonly "$sb"; remote_advance "$sb" 1
out=$(run_pull "$sb"); st=$?
assert_eq "exit 0" 0 "$st"
assert_contains "INFO 出力" "INFO: dot_claude: pull 成功" "$out"
assert_eq "HEAD が remote に一致" "$(remote_head "$sb")" "$(local_head "$sb")"

echo "Test 4: read-only / ローカル commit + remote 先行 → 何も変えず WARN"
sb=$(make_sandbox); set_readonly "$sb"; local_commit "$sb" a; remote_advance "$sb" 1
before=$(local_head "$sb")
out=$(run_pull "$sb"); st=$?
assert_eq "exit 0" 0 "$st"
assert_contains "read-only の WARN" "read-only モード" "$out"
assert_eq "HEAD 不変" "$before" "$(local_head "$sb")"
assert_eq "rebase 途中で止まっていない" no "$(rebase_in_progress "$sb")"

echo "Test 5: read-only / 未保存変更 + remote が同ファイルを更新 → 変更を守って WARN（autostash しない）"
sb=$(make_sandbox); set_readonly "$sb"
echo "dirty" >> "$(clone_dir "$sb")/CLAUDE.md"; remote_advance "$sb" 1
before=$(local_head "$sb")
out=$(run_pull "$sb"); st=$?
assert_eq "exit 0" 0 "$st"
assert_contains "read-only の WARN" "read-only モード" "$out"
assert_eq "HEAD 不変" "$before" "$(local_head "$sb")"
assert_eq "未保存変更が残る" 1 "$(grep -c dirty "$(clone_dir "$sb")/CLAUDE.md")"
assert_eq "stash が作られていない" 0 "$(git -C "$(clone_dir "$sb")" stash list | wc -l | tr -d ' ')"

echo "Test 6: 通常モード / ローカル commit あり → push hook が push する"
sb=$(make_sandbox); local_commit "$sb" a
out=$(run_push "$sb"); st=$?
assert_eq "exit 0" 0 "$st"
assert_contains "push 成功の INFO" "auto-push 成功" "$out"
assert_eq "remote HEAD がローカルに一致" "$(local_head "$sb")" "$(remote_head "$sb")"

echo "Test 7: read-only / ローカル commit あり → push hook は無言でスキップ"
sb=$(make_sandbox); set_readonly "$sb"; local_commit "$sb" a
rh=$(remote_head "$sb")
out=$(run_push "$sb"); st=$?
assert_eq "exit 0" 0 "$st"
assert_eq "出力なし" "" "$out"
assert_eq "remote HEAD 不変" "$rh" "$(remote_head "$sb")"

echo "Test 8: 通常モード / 差分なし → pull・push とも無音"
sb=$(make_sandbox)
assert_eq "pull 出力なし" "" "$(run_pull "$sb")"
assert_eq "push 出力なし" "" "$(run_push "$sb")"

echo ""
echo "Result: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
