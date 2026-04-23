#!/bin/bash
# SessionEnd hook: dot_claude の未push commit を自動push（実験運用）
# 設計: features/auto_manage/flow_diagram.md の commit〜push フロー / plan.md Phase 0.2.3

# dot_claude repo を ~/.claude/CLAUDE.md symlink から動的解決（OS/配置非依存）
REPO=""
if [ -L "$HOME/.claude/CLAUDE.md" ]; then
    target=$(readlink -f "$HOME/.claude/CLAUDE.md" 2>/dev/null || readlink "$HOME/.claude/CLAUDE.md")
    [ -n "$target" ] && REPO=$(dirname "$target")
fi
[ -z "$REPO" ] && REPO="$HOME/git_clone/dot_claude"  # fallback

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
    echo "  詳細は features/auto_manage/recovery.md「2. push rejected」参照"
fi
exit 0
