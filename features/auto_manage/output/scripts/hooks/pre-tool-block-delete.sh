#!/bin/bash
# PreToolUse hook: 削除系コマンドを bash/powershell 問わずブロック
# 設計: features/auto_manage/recovery.md の安全方針
#
# 動機:
# - permission rule の `Bash(rm *)` deny だけでは PowerShell の Remove-Item や
#   その alias (rm, del, rd, ri, erase) で迂回されうる
# - permission rule の PowerShell syntax は公式ドキュメント未確認
# - PreToolUse hook で tool_input.command を regex 検査する方が確実

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# 直接的な削除系コマンド（行頭 or 区切り文字直後にコマンド名）
DIRECT_DELETE='(^|[[:space:];|&])(rm|rmdir|unlink|del|erase|Remove-Item|rd|ri|shred)([[:space:]]|$)'

# 間接的な削除系（find -delete / xargs rm 等）
INDIRECT_DELETE='(find.+-delete|xargs.+(rm|rmdir|unlink))'

if echo "$CMD" | grep -qiE "$DIRECT_DELETE" || echo "$CMD" | grep -qiE "$INDIRECT_DELETE"; then
    echo "ERROR: 削除系コマンドはブロックされました（pre-tool-block-delete.sh）" >&2
    echo "  検出コマンド: $CMD" >&2
    echo "  対処: 削除せず mv でプロジェクト直下の _gomi/ へ退避（無ければ作成。CLAUDE.md 変更管理）。実削除はユーザーが行う" >&2
    exit 1
fi

exit 0
