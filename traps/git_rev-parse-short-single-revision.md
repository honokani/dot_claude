# git rev-parse --short に ref を2つ渡すと「Needed a single revision」で失敗する

## 症状

ブランチがそろっているかを1行で見ようとして ref を並べると:

```
$ git rev-parse --short develop master
fatal: Needed a single revision
```

## 原因

`--short` は `--verify` と同じ扱いで、引数を「ちょうど1つ」の object として解決する。2つ以上渡すと失敗する（`--short` なしの `git rev-parse develop master` は2行出せる）。

## 解決

- 1つずつ渡す: `git rev-parse --short develop && git rev-parse --short master`
- 並べて見るだけなら `--short` を外す: `git rev-parse develop master`（フルハッシュが2行）

## 観測
- 2026-11-01 pj_traincolor（記録をコミットした後、develop と master が同じかを `git rev-parse --short master develop` で見ようとした）
- 2026-11-02 pj_traincolor（同じ会話の2回目。`git fetch -q . develop:master` の後に `git rev-parse --short develop master` を付け、コミットと fetch は済んでいたのに exit 128 になった）
