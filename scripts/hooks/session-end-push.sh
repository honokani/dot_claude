#!/bin/bash
# SessionEnd hook: dot_claude の未push commit を自動push（実験運用）
# 設計: auto_manage/flow_diagram.md の commit〜push フロー / plan.md Phase 0.2.3

REPO="$HOME/git_clone/dot_claude"
[ -d "$REPO/.git" ] || exit 0
cd "$REPO" || exit 0

# 未pushの ahead count 取得（upstream未設定・detached等は 0 扱い）
ahead=$(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
[ "$ahead" -eq 0 ] && exit 0

echo "INFO: dot_claude: ${ahead} commit(s) to push"
if git push 2>&1; then
    echo "INFO: auto-push 成功"
else
    echo "WARN: auto-push 失敗。手動で解決:"
    echo "  cd $REPO && git status"
    echo "  詳細は auto_manage/recovery.md「2. push rejected」参照"
fi
exit 0
