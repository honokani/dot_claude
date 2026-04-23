#!/bin/bash
# SessionStart hook: dot_claude の remote 変更を pull で取り込む（Phase 0.2.2）
# 設計: auto_manage/flow_diagram.md SessionStart フロー / plan.md Phase 0.2.2

# dot_claude repo を ~/.claude/CLAUDE.md symlink から動的解決（OS/配置非依存）
REPO=""
if [ -L "$HOME/.claude/CLAUDE.md" ]; then
    target=$(readlink -f "$HOME/.claude/CLAUDE.md" 2>/dev/null || readlink "$HOME/.claude/CLAUDE.md")
    [ -n "$target" ] && REPO=$(dirname "$target")
fi
[ -z "$REPO" ] && REPO="$HOME/git_clone/dot_claude"  # fallback

[ -d "$REPO/.git" ] || exit 0
cd "$REPO" || exit 0

# 同期 pull（rebase + autostash でローカル変更があっても邪魔しない）
pull_output=$(git pull --rebase --autostash 2>&1)
pull_status=$?

if [ $pull_status -eq 0 ]; then
    # 成功時: up-to-date なら無音、更新あれば通知
    if echo "$pull_output" | grep -q "Already up to date"; then
        exit 0
    fi
    echo "INFO: dot_claude: pull 成功、remote の更新を取り込みました"
    echo "$pull_output" | tail -5
else
    echo "WARN: dot_claude: pull 失敗（conflict/reject/detached 等）"
    echo "$pull_output" | head -10
    echo "  手動対処: cd $REPO && git status"
    echo "  詳細: auto_manage/recovery.md「1. pull conflict」"
fi

# hook失敗で起動止めない方針（警告のみ、exit 0）
exit 0
