# フロー図

dot_claude 自動管理の各処理を PFD 精神に基づく箇条書きで記述する。

PFD の記法・思想（`◯` オブジェクト、`[ ]` タスク、交互連鎖、具体性の基準等）は
[`skills/pfd/SKILL.md`](../skills/pfd/SKILL.md) を参照。

## SessionStart 同期フロー

```
◯ $CLAUDE_SESSION_ID / $CLAUDE_PROJECT_DIR
  → [ session-start-pull.sh ]
  → ◯ git pull 終了コード

├─ 0   → ◯ 最新版 CLAUDE.md / GLOBAL_*.md (symlink先)
│        → [ Claude Code context 読込 ]
│        → ◯ セッション context
│
└─ 非0 → ◯ git status 出力 (conflict詳細)
         → [ hook stdout 出力 ]
         → ◯ 警告テキスト
         → recovery.md「1. pull conflict」
```

## commit 〜 push フロー

```
◯ working tree の編集済みファイル
  → [ git add ]
  → ◯ staged diff
  → [ pre-commit hook: gitleaks protect --staged ]
     補助入力:
       ◯ dot_claude/.gitleaks.toml (汎用)
       ◯ ~/.claude/gitleaks/rules.toml (ローカル)
  → ◯ gitleaks 終了コード + 検出レポート

├─ 0   → [ git commit ]
│        → ◯ local HEAD の新 commit
│        → [ SessionEnd hook: git status --branch ]
│        → ◯ "ahead N" または "up-to-date"
│
│        ├─ N>0 → ◯ 警告テキスト
│        │        → [ hook stdout 出力 ]
│        │        → ◯ 警告 in context
│        │        → [ ユーザー: git push ]
│        │        → ◯ remote HEAD (更新済)
│        │
│        └─ N=0 → ◯ 無変更 → 無音終了
│
└─ 非0 → ◯ 検出情報 (ファイル・行・パターンID)
         → [ commit 中断 (hook exit 1) ]
         → ◯ staged diff そのまま残存
         → recovery.md「3. gitleaks検出」
```

## 異常系への接続

各フロー末尾の `recovery.md「...」` が異常系への分岐点。対応手順は [`recovery.md`](recovery.md) を参照。
