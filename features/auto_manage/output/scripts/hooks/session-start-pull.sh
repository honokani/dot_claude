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

# read-only モード（clone はできるが push できない環境）: その clone で
#   git config dot-claude.readonly true
# を一度実行して有効化。ローカル commit を rebase で動かさず fast-forward だけ試み、
# できなければ何も変えずに警告する（rebase 途中の状態がワークツリーに残らない）
readonly_mode=$(git config --bool --get dot-claude.readonly 2>/dev/null)

if [ "$readonly_mode" = "true" ]; then
    pull_output=$(git pull --ff-only 2>&1)
else
    # 同期 pull（rebase + autostash でローカル変更があっても邪魔しない）
    pull_output=$(git pull --rebase --autostash 2>&1)
fi
pull_status=$?

after=$(git rev-parse HEAD 2>/dev/null || echo "")

if [ $pull_status -eq 0 ]; then
    # HEAD 変化なし → 更新取込なし、無音
    if [ "$before" = "$after" ]; then
        exit 0
    fi
    echo "INFO: dot_claude: pull 成功、remote の更新を取り込みました（$before → $after）"
    echo "$pull_output" | tail -5
elif [ "$readonly_mode" = "true" ]; then
    echo "WARN: dot_claude: pull --ff-only 失敗（read-only モード。ローカルに commit/未保存変更があるか、remote に到達できません。ワークツリーは変更していません）"
    echo "$pull_output" | head -10
    echo "  手動対処: cd $REPO && git status（read-only 環境では clone を編集・commit しない運用。詳細: MAINTENANCE.md「read-only モード」）"
else
    echo "WARN: dot_claude: pull 失敗（conflict/reject/detached 等）"
    echo "$pull_output" | head -10
    echo "  手動対処: cd $REPO && git status"
    echo "  詳細: features/auto_manage/recovery.md「1. pull conflict」"
fi

# hook失敗で起動止めない方針（警告のみ、exit 0）
exit 0
