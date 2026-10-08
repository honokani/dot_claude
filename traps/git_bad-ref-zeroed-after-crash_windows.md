# OS クラッシュ後に git のブランチ ref がゼロ埋め（bad ref / 全ファイルが A 表示）

## 症状
ブルースクリーン等の強制再起動のあと、
- `git status --short --branch` の先頭にブランチ名が出ず、全ファイルが `A`（新規追加）扱いになる
- `git fsck` が `error: bad ref for .git/logs/HEAD`（と作業ブランチの reflog）を出す

## 原因
作業中ブランチの ref ファイル（`.git/refs/heads/<branch>`、41 バイト）が NUL で埋まっている。書き込みの途中で電源断・クラッシュが起きた。
オブジェクトと reflog（`.git/logs/...`）は無事なことが多い。

## 確認
- `od -c .git/HEAD` → どのブランチを指しているか
- `od -An -c .git/refs/heads/<branch> | head -1` → `\0 \0 ...` ならゼロ埋め
- `tail -3 .git/logs/refs/heads/<branch>` → 各行 2 列目が「その操作後の位置」。最終行の 2 列目が直前の正しい先頭
- `git cat-file -t <hash>` → commit が残っているか

## 解決
1. 壊れた ref を退避（削除しない）: `mv .git/refs/heads/<branch> _gomi/...`
2. reflog 最終行の新しい側のハッシュを書き戻す: `printf '%s\n' <full-hash> > .git/refs/heads/<branch>`
3. `git status` / `git log -3` / `git fsck --no-dangling` で確認

## 観測
2026-10-08 pj_30croquis（バグチェック 0x139 で再起動後、feat ブランチの ref がゼロ埋め。`5b308e9` を書き戻して復旧）
