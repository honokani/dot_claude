#!/bin/bash
# PostToolUse / PostToolUseFailure Hook (matcher: Bash):
#   環境系エラー検出時に traps/ のポインタ（ファイル名+見出しのみ）を additionalContext 注入
#
# stdin: JSON { hook_event_name, tool_input: {command}, tool_response: {stdout, stderr, exit_code} }
#        ※ PostToolUseFailure では tool_response が文字列や欠落の可能性あり → 両対応
# stdout: {"hookSpecificOutput": {"hookEventName": ..., "additionalContext": ...}}
#         （環境系エラー かつ traps該当 のときのみ。それ以外は無音 exit 0）
#
# 設計（GLOBAL_DECISIONS 0.2.16-0.2.17）:
# - 発火条件を環境系シグネチャに限定 — テスト失敗・ビルドエラー等の作業系では発火しない
# - 注入はポインタのみ（数十トークン）。本文の Read 判断は Claude に委ねる段階的開示
# - 全文注入はコンテキスト浪費のため不採用
# - 照合先は traps/（エラー観測可能な躓き専用）。非エラー知見の tips/ は対象外

set -euo pipefail

INPUT=$(cat)

jget() { printf '%s' "$INPUT" | jq -r "$1" 2>/dev/null || true; }

EVENT=$(jget '.hook_event_name // "PostToolUse"')
EXIT_CODE=$(jget '.tool_response.exit_code? // empty')

# 成功イベントで exit 0 / exit_code 不明 → 環境系エラーなし、無音
if [ "$EVENT" = "PostToolUse" ]; then
  if [ -z "$EXIT_CODE" ] || [ "$EXIT_CODE" = "0" ]; then
    exit 0
  fi
fi

COMMAND=$(jget '.tool_input.command // ""')
ERRTEXT=$(jget '
  [ (.tool_response | if type == "string" then . else empty end),
    .tool_response.stderr?, .tool_response.stdout?, .tool_error? ]
  | map(select(. != null and . != "")) | join("\n")')

# 環境系エラーシグネチャ（該当しなければ無音）
SIGNATURES='command not found|is not recognized|syntax error|No such file or directory|FileNotFoundError|ModuleNotFoundError|ImportError|UnicodeDecodeError|UnicodeEncodeError|cp932|Permission denied|exec format error|panicked at|error\[E[0-9]+\]|cannot borrow|os error|Command timed out|認識されません|見つかりません|アクセスが拒否'
if ! printf '%s' "$ERRTEXT" | grep -qiE "$SIGNATURES"; then
  exit 0
fi

TRAPS_DIR="$HOME/.claude/traps"
[ -d "$TRAPS_DIR" ] || exit 0

# 主題語照合: ファイル名（主題_細目_環境）の構成語が コマンド/エラー文 に現れるか（部分一致 —
# serde_json/rustc等の連結識別子に単語境界マッチは効かないため）
SEARCH_TEXT=$(printf '%s\n%s' "$COMMAND" "$ERRTEXT" | head -c 20000)
# 照合エイリアス: cargo/rustcのエラー出力に "rust" は現れないため主題語を補完
case "$SEARCH_TEXT" in *cargo*|*rustc*) SEARCH_TEXT="$SEARCH_TEXT rust" ;; esac
STOPWORDS=" and to how non the for not with from "
NL=$'\n'
MATCHES=""
for f in "$TRAPS_DIR"/*.md; do
  base=$(basename "$f" .md)
  [ "$base" = "README" ] && continue
  for word in $(printf '%s' "$base" | tr '_-' '  '); do
    [ "${#word}" -le 1 ] && continue
    case "$STOPWORDS" in *" $word "*) continue ;; esac
    if printf '%s' "$SEARCH_TEXT" | grep -qi -- "$word"; then
      # 見出しが「# <ファイル名> — 説明」形式の場合はファイル名部を除去（ポインタ行の重複防止）
      heading=$(head -1 "$f" | sed 's/^#\+ *//; s/^'"$base"'\.md *[—-] *//')
      MATCHES="${MATCHES}- ${base}.md — ${heading}${NL}"
      break
    fi
  done
done

if [ -z "$MATCHES" ]; then
  exit 0
fi

CONTEXT="[traps-hint] 環境系エラーを検出。~/.claude/traps/ に関連しうる既知の罠:${NL}${MATCHES}修正を試みる前に、該当しそうなファイルを Read で確認すること。"

jq -n --arg ev "$EVENT" --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: $ev, additionalContext: $ctx}}'
exit 0
