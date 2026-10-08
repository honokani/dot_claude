# `cmd | tail -3 && next` で cmd の失敗が握りつぶされ、後続が走る

## 症状
`git pull --ff-only 2>&1 | tail -3 && git commit ... && git push` で pull が `Aborting` したのに commit が実行され、
push が non-fast-forward で拒否されて「ローカルだけ ahead 1 / behind N」の分岐状態が残る。

## 原因
パイプラインの終了ステータスは最後のコマンド（`tail`）のもの。`set -o pipefail` がない限り前段の失敗は `&&` に伝わらない。

## 解決
- 失敗を後続の条件にするコマンドはパイプに通さない（出力を絞りたいなら変数に取ってから表示）
- または `set -o pipefail` を先頭に置く
- 分岐してしまったら、自分のローカルコミットだけを `git reset --mixed HEAD~1` で戻す（作業ツリーは保持・reflog で復元可）。autostash は使わない（settings.json 衝突の前例: GLOBAL_PROGRESS 0.2.25）

## 観測
2026-10-08 pj_30croquis 作業中の dot_claude 反映（ユーザ未コミットの settings.json と取り込みが衝突して pull 中断）
