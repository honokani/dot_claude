# git — `git merge -F -` は標準入力を読めず `error: could not read file '-'`

## 症状
- `git merge --no-ff <branch> -F - <<'EOF' ... EOF` が `error: could not read file '-'` で止まる（2026-10-11、git 2.38.1.windows.1、Git Bash）
- マージは始まらない（ワークツリーもそのまま）。ただし `git checkout develop && git merge ...` とつないでいた場合、checkout は済んでいて、いるブランチが変わっている

## 原因
- `git merge` の `-F <file>` は「-」を標準入力として扱わない（`git commit -F -` は扱う）。「-」という名前のファイルを探して失敗する

## 対処
- メッセージは `-m` で渡す: `git merge --no-ff <branch> -m "Merge <branch> into develop"`。段落を分けたいときは `-m` を重ねる（`-m "1 行目" -m "本文"`）
- 長いメッセージはファイルに書いて `-F <ファイル>` で渡す
- 失敗した後は `git branch --show-current` と `git status` で、いるブランチと途中の状態を確かめてから打ち直す

## 観測
2026-10-11 pj_loratrain（feat/05 を develop へ merge するとき。commit の `-F -` と同じ書き方をした）
