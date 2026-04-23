# フロー図

dot_claude 自動管理の各処理を PFD 精神に基づき mermaid で記述する。

PFDの記法・思想（オブジェクト＝丸、タスク＝四角、交互連鎖、具体性の基準、色パレット等）は
[`skills/pfd/SKILL.md`](../skills/pfd/SKILL.md) 参照。

## SessionStart 同期フロー

```mermaid
flowchart TD
    O1(("$CLAUDE_SESSION_ID /<br/>$CLAUDE_PROJECT_DIR"))
    T1["session-start-pull.sh"]
    O2(("git pull 終了コード"))
    O3(("最新版 CLAUDE.md /<br/>GLOBAL_*.md (symlink先)"))
    T2["Claude Code context 読込"]
    O4(("セッション context"))
    O5(("git status 出力<br/>(conflict詳細)"))
    T3["hook stdout 出力"]
    O6(("警告テキスト"))
    R1[/"recovery.md<br/>「1. pull conflict」"/]

    O1 --> T1 --> O2
    O2 -->|"0"| O3 --> T2 --> O4
    O2 -->|"非0"| O5 --> T3 --> O6 --> R1

    classDef obj fill:#dae8fc,stroke:#6c8ebf
    classDef task fill:#fff2cc,stroke:#d6b656
    class O1,O2,O3,O4,O5,O6 obj
    class T1,T2,T3 task
```

## commit 〜 push フロー

```mermaid
flowchart TD
    O_edit(("working tree の<br/>編集済みファイル"))
    T_add["git add"]
    O_staged(("staged diff"))
    T_hook["pre-commit hook:<br/>gitleaks protect --staged"]
    O_rules_pub(("dot_claude/<br/>.gitleaks.toml (汎用)"))
    O_rules_loc(("~/.claude/gitleaks/<br/>rules.toml (ローカル)"))
    O_result(("gitleaks 終了コード<br/>+ 検出レポート"))

    T_commit["git commit"]
    O_head(("local HEAD の<br/>新 commit"))
    T_status["SessionEnd hook:<br/>git status --branch"]
    O_ahead(("ahead N<br/>または up-to-date"))
    O_warn(("警告テキスト"))
    T_out["hook stdout 出力"]
    O_ctx(("警告 in context"))
    T_push["ユーザー: git push"]
    O_remote(("remote HEAD<br/>(更新済)"))
    O_noop(("無変更<br/>→ 無音終了"))

    O_detect(("検出情報<br/>(ファイル/行/パターン)"))
    T_abort["commit 中断<br/>(hook exit 1)"]
    O_staged_left(("staged diff<br/>そのまま残存"))
    R_gl[/"recovery.md<br/>「3. gitleaks検出」"/]

    O_edit --> T_add --> O_staged --> T_hook --> O_result
    O_rules_pub -.補助.-> T_hook
    O_rules_loc -.補助.-> T_hook

    O_result -->|"0"| T_commit --> O_head --> T_status --> O_ahead
    O_ahead -->|"N>0"| O_warn --> T_out --> O_ctx --> T_push --> O_remote
    O_ahead -->|"N=0"| O_noop

    O_result -->|"非0"| O_detect --> T_abort --> O_staged_left --> R_gl

    classDef obj fill:#dae8fc,stroke:#6c8ebf
    classDef task fill:#fff2cc,stroke:#d6b656
    classDef aux fill:#ffe6cc,stroke:#d79b00
    class O_edit,O_staged,O_result,O_head,O_ahead,O_warn,O_ctx,O_remote,O_noop,O_detect,O_staged_left obj
    class T_add,T_hook,T_commit,T_status,T_out,T_push,T_abort task
    class O_rules_pub,O_rules_loc aux
```

## 異常系への接続

各フロー末尾の `recovery.md「...」` ノードが異常系への分岐点。対応手順は [`recovery.md`](recovery.md) 参照。
