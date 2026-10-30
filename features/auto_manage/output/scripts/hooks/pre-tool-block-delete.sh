#!/bin/bash
# PreToolUse hook: 削除系コマンドを bash/powershell 問わずブロック
# 設計: features/auto_manage/recovery.md の安全方針
#
# 動機:
# - permission rule の `Bash(rm *)` deny だけでは PowerShell の Remove-Item や
#   その alias (rm, del, rd, ri, erase) で迂回されうる
# - permission rule の PowerShell syntax は公式ドキュメント未確認
# - PreToolUse hook で tool_input.command を regex 検査する方が確実
# 止め方: exit 2（PreToolUse で exit 1 は止めない。エラー表示だけでコマンドは実行される。issue #20）
# 試験: scripts/test/hooks/test_block_delete_hook.sh

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# 直接的な削除系コマンド（行頭、または区切り文字・引用符・開き括弧の直後にコマンド名）
# 引用符と括弧: powershell -Command "Remove-Item x"、pwsh -c 'del x'、(rm x) を検出する（issue #20）
SQ="'"
DIRECT_DELETE="(^|[[:space:];|&(\"${SQ}])(rm|rmdir|unlink|del|erase|Remove-Item|rd|ri|shred)([[:space:]]|\$)"

# 間接的な削除系: find の単独の引数 -delete、xargs が（フラグと、その値の後に）実行する rm/rmdir/unlink
# 旧式 `xargs.+(rm|…)` は単語境界が無く、--format や permission の「rm」でも止まった（traps/pre-tool-block-delete_xargs-false-positive.md）
INDIRECT_DELETE='(find.+[[:space:]]-delete([[:space:];&|)]|$)|xargs([[:space:]]+-[^[:space:]]*([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+(rm|rmdir|unlink)([[:space:];&|)]|$))'

if echo "$CMD" | grep -qiE "$DIRECT_DELETE" || echo "$CMD" | grep -qiE "$INDIRECT_DELETE"; then
    echo "ERROR: 削除系コマンドはブロックされました（pre-tool-block-delete.sh）" >&2
    echo "  検出コマンド: $CMD" >&2
    echo "  対処: 削除せず mv でプロジェクト直下の _gomi/ へ退避（無ければ作成。CLAUDE.md 変更管理）。実削除はユーザーが行う" >&2
    exit 2
fi

exit 0
