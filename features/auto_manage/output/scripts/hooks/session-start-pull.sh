#!/bin/bash
# SessionStart hook: dot_claude の remote 変更を pull で取り込む（Phase 0.2.2）
# 設計: features/auto_manage/flow_diagram.md SessionStart フロー / plan.md Phase 0.2.2

# dot_claude repo を ~/.claude/CLAUDE.md symlink から動的解決（OS/配置非依存）
REPO=""
if [ -L "$HOME/.claude/CLAUDE.md" ]; then
    target=$(readlink -f "$HOME/.claude/CLAUDE.md" 2>/dev/null || readlink "$HOME/.claude/CLAUDE.md")
    [ -n "$target" ] && REPO=$(dirname "$target")
fi
[ -z "$REPO" ] && REPO="$HOME/git_clone/dot_claude"  # fallback

[ -d "$REPO/.git" ] || exit 0
cd "$REPO" || exit 0

# pull 前の HEAD を記録（表記ゆれに依存しない判定用）
before=$(git rev-parse HEAD 2>/dev/null || echo "")

# 未コミット変更があれば pull しない（stash禁止ルール準拠 / autostash の pop 衝突で
# settings.json 等にコンフリクトマーカーが残り、グローバル設定が壊れる事故を防ぐ）
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "WARN: dot_claude: 未コミット変更あり、pull skip"
    git status --short 2>/dev/null | head -5
    echo "  手動対処: cd $REPO && git status（commit or 破棄してから再起動）"
    exit 0
fi

# 同期 pull（clean な作業ツリーのみ。stash は使わない）
pull_output=$(git pull --rebase 2>&1)
pull_status=$?

after=$(git rev-parse HEAD 2>/dev/null || echo "")

if [ $pull_status -eq 0 ]; then
    # HEAD 変化なし → 更新取込なし、無音
    if [ "$before" = "$after" ]; then
        exit 0
    fi
    echo "INFO: dot_claude: pull 成功、remote の更新を取り込みました（$before → $after）"
    echo "$pull_output" | tail -5
else
    echo "WARN: dot_claude: pull 失敗（conflict/reject/detached 等）"
    echo "$pull_output" | head -10
    echo "  手動対処: cd $REPO && git status"
    echo "  詳細: features/auto_manage/recovery.md「1. pull conflict」"
fi

# hook失敗で起動止めない方針（警告のみ、exit 0）
exit 0
