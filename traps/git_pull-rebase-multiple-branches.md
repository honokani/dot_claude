# git pull --rebase が「Cannot rebase onto multiple branches」で失敗する

## 症状

SessionStart hook（session-start-pull.sh）や手動の `git pull --rebase` が:

```
fatal: Cannot rebase onto multiple branches.
```

ff-only 側の同型は `Cannot fast-forward to multiple branches.`。

## 原因

`git pull` は fetch が `.git/FETCH_HEAD` に書いた for-merge 行（`not-for-merge` マークの無い行）を rebase/merge 先として読む。これが2行以上あると rebase 開始前に即 fatal。2行以上になる経路は2つ:

1. **FETCH_HEAD の並行書き込み競合（一過性）** — FETCH_HEAD は refs と違いロックされないため、同一 repo で複数の git プロセスが同時に fetch/pull すると for-merge 行が混ざる。dot_claude は全セッション共通の SessionStart hook が pull するので、Claude Code をほぼ同時に2窓起動すると踏みうる。VS Code の git 拡張のバックグラウンド fetch との競合も同型（`git config --get-regexp vscode-merge-base` が出れば VS Code もこの repo を触っている）
2. **branch.<name>.merge の重複（恒久）** — `.git/config` に同じブランチの `merge =` 行が2本ある（config 書き込みの競合や手編集の残骸）

## 診断

```sh
git config --get-all "branch.$(git branch --show-current).merge"  # 2行出たら原因2
cat .git/FETCH_HEAD   # not-for-merge の無い行が2行以上なら直前の競合の痕跡（次の fetch で上書きされる）
ls .git/rebase-merge .git/rebase-apply 2>/dev/null  # 無ければ rebase 未開始＝ワークツリー無傷
```

## 解決

- 原因1: 何もしなくてよい。再実行（次セッション起動 or 手動 `git pull --rebase --autostash`）で成功する。fatal は rebase 開始前なのでブランチ・ワークツリーに副作用なし
- 原因2: `git config --unset-all branch.<name>.merge && git config branch.<name>.merge refs/heads/<name>`

## 実測

2026-10-01 dot_claude で観測（別セッションの SessionStart hook が WARN）。診断の結果 config 重複なし・FETCH_HEAD 正常・残骸なし・hook 再実行成功 → 原因1と判定。競合相手のプロセスは未特定（推測: 同時起動した別セッションの hook、または VS Code の fetch）。
