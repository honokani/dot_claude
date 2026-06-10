#!/bin/bash
# PostToolUse / PostToolUseFailure Hook (matcher: Bash):
#   環境系エラー検出時に tips/ のポインタ（ファイル名+見出しのみ）を additionalContext 注入
#
# stdin: JSON { hook_event_name, tool_input: {command}, tool_response: {stdout, stderr, exit_code} }
#        ※ PostToolUseFailure では tool_response が文字列や欠落の可能性あり → 両対応
# stdout: {"hookSpecificOutput": {"hookEventName": ..., "additionalContext": ...}}
#         （環境系エラー かつ tips該当 のときのみ。それ以外は無音 exit 0）
#
# 設計（GLOBAL_DECISIONS 0.2.16）:
# - 発火条件を環境系シグネチャに限定 — テスト失敗・ビルドエラー等の作業系では発火しない
# - 注入はポインタのみ（数十トークン）。本文の Read 判断は Claude に委ねる段階的開示
# - tips全文注入（~41KB）はコンテキスト浪費のため不採用

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
SIGNATURES='command not found|is not recognized|syntax error|No such file or directory|FileNotFoundError|ModuleNotFoundError|ImportError|UnicodeDecodeError|UnicodeEncodeError|cp932|Permission denied|exec format error|認識されません|見つかりません'
if ! printf '%s' "$ERRTEXT" | grep -qiE "$SIGNATURES"; then
  exit 0
fi

TIPS_DIR="$HOME/.claude/tips"
[ -d "$TIPS_DIR" ] || exit 0

# 主題語照合: ファイル名（主題_細目_環境）の構成語が コマンド/エラー文 に単語として現れるか
SEARCH_TEXT=$(printf '%s\n%s' "$COMMAND" "$ERRTEXT" | head -c 20000)
STOPWORDS=" and to how non the for not with from "
NL=$'\n'
MATCHES=""
for f in "$TIPS_DIR"/*.md; do
  base=$(basename "$f" .md)
  [ "$base" = "README" ] && continue
  for word in $(printf '%s' "$base" | tr '_-' '  '); do
    [ "${#word}" -le 1 ] && continue
    case "$STOPWORDS" in *" $word "*) continue ;; esac
    if printf '%s' "$SEARCH_TEXT" | grep -qiw -- "$word"; then
      heading=$(head -1 "$f" | sed 's/^#\+ *//')
      MATCHES="${MATCHES}- ${base}.md — ${heading}${NL}"
      break
    fi
  done
done

if [ -z "$MATCHES" ]; then
  exit 0
fi

CONTEXT="[tips-hint] 環境系エラーを検出。~/.claude/tips/ に関連しうる既知の罠:${NL}${MATCHES}修正を試みる前に、該当しそうなファイルを Read で確認すること。"

jq -n --arg ev "$EVENT" --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: $ev, additionalContext: $ctx}}'
exit 0
